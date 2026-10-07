//
//  GADInterstitialAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <GoogleMobileAds/GADAdValue.h>
#import <GoogleMobileAds/GADFullScreenContentDelegate.h>
#import <GoogleMobileAds/GADRequest.h>
#import <GoogleMobileAds/GADResponseInfo.h>
#import <GoogleMobileAds/GADServerSideVerificationOptions.h>

@class GADInterstitialAd;

/// A block to be executed when the ad request operation completes. On success,
/// interstitialAd is non-nil and |error| is nil. On failure, interstitialAd is nil
/// and |error| is non-nil.
typedef void (^GADInterstitialAdLoadCompletionHandler)(GADInterstitialAd *_Nullable interstitialAd,
                                                       NSError *_Nullable error);

/// An interstitial ad. This is a full-screen advertisement shown at natural transition points in
/// your application such as between game levels or news stories. See
/// https://developers.google.com/admob/ios/interstitial to get started.
@interface GADInterstitialAd : NSObject <GADFullScreenPresentingAd>

/// The ad unit ID.
@property(nonatomic, readonly, nonnull) NSString *adUnitID;

/// Information about the ad response that returned the ad.
@property(nonatomic, readonly, nonnull) GADResponseInfo *responseInfo;

/// Delegate for handling full screen content messages.
@property(nonatomic, weak, nullable) id<GADFullScreenContentDelegate> fullScreenContentDelegate;

/// Called when the ad is estimated to have earned money. Available for allowlisted accounts only.
@property(nonatomic, nullable, copy) GADPaidEventHandler paidEventHandler;

/// Loads an interstitial ad.
///
/// @param adUnitID An ad unit ID created in the AdMob or Ad Manager UI.
/// @param request An ad request object. If nil, a default ad request object is used.
/// @param completionHandler A handler to execute when the load operation finishes or times out.
+ (void)loadWithAdUnitID:(nonnull NSString *)adUnitID
                 request:(nullable GADRequest *)request
       completionHandler:(nonnull GADInterstitialAdLoadCompletionHandler)completionHandler;

/// Loads an interstitial ad.
///
/// @param adResponseString A server-to-server ad response string.
/// @param completionHandler A handler to execute when the load operation finishes or times out.
+ (void)loadWithAdResponseString:(nonnull NSString *)adResponseString
               completionHandler:(nonnull GADInterstitialAdLoadCompletionHandler)completionHandler;

/// Indicates whether the interstitial ad can be presented from the provided root view controller.
/// Must be called on the main thread.
///
/// - Parameters:
///   - rootViewController: The root view controller to present the ad from. If `rootViewController`
/// is `nil`, uses the top view controller of the application's main window.
///   - error: Sets the error out parameter if the ad can't be presented.
/// - Returns: `YES` if the interstitial ad can be presented from the provided root view controller,
/// `NO` otherwise.
- (BOOL)canPresentFromRootViewController:(nullable UIViewController *)rootViewController
                                   error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/// Presents the interstitial ad. Must be called on the main thread.
///
/// @param rootViewController A view controller to present the ad. If nil, attempts to present from
/// the top view controller of the application's main window.
- (void)presentFromRootViewController:(nullable UIViewController *)rootViewController;

@end
