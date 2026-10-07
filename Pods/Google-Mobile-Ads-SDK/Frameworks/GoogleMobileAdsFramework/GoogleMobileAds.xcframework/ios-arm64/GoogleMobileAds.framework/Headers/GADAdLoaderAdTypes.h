//
//  GADAdLoaderAdTypes.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

typedef NSString *GADAdLoaderAdType NS_TYPED_ENUM;

/// Use with GADAdLoader to request native custom template ads. To receive ads, the ad loader's
/// delegate must conform to the GADCustomNativeAdLoaderDelegate protocol. See GADCustomNativeAd.h.
FOUNDATION_EXPORT GADAdLoaderAdType _Nonnull const GADAdLoaderAdTypeCustomNative;

/// Use with GADAdLoader to request Google Ad Manager banner ads. To receive ads, the ad loader's
/// delegate must conform to the GAMBannerAdLoaderDelegate protocol. See GAMBannerView.h.
FOUNDATION_EXPORT GADAdLoaderAdType _Nonnull const GADAdLoaderAdTypeGAMBanner;

/// Use with GADAdLoader to request native ads. To receive ads, the ad loader's delegate must
/// conform to the GADNativeAdLoaderDelegate protocol. See GADNativeAd.h.
FOUNDATION_EXPORT GADAdLoaderAdType _Nonnull const GADAdLoaderAdTypeNative;
