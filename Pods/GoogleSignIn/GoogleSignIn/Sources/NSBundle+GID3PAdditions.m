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

#import "GoogleSignIn/Sources/NSBundle+GID3PAdditions.h"

#import <CoreText/CoreText.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

NS_ASSUME_NONNULL_BEGIN

#if SWIFT_PACKAGE
NSString *const GoogleSignInBundleName = @"GoogleSignIn_GoogleSignIn";
#else
NSString *const GoogleSignInBundleName = @"GoogleSignIn";
#endif

@implementation NSBundle (GID3PAdditions)

+ (nullable NSBundle *)gid_frameworkBundle {
  // Look for the resource bundle in the main bundle.
  NSString *path = [[NSBundle mainBundle] pathForResource:GoogleSignInBundleName
                                                   ofType:@"bundle"];
  if (!path) {
    // If we can't find the resource bundle in the main bundle, look for it in the framework bundle.
    path = [[NSBundle bundleForClass:[GIDSignIn class]] pathForResource:GoogleSignInBundleName
                                                                 ofType:@"bundle"];
  }
  return [NSBundle bundleWithPath:path];
}

+ (void)gid_registerFonts {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSArray* allFontNames = @[ @"Roboto-Bold" ];
    NSBundle* bundle = [self gid_frameworkBundle];
    for (NSString *fontName in allFontNames) {
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
      // Check to see if the font is already here, and skip registration if so.
      if ([UIFont fontWithName:fontName size:[UIFont systemFontSize]]) {  // size doesn't matter
        continue;
      }
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST

      // Load the font data file from the bundle.
      NSString *path = [bundle pathForResource:fontName ofType:@"ttf"];
      CGDataProviderRef provider = CGDataProviderCreateWithFilename([path UTF8String]);
      CFErrorRef error;
      CGFontRef newFont = CGFontCreateWithDataProvider(provider);
      if (!newFont || !CTFontManagerRegisterGraphicsFont(newFont, &error)) {
#ifdef DEBUG
        NSLog(@"Unable to load font: %@", fontName);
#endif
      }
      CGFontRelease(newFont);
      CGDataProviderRelease(provider);
    }
  });
}

@end

NS_ASSUME_NONNULL_END
