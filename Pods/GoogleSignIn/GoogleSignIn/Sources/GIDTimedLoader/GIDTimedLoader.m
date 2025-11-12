/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleSignIn/Sources/GIDTimedLoader/GIDTimedLoader.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@import UIKit;
@import CoreMedia;
#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/GIDAppCheck.h"
#import "GoogleSignIn/Sources/GIDAppCheck/UI/GIDActivityIndicatorViewController.h"

CFTimeInterval const kGIDTimedLoaderMinAnimationDuration = 1.0;
CFTimeInterval const kGIDTimedLoaderMaxDelayBeforeAnimating = 0.8;

@interface GIDTimedLoader ()

@property(nonatomic, strong) UIViewController *presentingViewController;
@property(nonatomic, strong) GIDActivityIndicatorViewController *loadingViewController;
@property(nonatomic, strong, nullable) NSTimer *loadingTimer;
/// Timestamp representing when the loading view controller was presented and started animating
@property(nonatomic) CFTimeInterval loadingTimeStamp;

@end

@implementation GIDTimedLoader

- (instancetype)initWithPresentingViewController:(UIViewController *)presentingViewController {
  if (self = [super init]) {
    _presentingViewController = presentingViewController;
    _loadingViewController = [[GIDActivityIndicatorViewController alloc] init];
    _animationStatus = GIDTimedLoaderAnimationStatusNotStarted;
  }
  return self;
}

- (void)startTiming {
  if (self.animationStatus == GIDTimedLoaderAnimationStatusAnimating) {
    return;
  }

  self.animationStatus = GIDTimedLoaderAnimationStatusAnimating;
  self.loadingTimer = [NSTimer scheduledTimerWithTimeInterval:kGIDTimedLoaderMaxDelayBeforeAnimating
                                                       target:self
                                                     selector:@selector(presentLoadingViewController)
                                                     userInfo:nil
                                                      repeats:NO];
}

- (void)presentLoadingViewController {
  if (self.animationStatus == GIDTimedLoaderAnimationStatusStopped) {
    return;
  }
  self.animationStatus = GIDTimedLoaderAnimationStatusAnimating;
  self.loadingTimeStamp = CACurrentMediaTime();
  dispatch_async(dispatch_get_main_queue(), ^{
    // Since this loading VC may be reused, the activity indicator may have been stopped; restart it
    self.loadingViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.loadingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.presentingViewController.definesPresentationContext = YES;
    [self.loadingViewController.activityIndicator startAnimating];
    [self.presentingViewController presentViewController:self.loadingViewController
                                                animated:YES
                                              completion:nil];
  });
}

- (void)stopTimingWithCompletion:(void (^)(void))completion {
  if (self.animationStatus != GIDTimedLoaderAnimationStatusAnimating) {
    return;
  }

  [self.loadingTimer invalidate];
  self.loadingTimer = nil;

  dispatch_time_t deadline = [self remainingDurationToAnimate];
  dispatch_after(deadline, dispatch_get_main_queue(), ^{
    self.animationStatus = GIDTimedLoaderAnimationStatusStopped;
    [self.loadingViewController.activityIndicator stopAnimating];
    [self.loadingViewController dismissViewControllerAnimated:YES completion:nil];
    completion();
  });
}

- (dispatch_time_t)remainingDurationToAnimate {
  // If we are not animating, then no need to wait
  if (self.animationStatus != GIDTimedLoaderAnimationStatusAnimating) {
    return 0;
  }

  CFTimeInterval now = CACurrentMediaTime();
  CFTimeInterval durationWaited = now - self.loadingTimeStamp;
  // If we have already waited for the minimum animation duration, then no need to wait
  if (durationWaited >= kGIDTimedLoaderMinAnimationDuration) {
    return 0;
  }

  CFTimeInterval diff = kGIDTimedLoaderMinAnimationDuration - durationWaited;
  int64_t diffNanos = diff * NSEC_PER_SEC;
  dispatch_time_t timeToWait = dispatch_time(DISPATCH_TIME_NOW, diffNanos);
  return timeToWait;
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
