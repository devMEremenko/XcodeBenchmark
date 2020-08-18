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

#import "firebasecore.nanopb.h"
#import "GoogleDataTransportInternal.h"
#import "GULAppEnvironmentUtil.h"
#import "GULHeartbeatDateStorage.h"
#import "GULKeychainStorage.h"
#import "GULKeychainUtils.h"
#import "GULSecureCoding.h"
#import "GULLogger.h"
#import "FIRCoreDiagnosticsData.h"
#import "FIRCoreDiagnosticsInterop.h"

FOUNDATION_EXPORT double FirebaseCoreDiagnosticsVersionNumber;
FOUNDATION_EXPORT const unsigned char FirebaseCoreDiagnosticsVersionString[];

