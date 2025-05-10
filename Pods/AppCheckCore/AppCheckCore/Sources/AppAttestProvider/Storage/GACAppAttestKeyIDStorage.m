/*
 * Copyright 2021 Google LLC
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

#import "AppCheckCore/Sources/AppAttestProvider/Storage/GACAppAttestKeyIDStorage.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import <GoogleUtilities/GULUserDefaults.h>

#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"

/// The `GULUserDefaults` suite name for the storage location of the app attest key ID.
static NSString *const kKeyIDStorageDefaultsSuiteName = @"com.firebase.GACAppAttestKeyIDStorage";

@interface GACAppAttestKeyIDStorage ()

@property(nonatomic, readonly) NSString *keySuffix;

/// The app attest key ID is stored using `GULUserDefaults` .
@property(nonatomic, readonly) GULUserDefaults *userDefaults;

@end

@implementation GACAppAttestKeyIDStorage

- (instancetype)initWithKeySuffix:(NSString *)keySuffix {
  self = [super init];
  if (self) {
    _keySuffix = [keySuffix copy];
    _userDefaults = [[GULUserDefaults alloc] initWithSuiteName:kKeyIDStorageDefaultsSuiteName];
  }
  return self;
}

- (nonnull FBLPromise<NSString *> *)setAppAttestKeyID:(nullable NSString *)keyID {
  [self storeAppAttestKeyID:keyID];
  return [FBLPromise resolvedWith:keyID];
}

- (nonnull FBLPromise<NSString *> *)getAppAttestKeyID {
  NSString *appAttestKeyID = [self appAttestKeyIDFromStorage];
  if (appAttestKeyID) {
    return [FBLPromise resolvedWith:appAttestKeyID];
  } else {
    NSError *error = [GACAppCheckErrorUtil appAttestKeyIDNotFound];
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise reject:error];
    return rejectedPromise;
  }
}

#pragma mark - Helpers

- (void)storeAppAttestKeyID:(nullable NSString *)keyID {
  if (keyID) {
    [self.userDefaults setObject:keyID forKey:[self keyIDStorageKey]];
  } else {
    [self.userDefaults removeObjectForKey:[self keyIDStorageKey]];
  }
}

- (nullable NSString *)appAttestKeyIDFromStorage {
  NSString *appAttestKeyID = nil;
  appAttestKeyID = [self.userDefaults objectForKey:[self keyIDStorageKey]];
  return appAttestKeyID;
}

- (NSString *)keyIDStorageKey {
  return [NSString stringWithFormat:@"app_attest_keyID.%@", self.keySuffix];
}

@end
