//
//  GADAppEventDelegate.h
//  Google Mobile Ads SDK
//
//  Copyright 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GADBannerView;
@class GADInterstitialAd;

/// Implement your app event within these methods. The delegate will be notified when the SDK
/// receives an app event message from the ad.
@protocol GADAppEventDelegate <NSObject>

@optional

/// Called when the banner receives an app event.
- (void)adView:(nonnull GADBannerView *)banner
    didReceiveAppEvent:(nonnull NSString *)name
              withInfo:(nullable NSString *)info;

/// Called when the interstitial receives an app event.
- (void)interstitialAd:(nonnull GADInterstitialAd *)interstitialAd
    didReceiveAppEvent:(nonnull NSString *)name
              withInfo:(nullable NSString *)info;

@end
