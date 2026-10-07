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

#import <TargetConditionals.h>

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class GIDGoogleUser;
@class GIDSignInInternalOptions;
@class GTMKeychainStore;
@class GIDAppCheck;

/// Represents a completion block that takes a `GIDSignInResult` on success or an error if the
/// operation was unsuccessful.
typedef void (^GIDSignInCompletion)(GIDSignInResult *_Nullable signInResult,
                                    NSError *_Nullable error);

/// Represents a completion block that takes an error if the operation was unsuccessful.
typedef void (^GIDDisconnectCompletion)(NSError *_Nullable error);

// Private |GIDSignIn| methods that are used internally in this SDK and other Google SDKs.
@interface GIDSignIn ()

/// Redeclare |currentUser| as readwrite for internal use.
@property(nonatomic, readwrite, nullable) GIDGoogleUser *currentUser;

/// Private initializer taking a `GTMKeychainStore`.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
/// Private initializer taking a `GTMKeychainStore` and `GIDAppCheckProvider`.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore
                             appCheck:(GIDAppCheck *)appCheck
API_AVAILABLE(ios(14));
#endif // TARGET_OS_IOS || !TARGET_OS_MACCATALYST

/// Authenticates with extra options.
- (void)signInWithOptions:(GIDSignInInternalOptions *)options;

/// Restores a previously authenticated user from the keychain synchronously without refreshing
/// the access token or making a userinfo request.
/// 
/// The currentUser.profile will be nil unless the profile data can be extracted from the ID token.
///
/// @return NO if there is no user restored from the keychain.
- (BOOL)restorePreviousSignInNoRefresh;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// Starts an interactive consent flow on iOS to add scopes to the current user's grants.
///
/// The completion will be called at the end of this process.  If successful, a `GIDSignInResult`
/// instance will be returned reflecting the new scopes and saved sign-in state will be updated.
///
/// @param scopes The scopes to ask the user to consent to.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param completion The block that is called on completion.  This block will be called asynchronously
///     on the main queue.
- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable GIDSignInCompletion)completion
    NS_EXTENSION_UNAVAILABLE("The add scopes flow is not supported in App Extensions.");

#elif TARGET_OS_OSX

/// Starts an interactive consent flow on macOS to add scopes to the current user's grants.
///
/// The completion will be called at the end of this process.  If successful, a `GIDSignInResult`
/// instance will be returned reflecting the new scopes and saved sign-in state will be updated.
///
/// @param scopes An array of scopes to ask the user to consent to.
/// @param presentingWindow The window used to supply `presentationContextProvider` for
///     `ASWebAuthenticationSession`.
/// @param completion The block that is called on completion.  This block will be called asynchronously
///     on the main queue.
- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingWindow:(NSWindow *)presentingWindow
          completion:(nullable GIDSignInCompletion)completion;

#endif

@end

NS_ASSUME_NONNULL_END
