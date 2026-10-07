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

#import "GoogleSignIn/Sources/GIDSignInStrings.h"

#import "GoogleSignIn/Sources/NSBundle+GID3PAdditions.h"

NS_ASSUME_NONNULL_BEGIN

// The table name for localized strings (i.e. file name before .strings suffix).
static NSString * const kStringsTableName = @"GoogleSignIn";

#pragma mark - Button Text Constants

// Button texts used as both keys in localized strings files and default values.
static NSString *const kStandardButtonText = @"Sign in";
static NSString *const kWideButtonText = @"Sign in with Google";

@implementation GIDSignInStrings

+ (nullable NSString *)localizedStringForKey:(NSString *)key text:(NSString *)text {
  NSBundle *frameworkBundle = [NSBundle gid_frameworkBundle];
  return [frameworkBundle localizedStringForKey:key value:text table:kStringsTableName];
}

+ (nullable NSString *)signInString {
  return [self localizedStringForKey:kStandardButtonText text:kStandardButtonText];
}

+ (nullable NSString *)signInWithGoogleString {
  return [self localizedStringForKey:kWideButtonText text:kWideButtonText];
}

@end

NS_ASSUME_NONNULL_END
