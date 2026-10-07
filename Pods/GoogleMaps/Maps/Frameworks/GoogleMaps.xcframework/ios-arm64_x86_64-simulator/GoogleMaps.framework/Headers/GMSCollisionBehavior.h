//
//  GMSCollisionBehavior.h
//  Google Maps SDK for iOS
//
//  Copyright 2023 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup CollisionBehavior GMSCollisionBehavior
 * @{
 */

/**
 * How markers interact with other markers and regular labels. Defaults to
 * @c GMSCollisionBehaviorRequired.
 *
 * Marker collisions occur when coordinates intersect.
 *
 * Priority is defined as:
 * 1) Required > Optional
 * 2) zIndex: higher zIndex > lower zIndex
 *
 * Beyond this, it is undefined which marker will show if both are optional and have the same
 * zIndex.
 * Regular map labels are the lowest priority.
 */
typedef NS_ENUM(NSInteger, GMSCollisionBehavior) {
  /**
   * Always display the marker regardless of collision. This is the default behavior.
   * Has no impact on whether any other markers or basemap labels show.
   */
  GMSCollisionBehaviorRequired,

  /**
   * Always display the marker regardless of collision, and hide any
   * CollisionBehaviorOptionalAndHidesLowerPriority markers or labels that would overlap with the
   * marker.
   */
  GMSCollisionBehaviorRequiredAndHidesOptional,

  /**
   * Display the marker only if it does not overlap with other markers. Does not include
   * GMSCollisionBehaviorRequired. If two markers of this type would overlap, the one with the
   * higher zIndex is shown. Collision rules for markers with the same zIndex is undefined.
   */
  GMSCollisionBehaviorOptionalAndHidesLowerPriority,
};

/**@}*/

NS_ASSUME_NONNULL_END
