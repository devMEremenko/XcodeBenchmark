// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"

#import <UIKit/UIKit.h>

#import "GoogleSignIn/Sources/GIDSignInStrings.h"

NS_ASSUME_NONNULL_BEGIN

// The error key in the server response.
static NSString *const kErrorKey = @"error";

// Error strings in the server response.
static NSString *const kGeneralErrorPrefix = @"emm_";
static NSString *const kScreenlockRequiredError = @"emm_passcode_required";
static NSString *const kAppVerificationRequiredErrorPrefix = @"emm_app_verification_required";

// Optional separator between error prefix and the payload.
static NSString *const kErrorPayloadSeparator = @":";

// A list for recognized error codes.
typedef enum {
  ErrorCodeNone = 0,
  ErrorCodeDeviceNotCompliant,
  ErrorCodeScreenlockRequired,
  ErrorCodeAppVerificationRequired,
} ErrorCode;

@implementation GIDEMMErrorHandler {
  // Whether or not a dialog is pending user interaction.
  BOOL _pendingDialog;
}

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static GIDEMMErrorHandler *sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (BOOL)handleErrorFromResponse:(NSDictionary<NSString *, id> *)response
                     completion:(void (^)(void))completion {
  ErrorCode errorCode = ErrorCodeNone;
  NSURL *appVerificationURL;
  @synchronized(self) {  // for accessing _pendingDialog
    if (!_pendingDialog && [UIAlertController class] &&
        [response isKindOfClass:[NSDictionary class]]) {
      id errorValue = response[kErrorKey];
      if ([errorValue isEqual:kScreenlockRequiredError]) {
        errorCode = ErrorCodeScreenlockRequired;
      } else if ([errorValue hasPrefix:kAppVerificationRequiredErrorPrefix]) {
        errorCode = ErrorCodeAppVerificationRequired;
        NSString *appVerificationString =
            [errorValue substringFromIndex:kAppVerificationRequiredErrorPrefix.length];
        if ([appVerificationString hasPrefix:kErrorPayloadSeparator]) {
          appVerificationString =
              [appVerificationString substringFromIndex:kErrorPayloadSeparator.length];
        }
        appVerificationString = [appVerificationString
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (appVerificationString.length) {
          appVerificationURL = [NSURL URLWithString:appVerificationString];
        }
      } else if ([errorValue hasPrefix:kGeneralErrorPrefix]) {
        errorCode = ErrorCodeDeviceNotCompliant;
      }
      if (errorCode) {
        _pendingDialog = YES;
      }
    }
  }
  if (!errorCode) {
    completion();
    return NO;
  }
  // All UI must happen in the main thread.
  dispatch_async(dispatch_get_main_queue(), ^() {
    UIWindow *keyWindow = [self keyWindow];
    if (!keyWindow) {
      // Shouldn't happen, just in case.
      completion();
      return;
    }
    UIWindow *alertWindow;
    if (@available(iOS 13, *)) {
      if (keyWindow.windowScene) {
        alertWindow = [[UIWindow alloc] initWithWindowScene:keyWindow.windowScene];
      }
    }
    if (!alertWindow) {
      CGRect keyWindowBounds = CGRectIsEmpty(keyWindow.bounds) ?
        keyWindow.bounds : [UIScreen mainScreen].bounds;
      alertWindow = [[UIWindow alloc] initWithFrame:keyWindowBounds];
    }
    alertWindow.backgroundColor = [UIColor clearColor];
    alertWindow.rootViewController = [[UIViewController alloc] init];
    alertWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
    alertWindow.windowLevel = UIWindowLevelAlert;
    [alertWindow makeKeyAndVisible];
    void (^finish)(void) = ^{
      alertWindow.hidden = YES;
      alertWindow.rootViewController = nil;
      [keyWindow makeKeyAndVisible];
      self->_pendingDialog = NO;
      completion();
    };
    UIAlertController *alert;
    switch (errorCode) {
      case ErrorCodeNone:
        break;
      case ErrorCodeScreenlockRequired:
        alert = [self passcodeRequiredAlertWithCompletion:finish];
        break;
      case ErrorCodeAppVerificationRequired:
        alert = [self appVerificationRequiredAlertWithURL:appVerificationURL completion:finish];
        break;
      case ErrorCodeDeviceNotCompliant:
        alert = [self deviceNotCompliantAlertWithCompletion:finish];
        break;
    }
    if (alert) {
      [alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
      // Should not happen but just in case.
      finish();
    }
  });
  return YES;
}

// This method is exposed to the unit test.
- (nullable UIWindow *)keyWindow {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
  if (@available(iOS 15, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if ([scene isKindOfClass:[UIWindowScene class]] &&
          scene.activationState == UISceneActivationStateForegroundActive) {
        return ((UIWindowScene *)scene).keyWindow;
      }
    }
  } else
#endif  // __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
  {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
    if (@available(iOS 13, *)) {
      for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
          return window;
        }
      }
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
      return UIApplication.sharedApplication.keyWindow;
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
    }
#endif  // __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_15_0
  }
  return nil;
}

#pragma mark - Alerts

// Returns an alert controller for device not compliant error.
- (UIAlertController *)deviceNotCompliantAlertWithCompletion:(void (^)(void))completion {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:[self unableToAccessString]
                                          message:[self deviceNotCompliantString]
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:[self okayString]
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
    completion();
  }]];
  return alert;
};

// Returns an alert controller for passcode required error.
- (UIAlertController *)passcodeRequiredAlertWithCompletion:(void (^)(void))completion {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:[self unableToAccessString]
                                          message:[self passcodeRequiredString]
                                   preferredStyle:UIAlertControllerStyleAlert];
  BOOL canOpenSettings = YES;
  if ([[UIDevice currentDevice].systemVersion hasPrefix:@"10."]) {
     // In iOS 10, `UIApplicationOpenSettingsURLString` fails to open the Settings app if the
     // opening app does not have Setting bundle.
    NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
    NSString* settingsBundlePath = [mainBundlePath
        stringByAppendingPathComponent:@"Settings.bundle"];
    if (![NSBundle bundleWithPath:settingsBundlePath]) {
      canOpenSettings = NO;
    }
  }
  if (canOpenSettings) {
    [alert addAction:[UIAlertAction actionWithTitle:[self cancelString]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
      completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:[self settingsString]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
      completion();
      [self openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
  } else {
    [alert addAction:[UIAlertAction actionWithTitle:[self okayString]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
      completion();
    }]];
  }
  return alert;
};

// Returns an alert controller for app verification required error.
- (UIAlertController *)appVerificationRequiredAlertWithURL:(nullable NSURL *)url
                                                completion:(void (^)(void))completion {
  UIAlertController *alert;
  if (url) {
    // If the URL is provided, prompt user to open this URL or cancel.
    alert = [UIAlertController alertControllerWithTitle:[self appVerificationTitleString]
                                                message:[self appVerificationTextString]
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[self cancelString]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
      completion();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:[self appVerificationActionString]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
      completion();
      [self openURL:url];
    }]];
  } else {
    // If the URL is not provided, simple let user acknowledge the issue. This is not supposed to
    // happen but just to fail gracefully.
    alert = [UIAlertController alertControllerWithTitle:[self unableToAccessString]
                                                message:[self appVerificationTextString]
                                         preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[self okayString]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
      completion();
    }]];
  }
  return alert;
}

- (void)openURL:(NSURL *)url {
  [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

#pragma mark - Localization

// The English version of the strings are used as back-up in case the bundle resource is missing
// from the third-party app. Please keep them in sync with the strings in the bundle.

// Returns a localized string for unable to access the account.
- (NSString *)unableToAccessString {
  return [GIDSignInStrings localizedStringForKey:@"EmmErrorTitle"
                                            text:@"Unable to sign in to account"];
}

// Returns a localized string for device passcode required error.
- (NSString *)passcodeRequiredString {
  NSString *defaultText =
      @"Your administrator requires you to set a passcode on this device to access this account. "
      "Please set a passcode and try again.";
  return [GIDSignInStrings localizedStringForKey:@"EmmPasscodeRequired" text:defaultText];
}

// Returns a localized string for app verification error dialog title.
- (NSString *)appVerificationTitleString {
  return [GIDSignInStrings localizedStringForKey:@"EmmConnectTitle"
                                            text:@"Connect with Device Policy App?"];
}

// Returns a localized string for app verification error dialog message.
- (NSString *)appVerificationTextString {
  NSString *defaultText = @"In order to protect your organization's data, "
      "you must connect with the Device Policy app before logging in.";
  return [GIDSignInStrings localizedStringForKey:@"EmmConnectText" text:defaultText];
}

// Returns a localized string for app verification error dialog action button label.
- (NSString *)appVerificationActionString {
  return [GIDSignInStrings localizedStringForKey:@"EmmConnectLabel" text:@"Connect"];
}

// Returns a localized string for general device non-compliance error.
- (NSString *)deviceNotCompliantString {
  NSString *defaultText =
      @"The device is not compliant with the security policy set by your administrator.";
  return [GIDSignInStrings localizedStringForKey:@"EmmGeneralError" text:defaultText];
}

// Returns a localized string for "Settings".
- (NSString *)settingsString {
  return [GIDSignInStrings localizedStringForKey:@"SettingsAppName" text:@"Settings"];
}

// Returns a localized string for "OK".
- (NSString *)okayString {
  return [GIDSignInStrings localizedStringForKey:@"OK" text:@"OK"];
}

// Returns a localized string for "Cancel".
- (NSString *)cancelString {
  return [GIDSignInStrings localizedStringForKey:@"Cancel" text:@"Cancel"];
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
