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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDToken.h"

#import "GoogleSignIn/Sources/GIDToken_Private.h"

// Key constants used for encode and decode.
static NSString *const kTokenStringKey = @"tokenString";
static NSString *const kExpirationDateKey = @"expirationDate";

NS_ASSUME_NONNULL_BEGIN

@implementation GIDToken

- (instancetype)initWithTokenString:(NSString *)tokenString
                     expirationDate:(nullable NSDate *)expirationDate {
  self = [super init];
  if (self) {
    _tokenString = [tokenString copy];
    _expirationDate  = expirationDate;
  }
  
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _tokenString = [decoder decodeObjectOfClass:[NSString class] forKey:kTokenStringKey];
    _expirationDate = [decoder decodeObjectOfClass:[NSDate class] forKey:kExpirationDateKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_tokenString forKey:kTokenStringKey];
  [encoder encodeObject:_expirationDate forKey:kExpirationDateKey];
}

#pragma mark - isEqual

- (BOOL)isEqual:(nullable id)object {
  if (object == nil) {
    return NO;
  }
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[GIDToken class]]) {
    return NO;
  }
  return [self isEqualToToken:(GIDToken *)object];
}

- (BOOL)isEqualToToken:(GIDToken *)otherToken {
  return [_tokenString isEqual:otherToken.tokenString] &&
      [self isTheSameDate:_expirationDate with:otherToken.expirationDate];
}

// The date is nullable in GIDToken. Two `nil` dates are considered equal so
// token equality check succeeds if token strings are equal and have no expiration.
- (BOOL)isTheSameDate:(nullable NSDate *)date1
                 with:(nullable NSDate *)date2 {
  if (!date1 && !date2) {
    return YES;
  }
  return [date1 isEqualToDate:date2];
}

- (NSUInteger)hash {
  return [self.tokenString hash] ^ [self.expirationDate hash];
}

@end

NS_ASSUME_NONNULL_END
