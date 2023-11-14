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

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The layout styles supported by the `GIDSignInButton`.
///
/// The minimum size of the button depends on the language used for text.
/// The following dimensions (in points) fit for all languages:
/// - kGIDSignInButtonStyleStandard: 230 x 48
/// - kGIDSignInButtonStyleWide:     312 x 48
/// - kGIDSignInButtonStyleIconOnly: 48 x 48 (no text, fixed size)
typedef NS_ENUM(NSInteger, GIDSignInButtonStyle) {
  kGIDSignInButtonStyleStandard = 0,
  kGIDSignInButtonStyleWide = 1,
  kGIDSignInButtonStyleIconOnly = 2
};

/// The color schemes supported by the `GIDSignInButton`.
typedef NS_ENUM(NSInteger, GIDSignInButtonColorScheme) {
  kGIDSignInButtonColorSchemeDark = 0,
  kGIDSignInButtonColorSchemeLight = 1
};

/// This class provides the "Sign in with Google" button.
///
/// You can instantiate this class programmatically or from a NIB file. You should connect this
/// control to an `IBAction`, or something similar, that calls
/// signInWithPresentingViewController:completion: on `GIDSignIn` and add it to your view
/// hierarchy.
@interface GIDSignInButton : UIControl

/// The layout style for the sign-in button.
/// Possible values:
/// - kGIDSignInButtonStyleStandard: 230 x 48 (default)
/// - kGIDSignInButtonStyleWide:     312 x 48
/// - kGIDSignInButtonStyleIconOnly: 48 x 48 (no text, fixed size)
@property(nonatomic, assign) GIDSignInButtonStyle style;

/// The color scheme for the sign-in button.
/// Possible values:
/// - kGIDSignInButtonColorSchemeDark
/// - kGIDSignInButtonColorSchemeLight (default)
@property(nonatomic, assign) GIDSignInButtonColorScheme colorScheme;

@end

NS_ASSUME_NONNULL_END

#endif
