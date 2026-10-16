//
//  GAMInterstitialAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2020 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAppEventDelegate.h>
#import <GoogleMobileAds/GADInterstitialAd.h>
#import <GoogleMobileAds/GAMRequest.h>

@class GAMInterstitialAd;
typedef void (^GAMInterstitialAdLoadCompletionHandler)(GAMInterstitialAd *_Nullable interstitialAd,
                                                       NSError *_Nullable error);

/// Google Ad Manager interstitial ad, a full-screen advertisement shown at natural
/// transition points in your application such as between game levels or news stories.
@interface GAMInterstitialAd : GADInterstitialAd

/// Optional delegate that is notified when creatives send app events.
@property(nonatomic, weak, nullable) id<GADAppEventDelegate> appEventDelegate;

/// Loads an interstitial ad.
///
/// @param adUnitID An ad unit ID created in the Ad Manager UI.
/// @param request An ad request object. If nil, a default ad request object is used.
/// @param completionHandler A handler to execute when the load operation finishes or times out.
+ (void)loadWithAdManagerAdUnitID:(nonnull NSString *)adUnitID
                          request:(nullable GAMRequest *)request
                completionHandler:(nonnull GAMInterstitialAdLoadCompletionHandler)completionHandler;

+ (void)loadWithAdUnitID:(nonnull NSString *)adUnitID
                 request:(nullable GADRequest *)request
       completionHandler:(nonnull GADInterstitialAdLoadCompletionHandler)completionHandler
    NS_UNAVAILABLE;

@end
