//
//  GMSPlaceFieldMask.h
//  Google Places SDK for iOS
//
//  Copyright 2018 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup GMSPlaceField GMSPlaceField
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
typedef NS_OPTIONS(uint64_t, GMSPlaceField) {
  GMSPlaceFieldName = 1 << 0,
  GMSPlaceFieldPlaceID = GMSPlaceFieldName << 1,
  GMSPlaceFieldPlusCode = GMSPlaceFieldName << 2,
  GMSPlaceFieldCoordinate = GMSPlaceFieldName << 3,
  GMSPlaceFieldOpeningHours = GMSPlaceFieldName << 4,
  GMSPlaceFieldPhoneNumber = GMSPlaceFieldName << 5,
  GMSPlaceFieldFormattedAddress = GMSPlaceFieldName << 6,
  GMSPlaceFieldRating = GMSPlaceFieldName << 7,
  GMSPlaceFieldPriceLevel = GMSPlaceFieldName << 8,
  GMSPlaceFieldTypes = GMSPlaceFieldName << 9,
  GMSPlaceFieldWebsite = GMSPlaceFieldName << 10,
  GMSPlaceFieldViewport = GMSPlaceFieldName << 11,
  GMSPlaceFieldAddressComponents = GMSPlaceFieldName << 12,
  GMSPlaceFieldPhotos = GMSPlaceFieldName << 13,
  GMSPlaceFieldUserRatingsTotal = GMSPlaceFieldName << 14,
  GMSPlaceFieldUTCOffsetMinutes = GMSPlaceFieldName << 15,
  GMSPlaceFieldBusinessStatus = GMSPlaceFieldName << 16,
  GMSPlaceFieldIconImageURL = GMSPlaceFieldName << 17,
  GMSPlaceFieldIconBackgroundColor = GMSPlaceFieldName << 18,
  GMSPlaceFieldTakeout = GMSPlaceFieldName << 19,
  GMSPlaceFieldDelivery = GMSPlaceFieldName << 20,
  GMSPlaceFieldDineIn = GMSPlaceFieldName << 21,
  GMSPlaceFieldCurbsidePickup = GMSPlaceFieldName << 22,
  GMSPlaceFieldReservable = GMSPlaceFieldName << 23,
  GMSPlaceFieldServesBreakfast = GMSPlaceFieldName << 24,
  GMSPlaceFieldServesLunch = GMSPlaceFieldName << 25,
  GMSPlaceFieldServesDinner = GMSPlaceFieldName << 26,
  GMSPlaceFieldServesBeer = GMSPlaceFieldName << 27,
  GMSPlaceFieldServesWine = GMSPlaceFieldName << 28,
  GMSPlaceFieldServesBrunch = GMSPlaceFieldName << 29,
  GMSPlaceFieldServesVegetarianFood = GMSPlaceFieldName << 30,
  GMSPlaceFieldWheelchairAccessibleEntrance = GMSPlaceFieldName
                                              << 31,
  GMSPlaceFieldCurrentOpeningHours = GMSPlaceFieldName << 32,
  GMSPlaceFieldSecondaryOpeningHours = GMSPlaceFieldName << 33,
  GMSPlaceFieldEditorialSummary = GMSPlaceFieldName << 34,
  GMSPlaceFieldAll = UINT64_MAX,
};

/**@}*/

NS_ASSUME_NONNULL_END
