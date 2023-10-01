//
//  GADResponseInfo.h
//  Google Mobile Ads SDK
//
//  Copyright 2019-2021 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

/// Response metadata for an individual ad network in an ad response.
@interface GADAdNetworkResponseInfo : NSObject

/// A class name that identifies the ad network.
@property(nonatomic, readonly, nonnull) NSString *adNetworkClassName;

/// Network configuration set on the AdMob UI.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *adUnitMapping;

/// The ad source name associated with this ad network response. Nil if the ad server does not
/// populate this field.
@property(nonatomic, readonly, nullable) NSString *adSourceName;

/// The ad source ID associated with this ad network response. Nil if the ad server does not
/// populate this field.
@property(nonatomic, readonly, nullable) NSString *adSourceID;

/// The ad source instance name associated with this ad network response. Nil if the ad server does
/// not populate this field.
@property(nonatomic, readonly, nullable) NSString *adSourceInstanceName;

/// The ad source instance ID associated with this ad network response. Nil if the ad server does
/// not populate this field.
@property(nonatomic, readonly, nullable) NSString *adSourceInstanceID;

/// Error associated with the request to the network. Nil if the network successfully loaded an ad
/// or if the network was not attempted.
@property(nonatomic, readonly, nullable) NSError *error;

/// Amount of time the ad network spent loading an ad. 0 if the network was not attempted.
@property(nonatomic, readonly) NSTimeInterval latency;

/// JSON-safe dictionary representation of the ad network response info.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *dictionaryRepresentation;

@end

/// Ad network class name for ads returned from Google's ad network.
FOUNDATION_EXPORT NSString *_Nonnull const GADGoogleAdNetworkClassName;

/// Ad network class name for custom event ads.
FOUNDATION_EXPORT NSString *_Nonnull const GADCustomEventAdNetworkClassName;

/// Key into NSError.userInfo mapping to a GADResponseInfo object. When ads fail to load, errors
/// returned contain an instance of GADResponseInfo.
FOUNDATION_EXPORT NSString *_Nonnull GADErrorUserInfoKeyResponseInfo;

/// Information about a response to an ad request.
@interface GADResponseInfo : NSObject

/// Unique identifier of the ad response.
@property(nonatomic, readonly, nullable) NSString *responseIdentifier;

/// Dictionary of extra parameters that may be returned in an ad response.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *extrasDictionary;

/// The GADAdNetworkResponseInfo corresponding to the adapter that was used to load the ad. Nil if
/// the ad failed to load.
@property(nonatomic, readonly, nullable) GADAdNetworkResponseInfo *loadedAdNetworkResponseInfo;

/// Array of metadata for each ad network included in the response.
@property(nonatomic, readonly, nonnull) NSArray<GADAdNetworkResponseInfo *> *adNetworkInfoArray;

/// JSON-safe dictionary representation of the response info.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *dictionaryRepresentation;

#pragma mark - Deprecated

/// Deprecated. Use loadedAdNetworkResponseInfo.adNetworkClassName instead.
@property(nonatomic, readonly, nullable) NSString *adNetworkClassName GAD_DEPRECATED_MSG_ATTRIBUTE(
    "Deprecated. Use loadedAdNetworkResponseInfo.adNetworkClassName instead.");

@end
