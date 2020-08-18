//
//  VKAccessToken.h
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  --------------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
#import "VKObject.h"
#import "VKUser.h"

/**
 * Represents VK API access token that used for loading API methods and other stuff.
 */
@interface VKAccessToken : VKObject <NSCoding>

/// String token for use in request parameters
@property(nonatomic, readonly, copy) NSString *accessToken;

/// Current user id for this token
@property(nonatomic, readonly, copy) NSString *userId;

/// User secret to sign requests (if nohttps used)
@property(nonatomic, readonly, copy) NSString *secret;

// Permisiions assosiated with token
@property(nonatomic, readonly, copy) NSArray *permissions;

// User email (if passed)
@property(nonatomic, readonly, copy) NSString *email;

/// Time when token expires
@property(nonatomic, readonly, assign) NSInteger expiresIn;

/// If user sets "Always use HTTPS" setting in his profile, it will be true
@property(nonatomic, readonly, assign) BOOL httpsRequired;

/// Indicates time of token creation
@property(nonatomic, readonly, assign) NSTimeInterval created;

/// Contains basic current user information. Available after delegate method -[VKSdkDelegate vkSdkAuthorizationStateUpdatedWithResult:] called
@property(nonatomic, readonly, strong) VKUser *localUser;

/**
Retrieve token from key-value query string
@param urlString string that contains URL-query part with token. E.g. access_token=ffffff&expires_in=0...
@return parsed token
*/
+ (instancetype)tokenFromUrlString:(NSString *)urlString;

/**
Create token with existing properties
@param accessToken token string
@param secret secret
@param userId user id
@return new token
*/
+ (instancetype)tokenWithToken:(NSString *)accessToken secret:(NSString *)secret userId:(NSString *)userId;

/**
Retrieve token from user defaults. Token must be saved to defaults with saveTokenToDefaults method
@param defaultsKey path to file with saved token
@return parsed token
*/
+ (instancetype)savedToken:(NSString *)defaultsKey;

/**
Save token into user defaults by specified key
@param defaultsKey key for defaults
*/
- (void)saveTokenToDefaults:(NSString *)defaultsKey;

/// Return YES if token has expired
- (BOOL)isExpired;

/**
 Remove token from storage
 
 @param service Access token storage key name
 */
+ (void)delete:(NSString *)service;

@end

/**
 * This is mutable version of VKAccessToken. You should never use this class directly
 */
@interface VKAccessTokenMutable : VKAccessToken
@property(nonatomic, readwrite, copy) NSString *accessToken;
@property(nonatomic, readwrite, copy) NSString *userId;
@property(nonatomic, readwrite, copy) NSString *secret;
@property(nonatomic, readwrite, copy) NSArray *permissions;
@property(nonatomic, readwrite, assign) BOOL httpsRequired;
@property(nonatomic, readwrite, assign) NSInteger expiresIn;
@property(nonatomic, readwrite, strong) VKUser *localUser;
@end
