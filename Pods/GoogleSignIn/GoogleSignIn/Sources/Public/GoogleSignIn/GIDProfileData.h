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

/// This class represents the basic profile information of a `GIDGoogleUser`.
@interface GIDProfileData : NSObject <NSCopying, NSSecureCoding>

/// The Google user's email.
@property(nonatomic, readonly) NSString *email;

/// The Google user's full name.
@property(nonatomic, readonly) NSString *name;

/// The Google user's given name.
@property(nonatomic, readonly, nullable) NSString *givenName;

/// The Google user's family name.
@property(nonatomic, readonly, nullable) NSString *familyName;

/// Whether or not the user has profile image.
@property(nonatomic, readonly) BOOL hasImage;

/// Gets the user's profile image URL for the given dimension in pixels for each side of the square.
///
/// @param dimension The desired height (and width) of the profile image.
/// @return The URL of the user's profile image.
- (nullable NSURL *)imageURLWithDimension:(NSUInteger)dimension;

@end

NS_ASSUME_NONNULL_END
