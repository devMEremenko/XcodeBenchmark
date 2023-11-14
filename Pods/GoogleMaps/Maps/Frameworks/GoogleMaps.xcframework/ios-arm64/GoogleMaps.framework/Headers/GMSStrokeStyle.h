//
//  GMSStrokeStyle.h
//  Google Maps SDK for iOS
//
//  Copyright 2019 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <UIKit/UIKit.h>

@class GMSStampStyle;

NS_ASSUME_NONNULL_BEGIN

/** Describes the drawing style for one-dimensional entities such as polylines. */
@interface GMSStrokeStyle : NSObject

/**
 * A repeated image over the stroke to allow a user to set a 2D texture on top of a stroke.
 * If the image has transparent or semi-transparent portions, the underlying stroke color will show
 * through in those places. Solid portions of the stamp will completely cover the base stroke.
 */
@property(nonatomic, strong, nullable) GMSStampStyle *stampStyle;

/** Creates a solid color stroke style. */
+ (instancetype)solidColor:(UIColor *)color;

/** Creates a gradient stroke style interpolating from |fromColor| to |toColor|. */
+ (instancetype)gradientFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor;

/** Creates a transparent stroke style and sets the stampStyle. */
+ (instancetype)transparentStrokeWithStampStyle:(GMSStampStyle *)stampStyle;

@end

NS_ASSUME_NONNULL_END
