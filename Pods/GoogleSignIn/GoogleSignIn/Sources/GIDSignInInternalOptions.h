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

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"

@class GIDConfiguration;
@class GIDSignInResult;

NS_ASSUME_NONNULL_BEGIN

/// The options used internally for aspects of the sign-in flow.
@interface GIDSignInInternalOptions : NSObject

/// Whether interaction with user is allowed at all.
@property(nonatomic, readonly) BOOL interactive;

/// Whether the sign-in is a continuation of the previous one.
@property(nonatomic, readonly) BOOL continuation;

/// Whether the sign-in is an addScopes flow. NO means it is a sign in flow.
@property(nonatomic, readonly) BOOL addScopesFlow;

/// The extra parameters used in the sign-in URL.
@property(nonatomic, readonly, nullable) NSDictionary *extraParams;

/// The configuration to use during the flow.
@property(nonatomic, readonly, nullable) GIDConfiguration *configuration;

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
/// The view controller to use during the flow.
@property(nonatomic, readonly, weak, nullable) UIViewController *presentingViewController;
#elif TARGET_OS_OSX
/// The window to use during the flow.
@property(nonatomic, readonly, weak, nullable) NSWindow *presentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// The completion block to be called at the completion of the flow.
@property(nonatomic, readonly, nullable) GIDSignInCompletion completion;

/// The scopes to be used during the flow.
@property(nonatomic, copy, nullable) NSArray<NSString *> *scopes;

/// The login hint to be used during the flow.
@property(nonatomic, copy, nullable) NSString *loginHint;

/// Creates the default options.
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:(nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                     completion:(nullable GIDSignInCompletion)completion;

+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:(nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                         scopes:(nullable NSArray *)scopes
                                     completion:(nullable GIDSignInCompletion)completion;

#elif TARGET_OS_OSX
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                               presentingWindow:(nullable NSWindow *)presentingWindow
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                     completion:(nullable GIDSignInCompletion)completion;

+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                               presentingWindow:(nullable NSWindow *)presentingWindow
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                         scopes:(nullable NSArray *)scopes
                                     completion:(nullable GIDSignInCompletion)completion;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// Creates the options to sign in silently.
+ (instancetype)silentOptionsWithCompletion:(GIDSignInCompletion)completion;

/// Creates options with the same values as the receiver, except for the "extra parameters", and
/// continuation flag, which are replaced by the arguments passed to this method.
- (instancetype)optionsWithExtraParameters:(NSDictionary *)extraParams
                           forContinuation:(BOOL)continuation;

@end

NS_ASSUME_NONNULL_END
