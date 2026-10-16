//
//  GADCustomNativeAdDelegate.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GADCustomNativeAd;

/// Identifies native ad assets.
@protocol GADCustomNativeAdDelegate <NSObject>

@optional

#pragma mark Ad Lifecycle Events

/// Called when an impression is recorded for a custom native ad.
- (void)customNativeAdDidRecordImpression:(nonnull GADCustomNativeAd *)nativeAd;

/// Called when a click is recorded for a custom native ad.
- (void)customNativeAdDidRecordClick:(nonnull GADCustomNativeAd *)nativeAd;

#pragma mark Click-Time Lifecycle Notifications

/// Called just before presenting the user a full screen view, such as a browser, in response to
/// clicking on an ad. Use this opportunity to stop animations, time sensitive interactions, etc.
///
/// Normally the user looks at the ad, dismisses it, and control returns to your application with
/// the customNativeAdDidDismissScreen: message. However, if the user hits the Home button or clicks
/// on an App Store link, your application will end. The next method called will be the
/// applicationWillResignActive: of your UIApplicationDelegate object.
- (void)customNativeAdWillPresentScreen:(nonnull GADCustomNativeAd *)nativeAd;

/// Called just before dismissing a full screen view.
- (void)customNativeAdWillDismissScreen:(nonnull GADCustomNativeAd *)nativeAd;

/// Called just after dismissing a full screen view. Use this opportunity to restart anything you
/// may have stopped as part of customNativeAdWillPresentScreen:.
- (void)customNativeAdDidDismissScreen:(nonnull GADCustomNativeAd *)nativeAd;

@end
