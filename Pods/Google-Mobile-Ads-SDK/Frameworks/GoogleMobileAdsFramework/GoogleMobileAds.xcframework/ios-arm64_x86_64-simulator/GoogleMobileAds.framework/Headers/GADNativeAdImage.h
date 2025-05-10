//
//  GADNativeAdImage.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// Native ad image.
@interface GADNativeAdImage : NSObject

/// The image. If image autoloading is disabled, this property will be nil.
@property(nonatomic, readonly, strong, nullable) UIImage *image;

/// The image's URL.
@property(nonatomic, readonly, copy, nullable) NSURL *imageURL;

/// The image's scale.
@property(nonatomic, readonly, assign) CGFloat scale;

@end
