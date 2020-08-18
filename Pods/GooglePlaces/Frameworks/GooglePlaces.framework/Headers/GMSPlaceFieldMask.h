//
//  GMSPlaceFieldMask.h
//  Google Places SDK for iOS
//
//  Copyright 2018 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup PlaceField GMSPlaceField
 * @{
 */

/**
 * The fields represent individual information that can be requested for a |GMSPlace| object.
 * If no request fields are set, the |GMSPlace| object will be empty with no useful information.
 *
 * Note: GMSPlaceFieldPhoneNumber, GMSPlaceFieldWebsite and GMSPlaceFieldAddressComponents are not
 *       supported for |GMSPlaceLikelihoodList| place objects. Please refer to
 *       https://developers.google.com/places/ios-sdk/place-data-fields for more details.
 */
typedef NS_ENUM(NSUInteger, GMSPlaceField) {
  GMSPlaceFieldName = 1 << 0,
  GMSPlaceFieldPlaceID = 1 << 1,
  GMSPlaceFieldPlusCode = 1 << 2,
  GMSPlaceFieldCoordinate = 1 << 3,
  GMSPlaceFieldOpeningHours = 1 << 4,
  GMSPlaceFieldPhoneNumber = 1 << 5,
  GMSPlaceFieldFormattedAddress = 1 << 6,
  GMSPlaceFieldRating = 1 << 7,
  GMSPlaceFieldPriceLevel = 1 << 8,
  GMSPlaceFieldTypes = 1 << 9,
  GMSPlaceFieldWebsite = 1 << 10,
  GMSPlaceFieldViewport = 1 << 11,
  GMSPlaceFieldAddressComponents = 1 << 12,
  GMSPlaceFieldPhotos = 1 << 13,
  GMSPlaceFieldUserRatingsTotal = 1 << 14,
  GMSPlaceFieldUTCOffsetMinutes = 1 << 15,
  GMSPlaceFieldBusinessStatus = 1 << 16,
  GMSPlaceFieldAll = NSUIntegerMax,
};

/**@}*/

NS_ASSUME_NONNULL_END
