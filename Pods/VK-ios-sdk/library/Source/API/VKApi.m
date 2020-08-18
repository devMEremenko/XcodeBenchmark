//
//  VKApi.m
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

#import "VKApi.h"
#import "VKUploadWallPhotoRequest.h"
#import "VKUploadPhotoRequest.h"
#import "VKUploadMessagesPhotoRequest.h"

@implementation VKApi
+ (VKApiUsers *)users {
    return [VKApiUsers new];
}

+ (VKApiWall *)wall {
    return [VKApiWall new];
}

+ (VKApiPhotos *)photos {
    return [VKApiPhotos new];
}

+ (VKApiFriends *)friends {
    return [VKApiFriends new];
}

+ (VKApiGroups *)groups {
    return [VKApiGroups new];
}

+ (VKRequest *)requestWithMethod:(NSString *)method
                   andParameters:(NSDictionary *)parameters {
    return [VKRequest requestWithMethod:method parameters:parameters];
}

+ (VKRequest *)requestWithMethod:(NSString *)method
                   andParameters:(NSDictionary *)parameters
                   andHttpMethod:(NSString *)httpMethod {
    return [VKRequest requestWithMethod:method parameters:parameters];
}

+ (VKRequest *)uploadWallPhotoRequest:(UIImage *)image
                           parameters:(VKImageParameters *)parameters
                               userId:(NSInteger)userId
                              groupId:(NSInteger)groupId {
    return [[VKUploadWallPhotoRequest alloc] initWithImage:image parameters:parameters userId:userId groupId:groupId];
}

+ (VKRequest *)uploadAlbumPhotoRequest:(UIImage *)image
                            parameters:(VKImageParameters *)parameters
                               albumId:(NSInteger)albumId
                               groupId:(NSInteger)groupId {
    return [[VKUploadPhotoRequest alloc] initWithImage:image parameters:parameters albumId:albumId groupId:groupId];
}

+ (VKRequest *)uploadMessagePhotoRequest:(UIImage *)image parameters:(VKImageParameters *)parameters {
    return [[VKUploadMessagesPhotoRequest alloc] initWithImage:image parameters:parameters];
}

@end
