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

// The utility class to provide scope constants and check their existence.  Note that most methods
// only work with limited client-side knowledge, a "scopesWith*" method could add the scope
// unnecessarily.
@interface GIDScopes : NSObject

// Adds "email" and "profile" scopes to |scopes| if they are not already contained or implied.
+ (NSArray *)scopesWithBasicProfile:(NSArray *)scopes;

@end

NS_ASSUME_NONNULL_END
