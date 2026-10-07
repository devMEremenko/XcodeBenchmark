//
//  GADNativeAdCustomClickGestureOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2022 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>

/// Ad loader options for custom click gestures. Available for allowlisted publishers only. These
/// options will be ignored for publishers not allowlisted.
@interface GADNativeAdCustomClickGestureOptions : GADAdLoaderOptions

/// The direction in which swipe gestures should be detected and counted as clicks.
@property(nonatomic, assign) UISwipeGestureRecognizerDirection swipeGestureDirection;

/// Whether tap gestures should continue to be detected and counted as clicks.
@property(nonatomic, assign) BOOL tapsAllowed;

/// Initialize with the direction for detecting swipe gestures and counting them as clicks, and
/// whether tap gestures are allowed on the ad.
- (nonnull instancetype)initWithSwipeGestureDirection:(UISwipeGestureRecognizerDirection)direction
                                          tapsAllowed:(BOOL)tapsAllowed NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
