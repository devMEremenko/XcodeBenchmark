//
//  GADMediationAdRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GoogleMobileAds/GADAdNetworkExtras.h>
#import <GoogleMobileAds/GADRequest.h>
#import <GoogleMobileAds/GADRequestConfiguration.h>
#import <GoogleMobileAds/Mediation/GADMEnums.h>

/// Provides information which can be used for making ad requests during mediation.
@protocol GADMediationAdRequest <NSObject>

/// Publisher ID set by the publisher on the AdMob frontend.
- (nullable NSString *)publisherId;

/// Mediation configurations set by the publisher on the AdMob frontend.
- (nullable NSDictionary *)credentials;

/// Returns YES if the publisher is requesting test ads.
- (BOOL)testMode;

/// The adapter's ad network extras specified in GADRequest.
- (nullable id<GADAdNetworkExtras>)networkExtras;

/// Returns the value of childDirectedTreatment supplied by the publisher. Returns nil if the
/// publisher hasn't specified child directed treatment. Returns @YES if child directed treatment is
/// enabled.
- (nullable NSNumber *)childDirectedTreatment;

/// Returns the maximum ad content rating supplied by the publisher. Returns nil if the publisher
/// hasn't specified a max ad content rating.
- (nullable GADMaxAdContentRating)maxAdContentRating;

/// Returns the value of underAgeOfConsent supplied by the publisher. Returns nil if the publisher
/// hasn't specified the user is under the age of consent. Returns @YES if the user is under the age
/// of consent.
- (nullable NSNumber *)underAgeOfConsent;

/// Keywords describing the user's current activity. Example: @"Sport Scores".
- (nullable NSArray *)userKeywords;

@end
