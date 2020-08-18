//
//  GMSAddressComponent.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

#import <Foundation/Foundation.h>

#import "GMSPlacesDeprecationUtils.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a component of an address, e.g., street number, postcode, city, etc.
 */
@interface GMSAddressComponent : NSObject

/**
 * Type of the address component. For a list of supported types, see
 * https://developers.google.com/places/ios-sdk/supported_types#table2. This string will be one
 * of the constants defined in GMSPlaceTypes.h.
 */
@property(nonatomic, readonly, copy) NSString *type __GMS_PLACES_AVAILABLE_BUT_DEPRECATED_MSG(
    "type property is deprecated in favor of types");

/**
 * Types associated with the address component. For a list of supported types, see
 * https://developers.google.com/places/ios-sdk/supported_types#table2. This array will contain
 * one or more of the constants strings defined in GMSPlaceTypes.h.
 */
@property(nonatomic, readonly, strong) NSArray<NSString *> *types;

/** Name of the address component, e.g. "Sydney" */
@property(nonatomic, readonly, copy) NSString *name;

/** Short name of the address component, e.g. "AU" */
@property(nonatomic, readonly, copy) NSString *_Nullable shortName;

@end

NS_ASSUME_NONNULL_END
