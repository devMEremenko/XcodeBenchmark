//
//  VKApi.h
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

#import <Foundation/Foundation.h>
#import "VKRequest.h"
#import "VKApiUsers.h"
#import "VKApiFriends.h"
#import "VKApiPhotos.h"
#import "VKApiWall.h"
#import "VKApiConst.h"
#import "VKApiCaptcha.h"
#import "VKApiGroups.h"
#import "VKApiDocs.h"
#import "VKImageParameters.h"
#import "VKApiModels.h"


/**
Provides access for API parts.
*/
@interface VKApi : NSObject
/**
https://vk.com/dev/users
Returns object for preparing requests to users part of API
*/
+ (VKApiUsers *)users;

/**
https://vk.com/dev/wall
Returns object for preparing requests to wall part of API
*/
+ (VKApiWall *)wall;

/**
https://vk.com/dev/photos
Returns object for preparing requests to photos part of API
*/
+ (VKApiPhotos *)photos;

/**
https://vk.com/dev/friends
Returns object for preparing requests to friends part of API
*/
+ (VKApiFriends *)friends;

/**
https://vk.com/dev/friends
Returns object for preparing requests to groups part of API
*/
+ (VKApiGroups *)groups;

/**
 Create new request with parameters. See documentation for methods here https://vk.com/dev/methods

 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @param httpMethod HTTP method for execution, e.g. GET, POST
 @return Complete request class for execute or configure method
*/
+ (VKRequest *)requestWithMethod:(NSString *)method
                   andParameters:(NSDictionary *)parameters
                   andHttpMethod:(NSString *)httpMethod __deprecated;

/**
 Create new request with parameters. See documentation for methods here https://vk.com/dev/methods
 
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @return Complete request class for execute or configure method
 */
+ (VKRequest *)requestWithMethod:(NSString *)method
                   andParameters:(NSDictionary *)parameters;

/**
 Uploads photo for wall post
 
 @param image image used for saving to post
 @param parameters parameters for image to be uploaded
 @param userId ID of user on which wall image should be posted (or 0)
 @param groupId ID of group (without minus sign) on which wall image should be posted (or 0)
*/
+ (VKRequest *)uploadWallPhotoRequest:(UIImage *)image
                           parameters:(VKImageParameters *)parameters
                               userId:(NSInteger)userId
                              groupId:(NSInteger)groupId;

/**
 Uploads photo in user or group album
 
 @param image image used for saving to post
 @param parameters parameters for image to be uploaded
 @param albumId target album ID. Required
 @param groupId target group ID (positive). May be 0
*/
+ (VKRequest *)uploadAlbumPhotoRequest:(UIImage *)image
                            parameters:(VKImageParameters *)parameters
                               albumId:(NSInteger)albumId
                               groupId:(NSInteger)groupId;

/**
 Uploads photo for messaging
 
 @param image image used for saving to post
 @param parameters parameters for image to be uploaded
*/
+ (VKRequest *)uploadMessagePhotoRequest:(UIImage *)image
                              parameters:(VKImageParameters *)parameters;


@end
