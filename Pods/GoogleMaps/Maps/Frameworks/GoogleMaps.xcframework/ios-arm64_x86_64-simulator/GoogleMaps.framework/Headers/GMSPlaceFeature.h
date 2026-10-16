//
//  GMSPlaceFeature.h
//  Google Maps SDK for iOS
//
//  Copyright 2022 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>


#import "GMSFeature.h"

NS_ASSUME_NONNULL_BEGIN

/** An interface representing a place feature (a feature with a Place ID). */
NS_SWIFT_NAME(PlaceFeature)
@interface GMSPlaceFeature : NSObject <GMSFeature>

@property(nonatomic, readonly) GMSFeatureType featureType;

@property(nonatomic, readonly) NSString *placeID;

/**
 * Create a feature layer instance for testing.
 *
 * This method should be used for your unit tests only. In production, @c GMSPlaceFeature instances
 * should only be created by the SDK.
 */
- (instancetype)initWithFeatureType:(GMSFeatureType)featureType placeID:(NSString *)placeID;

- (instancetype)init NS_DESIGNATED_INITIALIZER NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
