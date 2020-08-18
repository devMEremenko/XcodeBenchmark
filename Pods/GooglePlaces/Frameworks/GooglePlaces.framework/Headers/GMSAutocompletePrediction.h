//
//  GMSAutocompletePrediction.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
/**
 * Attribute name for match fragments in |GMSAutocompletePrediction| attributedFullText.
 *
 * @related GMSAutocompletePrediction
 */
extern NSAttributedStringKey const kGMSAutocompleteMatchAttribute;
#else
/**
 * Attribute name for match fragments in |GMSAutocompletePrediction| attributedFullText.
 *
 * @related GMSAutocompletePrediction
 */
extern NSString *const kGMSAutocompleteMatchAttribute;
#endif

/**
 * This class represents a prediction of a full query based on a partially typed string.
 */
@interface GMSAutocompletePrediction : NSObject

/**
 * The full description of the prediction as a NSAttributedString. E.g., "Sydney Opera House,
 * Sydney, New South Wales, Australia".
 *
 * Every text range that matches the user input has a |kGMSAutocompleteMatchAttribute|.  For
 * example, you can make every match bold using enumerateAttribute:
 * <pre>
 *   UIFont *regularFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
 *   UIFont *boldFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
 *
 *   NSMutableAttributedString *bolded = [prediction.attributedFullText mutableCopy];
 *   [bolded enumerateAttribute:kGMSAutocompleteMatchAttribute
 *                      inRange:NSMakeRange(0, bolded.length)
 *                      options:0
 *                   usingBlock:^(id value, NSRange range, BOOL *stop) {
 *                     UIFont *font = (value == nil) ? regularFont : boldFont;
 *                     [bolded addAttribute:NSFontAttributeName value:font range:range];
 *                   }];
 *
 *   label.attributedText = bolded;
 * </pre>
 */
@property(nonatomic, copy, readonly) NSAttributedString *attributedFullText;

/**
 * The main text of a prediction as a NSAttributedString, usually the name of the place.
 * E.g. "Sydney Opera House".
 *
 * Text ranges that match user input are have a |kGMSAutocompleteMatchAttribute|,
 * like |attributedFullText|.
 */
@property(nonatomic, copy, readonly) NSAttributedString *attributedPrimaryText;

/**
 * The secondary text of a prediction as a NSAttributedString, usually the location of the place.
 * E.g. "Sydney, New South Wales, Australia".
 *
 * Text ranges that match user input are have a |kGMSAutocompleteMatchAttribute|, like
 * |attributedFullText|.
 *
 * May be nil.
 */
@property(nonatomic, copy, readonly, nullable) NSAttributedString *attributedSecondaryText;

/**
 * A property representing the place ID of the prediction, suitable for use in a place details
 * request.
 */
@property(nonatomic, copy, readonly) NSString *placeID;

/**
 * The types of this autocomplete result.  Types are NSStrings, valid values are any types
 * documented at <https://developers.google.com/places/ios-sdk/supported_types>.
 */
@property(nonatomic, copy, readonly) NSArray<NSString *> *types;

/**
 * The straight line distance in meters between the origin and this prediction if a valid origin is
 * specified in the |GMSAutocompleteFilter| of the request.
 */
@property(nonatomic, readonly, nullable) NSNumber *distanceMeters;

/**
 * Initializer is not available.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
