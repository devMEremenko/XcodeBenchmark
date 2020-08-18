//
//  VKApiUsers.h
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

#import "VKApiBase.h"

/**
Builds requests for API.users part
*/
@interface VKApiUsers : VKApiBase
/**
Returns basic information about current user
@return Request for load
*/
- (VKRequest *)get;

/**
https://vk.com/dev/users.get
@param params use parameters from description with VK_API prefix, e.g. VK_API_USER_IDS, VK_API_FIELDS, VK_API_NAME_CASE
@return Request for load
*/
- (VKRequest *)get:(NSDictionary *)params;

/**
https://vk.com/dev/users.search
@param params use parameters from description with VK_API prefix, e.g. VK_API_Q, VK_API_CITY, VK_API_COUNTRY, etc.
@return Request for load
*/
- (VKRequest *)search:(NSDictionary *)params;

/**
https://vk.com/dev/users.isAppUser
@return Request for load
*/
- (VKRequest *)isAppUser;

/**
https://vk.com/dev/users.isAppUser
@param userID ID of user to check
@return Request for load
*/
- (VKRequest *)isAppUser:(NSInteger)userID;

/**
https://vk.com/dev/users.getSubscriptions
@return Request for load
*/
- (VKRequest *)getSubscriptions;

/**
https://vk.com/dev/users.getSubscriptions
@param params use parameters from description with VK_API prefix, e.g. VK_API_USER_ID, VK_API_EXTENDED, etc.
@return Request for load
*/
- (VKRequest *)getSubscriptions:(NSDictionary *)params;

/**
https://vk.com/dev/users.getFollowers
@return Request for load
*/
- (VKRequest *)getFollowers;

/**
https://vk.com/dev/users.getFollowers
@param params use parameters from description with VK_API prefix, e.g. VK_API_USER_ID, VK_API_OFFSET, etc.
@return Request for load
*/
- (VKRequest *)getFollowers:(NSDictionary *)params;
@end
