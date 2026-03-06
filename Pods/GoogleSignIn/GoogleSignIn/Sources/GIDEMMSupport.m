/*
 * Copyright 2022 Google LLC
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDEMMSupport.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";
static NSString *const kEMMOSVersionParameterName = @"device_os";
static NSString *const kEMMPasscodeInfoParameterName = @"emm_passcode_info";

// Old UIDevice system name for iOS.
static NSString *const kOldIOSSystemName = @"iPhone OS";

// New UIDevice system name for iOS.
static NSString *const kNewIOSSystemName = @"iOS";

// The error key in the server response.
static NSString *const kErrorKey = @"error";

// Optional separator between error prefix and the payload.
static NSString *const kErrorPayloadSeparator = @":";

// A list for recognized error codes.
typedef NS_ENUM(NSInteger, ErrorCode) {
  ErrorCodeNone = 0,
  ErrorCodeDeviceNotCompliant,
  ErrorCodeScreenlockRequired,
  ErrorCodeAppVerificationRequired,
};

@implementation GIDEMMSupport

- (instancetype)init {
  return [super init];
}

+ (void)handleTokenFetchEMMError:(nullable NSError *)error
                      completion:(void (^)(NSError *_Nullable))completion {
  NSDictionary *errorJSON = error.userInfo[OIDOAuthErrorResponseErrorKey];
  if (errorJSON) {
    __block BOOL handled = NO;
    handled = [[GIDEMMErrorHandler sharedInstance] handleErrorFromResponse:errorJSON
                                                                completion:^() {
      if (handled) {
        completion([NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeEMM
                                   userInfo:error.userInfo]);
      } else {
        completion(error);
      }
    }];
  } else {
    completion(error);
  }
}

+ (NSDictionary *)updatedEMMParametersWithParameters:(NSDictionary *)parameters {
  return [self parametersWithParameters:parameters
                             emmSupport:parameters[kEMMSupportParameterName]
                 isPasscodeInfoRequired:parameters[kEMMPasscodeInfoParameterName] != nil];
}


+ (NSDictionary *)parametersWithParameters:(NSDictionary *)parameters
                                emmSupport:(nullable NSString *)emmSupport
                    isPasscodeInfoRequired:(BOOL)isPasscodeInfoRequired {
  if (!emmSupport) {
    return parameters;
  }
  NSMutableDictionary *allParameters = [(parameters ?: @{}) mutableCopy];
  allParameters[kEMMSupportParameterName] = emmSupport;
  UIDevice *device = [UIDevice currentDevice];
  NSString *systemName = device.systemName;
  if ([systemName isEqualToString:kOldIOSSystemName]) {
    systemName = kNewIOSSystemName;
  }
  allParameters[kEMMOSVersionParameterName] =
      [NSString stringWithFormat:@"%@ %@", systemName, device.systemVersion];
  if (isPasscodeInfoRequired) {
    allParameters[kEMMPasscodeInfoParameterName] = [GIDMDMPasscodeState passcodeState].info;
  }
  return allParameters;
}

#pragma mark - GTMAuthSessionDelegate

- (nullable NSDictionary<NSString *,NSString *> *)
additionalTokenRefreshParametersForAuthSession:(GTMAuthSession *)authSession {
  return [GIDEMMSupport updatedEMMParametersWithParameters:
          authSession.authState.lastTokenResponse.additionalParameters];
}

- (void)updateErrorForAuthSession:(GTMAuthSession *)authSession
                    originalError:(NSError *)originalError
                       completion:(void (^)(NSError * _Nullable))completion {
  [GIDEMMSupport handleTokenFetchEMMError:originalError completion:^(NSError *_Nullable error) {
    completion(error);
  }];
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
