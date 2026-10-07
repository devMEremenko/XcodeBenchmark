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

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

#import "GoogleSignIn/Sources/GIDScopes.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDSignInInternalOptions
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:(nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                         scopes:(nullable NSArray *)scopes
                                     completion:(nullable GIDSignInCompletion)completion {
#elif TARGET_OS_OSX
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                               presentingWindow:(nullable NSWindow *)presentingWindow
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                         scopes:(nullable NSArray *)scopes
                                     completion:(nullable GIDSignInCompletion)completion {
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = YES;
    options->_continuation = NO;
    options->_addScopesFlow = addScopesFlow;
    options->_configuration = configuration;
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    options->_presentingViewController = presentingViewController;
#elif TARGET_OS_OSX
    options->_presentingWindow = presentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
    options->_loginHint = loginHint;
    options->_completion = completion;
    options->_scopes = [GIDScopes scopesWithBasicProfile:scopes];
  }
  return options;
}

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:(nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                     completion:(nullable GIDSignInCompletion)completion {
#elif TARGET_OS_OSX
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                               presentingWindow:(nullable NSWindow *)presentingWindow
                                      loginHint:(nullable NSString *)loginHint
                                  addScopesFlow:(BOOL)addScopesFlow
                                     completion:(nullable GIDSignInCompletion)completion {
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
    GIDSignInInternalOptions *options = [self defaultOptionsWithConfiguration:configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                     presentingViewController:presentingViewController
#elif TARGET_OS_OSX
                                                             presentingWindow:presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                                    loginHint:loginHint
                                                                addScopesFlow:addScopesFlow
                                                                       scopes:@[]
                                                                   completion:completion];
  return options;
}

+ (instancetype)silentOptionsWithCompletion:(GIDSignInCompletion)completion {
  GIDSignInInternalOptions *options = [self defaultOptionsWithConfiguration:nil
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                   presentingViewController:nil
#elif TARGET_OS_OSX
                                                           presentingWindow:nil
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                                                  loginHint:nil
                                                              addScopesFlow:NO
                                                                 completion:completion];
  if (options) {
    options->_interactive = NO;
  }
  return options;
}

- (instancetype)optionsWithExtraParameters:(NSDictionary *)extraParams
                           forContinuation:(BOOL)continuation {
  GIDSignInInternalOptions *options = [[GIDSignInInternalOptions alloc] init];
  if (options) {
    options->_interactive = _interactive;
    options->_continuation = continuation;
    options->_addScopesFlow = _addScopesFlow;
    options->_configuration = _configuration;
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    options->_presentingViewController = _presentingViewController;
#elif TARGET_OS_OSX
    options->_presentingWindow = _presentingWindow;
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
    options->_loginHint = _loginHint;
    options->_completion = _completion;
    options->_scopes = _scopes;
    options->_extraParams = [extraParams copy];
  }
  return options;
}

@end

NS_ASSUME_NONNULL_END
