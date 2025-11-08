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

#import "FIRAuth.h"
#import "FIRAuthErrors.h"
#import "FirebaseAuth.h"
#import "FIREmailAuthProvider.h"
#import "FIRFacebookAuthProvider.h"
#import "FIRFederatedAuthProvider.h"
#import "FIRGameCenterAuthProvider.h"
#import "FIRGitHubAuthProvider.h"
#import "FIRGoogleAuthProvider.h"
#import "FIRMultiFactor.h"
#import "FIRPhoneAuthProvider.h"
#import "FIRTwitterAuthProvider.h"
#import "FIRUser.h"

FOUNDATION_EXPORT double FirebaseAuthVersionNumber;
FOUNDATION_EXPORT const unsigned char FirebaseAuthVersionString[];

