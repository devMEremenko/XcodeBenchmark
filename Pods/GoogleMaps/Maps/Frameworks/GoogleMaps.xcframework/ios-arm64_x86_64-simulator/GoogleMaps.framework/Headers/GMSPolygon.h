//
//  GMSPolygon.h
//  Google Maps SDK for iOS
//
//  Copyright 2013 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <UIKit/UIKit.h>

#import "GMSOverlay.h"

@class GMSPath;
@class GMSPolygonLayer;

NS_ASSUME_NONNULL_BEGIN

/**
 * GMSPolygon defines a polygon that appears on the map. A polygon (like a polyline) defines a
 * series of connected coordinates in an ordered sequence; additionally, polygons form a closed loop
 * and define a filled region.
 */
@interface GMSPolygon : GMSOverlay

/** The path that describes this polygon. The coordinates composing the path must be valid. */
@property(nonatomic, copy, nullable) GMSPath *path;

/**
 * The array of GMSPath instances that describes any holes in this polygon. The coordinates
 * composing each path must be valid.
 */
@property(nonatomic, copy, nullable) NSArray<GMSPath *> *holes;

/** The width of the polygon outline in screen points. Defaults to 1. */
@property(nonatomic) CGFloat strokeWidth;

/** The color of the polygon outline. Defaults to nil. */
@property(nonatomic, nullable) UIColor *strokeColor;

/** The fill color. Defaults to blueColor. */
@property(nonatomic, nullable) UIColor *fillColor;

/** Whether this polygon should be rendered with geodesic correction. */
@property(nonatomic) BOOL geodesic;

/** Provides the Core Animation layer for this GMSPolygon. */
@property(nonatomic, readonly) GMSPolygonLayer *layer;

/**
 * Convenience constructor for GMSPolygon for a particular path. Other properties will have default
 * values.
 */
+ (instancetype)polygonWithPath:(nullable GMSPath *)path;

@end

NS_ASSUME_NONNULL_END
