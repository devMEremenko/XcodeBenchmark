//
//  GADNativeAdDelegate.h
//  Google Mobile Ads SDK
//
//  Copyright 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GADNativeAd;

/// Identifies native ad assets.
@protocol GADNativeAdDelegate <NSObject>

@optional

#pragma mark - Ad Lifecycle Events

/// Called when an impression is recorded for an ad.
- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd;

/// Called when a click is recorded for an ad.
- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd;

/// Called when a swipe gesture click is recorded for an ad.
- (void)nativeAdDidRecordSwipeGestureClick:(nonnull GADNativeAd *)nativeAd;

#pragma mark - Click-Time Lifecycle Notifications

/// Called before presenting the user a full screen view in response to an ad action. Use this
/// opportunity to stop animations, time sensitive interactions, etc.
///
/// Normally the user looks at the ad, dismisses it, and control returns to your application with
/// the nativeAdDidDismissScreen: message. However, if the user hits the Home button or clicks on an
/// App Store link, your application will be backgrounded. The next method called will be the
/// applicationWillResignActive: of your UIApplicationDelegate object.
- (void)nativeAdWillPresentScreen:(nonnull GADNativeAd *)nativeAd;

/// Called before dismissing a full screen view.
- (void)nativeAdWillDismissScreen:(nonnull GADNativeAd *)nativeAd;

/// Called after dismissing a full screen view. Use this opportunity to restart anything you may
/// have stopped as part of nativeAdWillPresentScreen:.
- (void)nativeAdDidDismissScreen:(nonnull GADNativeAd *)nativeAd;

#pragma mark - Mute This Ad

/// Used for Mute This Ad feature. Called after the native ad is muted. Only called for Google ads
/// and is not supported for mediated ads.
- (void)nativeAdIsMuted:(nonnull GADNativeAd *)nativeAd;

@end
