//
//  VKBundle.h
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

#define VKLocalizedString(s) [VKBundle localizedString:s]
#define VKImageNamed(s)      [VKBundle vkLibraryImageNamed:s]

/**
Class for providing resources from VK SDK Bundle
*/
@interface VKBundle : VKObject
/**
Returns bundle for VK SDK (by default VKSdkResources)
@return Bundle object or nil
*/
+ (NSBundle *)vkLibraryResourcesBundle;

/**
Searches for image in main application bundle, then VK SDK bundle
@param name Name for image to find
@return Founded image object or nil, if file not found
*/
+ (UIImage *)vkLibraryImageNamed:(NSString *)name;

/**
* Returns localized string from VK bundle
*/
+ (NSString *)localizedString:(NSString *)string;
@end
