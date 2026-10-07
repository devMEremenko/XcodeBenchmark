//
//  GMSPlaceSpecialDay.h
//  Google Places SDK for iOS
//
//  Copyright 2023 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents information on a particular day which may have opening hours different than normal.
 */
@interface GMSPlaceSpecialDay : NSObject

/** Date for which there may be exceptional hours. */
@property(nonatomic, copy, readonly, nullable) NSDate *date;

/** Returns whether or not the day has exceptional hours which can
 * replace the regular hours on certain dates (often holidays). */
@property(nonatomic, readonly) BOOL isExceptional;

@end

NS_ASSUME_NONNULL_END
