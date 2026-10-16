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

// A utility class for dealing with callback schemes.
@interface GIDSignInCallbackSchemes : NSObject

// Please call the designated initializer.
- (instancetype)init NS_UNAVAILABLE;

// The designated initializer.
- (instancetype)initWithClientIdentifier:(NSString *)clientIdentifier NS_DESIGNATED_INITIALIZER;

// The canonical client identifier callback scheme. Requires clientId to be set on GIDSignIn.
- (NSString *)clientIdentifierScheme;

// An array of all schemes used for sign-in callbacks.
- (NSArray *)allSchemes;

// Returns a list of URL schemes the current app host should support for Google Sign-In to work.
- (NSMutableArray *)unsupportedSchemes;

// Indicates the scheme of an NSURL is a sign-in callback scheme.
- (BOOL)URLSchemeIsCallbackScheme:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
