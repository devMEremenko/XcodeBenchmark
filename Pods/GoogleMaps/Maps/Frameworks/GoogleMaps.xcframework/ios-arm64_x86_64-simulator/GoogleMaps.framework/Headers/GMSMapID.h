//
//  GMSMapID.h
//  Google Maps SDK for iOS
//
//  Copyright 2019 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/** An opaque identifier for a custom map configuration. */
@interface GMSMapID : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/** Creates a new mapID with the given string value. */
- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

/** Creates a new mapID with the given string value. */
+ (instancetype)mapIDWithIdentifier:(NSString *)identifier
    NS_SWIFT_UNAVAILABLE("Use initializer instead");

/**
 * Returns the DEMO_MAP_ID, which can be used for code samples which require a map ID. This map ID
 * is not intended for use in production applications and cannot be used for features which require
 * cloud configuration (such as Cloud Styling).
 *
 * @note Usage of DEMO_MAP_ID triggers a map load charge against the Dynamic Maps SKU for Android
 * and iOS. For more Information see Google Maps Billing:
 * https://developers.google.com/maps/billing-and-pricing/pricing#dynamic-maps
 */
@property(nonatomic, class, readonly) GMSMapID *demoMapID NS_SWIFT_NAME(demoMapID);

@end

NS_ASSUME_NONNULL_END
