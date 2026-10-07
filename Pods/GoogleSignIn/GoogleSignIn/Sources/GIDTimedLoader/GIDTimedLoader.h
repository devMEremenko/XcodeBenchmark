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

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

/// An enumeration detailing the states of the timed loader.
typedef NS_ENUM(NSUInteger, GIDTimedLoaderAnimationStatus) {
  /// The timed loader has not started.
  GIDTimedLoaderAnimationStatusNotStarted,
  /// The timed loader's activity indicator is animating.
  GIDTimedLoaderAnimationStatusAnimating,
  /// The timed loader's activity indicator has stopped animating.
  GIDTimedLoaderAnimationStatusStopped,
};

/// The minimum animation duration time for the timed loader's activity indicator.
extern CFTimeInterval const kGIDTimedLoaderMinAnimationDuration;
/// The maximum delay to wait before the time loader will display the loading activity indicator.
extern CFTimeInterval const kGIDTimedLoaderMaxDelayBeforeAnimating;

@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

/// A type used to manage the presentation of a load screen for at least
/// `kGIDTimedLoaderMinAnimationDuration` to prevent flashing.
///
/// `GIDTimedLoader` will also only show its loading screen until
/// `kGIDTimedLoaderMaxDelayBeforeAnimating` has expired.
@interface GIDTimedLoader : NSObject

/// Created this timed loading controller with the provided presenting view controller, which will
/// be used for presenting hte loading view controller with the activity indicator.
- (instancetype)initWithPresentingViewController:(UIViewController *)presentingViewController;

- (instancetype)init NS_UNAVAILABLE;

/// Tells the controller to start keeping track of loading time.
- (void)startTiming;

/// Tells the controller to stop keeping track of loading time.
///
/// @param completion The block to invoke upon successfully stopping.
/// @note Use the completion parameter to, for example, present the UI that should be shown after
///     the work has completed.
- (void)stopTimingWithCompletion:(void (^)(void))completion;

@property(nonatomic) GIDTimedLoaderAnimationStatus animationStatus;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
