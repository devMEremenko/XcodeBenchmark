//
//  GMSAccessibilityLabels.h
//  Google Maps SDK for iOS
//
//  Copyright 2022 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

/**
 * A previous version of this API contained this misspelling, this preserves compatibility with old
 * versions. Use kGMSAccessibilityOutOfQuota instead.
 */
#define kGMSAccessiblityOutOfQuota kGMSAccessibilityOutOfQuota;

/**
 * Accessibility identifier for the compass button.
 *
 * @related GMSMapView
 */
extern NSString *const kGMSAccessibilityCompass;

/**
 * Accessibility identifier for the "my location" button.
 *
 * @related GMSMapView
 */
extern NSString *const kGMSAccessibilityMyLocation;

/**
 * Accessibility identifier for the "out of quota" error label.
 *
 * @related GMSMapView
 */
extern NSString *const kGMSAccessibilityOutOfQuota;
