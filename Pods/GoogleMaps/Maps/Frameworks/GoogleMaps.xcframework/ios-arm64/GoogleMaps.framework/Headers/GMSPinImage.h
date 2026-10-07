//
//  GMSPinImage.h
//  Google Maps SDK for iOS
//
//  Copyright 2023 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class GMSPinImageOptions;
NS_ASSUME_NONNULL_BEGIN

@interface GMSPinImage : UIImage

- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns an image style with the given pin image options that can be used as a standalone UIImage,
 * or as the icon of an Advanced Marker only.
 *
 * @param options A @c GMSPinImageOptions object to use to customize the marker image.
 * @return An image configured with the provided options.
 */
+ (GMSPinImage *)pinImageWithOptions:(GMSPinImageOptions *)options;

@end
NS_ASSUME_NONNULL_END
