//
//  GADNativeAdUnconfirmedClickDelegate.h
//  Google Mobile Ads SDK
//
//  Copyright 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADNativeAdAssetIdentifiers.h>

@class GADNativeAd;

/// Delegate methods for handling native ad unconfirmed clicks.
@protocol GADNativeAdUnconfirmedClickDelegate <NSObject>

/// Tells the delegate that native ad receives an unconfirmed click on view with asset ID. You
/// should update user interface and ask user to confirm the click once this message is received.
/// Use the -registerClickConfirmingView: method in GADNativeAd+ConfirmedClick.h to register
/// a view that will confirm the click. Only called for Google ads and is not supported for mediated
/// ads.
- (void)nativeAd:(nonnull GADNativeAd *)nativeAd
    didReceiveUnconfirmedClickOnAssetID:(nonnull GADNativeAssetIdentifier)assetID;

/// Tells the delegate that the unconfirmed click is cancelled. You should revert the user interface
/// change once this message is received. Only called for Google ads and is not supported for
/// mediated ads.
- (void)nativeAdDidCancelUnconfirmedClick:(nonnull GADNativeAd *)nativeAd;

@end
