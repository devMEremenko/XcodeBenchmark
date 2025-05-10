/*
 * Copyright 2023 Google LLC
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

@class GACAppCheckToken;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppCheckCoreTokenDelegate)
@protocol GACAppCheckTokenDelegate <NSObject>

/// Called each time an App Check token is refreshed.
///
/// @param token The updated App Check token.
/// @param serviceName A unique identifier for the App Check instance, may be a Firebase App Name
/// or an SDK name.
- (void)tokenDidUpdate:(GACAppCheckToken *)token serviceName:(NSString *)serviceName;

@end

NS_ASSUME_NONNULL_END
