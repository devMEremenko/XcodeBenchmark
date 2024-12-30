//
//  GMSCompatabilityMacros.h
//  Google Maps SDK for iOS
//
//  Copyright 2015 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>

/**
 * A Swift 2/3 version conditional variant of NS_SWIFT_NAME. This is used in
 * places where NS_SWIFT_NAME is needed but the Swift-transcribed name of the
 * Objective-C name is conditional on the Swift version being compiled. This
 * macro determines which version of Swift this code is being imported from by
 * looking for the presence of the SWIFT_SDK_OVERLAY_UIKIT_EPOCH macro which is
 * only defined in Swift 3+.
 */
#if defined(SWIFT_SDK_OVERLAY_UIKIT_EPOCH)
#define GMS_SWIFT_NAME_2_0_3_0(name_swift_2, name_swift_3) \
  NS_SWIFT_NAME(name_swift_3)
#else
#define GMS_SWIFT_NAME_2_0_3_0(name_swift_2, name_swift_3) \
  NS_SWIFT_NAME(name_swift_2)
#endif
