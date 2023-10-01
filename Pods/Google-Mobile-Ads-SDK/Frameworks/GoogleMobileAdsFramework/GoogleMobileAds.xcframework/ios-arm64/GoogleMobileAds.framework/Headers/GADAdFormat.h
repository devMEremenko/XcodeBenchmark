//
//  GADAdFormat.h
//  Google Mobile Ads SDK
//
//  Copyright 2018-2022 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Requested ad format.
typedef NS_ENUM(NSInteger, GADAdFormat) {
  GADAdFormatBanner,                ///< Banner.
  GADAdFormatInterstitial,          ///< Interstitial.
  GADAdFormatRewarded,              ///< Rewarded.
  GADAdFormatNative,                ///< Native.
  GADAdFormatRewardedInterstitial,  ///< Rewarded interstitial.
  GADAdFormatUnknown,               ///< Unknown.
  GADAdFormatAppOpen,               ///< App open.
};
