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

NS_ASSUME_NONNULL_BEGIN

// Provides localized strings.
// TODO(xiangtian) At some point we should probably convert this so that it's auto-generated from
// a script. This is a "better than what was there before, and what we need now, but probably not
// ideal" solution.
@interface GIDSignInStrings : NSObject

// Returns the localized string for the key if available, or the supplied default text if not.
+ (nullable NSString *)localizedStringForKey:(NSString *)key text:(NSString *)text;

// "Sign In"
+ (nullable NSString *)signInString;

// "Sign in with Google"
+ (nullable NSString *)signInWithGoogleString;

@end

NS_ASSUME_NONNULL_END
