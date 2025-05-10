//
//  GADMediationBannerAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2018 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdSize.h>
#import <GoogleMobileAds/Mediation/GADMediationAd.h>
#import <GoogleMobileAds/Mediation/GADMediationAdConfiguration.h>
#import <GoogleMobileAds/Mediation/GADMediationAdEventDelegate.h>
#import <UIKit/UIKit.h>

/// Rendered banner ad. Provides a single subview to add to the banner view's view hierarchy.
@protocol GADMediationBannerAd <GADMediationAd>

/// The banner ad view.
@property(nonatomic, readonly, nonnull) UIView *view;

@optional

/// Tells the ad to resize the banner. Implement if banner content is resizable.
- (void)changeAdSizeTo:(GADAdSize)adSize;
@end

/// Rendered interscroller ad.
GAD_DEPRECATED_MSG_ATTRIBUTE("Interscroller will not be supported.")
@protocol GADMediationInterscrollerAd <GADMediationBannerAd>

/// Indicates whether the interscroller rendering effect should be delegated to the Google Mobile
/// Ads SDK.
@property(nonatomic, assign) BOOL delegateInterscrollerEffect;

@end

/// Banner ad configuration.
@interface GADMediationBannerAdConfiguration : GADMediationAdConfiguration

/// Banner ad size requested of the adapter.
@property(nonatomic, readonly) GADAdSize adSize;

@end
