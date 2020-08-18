//
//  VKImageParameters.h
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

#import "VKObject.h"

/**
Describes image representation type
*/
typedef enum VKImageType {
    /// Sets jpeg representation of image
            VKImageTypeJpg,
    /// Sets png representation of image
            VKImageTypePng
} VKImageType;

/**
Parameters used for uploading image into VK servers
*/
@interface VKImageParameters : VKObject

/// Type of image compression. Can be <b>VKImageTypeJpg</b> or <b>VKImageTypePng</b>.
@property(nonatomic, assign) VKImageType imageType;
/// Quality used for jpg compression. From 0.0 to 1.0
@property(nonatomic, assign) CGFloat jpegQuality;

/**
Creates new parameters instance for png image.
@return New instance of parameters
*/
+ (instancetype)pngImage;

/**
Creates new parameters instance for jpeg image.
@param quality Used only for <b>VKImageTypeJpg</b> representation. From 0.0 to 1.0
@return New instance with passed parameters
*/
+ (instancetype)jpegImageWithQuality:(float)quality;

/**
Return file extension for selected type
@return png for VKImageTypePng image type, jpg for VKImageTypeJpg image type
*/
- (NSString *)fileExtension;

/**
Return mime type
@return parameters mime type
*/
- (NSString *)mimeType;
@end


