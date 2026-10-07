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

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

#import <GTMSessionFetcher/GTMSessionFetcher.h>

@class GIDConfiguration;
@class GIDSignInResult;
@class GIDToken;
@class GIDProfileData;

NS_ASSUME_NONNULL_BEGIN

/// This class represents a signed-in user.
@interface GIDGoogleUser : NSObject <NSSecureCoding>

/// The Google user ID.
@property(nonatomic, readonly, nullable) NSString *userID;

/// The basic profile data for the user.
@property(nonatomic, readonly, nullable) GIDProfileData *profile;

/// The OAuth2 scopes granted to the app in an array of `NSString`.
@property(nonatomic, readonly, nullable) NSArray<NSString *> *grantedScopes;

/// The configuration that was used to sign in this user.
@property(nonatomic, readonly) GIDConfiguration *configuration;

/// The OAuth2 access token to access Google services.
@property(nonatomic, readonly) GIDToken *accessToken;

/// The OAuth2 refresh token to exchange for new access tokens.
@property(nonatomic, readonly) GIDToken *refreshToken;

/// The OpenID Connect ID token that identifies the user.
///
/// Send this token to your server to authenticate the user there. For more information on this topic,
/// see https://developers.google.com/identity/sign-in/ios/backend-auth.
@property(nonatomic, readonly, nullable) GIDToken *idToken;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
/// The authorizer for use with `GTLRService`, `GTMSessionFetcher`, or `GTMHTTPFetcher`.
@property(nonatomic, readonly) id<GTMFetcherAuthorizationProtocol> fetcherAuthorizer;
#pragma clang diagnostic pop

/// Refresh the user's access and ID tokens if they have expired or are about to expire.
///
/// @param completion A completion block that takes a `GIDGoogleUser` or an error if the attempt to
///     refresh tokens was unsuccessful.  The block will be called asynchronously on the main queue.
- (void)refreshTokensIfNeededWithCompletion:(void (^)(GIDGoogleUser *_Nullable user,
                                                      NSError *_Nullable error))completion;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// Starts an interactive consent flow on iOS to add new scopes to the user's `grantedScopes`.
///
/// The completion will be called at the end of this process.  If successful, a `GIDSignInResult`
/// instance will be returned reflecting the new scopes and saved sign-in state will be updated.
///
/// @param scopes The scopes to ask the user to consent to.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param completion The optional block that is called on completion.  This block will be called
///     asynchronously on the main queue.
- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                NSError *_Nullable error))completion
    NS_EXTENSION_UNAVAILABLE("The add scopes flow is not supported in App Extensions.");

#elif TARGET_OS_OSX

/// Starts an interactive consent flow on macOS to add new scopes to the user's `grantedScopes`.
///
/// The completion will be called at the end of this process.  If successful, a `GIDSignInResult`
/// instance will be returned reflecting the new scopes and saved sign-in state will be updated.
///
/// @param scopes An array of scopes to ask the user to consent to.
/// @param presentingWindow The window used to supply `presentationContextProvider` for
///     `ASWebAuthenticationSession`.
/// @param completion The optional block that is called on completion.  This block will be called
///     asynchronously on the main queue.
- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingWindow:(NSWindow *)presentingWindow
          completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                        NSError *_Nullable error))completion;

#endif

@end

NS_ASSUME_NONNULL_END
