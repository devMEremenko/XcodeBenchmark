//
//  GMSFeature.h
//  Google Maps SDK for iOS
//
//  Copyright 2022 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Identifiers for feature types of data-driven styling features. */
NS_SWIFT_NAME(FeatureType) typedef NSString *GMSFeatureType NS_TYPED_EXTENSIBLE_ENUM;

FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypeAdministrativeAreaLevel1;
FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypeAdministrativeAreaLevel2;
FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypeCountry;
FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypeLocality;
FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypePostalCode;
FOUNDATION_EXPORT GMSFeatureType const GMSFeatureTypeSchoolDistrict;

/**
 * An interface representing a feature's metadata.
 *
 * Do not save a reference to a particular feature object because the reference will not be stable.
 */
NS_SWIFT_NAME(Feature)
@protocol GMSFeature <NSObject>

/** Type of this feature. */
- (GMSFeatureType)featureType;

@end

NS_ASSUME_NONNULL_END
