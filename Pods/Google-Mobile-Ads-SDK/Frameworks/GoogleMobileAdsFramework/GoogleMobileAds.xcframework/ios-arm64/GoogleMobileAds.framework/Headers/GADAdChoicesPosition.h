//
//  GADNativeAdViewAdOptions.h
//  Google Mobile Ads SDK
//
//  Copyright 2023 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Position of the AdChoices icon in the containing ad.
typedef NS_ENUM(NSInteger, GADAdChoicesPosition) {
  GADAdChoicesPositionTopRightCorner,     ///< Top right corner.
  GADAdChoicesPositionTopLeftCorner,      ///< Top left corner.
  GADAdChoicesPositionBottomRightCorner,  ///< Bottom right corner.
  GADAdChoicesPositionBottomLeftCorner    ///< Bottom Left Corner.
};
