//
//  GADFullScreenContentDelegate.h
//  Google Mobile Ads SDK
//
//  Copyright 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GADFullScreenContentDelegate;

/// Protocol for ads that present full screen content.
@protocol GADFullScreenPresentingAd <NSObject>

/// Delegate object that receives full screen content messages.
@property(nonatomic, weak, nullable) id<GADFullScreenContentDelegate> fullScreenContentDelegate;

@end

/// Delegate methods for receiving notifications about presentation and dismissal of full screen
/// content. Full screen content covers your application's content. The delegate may want to pause
/// animations or time sensitive interactions. Full screen content may be presented in the following
/// cases:
/// 1. A full screen ad is presented.
/// 2. An ad interaction opens full screen content.
@protocol GADFullScreenContentDelegate <NSObject>

@optional

/// Tells the delegate that an impression has been recorded for the ad.
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad;

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad;

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad
    didFailToPresentFullScreenContentWithError:(nonnull NSError *)error;

/// Tells the delegate that the ad will present full screen content.
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad;

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad;

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad;

#pragma mark - Unavailable

/// Unsupported. Delegates should implement adWillPresentFullScreenContent: instead.
- (void)adDidPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad NS_UNAVAILABLE;

@end
