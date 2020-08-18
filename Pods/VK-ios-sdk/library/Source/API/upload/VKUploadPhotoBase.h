//
//  VKPhotoUploadBase.h
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

#import "VKRequest.h"
#import "VKImageParameters.h"
#import "VKOperation.h"

/**
Provides common part of photo upload process
*/
@interface VKUploadPhotoBase : VKRequest
/// ID of album to upload
@property(nonatomic, assign) NSInteger albumId;
/// ID of group to upload
@property(nonatomic, assign) NSInteger groupId;
/// ID of user wall to upload
@property(nonatomic, assign) NSInteger userId;

/// Passed image parameters
@property(nonatomic, strong) VKImageParameters *imageParameters;
/// Image to upload
@property(nonatomic, strong) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image parameters:(VKImageParameters *)parameters;
@end

/**
Special operation for execute upload
*/
@interface VKUploadImageOperation : VKOperation

+ (instancetype)operationWithUploadRequest:(VKUploadPhotoBase *)request;
@end
