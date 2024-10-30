// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDMDMPasscodeCache.h"

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>

#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState_Private.h"

NS_ASSUME_NONNULL_BEGIN

/** The JSON key for passcode info obtained by LocalAuthentication API. */
static NSString *const kLocalAuthenticationKey = @"LocalAuthentication";

/** The JSON key for passcode info obtained by Keychain API. */
static NSString *const kKeychainKey = @"Keychain";

/** The JSON key for API result. */
static NSString *const kResultKey = @"result";

/** The JSON key for error domain. */
static NSString *const kErrorDomainKey = @"error_domain";

/** The JSON key for error code. */
static NSString *const kErrorCodeKey = @"error_code";

/** Service name for the keychain item used to probe passcode state. */
static NSString * const kPasscodeStatusService = @"com.google.MDM.PasscodeKeychainService";

/** Account name for the keychain item used to probe passcode state. */
static NSString * const kPasscodeStatusAccount = @"com.google.MDM.PasscodeKeychainAccount";

/** The time for passcode state retrieved by Keychain API to be cached. */
static const NSTimeInterval kKeychainInfoCacheTime = 5;

/** The time to wait (in nanaoseconds) on obtaining keychain info. */
static const int64_t kObtainKeychainInfoWaitTime = 3 * NSEC_PER_SEC;

@implementation GIDMDMPasscodeCache {
  /** Whether or not LocalAuthentication API is available. */
  BOOL _hasLocalAuthentication;

  /** The passcode information obtained by LocalAuthentication API. */
  NSDictionary<NSString *, NSObject *> *_localAuthenticationInfo;

  /** Whether the app has entered background since _localAuthenticationInfo was obtained. */
  BOOL _hasEnteredBackground;

  /** Whether or not Keychain API is available. */
  BOOL _hasKeychain;

  /** The passcode information obtained by LocalAuthentication API. */
  NSDictionary<NSString *, NSObject *> *_keychainInfo;

  /** The timestamp for _keychainInfo to expire. */
  NSDate *_keychainExpireTime;

  /** The cached passcode state. */
  GIDMDMPasscodeState *_cachedState;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _hasLocalAuthentication = [self hasLocalAuthentication];
    _hasKeychain = [self hasKeychain];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationDidEnterBackground:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
  static GIDMDMPasscodeCache *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GIDMDMPasscodeCache alloc] init];
  });
  return sharedInstance;
}

- (GIDMDMPasscodeState *)passcodeState {
  // If the method is called by multiple threads at the same time, they need to execute sequentially
  // to maintain internal data integrity.
  @synchronized(self) {
    BOOL refreshLocalAuthentication = _hasLocalAuthentication &&
        (_localAuthenticationInfo == nil || _hasEnteredBackground);
    BOOL refreshKeychain = _hasKeychain &&
        (_keychainInfo == nil || [_keychainExpireTime timeIntervalSinceNow] < 0);

    if (!refreshLocalAuthentication && !refreshKeychain && _cachedState) {
      return _cachedState;
    }

    static dispatch_queue_t workQueue;
    static dispatch_semaphore_t semaphore;
    if (!workQueue) {
      workQueue = dispatch_queue_create("com.google.MDM.PasscodeWorkQueue", DISPATCH_QUEUE_SERIAL);
      semaphore = dispatch_semaphore_create(0);
    }
    if (refreshKeychain) {
      _keychainInfo = nil;
      dispatch_async(workQueue, ^() {
        [self obtainKeychainInfo];
        dispatch_semaphore_signal(semaphore);
      });
    }

    if (refreshLocalAuthentication) {
      [self obtainLocalAuthenticationInfo];
    }

    if (refreshKeychain) {
      dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kObtainKeychainInfoWaitTime);
      dispatch_semaphore_wait(semaphore, timeout);
    }
    _cachedState = [[GIDMDMPasscodeState alloc] initWithStatus:[self status] info:[self info]];
    return _cachedState;
  }
}

#pragma mark - Private Methods

/**
 * Detects whether LocalAuthentication API is available for passscode detection purpose.
 */
- (BOOL)hasLocalAuthentication {
  // While the LocalAuthentication framework itself is available at iOS 8+, the particular constant
  // we need, kLAPolicyDeviceOwnerAuthentication, is only available at iOS 9+. Since the constant
  // is defined as a macro, there is no good way to detect its availability at runtime, so we can
  // only check OS version here.
  NSProcessInfo *processInfo = [NSProcessInfo processInfo];
  return [processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] &&
      [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9}];
}

/**
 * Detects whether Keychain API is available for passscode detection purpose.
 */
- (BOOL)hasKeychain {
  // While the Keychain Source is available at iOS 4+, the particular constant we need,
  // kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, is only available at iOS 8+.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
  return &kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly != NULL;
#pragma clang diagnostic pop
}

/**
 * Handles the notification for the application entering background.
 */
- (void)applicationDidEnterBackground:(NSNotification *)notification {
  _hasEnteredBackground = YES;
}

/**
 * Obtains device passcode presence info with LocalAuthentication APIs.
 */
- (void)obtainLocalAuthenticationInfo {
#if DEBUG
  NSLog(@"Calling LocalAuthentication API for device passcode state...");
#endif
  _hasEnteredBackground = NO;
  static LAContext *context;
  @try {
    if (!context) {
      context = [[LAContext alloc] init];
    }
  } @catch (NSException *) {
    // In theory there should be no exceptions but in practice there may be: b/23200390, b/23218643.
    return;
  }
  int result;
  NSError *error;
  result = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error] ? 1 : 0;
  if (error) {
    _localAuthenticationInfo = @{
      kResultKey : @(result),
      kErrorDomainKey : error.domain,
      kErrorCodeKey : @(error.code),
    };
  } else {
    _localAuthenticationInfo = @{
      kResultKey : @(result),
    };
  }
}

/**
 * Obtains device passcode presence info with Keychain APIs.
 */
- (void)obtainKeychainInfo {
#if DEBUG
  NSLog(@"Calling Keychain API for device passcode state...");
#endif
  _keychainExpireTime = [NSDate dateWithTimeIntervalSinceNow:kKeychainInfoCacheTime];
  static NSDictionary *attributes;
  static NSDictionary *query;
  if (!attributes) {
    NSData *secret = [@"Has passcode set?" dataUsingEncoding:NSUTF8StringEncoding];
    attributes = @{
      (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
      (__bridge id)kSecAttrService : kPasscodeStatusService,
      (__bridge id)kSecAttrAccount : kPasscodeStatusAccount,
      (__bridge id)kSecValueData : secret,
      (__bridge id)kSecAttrAccessible :
          (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    };
    query = @{
      (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
      (__bridge id)kSecAttrService: kPasscodeStatusService,
      (__bridge id)kSecAttrAccount: kPasscodeStatusAccount
    };
  }
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
  if (status == errSecDuplicateItem) {
    // If for some reason the item already exists, delete the item and try again.
    SecItemDelete((__bridge CFDictionaryRef)query);
    status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
  };
  if (status == errSecSuccess) {
    SecItemDelete((__bridge CFDictionaryRef)query);
  }
  _keychainInfo = @{
    kResultKey : @(status)
  };
}

/**
 * Computes the status string from the current data.
 */
- (NSString *)status {
  // Prefer LocalAuthentication info if available.
  if (_localAuthenticationInfo != nil) {
    return ((NSNumber *)_localAuthenticationInfo[kResultKey]).boolValue ? @"YES" : @"NO";
  }
  if (_keychainInfo != nil){
    switch ([(NSNumber *)_keychainInfo[kResultKey] intValue]) {
      case errSecSuccess:
        return @"YES";
      case errSecDecode:  // iOS 8.0+
      case errSecAuthFailed:  // iOS 9.1+
      case errSecNotAvailable:  // iOS 11.0+
        return @"NO";
      default:
        break;
    }
  }
  return @"UNCHECKED";
}

/**
 * Computes the encoded detailed information string from the current data.
 */
- (NSString *)info {
  NSMutableDictionary<NSString *, NSDictionary<NSString *, NSObject *> *> *infoDict =
      [NSMutableDictionary dictionaryWithCapacity:2];
  if (_localAuthenticationInfo) {
    infoDict[kLocalAuthenticationKey] = _localAuthenticationInfo;
  }
  if (_keychainInfo) {
    infoDict[kKeychainKey] = _keychainInfo;
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:infoDict
                                                 options:0
                                                   error:NULL];
  NSString *string = [data base64EncodedStringWithOptions:0];
  string = [string stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  string = [string stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  return string ?: @"e30=";  // Use encoded "{}" in case of error.
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
