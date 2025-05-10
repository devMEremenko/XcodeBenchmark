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

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

@class GIDConfiguration;
@class GIDGoogleUser;
@class GIDSignInResult;

NS_ASSUME_NONNULL_BEGIN

/// The error domain for `NSError`s returned by the Google Sign-In SDK.
extern NSErrorDomain const kGIDSignInErrorDomain;

/// A list of potential error codes returned from the Google Sign-In SDK.
typedef NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDSignInErrorCode) {
  /// Indicates an unknown error has occurred.
  kGIDSignInErrorCodeUnknown = -1,
  /// Indicates a problem reading or writing to the application keychain.
  kGIDSignInErrorCodeKeychain = -2,
  /// Indicates there are no valid auth tokens in the keychain. This error code will be returned by
  /// `restorePreviousSignIn` if the user has not signed in before or if they have since signed out.
  kGIDSignInErrorCodeHasNoAuthInKeychain = -4,
  /// Indicates the user canceled the sign in request.
  kGIDSignInErrorCodeCanceled = -5,
  /// Indicates an Enterprise Mobility Management related error has occurred.
  kGIDSignInErrorCodeEMM = -6,
  /// Indicates the requested scopes have already been granted to the `currentUser`.
  kGIDSignInErrorCodeScopesAlreadyGranted = -8,
  /// Indicates there is an operation on a previous user.
  kGIDSignInErrorCodeMismatchWithCurrentUser = -9,
};

/// This class is used to sign in users with their Google account and manage their session.
///
/// For reference, please see "Google Sign-In for iOS and macOS" at
/// https://developers.google.com/identity/sign-in/ios
@interface GIDSignIn : NSObject

/// The shared `GIDSignIn` instance.
@property(class, nonatomic, readonly) GIDSignIn *sharedInstance;

/// The `GIDGoogleUser` object representing the current user or `nil` if there is no signed-in user.
@property(nonatomic, readonly, nullable) GIDGoogleUser *currentUser;

/// The active configuration for this instance of `GIDSignIn`.
@property(nonatomic, nullable) GIDConfiguration *configuration;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

/// Configures `GIDSignIn` for use.
///
/// @param completion A nullable callback block passing back any error arising from the
///     configuration process if any exists.
///
/// Call this method on `GIDSignIn` prior to use and as early as possible. This method generates App
/// Attest key IDs and the attestation object eagerly to minimize latency later on during the sign
/// in or add scopes flows.
- (void)configureWithCompletion:(nullable void (^)(NSError * _Nullable error))completion
NS_SWIFT_NAME(configure(completion:));

/// Configures `GIDSignIn` for use in debug or test environments.
///
/// @param APIKey The API Key to use during configuration of the App Check debug provider.
/// @param completion A nullable callback block passing back any error arising from the
///     configuration process if any exists.
///
/// Call this method on `GIDSignIn` prior to use and as early as possible. This method generates App
/// Attest key IDs and the attestation object eagerly to minimize latency later on during the sign
/// in or add scopes flows.
- (void)configureDebugProviderWithAPIKey:(NSString *)APIKey
                              completion:(nullable void (^)(NSError * _Nullable error))completion
API_AVAILABLE(ios(14))
NS_SWIFT_NAME(configureDebugProvider(withAPIKey:completion:));

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

/// Unavailable. Use the `sharedInstance` property to instantiate `GIDSignIn`.
/// :nodoc:
+ (instancetype)new NS_UNAVAILABLE;

/// Unavailable. Use the `sharedInstance` property to instantiate `GIDSignIn`.
/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/// This method should be called from your `UIApplicationDelegate`'s `application:openURL:options:`
/// method.
///
/// @param url The URL that was passed to the app.
/// @return `YES` if `GIDSignIn` handled this URL.
- (BOOL)handleURL:(NSURL *)url;

/// Checks if there is a previous user sign-in saved in keychain.
///
/// @return `YES` if there is a previous user sign-in saved in keychain.
- (BOOL)hasPreviousSignIn;

/// Attempts to restore a previous user sign-in without interaction. 
///
/// Restores user from the local cache and refreshes tokens if they have expired (>1 hour).
///
/// @param completion The block that is called on completion.  This block will be called asynchronously
///     on the main queue.
- (void)restorePreviousSignInWithCompletion:(nullable void (^)(GIDGoogleUser *_Nullable user,
                                                               NSError *_Nullable error))completion;

/// Signs out the `currentUser`, removing it from the keychain.
- (void)signOut;

/// Disconnects the `currentUser` by signing them out and revoking all OAuth2 scope grants made to the app.
///
/// @param completion The optional block that is called on completion.
///     This block will be called asynchronously on the main queue.
- (void)disconnectWithCompletion:(nullable void (^)(NSError *_Nullable error))completion;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// Starts an interactive sign-in flow on iOS.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                completion:
    (nullable void (^)(GIDSignInResult *_Nullable signInResult,
                       NSError *_Nullable error))completion
    NS_EXTENSION_UNAVAILABLE("The sign-in flow is not supported in App Extensions.");

/// Starts an interactive sign-in flow on iOS using the provided hint.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                      hint:(nullable NSString *)hint
                                completion:
(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                   NSError *_Nullable error))completion
NS_EXTENSION_UNAVAILABLE("The sign-in flow is not supported in App Extensions.");

/// Starts an interactive sign-in flow on iOS using the provided hint and additional scopes.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param additionalScopes An optional array of scopes to request in addition to the basic profile scopes.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingViewController:(UIViewController *)presentingViewController
                                      hint:(nullable NSString *)hint
                          additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                                completion:
(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                   NSError *_Nullable error))completion
NS_EXTENSION_UNAVAILABLE("The sign-in flow is not supported in App Extensions.");

#elif TARGET_OS_OSX

/// Starts an interactive sign-in flow on macOS.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingWindow The window used to supply `presentationContextProvider` for `ASWebAuthenticationSession`.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                        completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                      NSError *_Nullable error))completion;

/// Starts an interactive sign-in flow on macOS using the provided hint.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingWindow The window used to supply `presentationContextProvider` for `ASWebAuthenticationSession`.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                              hint:(nullable NSString *)hint
                        completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                      NSError *_Nullable error))completion;

/// Starts an interactive sign-in flow on macOS using the provided hint.
///
/// The completion will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCompletion:` method to restore a previous sign-in.
///
/// @param presentingWindow The window used to supply `presentationContextProvider` for `ASWebAuthenticationSession`.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param additionalScopes An optional array of scopes to request in addition to the basic profile scopes.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)signInWithPresentingWindow:(NSWindow *)presentingWindow
                              hint:(nullable NSString *)hint
                  additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                        completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                      NSError *_Nullable error))completion;

#endif

@end

NS_ASSUME_NONNULL_END
