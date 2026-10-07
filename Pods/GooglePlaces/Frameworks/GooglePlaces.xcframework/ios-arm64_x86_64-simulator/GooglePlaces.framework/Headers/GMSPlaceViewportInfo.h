//
//  GMSPlaceViewportInfo.h
//  Google Places SDK for iOS
//
//  Copyright 2020 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <CoreLocation/CoreLocation.h>

/**
 * GMSPlaceViewportInfo represents a rectangular bounding box on the Earth's surface.
 * GMSPlaceViewportInfo is immutable and can't be modified after construction.
 */
@interface GMSPlaceViewportInfo : NSObject

/** The North-East corner of these bounds. */
@property(nonatomic, readonly) CLLocationCoordinate2D northEast;

/** The South-West corner of these bounds. */
@property(nonatomic, readonly) CLLocationCoordinate2D southWest;

/**
 * Returns NO if this bounds does not contain any points. For example, [[GMSPlaceViewportInfo alloc]
 * init].valid == NO.
 */
@property(nonatomic, readonly, getter=isValid) BOOL valid;

/**
 * Inits the northEast and southWest bounds corresponding to the rectangular region defined by the
 * two corners.
 *
 * @param northEast The North-East corner of these bounds.
 * @param southWest The South-West corner of these bounds
 */
- (id)initWithNorthEast:(CLLocationCoordinate2D)northEast
              southWest:(CLLocationCoordinate2D)southWest;

@end
