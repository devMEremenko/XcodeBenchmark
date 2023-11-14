//
//  GADCustomNativeAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADAdLoaderDelegate.h>
#import <GoogleMobileAds/GADDisplayAdMeasurement.h>
#import <GoogleMobileAds/GADMediaView.h>
#import <GoogleMobileAds/GADNativeAdImage.h>
#import <GoogleMobileAds/GADResponseInfo.h>
#import <GoogleMobileAds/GADVideoController.h>
#import <UIKit/UIKit.h>

/// Native ad custom click handler block. |assetID| is the ID of asset that has received a click.
typedef void (^GADNativeAdCustomClickHandler)(NSString *_Nonnull assetID);

/// Asset key for the GADMediaView asset view.
FOUNDATION_EXPORT NSString *_Nonnull const GADCustomNativeAdMediaViewKey;

@protocol GADCustomNativeAdDelegate;

/// Custom native ad. To request this ad type, you need to pass
/// GADAdLoaderAdTypeCustomNative (see GADAdLoaderAdTypes.h) to the |adTypes| parameter
/// in GADAdLoader's initializer method. If you request this ad type, your delegate must conform to
/// the GADCustomNativeAdLoaderDelegate protocol.
@interface GADCustomNativeAd : NSObject

/// The ad's format ID.
@property(nonatomic, readonly, nonnull) NSString *formatID;

/// Array of available asset keys.
@property(nonatomic, readonly, nonnull) NSArray<NSString *> *availableAssetKeys;

/// Custom click handler. Set this property only if this ad is configured with a custom click
/// action, otherwise set it to nil. If this property is set to a non-nil value, the ad's built-in
/// click actions are ignored and |customClickHandler| is executed when a click on the asset is
/// received.
@property(atomic, copy, nullable) GADNativeAdCustomClickHandler customClickHandler;

/// The display ad measurement associated with this ad.
@property(nonatomic, readonly, nullable) GADDisplayAdMeasurement *displayAdMeasurement;

/// Media content.
@property(nonatomic, readonly, nonnull) GADMediaContent *mediaContent;

/// Optional delegate to receive state change notifications.
@property(nonatomic, weak, nullable) id<GADCustomNativeAdDelegate> delegate;

/// Reference to a root view controller that is used by the ad to present full screen content after
/// the user interacts with the ad. The root view controller is most commonly the view controller
/// displaying the ad.
@property(nonatomic, weak, nullable) UIViewController *rootViewController;

/// Information about the ad response that returned the ad.
@property(nonatomic, readonly, nonnull) GADResponseInfo *responseInfo;

/// Returns the native ad image corresponding to the specified key or nil if the image is not
/// available.
- (nullable GADNativeAdImage *)imageForKey:(nonnull NSString *)key;

/// Returns the string corresponding to the specified key or nil if the string is not available.
- (nullable NSString *)stringForKey:(nonnull NSString *)key;

/// Call when the user clicks on the ad. Provide the asset key that best matches the asset the user
/// interacted with. If this ad is configured with a custom click action, ensure the receiver's
/// customClickHandler property is set before calling this method.
- (void)performClickOnAssetWithKey:(nonnull NSString *)assetKey;

/// Call when the ad is displayed on screen to the user. Can be called multiple times. Only the
/// first impression is recorded.
- (void)recordImpression;

@end

#pragma mark - Loading Protocol

/// The delegate of a GADAdLoader object implements this protocol to receive
/// GADCustomNativeAd ads.
@protocol GADCustomNativeAdLoaderDelegate <GADAdLoaderDelegate>

/// Called when requesting an ad. Asks the delegate for an array of custom native ad format ID
/// strings.
- (nonnull NSArray<NSString *> *)customNativeAdFormatIDsForAdLoader:(nonnull GADAdLoader *)adLoader;

/// Tells the delegate that a custom native ad was received.
- (void)adLoader:(nonnull GADAdLoader *)adLoader
    didReceiveCustomNativeAd:(nonnull GADCustomNativeAd *)customNativeAd;

@end
