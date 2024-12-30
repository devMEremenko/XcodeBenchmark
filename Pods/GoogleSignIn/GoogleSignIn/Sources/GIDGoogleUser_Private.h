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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

@class OIDAuthState;

NS_ASSUME_NONNULL_BEGIN

/// A completion block that takes a `GIDGoogleUser` or an error if the attempt to refresh tokens was unsuccessful.
typedef void (^GIDGoogleUserCompletion)(GIDGoogleUser *_Nullable user, NSError *_Nullable error);

// Internal methods for the class that are not part of the public API.
@interface GIDGoogleUser () <GTMAppAuthFetcherAuthorizationTokenRefreshDelegate,
                             OIDAuthStateChangeDelegate>

@property(nonatomic, readwrite) GIDToken *accessToken;

@property(nonatomic, readwrite) GIDToken *refreshToken;

@property(nonatomic, readwrite, nullable) GIDToken *idToken;

// A representation of the state of the OAuth session for this instance.
@property(nonatomic, readonly) OIDAuthState *authState;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property(nonatomic, readwrite) id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer;
#pragma clang diagnostic pop

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// A string indicating support for Enterprise Mobility Management.
@property(nonatomic, readonly, nullable) NSString *emmSupport;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

// Create a object with an auth state, scopes, and profile data.
- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData;

// Update the auth state and profile data.
- (void)updateWithTokenResponse:(OIDTokenResponse *)tokenResponse
          authorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                    profileData:(nullable GIDProfileData *)profileData;

@end

NS_ASSUME_NONNULL_END
