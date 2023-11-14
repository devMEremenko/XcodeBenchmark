#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "RCAActionProtocol.h"
#import "RCARecaptchaClientProtocol.h"
#import "RCARecaptchaProtocol.h"
#import "RecaptchaInterop.h"

FOUNDATION_EXPORT double RecaptchaInteropVersionNumber;
FOUNDATION_EXPORT const unsigned char RecaptchaInteropVersionString[];

