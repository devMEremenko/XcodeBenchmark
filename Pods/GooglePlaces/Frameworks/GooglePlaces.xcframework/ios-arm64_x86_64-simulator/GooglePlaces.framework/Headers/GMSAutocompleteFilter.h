//
//  GMSAutocompleteFilter.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "GMSPlacesDeprecationUtils.h"

@protocol GMSPlaceLocationBias;
@protocol GMSPlaceLocationRestriction;

NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup PlacesAutocompleteTypeFilter GMSPlacesAutocompleteTypeFilter
 * @{
 */

/**
 * The type filters that may be applied to an autocomplete request to restrict results to different
 * types.
 */
typedef NS_ENUM(NSInteger, GMSPlacesAutocompleteTypeFilter) {
  /** All results. */
  kGMSPlacesAutocompleteTypeFilterNoFilter,

  /** Geocoding results, as opposed to business results. */
  kGMSPlacesAutocompleteTypeFilterGeocode,

  /** Geocoding results with a precise address. */
  kGMSPlacesAutocompleteTypeFilterAddress,

  /** Business results. */
  kGMSPlacesAutocompleteTypeFilterEstablishment,

  /**
   * Results that match the following types:
   * "locality",
   * "sublocality"
   * "postal_code",
   * "country",
   * "administrative_area_level_1",
   * "administrative_area_level_2"
   */
  kGMSPlacesAutocompleteTypeFilterRegion,

  /**
   * Results that match the following types:
   * "locality",
   * "administrative_area_level_3"
   */
  kGMSPlacesAutocompleteTypeFilterCity,
};

/**@}*/

/**
 * This class represents a set of restrictions that may be applied to autocomplete requests. This
 * allows customization of autocomplete suggestions to only those places that are of interest.
 */
@interface GMSAutocompleteFilter : NSObject

/**
 * DEPRECATED. The type filter applied to an autocomplete request to restrict results to different
 * types. Default value is kGMSPlacesAutocompleteTypeFilterNoFilter.
 *
 * NOTE: Ignored if the "types" property is set.
 */
@property(nonatomic, assign)
    GMSPlacesAutocompleteTypeFilter type __GMS_AVAILABLE_BUT_DEPRECATED_MSG(
        "<code>type</code> property is deprecated in favor of <code>types</code>.");

/**
 * The filter applied to an autocomplete request to restrict results using up to 5 different place
 * types.
 *
 * NOTE: This API can take an array of up to 5 entries from <a
 * href="https://developers.google.com/maps/documentation/places/ios-sdk/supported_types#table1">table_1</a>
 * or <a
 * href="https://developers.google.com/maps/documentation/places/ios-sdk/supported_types#table2">table_2</a>,
 * but only a single entry in <a
 * href="https://developers.google.com/maps/documentation/places/ios-sdk/supported_types#table3">table_3</a>.
 * Default value is null, which means no filters specified. Overrides the deprecated "type" property
 * if this is set.
 */
@property(nonatomic, nullable) NSArray<NSString *> *types;

/**
 * DEPRECATED. The country to restrict results to. This should be a ISO 3166-1 Alpha-2 country code
 * (case insensitive). If nil, no country filtering will take place.
 *
 * NOTE: Ignored if the "countries" property is set.
 */
@property(nonatomic, copy, nullable) NSString *country __GMS_AVAILABLE_BUT_DEPRECATED_MSG(
    "<code>country</code> property is deprecated in favor of <code>countries</code>.");

/**
 * The countries to restrict results to. This should be a ISO 3166-1 Alpha-2 country code (case
 * insensitive). Supports up to 5 countries to filter. If nil, no country filtering will take place.
 *
 * NOTE: Overrides the deprecated "country" property if that is set.
 */
@property(nonatomic, copy, nullable) NSArray<NSString *> *countries;

/**
 * The straight line distance origin location for measuring the straight line distance between the
 * origin location and autocomplete predictions.
 */
@property(nonatomic, nullable) CLLocation *origin;

/** The optional location bias to prefer place results near the location. */
@property(nonatomic, nullable) id<GMSPlaceLocationBias> locationBias;

/** The optional location restriction to limit the place results to. */
@property(nonatomic, nullable) id<GMSPlaceLocationRestriction> locationRestriction;

@end

NS_ASSUME_NONNULL_END
