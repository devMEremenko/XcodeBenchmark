//
//  GMSMarkerAnimation.h
//  Google Maps SDK for iOS
//
//  Copyright 2021 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup MarkerAnimation GMSMarkerAnimation
 * @{
 */

/** Animation types for GMSMarker. */
typedef NS_ENUM(NSUInteger, GMSMarkerAnimation) {
  /** No animation (default). */
  kGMSMarkerAnimationNone = 0,

  /** The marker will pop from its groundAnchor when added. */
  kGMSMarkerAnimationPop,

  /** The marker will fade in when added. */
  kGMSMarkerAnimationFadeIn,
};

/**@}*/

NS_ASSUME_NONNULL_END
