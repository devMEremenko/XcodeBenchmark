//
//  GADNativeAdViewAdOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2016 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdChoicesPosition.h>
#import <GoogleMobileAds/GADAdLoader.h>

/// Ad loader options for configuring the view of native ads.
@interface GADNativeAdViewAdOptions : GADAdLoaderOptions

/// Indicates preferred location of AdChoices icon. Default is GADAdChoicesPositionTopRightCorner.
@property(nonatomic, assign) GADAdChoicesPosition preferredAdChoicesPosition;

@end
