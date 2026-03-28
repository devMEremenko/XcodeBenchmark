//
//  GMSAdvancedMarker.h
//  Google Maps SDK for iOS
//
//  Copyright 2023 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import "GMSCollisionBehavior.h"
#import "GMSMarker.h"

NS_ASSUME_NONNULL_BEGIN

@interface GMSAdvancedMarker : GMSMarker

/**
 * The marker's collision behavior, which determines whether or not the marker's visibility can be
 * affected by other markers or labeled content on the map.
 */
@property(nonatomic) GMSCollisionBehavior collisionBehavior;

@end

NS_ASSUME_NONNULL_END
