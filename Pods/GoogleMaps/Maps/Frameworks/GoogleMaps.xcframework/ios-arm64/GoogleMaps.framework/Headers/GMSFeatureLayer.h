//
//  GMSFeatureLayer.h
//  Google Maps SDK for iOS
//
//  Copyright 2022 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import "GMSFeature.h"

@class GMSFeatureStyle;

NS_ASSUME_NONNULL_BEGIN

/**
 * A class representing a collection of all features of the same @c GMSFeatureType, whose style can
 * be overridden on the client. Each @c GMSFeatureType will have one corresponding @c
 * GMSFeatureLayer.
 */
NS_SWIFT_NAME(FeatureLayer)
@interface GMSFeatureLayer<__covariant T : id <GMSFeature>> : NSObject

/**
 * The feature type associated with this layer. All features associated with the layer will be of
 * this type.
 */
@property(nonatomic, readonly) GMSFeatureType featureType;

/**
 * Determines if the data-driven @c GMSFeatureLayer is available. Data-driven styling requires
 * the Metal Framework, a valid map ID and that the feature type be applied.
 * If @c NO, styling for the @c GMSFeatureLayer returns to the default and events are not triggered.
 */
@property(nonatomic, readonly, getter=isAvailable) BOOL available;

/**
 * Styling block to be applied to all features in this layer.
 *
 * The style block is applied to all visible features in the viewport when the setter is called, and
 * is run multiple times for the subsequent features entering the viewport.
 *
 * The function is required to be deterministic and return consistent results when it is applied
 * over the map tiles. If any styling specs of any feature would be changed, @c style must be set
 * again. Changing behavior of the style block without calling the @c style setter will result in
 * undefined behavior, including stale and/or shattered map renderings. See the example below:
 * @code{.swift}
 * var selectedPlaceIDs = Set<String>()
 * var style = FeatureStyle(fill: .red, stroke: .clear, strokeWidth: 0)
 * layer.style = { feature in
 *   selectedPlaceIDs.contains(feature.placeID) ? style : nil
 * }
 *
 *
 * selectedPlaceIDs.insert("foo")
 *
 * style = FeatureStyle(fill: .clear, stroke: .blue, strokeWidth: 1.5)
 *
 *
 * layer.style = { feature in
 *   selectedPlaceIDs.contains(feature.placeID) ? style : nil
 * }
 * @endcode
 */
@property(nonatomic, nullable) GMSFeatureStyle *_Nullable (^style)(T);

/**
 * Create a feature layer instance for testing.
 *
 * This method should be used for your unit tests only. In production, @c GMSFeatureLayer instances
 * should only be created by the SDK.
 */
- (instancetype)initWithFeatureType:(GMSFeatureType)featureType;

- (instancetype)init NS_DESIGNATED_INITIALIZER NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
