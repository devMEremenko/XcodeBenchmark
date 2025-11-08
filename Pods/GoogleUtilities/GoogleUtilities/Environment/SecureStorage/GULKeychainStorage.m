/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainStorage.h"
#import <Security/Security.h>

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainUtils.h"

@interface GULKeychainStorage ()
@property(nonatomic, readonly) dispatch_queue_t keychainQueue;
@property(nonatomic, readonly) dispatch_queue_t inMemoryCacheQueue;
@property(nonatomic, readonly) NSString *service;
@property(nonatomic, readonly) NSCache<NSString *, id<NSSecureCoding>> *inMemoryCache;
@end

@implementation GULKeychainStorage

- (instancetype)initWithService:(NSString *)service {
  NSCache *cache = [[NSCache alloc] init];
  // Cache up to 5 installations.
  cache.countLimit = 5;
  return [self initWithService:service cache:cache];
}

- (instancetype)initWithService:(NSString *)service cache:(NSCache *)cache {
  self = [super init];
  if (self) {
    _keychainQueue =
        dispatch_queue_create("com.gul.KeychainStorage.Keychain", DISPATCH_QUEUE_SERIAL);
    _inMemoryCacheQueue =
        dispatch_queue_create("com.gul.KeychainStorage.InMemoryCache", DISPATCH_QUEUE_SERIAL);
    _service = [service copy];
    _inMemoryCache = cache;
  }
  return self;
}

#pragma mark - Public

- (void)getObjectForKey:(NSString *)key
            objectClass:(Class)objectClass
            accessGroup:(nullable NSString *)accessGroup
      completionHandler:
          (void (^)(id<NSSecureCoding> _Nullable obj, NSError *_Nullable error))completionHandler {
  dispatch_async(self.inMemoryCacheQueue, ^{
    // Return cached object or fail otherwise.
    id object = [self.inMemoryCache objectForKey:key];
    if (object) {
      completionHandler(object, nil);
    } else {
      // Look for the object in the keychain.
      [self getObjectFromKeychainForKey:key
                            objectClass:objectClass
                            accessGroup:accessGroup
                      completionHandler:completionHandler];
    }
  });
}

- (void)setObject:(id<NSSecureCoding>)object
               forKey:(NSString *)key
          accessGroup:(nullable NSString *)accessGroup
    completionHandler:
        (void (^)(id<NSSecureCoding> _Nullable obj, NSError *_Nullable error))completionHandler {
  dispatch_async(self.inMemoryCacheQueue, ^{
    // Save to the in-memory cache first.
    [self.inMemoryCache setObject:object forKey:[key copy]];

    dispatch_async(self.keychainQueue, ^{
      // Then store the object to the keychain.
      NSDictionary *query = [self keychainQueryWithKey:key accessGroup:accessGroup];
      NSError *error;
      NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object
                                                    requiringSecureCoding:YES
                                                                    error:&error];
      if (!encodedObject) {
        completionHandler(nil, error);
        return;
      }

      if (![GULKeychainUtils setItem:encodedObject withQuery:query error:&error]) {
        completionHandler(nil, error);
        return;
      }

      completionHandler(object, nil);
    });
  });
}

- (void)removeObjectForKey:(NSString *)key
               accessGroup:(nullable NSString *)accessGroup
         completionHandler:(void (^)(NSError *_Nullable error))completionHandler {
  dispatch_async(self.inMemoryCacheQueue, ^{
    [self.inMemoryCache removeObjectForKey:key];
    dispatch_async(self.keychainQueue, ^{
      NSDictionary *query = [self keychainQueryWithKey:key accessGroup:accessGroup];

      NSError *error;
      if (![GULKeychainUtils removeItemWithQuery:query error:&error]) {
        completionHandler(error);
      } else {
        completionHandler(nil);
      }
    });
  });
}

#pragma mark - Private

- (void)getObjectFromKeychainForKey:(NSString *)key
                        objectClass:(Class)objectClass
                        accessGroup:(nullable NSString *)accessGroup
                  completionHandler:(void (^)(id<NSSecureCoding> _Nullable obj,
                                              NSError *_Nullable error))completionHandler {
  // Look for the object in the keychain.
  dispatch_async(self.keychainQueue, ^{
    NSDictionary *query = [self keychainQueryWithKey:key accessGroup:accessGroup];
    NSError *error;
    NSData *encodedObject = [GULKeychainUtils getItemWithQuery:query error:&error];

    if (error) {
      completionHandler(nil, error);
      return;
    }
    if (!encodedObject) {
      completionHandler(nil, nil);
      return;
    }
    id object = [NSKeyedUnarchiver unarchivedObjectOfClass:objectClass
                                                  fromData:encodedObject
                                                     error:&error];
    if (error) {
      completionHandler(nil, error);
      return;
    }

    dispatch_async(self.inMemoryCacheQueue, ^{
      // Save object to the in-memory cache if exists and return the object.
      if (object) {
        [self.inMemoryCache setObject:object forKey:[key copy]];
      }

      completionHandler(object, nil);
    });
  });
}

- (void)resetInMemoryCache {
  [self.inMemoryCache removeAllObjects];
}

#pragma mark - Keychain

- (NSMutableDictionary<NSString *, id> *)keychainQueryWithKey:(NSString *)key
                                                  accessGroup:(nullable NSString *)accessGroup {
  NSMutableDictionary<NSString *, id> *query = [NSMutableDictionary dictionary];

  query[(__bridge NSString *)kSecClass] = (__bridge NSString *)kSecClassGenericPassword;
  query[(__bridge NSString *)kSecAttrService] = self.service;
  query[(__bridge NSString *)kSecAttrAccount] = key;

  if (accessGroup) {
    query[(__bridge NSString *)kSecAttrAccessGroup] = accessGroup;
  }

  if (@available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, *)) {
    // Ensures that the keychain query behaves the same across all platforms.
    // See go/firebase-macos-keychain-popups for details.
    query[(__bridge id)kSecUseDataProtectionKeychain] = (__bridge id)kCFBooleanTrue;
  }

#if TARGET_OS_OSX
  if (self.keychainRef) {
    query[(__bridge NSString *)kSecUseKeychain] = (__bridge id)(self.keychainRef);
    query[(__bridge NSString *)kSecMatchSearchList] = @[ (__bridge id)(self.keychainRef) ];
  }
#endif  // TARGET_OS_OSX

  return query;
}

@end
