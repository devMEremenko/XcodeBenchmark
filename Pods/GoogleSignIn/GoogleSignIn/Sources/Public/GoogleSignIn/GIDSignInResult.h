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

@class GIDGoogleUser;

NS_ASSUME_NONNULL_BEGIN

/// A helper object that contains the result of a successful signIn or addScopes flow.
@interface GIDSignInResult : NSObject

/// The updated `GIDGoogleUser` instance for the user who just completed the flow.
@property(nonatomic, readonly) GIDGoogleUser *user;

/// An OAuth2 authorization code for the home server.
@property(nonatomic, readonly, nullable) NSString *serverAuthCode;

/// Unsupported.
+ (instancetype)new NS_UNAVAILABLE;

/// Unsupported.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
