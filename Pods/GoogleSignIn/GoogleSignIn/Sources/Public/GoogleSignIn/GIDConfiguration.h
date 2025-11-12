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

/// This class represents the client configuration provided by the developer.
@interface GIDConfiguration : NSObject <NSCopying, NSSecureCoding>

/// The client ID of the app from the Google Cloud Console.
@property(nonatomic, readonly) NSString *clientID;

/// The client ID of the home server.  This will be returned as the `audience` property of the
/// OpenID Connect ID token.  For more info on the ID token:
/// https://developers.google.com/identity/sign-in/ios/backend-auth
@property(nonatomic, readonly, nullable) NSString *serverClientID;

/// The Google Apps domain to which users must belong to sign in.  To verify, check
/// `GIDGoogleUser`'s `hostedDomain` property.
@property(nonatomic, readonly, nullable) NSString *hostedDomain;

/// The OpenID2 realm of the home server. This allows Google to include the user's OpenID
/// Identifier in the OpenID Connect ID token.
@property(nonatomic, readonly, nullable) NSString *openIDRealm;

/// Unavailable.  Please use `initWithClientID:` or one of the other initializers below.
/// :nodoc:
+ (instancetype)new NS_UNAVAILABLE;

/// Unavailable.  Please use `initWithClientID:` or one of the other initializers below.
/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/// Initialize a `GIDConfiguration` object with a client ID.
///
/// @param clientID The client ID of the app.
/// @return An initialized `GIDConfiguration` instance.
- (instancetype)initWithClientID:(NSString *)clientID;

/// Initialize a `GIDConfiguration` object with a client ID and server client ID.
///
/// @param clientID The client ID of the app.
/// @param serverClientID The server's client ID.
/// @return An initialized `GIDConfiguration` instance.
- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID;

/// Initialize a `GIDConfiguration` object by specifying all available properties.
///
/// @param clientID The client ID of the app.
/// @param serverClientID The server's client ID.
/// @param hostedDomain The Google Apps domain to be used.
/// @param openIDRealm The OpenID realm to be used.
/// @return An initialized `GIDConfiguration` instance.
- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID
                    hostedDomain:(nullable NSString *)hostedDomain
                     openIDRealm:(nullable NSString *)openIDRealm NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
