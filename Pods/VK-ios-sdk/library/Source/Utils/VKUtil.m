//
//  VKUtil.m
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

#import "VKUtil.h"

@implementation VKUtil

+ (NSDictionary *)explodeQueryString:(NSString *)queryString {
    NSArray *keyValuePairs = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    for (NSString *keyValueString in keyValuePairs) {
        NSArray *keyValueArray = [keyValueString componentsSeparatedByString:@"="];
        parameters[keyValueArray[0]] = keyValueArray[1];
    }
    return parameters;
}

+ (NSString *)generateGUID {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef str = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    NSString *uuidString = [NSString stringWithFormat:@"%@", (__bridge NSString *) str];
    CFRelease(uuid);
    CFRelease(str);
    return uuidString;
}

+ (NSNumber *)parseNumberString:(id)number {
    if ([number isKindOfClass:[NSNumber class]])
        return (NSNumber *) number;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t semaphore;
    static NSNumberFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        semaphore = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSNumber *value = [formatter numberFromString:number];
    dispatch_semaphore_signal(semaphore);
    return value;
}

+ (UIColor *)colorWithRGB:(NSInteger)rgb {
    return [UIColor colorWithRed:((CGFloat) ((rgb & 0xFF0000) >> 16)) / 255.f green:((CGFloat) ((rgb & 0xFF00) >> 8)) / 255.f blue:((CGFloat) (rgb & 0xFF)) / 255.f alpha:1.0f];
}

static NSString *const kCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

+ (NSString *)escapeString:(NSString *)value {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
    return (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef) value, NULL, (__bridge CFStringRef) kCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
#else 
    static NSCharacterSet *charset = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charset = [[NSCharacterSet characterSetWithCharactersInString:kCharactersToBeEscapedInQueryString] invertedSet];
    });
    return [value stringByAddingPercentEncodingWithAllowedCharacters:charset];
#endif
}

+ (NSString *)queryStringFromParams:(NSDictionary *)params {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:params.count];
    for (NSString *key in params) {
        if ([params[key] isKindOfClass:[NSString class]])
            [array addObject:[NSString stringWithFormat:@"%@=%@", key, [self escapeString:params[key]]]];
        else
            [array addObject:[NSString stringWithFormat:@"%@=%@", key, params[key]]];
    }
    return [array componentsJoinedByString:@"&"];
}

+ (BOOL) isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion) version {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
    } else {
        return (version.majorVersion == 7 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ||
               (version.majorVersion == 6 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_5_1);
        
    }
}

+ (BOOL) isOperatingSystemAtLeastIOS7 {
    return [VKUtil isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){7,0,0}];
}

+ (BOOL) isOperatingSystemAtLeastIOS8 {
    return [VKUtil isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){8,0,0}];
}

@end

///----------------------------
/// @name Processing preview images
///----------------------------

typedef enum CornerFlag {
    CornerFlagTopLeft = 0x01,
    CornerFlagTopRight = 0x02,
    CornerFlagBottomLeft = 0x04,
    CornerFlagBottomRight = 0x08,
    CornerFlagAll = CornerFlagTopLeft | CornerFlagTopRight | CornerFlagBottomLeft | CornerFlagBottomRight
} CornerFlag;


@implementation UIImage (RoundedImage)
- (void)vks_addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect width:(float)ovalWidth height:(float)ovalHeight toCorners:(CornerFlag)corners {
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    float fw = CGRectGetWidth(rect) / ovalWidth;
    float fh = CGRectGetHeight(rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh / 2);
    if (corners & CornerFlagTopRight) {
        CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, 1);
    } else {
        CGContextAddLineToPoint(context, fw, fh);
    }
    if (corners & CornerFlagTopLeft) {
        CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 1);
    } else {
        CGContextAddLineToPoint(context, 0, fh);
    }
    if (corners & CornerFlagBottomLeft) {
        CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 1);
    } else {
        CGContextAddLineToPoint(context, 0, 0);
    }
    if (corners & CornerFlagBottomRight) {
        CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, 1);
    } else {
        CGContextAddLineToPoint(context, fw, 0);
    }
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (UIImage *)vks_roundCornersImage:(CGFloat)cornerRadius resultSize:(CGSize)imageSize {
    CGImageRef imageRef = self.CGImage;
    float imageWidth = CGImageGetWidth(imageRef);
    float imageHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGRect drawRect = (CGRect) {CGPointZero, imageWidth, imageHeight};
    size_t w = (size_t) (imageSize.width * [UIScreen mainScreen].scale);
    size_t h = (size_t) (imageSize.height * [UIScreen mainScreen].scale);
    cornerRadius *= [UIScreen mainScreen].scale;

    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    if (!context) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    CGContextClearRect(context, CGRectMake(0, 0, w, h));
    CGColorSpaceRelease(colorSpace);
    CGRect clipRect = CGRectMake(0, 0, w, h);
    float widthScale = w / imageWidth;
    float heightScale = h / imageHeight;
    float scale = MAX(widthScale, heightScale);
    drawRect.size.width = imageWidth * scale;
    drawRect.size.height = imageHeight * scale;
    drawRect.origin.x = (w - drawRect.size.width) / 2.0f;
    drawRect.origin.y = (h - drawRect.size.height) / 2.0f;
    [self vks_addRoundedRectToPath:context rect:clipRect width:cornerRadius height:cornerRadius toCorners:CornerFlagAll];
    CGContextClip(context);

    CGContextSaveGState(context);
    CGContextDrawImage(context, drawRect, imageRef);
    CGContextRestoreGState(context);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}
@end
