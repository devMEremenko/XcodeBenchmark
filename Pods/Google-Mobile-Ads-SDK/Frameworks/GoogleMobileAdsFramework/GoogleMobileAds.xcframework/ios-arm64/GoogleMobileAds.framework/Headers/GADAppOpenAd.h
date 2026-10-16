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

/// Loads an app open ad.
///
/// @param adResponseString A server-to-server ad response string.
/// @param completionHandler A handler to execute when the load operation finishes or times out.
+ (void)loadWithAdResponseString:(nonnull NSString *)adResponseString
               completionHandler:(nonnull GADAppOpenAdLoadCompletionHandler)completionHandler;

/// Optional delegate object that receives notifications about presentation and dismissal of full
/// screen content from this ad. Full screen content covers your application's content. The delegate
/// may want to pause animations and time sensitive interactions. Set this delegate before
/// presenting the ad.
@property(nonatomic, weak, nullable) id<GADFullScreenContentDelegate> fullScreenContentDelegate;

/// The ad unit ID.
@property(nonatomic, readonly, nonnull) NSString *adUnitID;

/// Information about the ad response that returned the ad.
@property(nonatomic, readonly, nonnull) GADResponseInfo *responseInfo;

/// Called when the ad is estimated to have earned money. Available for allowlisted accounts only.
@property(nonatomic, nullable, copy) GADPaidEventHandler paidEventHandler;

/// Indicates whether the app open ad can be presented from the provided root view controller. Must
/// be called on the main thread.
///
/// - Parameters:
///   - rootViewController: The root view controller to present the ad from. If `rootViewController`
/// is `nil`, uses the top view controller of the application's main window.
///   - error: Sets the error out parameter if the ad can't be presented.
/// - Returns: `YES` if the app open ad can be presented from the provided root view controller,
/// `NO` otherwise.
- (BOOL)canPresentFromRootViewController:(nullable UIViewController *)rootViewController
                                   error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/// Presents the app open ad with the provided view controller. Must be called on the main thread.
/// If rootViewController is nil, attempts to present from the top view controller of the
/// application's main window.
- (void)presentFromRootViewController:(nullable UIViewController *)rootViewController;

@end
