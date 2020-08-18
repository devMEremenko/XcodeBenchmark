//
//  GMSAutocompleteBoundsMode.h
//  Google Places SDK for iOS
//
//  Copyright 2017 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

/**
 * \defgroup AutocompleteBoundsMode GMSAutocompleteBoundsMode
 * @{
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Specifies how autocomplete should interpret the |bounds| parameters.
 */
typedef NS_ENUM(NSUInteger, GMSAutocompleteBoundsMode) {
  /** Interpret |bounds| as a bias. */
  kGMSAutocompleteBoundsModeBias,
  /** Interpret |bounds| as a restrict. */
  kGMSAutocompleteBoundsModeRestrict
};

NS_ASSUME_NONNULL_END

/**@}*/
