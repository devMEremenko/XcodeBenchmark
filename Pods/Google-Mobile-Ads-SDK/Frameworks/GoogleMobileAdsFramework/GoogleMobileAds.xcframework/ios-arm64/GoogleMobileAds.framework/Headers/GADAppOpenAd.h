//
//  GADAppOpenAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2020 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdValue.h>
#import <GoogleMobileAds/GADFullScreenContentDelegate.h>
#import <GoogleMobileAds/GADRequest.h>
#import <GoogleMobileAds/GADResponseInfo.h>
#import <UIKit/UIKit.h>

#pragma mark - App Open Ad

@class GADAppOpenAd;

/// The handler block to execute when the ad load operation completes. On failure, the
/// appOpenAd is nil and the |error| is non-nil. On success, the appOpenAd is non-nil and the
/// |error| is nil.
typedef void (^GADAppOpenAdLoadCompletionHandler)(GADAppOpenAd *_Nullable appOpenAd,
                                                  NSError *_Nullable error);

/// An app open ad. Used to monetize app load screens.
@interface GADAppOpenAd : NSObject <GADFullScreenPresentingAd>

/// Loads an app open ad.
///
/// @param adUnitID An ad unit ID created in the AdMob or Ad Manager UI.
/// @param request An ad request object. If nil, a default ad request object is used.
/// @param completionHandler A handler to execute when the load operation finishes or times out.
+ (void)loadWithAdUnitID:(nonnull NSString *)adUnitID
                 request:(nullable GADRequest *)request
       completionHandler:(nonnull GADAppOpenAdLoadCompletionHandler)completionHandler;

/// Optional delegate object that receives notifications about presentation and dismissal of full
/// screen content from this ad. Full screen content covers your application's content. The delegate
/// may want to pause animations and time sensitive interactions. Set this delegate before
/// presenting the ad.
@property(nonatomic, weak, nullable) id<GADFullScreenContentDelegate> fullScreenContentDelegate;

/// Information about the ad response that returned the ad.
@property(nonatomic, readonly, nonnull) GADResponseInfo *responseInfo;

/// Called when the ad is estimated to have earned money. Available for allowlisted accounts only.
@property(nonatomic, nullable, copy) GADPaidEventHandler paidEventHandler;

/// Returns whether the app open ad can be presented from the provided root view controller. Sets
/// the error out parameter if the app open ad can't be presented. Must be called on the main
/// thread.
- (BOOL)canPresentFromRootViewController:(nonnull UIViewController *)rootViewController
                                   error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/// Presents the app open ad with the provided view controller. Must be called on the main thread.
- (void)presentFromRootViewController:(nonnull UIViewController *)rootViewController;

#pragma mark - Deprecated
/// Deprecated. Use +loadWithAdUnitID:request:completionHandler instead.
+ (void)loadWithAdUnitID:(nonnull NSString *)adUnitID
                 request:(nullable GADRequest *)request
             orientation:(UIInterfaceOrientation)orientation
       completionHandler:(nonnull GADAppOpenAdLoadCompletionHandler)completionHandler;

@end
