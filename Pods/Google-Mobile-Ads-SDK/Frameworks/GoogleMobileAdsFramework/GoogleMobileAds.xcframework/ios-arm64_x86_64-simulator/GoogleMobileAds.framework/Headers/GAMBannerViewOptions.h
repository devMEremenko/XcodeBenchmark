//
//  GAMBannerViewOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2016 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>

/// Ad loader options for banner ads.
@interface GAMBannerViewOptions : GADAdLoaderOptions

/// Whether the publisher will record impressions manually when the ad becomes visible to the user.
@property(nonatomic, assign) BOOL enableManualImpressions;

@end
