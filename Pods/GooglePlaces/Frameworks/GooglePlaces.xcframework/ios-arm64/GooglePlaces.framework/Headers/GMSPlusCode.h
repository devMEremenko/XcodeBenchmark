//
//  GMSPlusCode.h
//  Google Places SDK for iOS
//
//  Copyright 2018 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class containing the Plus codes representation for a location. See https://plus.codes/ for more
 * details.
 */
@interface GMSPlusCode : NSObject

/** Geo plus code, e.g. "8FVC9G8F+5W" */
@property(nonatomic, readonly, copy) NSString *globalCode;

/** Compound plus code, e.g. "9G8F+5W Zurich, Switzerland" */
@property(nullable, nonatomic, readonly, copy) NSString *compoundCode;

@end

NS_ASSUME_NONNULL_END
