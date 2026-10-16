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

#import "GIDAppCheckError.h"
#import "GIDConfiguration.h"
#import "GIDGoogleUser.h"
#import "GIDProfileData.h"
#import "GIDSignIn.h"
#import "GIDSignInButton.h"
#import "GIDSignInResult.h"
#import "GIDToken.h"
#import "GoogleSignIn.h"

FOUNDATION_EXPORT double GoogleSignInVersionNumber;
FOUNDATION_EXPORT const unsigned char GoogleSignInVersionString[];

