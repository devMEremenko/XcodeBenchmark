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

NS_ASSUME_NONNULL_BEGIN

/// This class represents an OAuth2 or OpenID Connect token.
@interface GIDToken : NSObject <NSSecureCoding>

/// The token string.
@property(nonatomic, copy, readonly) NSString *tokenString;

/// The estimated expiration date of the token.
@property(nonatomic, readonly, nullable) NSDate *expirationDate;

/// Check if current token is equal to another one.
///
/// @param otherToken Another token to compare.
- (BOOL)isEqualToToken:(GIDToken *)otherToken;

/// Unavailable.
/// :nodoc:
+ (instancetype)new NS_UNAVAILABLE;

/// Unavailable.
/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
