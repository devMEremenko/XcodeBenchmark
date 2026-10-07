//
//  GAMBannerView.h
//  Google Mobile Ads SDK
//
//  Copyright 2012 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>
#import <GoogleMobileAds/GADAdLoaderDelegate.h>
#import <GoogleMobileAds/GADAppEventDelegate.h>
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADVideoController.h>

@class GAMBannerView;

/// The delegate of a GADAdLoader object must conform to this protocol to receive GAMBannerViews.
@protocol GAMBannerAdLoaderDelegate <GADAdLoaderDelegate>

/// Asks the delegate which banner ad sizes should be requested.
- (nonnull NSArray<NSValue *> *)validBannerSizesForAdLoader:(nonnull GADAdLoader *)adLoader;

/// Tells the delegate that a Google Ad Manager banner ad was received.
- (void)adLoader:(nonnull GADAdLoader *)adLoader
    didReceiveGAMBannerView:(nonnull GAMBannerView *)bannerView;

@end

/// The view that displays Ad Manager banner ads.
///
/// To request this ad type using GADAdLoader, you need to pass GADAdLoaderAdTypeGAMBanner (see
/// GADAdLoaderAdTypes.h) to the |adTypes| parameter in GADAdLoader's initializer method. If you
/// request this ad type, your delegate must conform to the GAMBannerAdLoaderDelegate protocol.
@interface GAMBannerView : GADBannerView

/// Required value created on the Ad Manager website. Create a new ad unit for every unique
/// placement of an ad in your application. Set this to the ID assigned for this placement. Ad units
/// are important for targeting and statistics.
///
/// Example Ad Manager ad unit ID: @"/6499/example/banner"
@property(nonatomic, copy, nullable) NSString *adUnitID;

/// Optional delegate that is notified when creatives send app events.
@property(nonatomic, weak, nullable) IBOutlet id<GADAppEventDelegate> appEventDelegate;

/// Optional delegate that is notified when creatives cause the banner to change size.
@property(nonatomic, weak, nullable) IBOutlet id<GADAdSizeDelegate> adSizeDelegate;

/// Optional array of NSValue encoded GADAdSize structs, specifying all valid sizes that are
/// appropriate for this slot. Never create your own GADAdSize directly. Use one of the predefined
/// standard ad sizes (such as GADAdSizeBanner), or create one using the GADAdSizeFromCGSize
/// method.
///
/// Example:
///
///   \code
///   NSArray *validSizes = @[
///     NSValueFromGADAdSize(GADAdSizeBanner),
///     NSValueFromGADAdSize(GADAdSizeLargeBanner)
///   ];
///
///   bannerView.validAdSizes = validSizes;
///   \endcode
@property(nonatomic, copy, nullable) NSArray<NSValue *> *validAdSizes;

/// Indicates that the publisher will record impressions manually when the ad becomes visible to the
/// user.
@property(nonatomic) BOOL enableManualImpressions;

/// Video controller for controlling video rendered by this ad view.
@property(nonatomic, readonly, nonnull) GADVideoController *videoController;

/// If you've set enableManualImpressions to YES, call this method when the ad is visible.
- (void)recordImpression;

/// Use this function to resize the banner view without launching a new ad request.
- (void)resize:(GADAdSize)size;

/// Sets options that configure ad loading.
///
/// @param adOptions An array of GADAdLoaderOptions objects. The array is deep copied and option
/// objects cannot be modified after calling this method.
- (void)setAdOptions:(nonnull NSArray<GADAdLoaderOptions *> *)adOptions;

@end
