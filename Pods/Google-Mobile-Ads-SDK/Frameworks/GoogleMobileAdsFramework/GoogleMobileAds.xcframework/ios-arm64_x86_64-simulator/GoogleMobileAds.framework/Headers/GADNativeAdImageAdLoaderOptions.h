//
//  GADNativeAdImageAdLoaderOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>

/// Ad loader options for native ad image settings.
@interface GADNativeAdImageAdLoaderOptions : GADAdLoaderOptions

/// Indicates whether image asset content should be loaded by the SDK. If set to YES, the SDK will
/// not load image asset content and native ad image URLs can be used to fetch content. Defaults to
/// NO, image assets are loaded by the SDK.
@property(nonatomic, assign) BOOL disableImageLoading;

/// Indicates whether multiple images should be loaded for each asset. Defaults to NO.
@property(nonatomic, assign) BOOL shouldRequestMultipleImages;

@end
