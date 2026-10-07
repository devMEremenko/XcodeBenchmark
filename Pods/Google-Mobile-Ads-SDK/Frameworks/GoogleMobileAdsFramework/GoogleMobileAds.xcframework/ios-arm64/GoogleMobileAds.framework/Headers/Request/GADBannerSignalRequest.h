//
//  GADBannerSignalRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdSize.h>
#import <GoogleMobileAds/GADVideoOptions.h>
#import <GoogleMobileAds/Request/GADSignalRequest.h>

/// A banner signal request that can be used as input in server-to-server signal generation.
@interface GADBannerSignalRequest : GADSignalRequest

/// Indicates that the publisher will record impressions manually when the ad becomes visible to the
/// user.
@property(nonatomic) BOOL enableManualImpressions;

/// The banner ad size. Use one of the predefined standard ad sizes (such as GADAdSizeBanner), or
/// create one using the GADAdSizeFromCGSize method. Never create your own GADAdSize directly.
@property(nonatomic, assign) GADAdSize adSize;

/// Array of NSValue encoded GADAdSize structs, specifying all valid sizes that are
/// appropriate for this slot. Use one of the predefined
/// standard ad sizes (such as GADAdSizeBanner), or create one using the GADAdSizeFromCGSize
/// method. Never create your own GADAdSize directly.
///
/// Example:
///
///   \code
///   NSArray *adSizes = @[
///     NSValueFromGADAdSize(GADAdSizeBanner),
///     NSValueFromGADAdSize(GADAdSizeLargeBanner)
///   ];
///
///   signalRequest.adSizes = adSizes;
///   \endcode
@property(nonatomic, copy, nullable) NSArray<NSValue *> *adSizes;

/// Video ad options. Defaults to nil.
@property(nonatomic, copy, nullable) GADVideoOptions *videoOptions;

/// Returns an initialized banner signal request.
/// @param signalType The type of signal to request.
- (nonnull instancetype)initWithSignalType:(nonnull NSString *)signalType;

@end
