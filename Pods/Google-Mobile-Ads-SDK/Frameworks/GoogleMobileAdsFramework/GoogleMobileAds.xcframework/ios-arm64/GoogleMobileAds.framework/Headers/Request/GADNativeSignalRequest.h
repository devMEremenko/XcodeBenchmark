//
//  GADNativeSignalRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdChoicesPosition.h>
#import <GoogleMobileAds/GADMediaAspectRatio.h>
#import <GoogleMobileAds/GADVideoOptions.h>
#import <GoogleMobileAds/Request/GADSignalRequest.h>

/// A native signal request that can be used as input in server-to-server signal generation.
@interface GADNativeSignalRequest : GADSignalRequest

/// Number of ads to request. By default, numberOfAds
/// is one. Requests are invalid and will fail if numberOfAds is less than one. If numberOfAds
/// exceeds the maximum limit (5), only the maximum number of ads are requested.
@property(nonatomic) NSInteger numberOfAds;

/// Indicates whether image asset content should be loaded by the SDK. If set to YES, the SDK will
/// disable image asset loading and native ad image URLs can be used to fetch content. Defaults to
/// NO, image assets are loaded by the SDK.
@property(nonatomic, assign) BOOL disableImageLoading;

/// Indicates whether multiple images should be loaded for each asset. Defaults to NO.
@property(nonatomic, assign) BOOL shouldRequestMultipleImages;

/// Image and video aspect ratios. Portrait, landscape, and
/// square aspect ratios are returned when this property is GADMediaAspectRatioUnknown or
/// GADMediaAspectRatioAny. Defaults to GADMediaAspectRatioUnknown.
@property(nonatomic, assign) GADMediaAspectRatio mediaAspectRatio;

/// Indicates preferred location of AdChoices icon. Default is GADAdChoicesPositionTopRightCorner.
@property(nonatomic, assign) GADAdChoicesPosition preferredAdChoicesPosition;

/// Indicates whether the custom Mute This Ad feature is requested. Defaults to NO.
@property(nonatomic, assign) BOOL customMuteThisAdRequested;

/// Indicates whether the publisher will record impressions manually when the ad becomes visible to
/// the user. Defaults to NO.
@property(nonatomic, assign) BOOL enableManualImpressions;

/// Enable the direction for detecting swipe gestures and counting them as clicks, and
/// whether tap gestures are also allowed on the ad. By default, swipe gestures are disabled.
///
/// Available for allowlisted publishers only. Settings will be ignored for publishers not
/// allowlisted.
- (void)enableSwipeGestureDirection:(UISwipeGestureRecognizerDirection)direction
                        tapsAllowed:(BOOL)tapsAllowed;

/// Video ad options. Defaults to nil.
@property(nonatomic, copy, nullable) GADVideoOptions *videoOptions;

/// Array of NSValue encoded GADAdSize structs, specifying all valid sizes that are
/// appropriate for this slot. Never create your own GADAdSize directly. Use one of the predefined
/// standard ad sizes (such as GADAdSizeBanner), or create one using the GADAdSizeFromCGSize
/// method.
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

/// Set of ad loader ad types. See GADAdLoaderAdTypes.h for available ad loader ad types.
@property(nonatomic, copy, nullable) NSSet<GADAdLoaderAdType> *adLoaderAdTypes;

/// Array of custom native ad format IDs.
@property(nonatomic, copy, nullable) NSArray<NSString *> *customNativeAdFormatIDs;

/// Returns an initialized native signal request.
/// @param signalType The type of signal to request.
- (nonnull instancetype)initWithSignalType:(nonnull NSString *)signalType;

@end
