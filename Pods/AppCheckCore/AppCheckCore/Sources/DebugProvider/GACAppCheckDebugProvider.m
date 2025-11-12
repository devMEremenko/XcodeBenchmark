/*
 * Copyright 2020 Google LLC
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

#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckDebugProvider.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import <GoogleUtilities/GULUserDefaults.h>

#import "AppCheckCore/Sources/Core/APIService/GACAppCheckAPIService.h"
#import "AppCheckCore/Sources/Core/GACAppCheckLogger+Internal.h"
#import "AppCheckCore/Sources/DebugProvider/API/GACAppCheckDebugProviderAPIService.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckErrors.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckToken.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kDebugTokenEnvKey = @"AppCheckDebugToken";
static NSString *const kFirebaseDebugTokenEnvKey = @"FIRAAppCheckDebugToken";
static NSString *const kDebugTokenUserDefaultsKey = @"GACAppCheckDebugToken";

@interface GACAppCheckDebugProvider ()
@property(nonatomic, readonly) id<GACAppCheckDebugProviderAPIServiceProtocol> APIService;
@property(nonatomic, readonly, nullable, copy) NSString *debugTokenEnvValue;
@end

@implementation GACAppCheckDebugProvider

- (instancetype)initWithAPIService:(id<GACAppCheckDebugProviderAPIServiceProtocol>)APIService {
  self = [super init];
  if (self) {
    _APIService = APIService;
    _debugTokenEnvValue = EnvironmentVariableDebugToken();
  }
  return self;
}

- (instancetype)initWithServiceName:(NSString *)serviceName
                       resourceName:(NSString *)resourceName
                            baseURL:(nullable NSString *)baseURL
                             APIKey:(NSString *)APIKey
                       requestHooks:(nullable NSArray<GACAppCheckAPIRequestHook> *)requestHooks {
  NSURLSession *URLSession = [NSURLSession
      sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];

  GACAppCheckAPIService *APIService =
      [[GACAppCheckAPIService alloc] initWithURLSession:URLSession
                                                baseURL:baseURL
                                                 APIKey:APIKey
                                           requestHooks:requestHooks];

  GACAppCheckDebugProviderAPIService *debugAPIService =
      [[GACAppCheckDebugProviderAPIService alloc] initWithAPIService:APIService
                                                        resourceName:resourceName];

  return [self initWithAPIService:debugAPIService];
}

- (NSString *)currentDebugToken {
  if (self.debugTokenEnvValue) {
    return self.debugTokenEnvValue;
  } else {
    return [self localDebugToken];
  }
}

- (NSString *)localDebugToken {
  return LocalDebugToken();
}

#pragma mark - GACAppCheckProvider

- (void)getTokenWithCompletion:(void (^)(GACAppCheckToken *_Nullable, NSError *_Nullable))handler {
  [self getTokenWithLimitedUse:NO completion:handler];
}

- (void)getLimitedUseTokenWithCompletion:(void (^)(GACAppCheckToken *_Nullable,
                                                   NSError *_Nullable))handler {
  [self getTokenWithLimitedUse:YES completion:handler];
}

#pragma mark - Internal

- (void)getTokenWithLimitedUse:(BOOL)limitedUse
                    completion:(void (^)(GACAppCheckToken *_Nullable token,
                                         NSError *_Nullable error))handler {
  [FBLPromise do:^NSString * {
    return [self currentDebugToken];
  }]
      .then(^FBLPromise<GACAppCheckToken *> *(NSString *debugToken) {
        return [self.APIService appCheckTokenWithDebugToken:debugToken limitedUse:limitedUse];
      })
      .then(^id(GACAppCheckToken *appCheckToken) {
        handler(appCheckToken, nil);
        return nil;
      })
      .catch(^void(NSError *error) {
        NSString *logMessage = [NSString
            stringWithFormat:@"Failed to exchange debug token to app check token: %@", error];
        GACAppCheckLogDebug(GACLoggerAppCheckMessageDebugProviderFailedExchange, logMessage);
        handler(nil, error);
      });
}

static NSString *LocalDebugToken(void) {
  return StoredDebugToken() ?: GenerateAndStoreDebugToken();
}

static NSString *_Nullable StoredDebugToken(void) {
  return [[GULUserDefaults standardUserDefaults] stringForKey:kDebugTokenUserDefaultsKey];
}

static NSString *GenerateAndStoreDebugToken(void) {
  NSString *token = [NSUUID UUID].UUIDString;
  [[GULUserDefaults standardUserDefaults] setObject:token forKey:kDebugTokenUserDefaultsKey];
  return token;
}

static NSString *_Nullable EnvironmentVariableDebugToken(void) {
  NSDictionary<NSString *, NSString *> *environment = [[NSProcessInfo processInfo] environment];
  NSString *envVariableValue = environment[kDebugTokenEnvKey];
  NSString *firebaseEnvVariableValue = environment[kFirebaseDebugTokenEnvKey];
  if (envVariableValue.length == 0) {
    envVariableValue = nil;
  }
  if (firebaseEnvVariableValue == 0) {
    firebaseEnvVariableValue = nil;
  }

  if (envVariableValue && firebaseEnvVariableValue) {
    GACAppCheckLog(
        GACLoggerAppCheckMessageDebugProviderFirebaseEnvironmentVariable,
        GACAppCheckLogLevelWarning,
        [NSString stringWithFormat:@"The environment variables %@ and %@ are both set; using the "
                                   @"debug token specified in %@ and ignoring the value of %@.",
                                   kDebugTokenEnvKey, kFirebaseDebugTokenEnvKey, kDebugTokenEnvKey,
                                   kFirebaseDebugTokenEnvKey]);

    return envVariableValue;
  } else if (envVariableValue) {
    GACAppCheckLog(
        GACLoggerAppCheckMessageEnvironmentVariableDebugToken, GACAppCheckLogLevelDebug,
        [NSString
            stringWithFormat:@"Using the debug token specified in the environment variable %@.",
                             kDebugTokenEnvKey]);

    return envVariableValue;
  } else if (firebaseEnvVariableValue) {
    // TODO(andrewheard): Update the message to warn that "FIRAAppCheckDebugToken"
    // (kFirebaseDebugTokenEnvKey) is deprecated after Firebase App Check supports
    // "AppCheckDebugToken" (kDebugTokenEnvKey) and increase the severity to
    // GACAppCheckLogLevelWarning.
    GACAppCheckLog(
        GACLoggerAppCheckMessageDebugProviderFirebaseEnvironmentVariable, GACAppCheckLogLevelDebug,
        [NSString
            stringWithFormat:@"Using the debug token specified in the environment variable %@.",
                             kFirebaseDebugTokenEnvKey]);

    return firebaseEnvVariableValue;
  } else {
    // Print only a locally generated token to avoid a valid token leak on CI.
    GACAppCheckLog(GACLoggerAppCheckMessageLocalDebugToken, GACAppCheckLogLevelWarning,
                   [NSString stringWithFormat:@"App Check debug token: '%@'.", LocalDebugToken()]);

    return nil;
  }
}

@end

NS_ASSUME_NONNULL_END
