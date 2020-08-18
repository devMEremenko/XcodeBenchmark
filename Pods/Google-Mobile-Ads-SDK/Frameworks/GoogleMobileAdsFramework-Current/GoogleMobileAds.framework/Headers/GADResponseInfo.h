//
//  GADResponseInfo.h
//  Google Mobile Ads SDK
//
//  Copyright 2019-2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Response metadata for an individual ad network in an ad response.
@interface GADAdNetworkResponseInfo : NSObject

/// A class name that identifies the ad network.
@property(nonatomic, readonly, nonnull) NSString *adNetworkClassName;

/// Network configuration set on the AdMob UI.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *credentials;

/// Error associated with the request to the network. Nil if the network successfully loaded an ad
/// or if the network was not attempted.
@property(nonatomic, readonly, nullable) NSError *error;

/// Amount of time the ad network spent loading an ad. 0 if the network was not attempted.
@property(nonatomic, readonly) NSTimeInterval latency;

/// JSON-safe dictionary representation of the ad network response info.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *dictionaryRepresentation;

@end

/// Ad network class name for ads returned from Google's ad network.
extern NSString *_Nonnull const GADGoogleAdNetworkClassName;

/// Ad network class name for custom event ads.
extern NSString *_Nonnull const GADCustomEventAdNetworkClassName;

/// Key into NSError.userInfo mapping to a GADResponseInfo object. When ads fail to load, errors
/// returned contain an instance of GADResponseInfo.
extern NSString *_Nonnull GADErrorUserInfoKeyResponseInfo;

/// Information about a response to an ad request.
@interface GADResponseInfo : NSObject

/// Unique identifier of the ad response.
@property(nonatomic, readonly, nullable) NSString *responseIdentifier;

/// A class name that identifies the ad network that returned the ad. Nil if no ad was returned.
@property(nonatomic, readonly, nullable) NSString *adNetworkClassName;

/// Array of metadata for each ad network included in the response.
@property(nonatomic, readonly, nonnull) NSArray<GADAdNetworkResponseInfo *> *adNetworkInfoArray;

/// JSON-safe dictionary representation of the response info.
@property(nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *dictionaryRepresentation;

@end
