//
//  GMSPanoramaLayer.h
//  Google Maps SDK for iOS
//
//  Copyright 2013 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

#import "GMSCALayer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * kGMSLayerPanoramaHeadingKey ranges from [0, 360).
 *
 * @related GMSPanoramaLayer
 */
extern NSString *const kGMSLayerPanoramaHeadingKey;

/**
 * kGMSLayerPanoramaPitchKey ranges from [-90, 90].
 *
 * @related GMSPanoramaLayer
 */
extern NSString *const kGMSLayerPanoramaPitchKey;

/**
 * kGMSLayerCameraZoomLevelKey ranges from [1, 5], default 1.
 *
 * @related GMSPanoramaLayer
 */
extern NSString *const kGMSLayerPanoramaZoomKey;

/**
 * kGMSLayerPanoramaFOVKey ranges from [1, 160] (in degrees), default 90.
 *
 * @related GMSPanoramaLayer
 */
extern NSString *const kGMSLayerPanoramaFOVKey;

/**
 * GMSPanoramaLayer is a custom subclass of CALayer, provided as the layer class on GMSPanoramaView.
 * This layer should not be instantiated directly.
 */
@interface GMSPanoramaLayer : GMSCALayer
@property(nonatomic) CLLocationDirection cameraHeading;
@property(nonatomic) double cameraPitch;
@property(nonatomic) float cameraZoom;
@property(nonatomic) double cameraFOV;
@end

NS_ASSUME_NONNULL_END
