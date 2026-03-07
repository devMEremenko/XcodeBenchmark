//
//  GADAdFormat.h
//  Google Mobile Ads SDK
//
//  Copyright 2018-2022 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

/// Requested ad format.
typedef NS_ENUM(NSInteger, GADAdFormat) {
  GADAdFormatBanner = 0,                ///< Banner.
  GADAdFormatInterstitial = 1,          ///< Interstitial.
  GADAdFormatRewarded = 2,              ///< Rewarded.
  GADAdFormatNative = 3,                ///< Native.
  GADAdFormatRewardedInterstitial = 4,  ///< Rewarded interstitial.
  GADAdFormatAppOpen = 6,  ///< App open.
};
