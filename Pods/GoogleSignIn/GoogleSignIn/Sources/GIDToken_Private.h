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

NS_ASSUME_NONNULL_BEGIN

// Private |GIDToken| methods that are used in this SDK.
@interface GIDToken ()

// Private initializer for |GIDToken|.
// @param token The token String.
// @param expirationDate The expiration date of the token.
- (instancetype)initWithTokenString:(NSString *)tokenString
                     expirationDate:(nullable NSDate *)expirationDate;

@end

NS_ASSUME_NONNULL_END
