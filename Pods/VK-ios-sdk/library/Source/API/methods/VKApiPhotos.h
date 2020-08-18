//
//  VKApiPhotos.h
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
Builds requests for API.photos part
*/
@interface VKApiPhotos : VKApiBase
/**
https://vk.com/dev/photos.getUploadServer
@param albumId album identifier (positive integer)
@return Request for load
*/
- (VKRequest *)getUploadServer:(NSInteger)albumId;

/**
https://vk.com/dev/photos.getUploadServer
@param albumId album identifier (positive integer)
@param groupId group identifier (positive integer)
@return Request for load
*/
- (VKRequest *)getUploadServer:(NSInteger)albumId andGroupId:(NSInteger)groupId;

/**
https://vk.com/dev/photos.getWallUploadServer
@return Request for load
*/
- (VKRequest *)getWallUploadServer;

/**
https://vk.com/dev/photos.getWallUploadServer
@param groupId group identifier (positive integer)
@return Request for load
*/
- (VKRequest *)getWallUploadServer:(NSInteger)groupId;


/**
https://vk.com/dev/photos.save
@param params params received after photo upload, with user id or group id
@return Request for load
*/
- (VKRequest *)save:(NSDictionary *)params;

/**
https://vk.com/dev/photos.saveWallPhoto
@param params params received after photo upload, with user id or group id
@return Request for load
*/
- (VKRequest *)saveWallPhoto:(NSDictionary *)params;

@end
