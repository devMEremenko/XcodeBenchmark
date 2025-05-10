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

#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheck.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckErrors.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckProvider.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckSettings.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckToken.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckTokenDelegate.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckTokenResult.h"

#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"
#import "AppCheckCore/Sources/Core/GACAppCheckLogger+Internal.h"
#import "AppCheckCore/Sources/Core/Storage/GACAppCheckStorage.h"
#import "AppCheckCore/Sources/Core/TokenRefresh/GACAppCheckTokenRefreshResult.h"
#import "AppCheckCore/Sources/Core/TokenRefresh/GACAppCheckTokenRefresher.h"

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval kTokenExpirationThreshold = 5 * 60;  // 5 min.

typedef void (^GACAppCheckTokenHandler)(GACAppCheckTokenResult *result);

@interface GACAppCheck ()

@property(nonatomic, readonly) NSString *serviceName;
@property(nonatomic, readonly) id<GACAppCheckProvider> appCheckProvider;
@property(nonatomic, readonly) id<GACAppCheckStorageProtocol> storage;
@property(nonatomic, readonly) id<GACAppCheckSettingsProtocol> settings;
@property(nonatomic, readonly, nullable, weak) id<GACAppCheckTokenDelegate> tokenDelegate;

@property(nonatomic, readonly, nullable) id<GACAppCheckTokenRefresherProtocol> tokenRefresher;

@property(nonatomic, nullable) FBLPromise<GACAppCheckToken *> *ongoingRetrieveOrRefreshTokenPromise;

@end

@implementation GACAppCheck

#pragma mark - Internal

- (instancetype)initWithServiceName:(NSString *)serviceName
                   appCheckProvider:(id<GACAppCheckProvider>)appCheckProvider
                            storage:(id<GACAppCheckStorageProtocol>)storage
                     tokenRefresher:(id<GACAppCheckTokenRefresherProtocol>)tokenRefresher
                           settings:(id<GACAppCheckSettingsProtocol>)settings
                      tokenDelegate:(nullable id<GACAppCheckTokenDelegate>)tokenDelegate {
  self = [super init];
  if (self) {
    _serviceName = serviceName;
    _appCheckProvider = appCheckProvider;
    _storage = storage;
    _tokenRefresher = tokenRefresher;
    _settings = settings;
    _tokenDelegate = tokenDelegate;

    __auto_type __weak weakSelf = self;
    tokenRefresher.tokenRefreshHandler = ^(GACAppCheckTokenRefreshCompletion _Nonnull completion) {
      __auto_type strongSelf = weakSelf;
      [strongSelf periodicTokenRefreshWithCompletion:completion];
    };
  }
  return self;
}

#pragma mark - Public

- (instancetype)initWithServiceName:(NSString *)serviceName
                       resourceName:(NSString *)resourceName
                   appCheckProvider:(id<GACAppCheckProvider>)appCheckProvider
                           settings:(id<GACAppCheckSettingsProtocol>)settings
                      tokenDelegate:(nullable id<GACAppCheckTokenDelegate>)tokenDelegate
                keychainAccessGroup:(nullable NSString *)accessGroup {
  GACAppCheckTokenRefreshResult *refreshResult =
      [[GACAppCheckTokenRefreshResult alloc] initWithStatusNever];
  GACAppCheckTokenRefresher *tokenRefresher =
      [[GACAppCheckTokenRefresher alloc] initWithRefreshResult:refreshResult settings:settings];

  NSString *tokenKey =
      [NSString stringWithFormat:@"app_check_token.%@.%@", serviceName, resourceName];
  GACAppCheckStorage *storage = [[GACAppCheckStorage alloc] initWithTokenKey:tokenKey
                                                                 accessGroup:accessGroup];

  return [self initWithServiceName:serviceName
                  appCheckProvider:appCheckProvider
                           storage:storage
                    tokenRefresher:tokenRefresher
                          settings:settings
                     tokenDelegate:tokenDelegate];
}

- (void)tokenForcingRefresh:(BOOL)forcingRefresh completion:(GACAppCheckTokenHandler)handler {
  [self retrieveOrRefreshTokenForcingRefresh:forcingRefresh]
      .then(^id _Nullable(GACAppCheckToken *token) {
        handler([[GACAppCheckTokenResult alloc] initWithToken:token]);
        return token;
      })
      .catch(^(NSError *_Nonnull error) {
        handler([[GACAppCheckTokenResult alloc] initWithError:error]);
      });
}

- (void)limitedUseTokenWithCompletion:(GACAppCheckTokenHandler)handler {
  [self limitedUseToken]
      .then(^id _Nullable(GACAppCheckToken *token) {
        handler([[GACAppCheckTokenResult alloc] initWithToken:token]);
        return token;
      })
      .catch(^(NSError *_Nonnull error) {
        handler([[GACAppCheckTokenResult alloc] initWithError:error]);
      });
}

#pragma mark - FAA token cache

- (FBLPromise<GACAppCheckToken *> *)retrieveOrRefreshTokenForcingRefresh:(BOOL)forcingRefresh {
  return [FBLPromise do:^id _Nullable {
    // TODO(#42): Don't re-use ongoing promise if forcingRefresh is YES.
    if (self.ongoingRetrieveOrRefreshTokenPromise == nil) {
      // Kick off a new operation only when there is not an ongoing one.
      self.ongoingRetrieveOrRefreshTokenPromise =
          [self createRetrieveOrRefreshTokenPromiseForcingRefresh:forcingRefresh]

              // Release the ongoing operation promise on completion.
              .then(^GACAppCheckToken *(GACAppCheckToken *token) {
                self.ongoingRetrieveOrRefreshTokenPromise = nil;
                return token;
              })
              .recover(^NSError *(NSError *error) {
                self.ongoingRetrieveOrRefreshTokenPromise = nil;
                return error;
              });
    }
    return self.ongoingRetrieveOrRefreshTokenPromise;
  }];
}

- (FBLPromise<GACAppCheckToken *> *)createRetrieveOrRefreshTokenPromiseForcingRefresh:
    (BOOL)forcingRefresh {
  return [self getCachedValidTokenForcingRefresh:forcingRefresh].recover(
      ^id _Nullable(NSError *_Nonnull error) {
        return [self refreshToken];
      });
}

- (FBLPromise<GACAppCheckToken *> *)getCachedValidTokenForcingRefresh:(BOOL)forcingRefresh {
  if (forcingRefresh) {
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise reject:[GACAppCheckErrorUtil cachedTokenNotFound]];
    return rejectedPromise;
  }

  return [self.storage getToken].then(^id(GACAppCheckToken *_Nullable token) {
    if (token == nil) {
      return [GACAppCheckErrorUtil cachedTokenNotFound];
    }

    BOOL isTokenExpiredOrExpiresSoon =
        [token.expirationDate timeIntervalSinceNow] < kTokenExpirationThreshold;
    if (isTokenExpiredOrExpiresSoon) {
      return [GACAppCheckErrorUtil cachedTokenExpired];
    }

    return token;
  });
}

- (FBLPromise<GACAppCheckToken *> *)refreshToken {
  return [FBLPromise
             wrapObjectOrErrorCompletion:^(FBLPromiseObjectOrErrorCompletion _Nonnull handler) {
               [self.appCheckProvider getTokenWithCompletion:handler];
             }]
      .then(^id _Nullable(GACAppCheckToken *_Nullable token) {
        return [self.storage setToken:token];
      })
      .then(^id _Nullable(GACAppCheckToken *_Nullable token) {
        // TODO: Make sure the self.tokenRefresher is updated only once. Currently the timer will be
        // updated twice in the case when the refresh triggered by self.tokenRefresher, but it
        // should be fine for now as it is a relatively cheap operation.
        __auto_type refreshResult = [[GACAppCheckTokenRefreshResult alloc]
            initWithStatusSuccessAndExpirationDate:token.expirationDate
                                    receivedAtDate:token.receivedAtDate];
        [self.tokenRefresher updateWithRefreshResult:refreshResult];
        if (self.tokenDelegate) {
          [self.tokenDelegate tokenDidUpdate:token serviceName:self.serviceName];
        }
        return token;
      });
}

- (FBLPromise<GACAppCheckToken *> *)limitedUseToken {
  return
      [FBLPromise wrapObjectOrErrorCompletion:^(
                      FBLPromiseObjectOrErrorCompletion _Nonnull handler) {
        [self.appCheckProvider getLimitedUseTokenWithCompletion:handler];
      }].then(^id _Nullable(GACAppCheckToken *_Nullable token) {
        return token;
      });
}

#pragma mark - Token auto refresh

- (void)periodicTokenRefreshWithCompletion:(GACAppCheckTokenRefreshCompletion)completion {
  [self retrieveOrRefreshTokenForcingRefresh:NO]
      .then(^id _Nullable(GACAppCheckToken *_Nullable token) {
        __auto_type refreshResult = [[GACAppCheckTokenRefreshResult alloc]
            initWithStatusSuccessAndExpirationDate:token.expirationDate
                                    receivedAtDate:token.receivedAtDate];
        completion(refreshResult);
        return nil;
      })
      .catch(^(NSError *error) {
        __auto_type refreshResult = [[GACAppCheckTokenRefreshResult alloc] initWithStatusFailure];
        completion(refreshResult);
      });
}

@end

NS_ASSUME_NONNULL_END
