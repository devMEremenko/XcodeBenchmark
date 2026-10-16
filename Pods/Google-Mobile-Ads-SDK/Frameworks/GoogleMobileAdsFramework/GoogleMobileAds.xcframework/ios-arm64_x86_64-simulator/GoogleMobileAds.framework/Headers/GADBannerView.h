//
//  GADBannerView.h
//  Google Mobile Ads SDK
//
//  Copyright 2011 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdSize.h>
#import <GoogleMobileAds/GADAdSizeDelegate.h>
#import <GoogleMobileAds/GADAdValue.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADRequest.h>
#import <GoogleMobileAds/GADResponseInfo.h>
#import <UIKit/UIKit.h>

/// A view that displays banner ads. See https://developers.google.com/admob/ios/banner to get
/// started.
@interface GADBannerView : UIView

#pragma mark Initialization

/// Initializes and returns a banner view with the specified ad size and origin relative to the
/// banner's superview.
- (nonnull instancetype)initWithAdSize:(GADAdSize)adSize origin:(CGPoint)origin;

/// Initializes and returns a banner view with the specified ad size placed at its superview's
/// origin.
- (nonnull instancetype)initWithAdSize:(GADAdSize)adSize;

#pragma mark Pre-Request

/// Required value created on the AdMob website. Create a new ad unit for every unique placement of
/// an ad in your application. Set this to the ID assigned for this placement. Ad units are
/// important for targeting and statistics.
///
/// Example AdMob ad unit ID: @"ca-app-pub-0123456789012345/0123456789"
@property(nonatomic, copy, nullable) IBInspectable NSString *adUnitID;

/// Reference to a root view controller that is used by the banner to present full screen
/// content after the user interacts with the ad. If this is nil, the view controller containing the
/// banner view is used.
@property(nonatomic, weak, nullable) IBOutlet UIViewController *rootViewController;

/// Required to set this banner view to a proper size. Never create your own GADAdSize directly.
/// Use one of the predefined standard ad sizes (such as GADAdSizeBanner), or create one using the
/// GADAdSizeFromCGSize method. If not using mediation, then changing the adSize after an ad has
/// been shown will cause a new request (for an ad of the new size) to be sent. If using mediation,
/// then a new request may not be sent.
@property(nonatomic, assign) GADAdSize adSize;

/// Optional delegate object that receives state change notifications from this GADBannerView.
/// Typically this is a UIViewController.
@property(nonatomic, weak, nullable) IBOutlet id<GADBannerViewDelegate> delegate;

/// Optional delegate that is notified when creatives cause the banner to change size.
@property(nonatomic, weak, nullable) IBOutlet id<GADAdSizeDelegate> adSizeDelegate;

#pragma mark Making an Ad Request

/// Requests an ad. The request object supplies targeting information.
- (void)loadRequest:(nullable GADRequest *)request;

/// Loads the ad and informs |delegate| of the outcome.
- (void)loadWithAdResponseString:(nonnull NSString *)adResponseString;

/// A Boolean value that determines whether autoloading of ads in the receiver is enabled. If
/// enabled, you do not need to call the loadRequest: method to load ads.
@property(nonatomic, assign, getter=isAutoloadEnabled) IBInspectable BOOL autoloadEnabled;

#pragma mark Response

/// Information about the ad response that returned the current ad or an error. Nil until the first
/// ad request succeeds or fails.
@property(nonatomic, readonly, nullable) GADResponseInfo *responseInfo;

/// Called when ad is estimated to have earned money. Available for allowlisted accounts only.
@property(nonatomic, nullable, copy) GADPaidEventHandler paidEventHandler;

/// Indicates whether the last loaded ad is a collapsible banner.
@property(nonatomic, readonly) BOOL isCollapsible;

@end
