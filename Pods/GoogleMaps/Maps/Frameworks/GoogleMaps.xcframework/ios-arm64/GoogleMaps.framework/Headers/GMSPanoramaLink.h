//
//  GMSPanoramaLink.h
//  Google Maps SDK for iOS
//
//  Copyright 2013 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Links from a GMSPanorama to neighboring panoramas. */
@interface GMSPanoramaLink : NSObject

/** Angle of the neighboring panorama, clockwise from north in degrees. */
@property(nonatomic) CGFloat heading;

/** Panorama ID for the neighboring panorama. Do not store this persistenly, it changes in time. */
@property(nonatomic, copy) NSString *panoramaID;

@end

NS_ASSUME_NONNULL_END
