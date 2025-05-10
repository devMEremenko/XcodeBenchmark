/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageGraphics.h"
#import "NSImage+Compatibility.h"
#import "SDImageCoderHelper.h"
#import "objc/runtime.h"

#if SD_MAC
static void *kNSGraphicsContextScaleFactorKey;

static CGContextRef SDCGContextCreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale) {
    if (scale == 0) {
        // Match `UIGraphicsBeginImageContextWithOptions`, reset to the scale factor of the device’s main screen if scale is 0.
        NSScreen *mainScreen = nil;
        if (@available(macOS 10.12, *)) {
            mainScreen = [NSScreen mainScreen];
        } else {
            mainScreen = [NSScreen screens].firstObject;
        }
        scale = mainScreen.backingScaleFactor ?: 1.0f;
    }
    size_t width = ceil(size.width * scale);
    size_t height = ceil(size.height * scale);
    if (width < 1 || height < 1) return NULL;
    
    CGColorSpaceRef space = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
    // Check #3330 for more detail about why this bitmap is choosen.
    // From v5.17.0, use runtime detection of bitmap info instead of hardcode.
    // However, macOS's runtime detection will also call this function, cause recursive, so still hardcode here
    CGBitmapInfo bitmapInfo;
    if (!opaque) {
        // [NSImage imageWithSize:flipped:drawingHandler:] returns float(16-bits) RGBA8888 on alpha image, which we don't need
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    } else {
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    }
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, space, bitmapInfo);
    if (!context) {
        return NULL;
    }
    CGContextScaleCTM(context, scale, scale);
    
    return context;
}
#endif

CGContextRef SDGraphicsGetCurrentContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetCurrentContext();
#else
    return NSGraphicsContext.currentContext.CGContext;
#endif
}

void SDGraphicsBeginImageContext(CGSize size) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsBeginImageContext(size);
#else
    SDGraphicsBeginImageContextWithOptions(size, NO, 1.0);
#endif
}

void SDGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
#else
    CGContextRef context = SDCGContextCreateBitmapContext(size, opaque, scale);
    if (!context) {
        return;
    }
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    objc_setAssociatedObject(graphicsContext, &kNSGraphicsContextScaleFactorKey, @(scale), OBJC_ASSOCIATION_RETAIN);
    CGContextRelease(context);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = graphicsContext;
#endif
}

void SDGraphicsEndImageContext(void) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsEndImageContext();
#else
    [NSGraphicsContext restoreGraphicsState];
#endif
}

UIImage * SDGraphicsGetImageFromCurrentImageContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetImageFromCurrentImageContext();
#else
    NSGraphicsContext *context = NSGraphicsContext.currentContext;
    CGContextRef contextRef = context.CGContext;
    if (!contextRef) {
        return nil;
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    if (!imageRef) {
        return nil;
    }
    CGFloat scale = 0;
    NSNumber *scaleFactor = objc_getAssociatedObject(context, &kNSGraphicsContextScaleFactorKey);
    if ([scaleFactor isKindOfClass:[NSNumber class]]) {
        scale = scaleFactor.doubleValue;
    }
    if (!scale) {
        // reset to the scale factor of the device’s main screen if scale is 0.
        NSScreen *mainScreen = nil;
        if (@available(macOS 10.12, *)) {
            mainScreen = [NSScreen mainScreen];
        } else {
            mainScreen = [NSScreen screens].firstObject;
        }
        scale = mainScreen.backingScaleFactor ?: 1.0f;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
    CGImageRelease(imageRef);
    return image;
#endif
}
