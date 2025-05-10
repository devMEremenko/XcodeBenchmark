//
//  GMSPanoramaService.h
//  Google Maps SDK for iOS
//
//  Copyright 2013 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <CoreLocation/CoreLocation.h>

#import "GMSPanoramaSource.h"

@class GMSPanorama;

NS_ASSUME_NONNULL_BEGIN

/**
 * Callback for when a panorama metadata becomes available.
 * If an error occurred, |panorama| is nil and |error| is not nil.
 * Otherwise, |panorama| is not nil and |error| is nil.
 *
 * @related GMSPanoramaService
 */
typedef void (^GMSPanoramaCallback)(GMSPanorama *_Nullable panorama, NSError *_Nullable error);

/**
 * GMSPanoramaService can be used to request panorama metadata even when a GMSPanoramaView is not
 * active.
 *
 * Get an instance like this: [[GMSPanoramaService alloc] init].
 */
@interface GMSPanoramaService : NSObject

/**
 * Retrieves information about a panorama near the given |coordinate|.
 *
 * This is an asynchronous request, |callback| will be called with the result.
 */
- (void)requestPanoramaNearCoordinate:(CLLocationCoordinate2D)coordinate
                             callback:(GMSPanoramaCallback)callback;

/**
 * Similar to requestPanoramaNearCoordinate:callback: but allows specifying a search radius (meters)
 * around |coordinate|.
 */
- (void)requestPanoramaNearCoordinate:(CLLocationCoordinate2D)coordinate
                               radius:(NSUInteger)radius
                             callback:(GMSPanoramaCallback)callback;

/**
 * Similar to requestPanoramaNearCoordinate:callback: but allows specifying the panorama source type
 * near the given |coordinate|.
 *
 * This API is experimental and may not always filter by source.
 */
- (void)requestPanoramaNearCoordinate:(CLLocationCoordinate2D)coordinate
                               source:(GMSPanoramaSource)source
                             callback:(GMSPanoramaCallback)callback;

/**
 * Similar to requestPanoramaNearCoordinate:callback: but allows specifying a search radius (meters)
 * and the panorama source type near the given |coordinate|.
 *
 * This API is experimental and may not always filter by source.
 */
- (void)requestPanoramaNearCoordinate:(CLLocationCoordinate2D)coordinate
                               radius:(NSUInteger)radius
                               source:(GMSPanoramaSource)source
                             callback:(GMSPanoramaCallback)callback;

/**
 * Retrieves information about a panorama with the given |panoramaID|.
 *
 * |callback| will be called with the result. Only panoramaIDs obtained from the Google Maps SDK for
 * iOS are supported.
 */
- (void)requestPanoramaWithID:(NSString *)panoramaID callback:(GMSPanoramaCallback)callback;

@end

NS_ASSUME_NONNULL_END
