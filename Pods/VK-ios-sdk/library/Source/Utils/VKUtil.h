//
//  VKUtil.h
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

#define VK_COLOR                                       [UIColor colorWithRed:85.0f / 255 green:133.0f / 255 blue:188.0f / 255 alpha:1.0f]
#define VK_IS_DEVICE_IPAD                               (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])

#import <UIKit/UIKit.h>

/**
Various functions
*/
@interface VKUtil : NSObject
/**
Breaks key=value string to dictionary
@param queryString string with key=value pairs joined by & symbol
@return Dictionary of parameters
*/
+ (NSDictionary *)explodeQueryString:(NSString *)queryString;

+ (NSString *)generateGUID;

+ (NSNumber *)parseNumberString:(id)number;

+ (UIColor *)colorWithRGB:(NSInteger)rgb;

+ (NSString *)queryStringFromParams:(NSDictionary *)params;

/**
 * Indicates that the current device system version at least conforms the argument version
 */
+ (BOOL) isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion) version;

/**
 * Returns true if the current device uses iOS 7 or greater
 */
+ (BOOL) isOperatingSystemAtLeastIOS7;

/**
 * Returns true if the current device uses iOS 8 or greater
 */
+ (BOOL) isOperatingSystemAtLeastIOS8;
@end


@interface UIImage (RoundedImage)
- (UIImage *)vks_roundCornersImage:(CGFloat)cornerRadius resultSize:(CGSize)imageSize;
@end

static inline NSNumber *VK_ENSURE_NUM(id obj) {
    return [obj isKindOfClass:[NSNumber class]] ? obj : nil;
}

static inline NSDictionary *VK_ENSURE_DICT(id data) {
    return [data isKindOfClass:[NSDictionary class]] ? data : nil;
}

static inline NSArray *VK_ENSURE_ARRAY(id data) {
    return [data isKindOfClass:[NSArray class]] ? data : nil;
}

static inline id VK_ENSURE(id data, Class objectClass) {
    return [data isKindOfClass:objectClass] ? data : nil;
}
