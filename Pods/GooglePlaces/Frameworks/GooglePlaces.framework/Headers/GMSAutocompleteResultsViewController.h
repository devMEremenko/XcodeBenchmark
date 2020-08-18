//
//  GMSAutocompleteResultsViewController.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

#import <UIKit/UIKit.h>

#import "GMSAutocompleteBoundsMode.h"
#import "GMSAutocompleteFilter.h"
#import "GMSAutocompletePrediction.h"
#import "GMSPlace.h"
#import "GMSPlaceFieldMask.h"
#import "GMSPlacesDeprecationUtils.h"

@class GMSAutocompleteResultsViewController;
@class GMSCoordinateBounds;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol used by |GMSAutocompleteResultsViewController|, to communicate the user's interaction
 * with the controller to the application.
 */
@protocol GMSAutocompleteResultsViewControllerDelegate <NSObject>

@required

/**
 * Called when a place has been selected from the available autocomplete predictions.
 * @param resultsController The |GMSAutocompleteResultsViewController| that generated the event.
 * @param place The |GMSPlace| that was returned.
 */
- (void)resultsController:(GMSAutocompleteResultsViewController *)resultsController
    didAutocompleteWithPlace:(GMSPlace *)place;

/**
 * Called when a non-retryable error occurred when retrieving autocomplete predictions or place
 * details. A non-retryable error is defined as one that is unlikely to be fixed by immediately
 * retrying the operation.
 * <p>
 * Only the following values of |GMSPlacesErrorCode| are retryable:
 * <ul>
 * <li>kGMSPlacesNetworkError
 * <li>kGMSPlacesServerError
 * <li>kGMSPlacesInternalError
 * </ul>
 * All other error codes are non-retryable.
 * @param resultsController The |GMSAutocompleteResultsViewController| that generated the event.
 * @param error The |NSError| that was returned.
 */
- (void)resultsController:(GMSAutocompleteResultsViewController *)resultsController
    didFailAutocompleteWithError:(NSError *)error;

@optional

/**
 * Called when the user selects an autocomplete prediction from the list but before requesting
 * place details. Returning NO from this method will suppress the place details fetch and
 * didAutocompleteWithPlace will not be called.
 * @param resultsController The |GMSAutocompleteResultsViewController| that generated the event.
 * @param prediction The |GMSAutocompletePrediction| that was selected.
 */
- (BOOL)resultsController:(GMSAutocompleteResultsViewController *)resultsController
      didSelectPrediction:(GMSAutocompletePrediction *)prediction;

/**
 * Called once every time new autocomplete predictions are received.
 * @param resultsController The |GMSAutocompleteResultsViewController| that generated the event.
 */
- (void)didUpdateAutocompletePredictionsForResultsController:
    (GMSAutocompleteResultsViewController *)resultsController;

/**
 * Called once immediately after a request for autocomplete predictions is made.
 * @param resultsController The |GMSAutocompleteResultsViewController| that generated the event.
 */
- (void)didRequestAutocompletePredictionsForResultsController:
    (GMSAutocompleteResultsViewController *)resultsController;

@end

/**
 * GMSAutocompleteResultsViewController provides an interface that displays place autocomplete
 * predictions in a table view. The table view will be automatically updated as input text
 * changes.
 *
 * This class is intended to be used as the search results controller of a UISearchController. Pass
 * an instance of |GMSAutocompleteResultsViewController| to UISearchController's
 * initWithSearchResultsController method, then set the controller as the UISearchController's
 * searchResultsUpdater property.
 *
 * Use the |GMSAutocompleteResultsViewControllerDelegate| delegate protocol to be notified when a
 * place is selected from the list.
 */
@interface GMSAutocompleteResultsViewController : UIViewController <UISearchResultsUpdating>

/** Delegate to be notified when a place is selected. */
@property(nonatomic, weak, nullable) id<GMSAutocompleteResultsViewControllerDelegate> delegate;

/**
 * Bounds used to bias or restrict the autocomplete results depending on the value of
 * |autocompleteBoundsMode| (can be nil).
 */
@property(nonatomic, strong, nullable)
    GMSCoordinateBounds *autocompleteBounds __GMS_PLACES_AVAILABLE_BUT_DEPRECATED_MSG(
        "autocompleteBounds property is deprecated in favor of autocompleteFilter.locationBias or autocompleteFilter.locationRestriction");

/**
 * How to treat the |autocompleteBounds| property. Defaults to |kGMSAutocompleteBoundsModeBias|.
 *
 * Has no effect if |autocompleteBounds| is nil.
 */
@property(nonatomic, assign)
    GMSAutocompleteBoundsMode autocompleteBoundsMode __GMS_PLACES_AVAILABLE_BUT_DEPRECATED_MSG(
        "autocompleteBoundsMode property is deprecated in favor of autocompleteFilter.locationBias or autocompleteFilter.locationRestriction");

/** Filter to apply to autocomplete suggestions (can be nil). */
@property(nonatomic, strong, nullable) GMSAutocompleteFilter *autocompleteFilter;

/** The background color of table cells. */
@property(nonatomic, strong) IBInspectable UIColor *tableCellBackgroundColor;

/** The color of the separator line between table cells. */
@property(nonatomic, strong) IBInspectable UIColor *tableCellSeparatorColor;

/** The color of result name text in autocomplete results */
@property(nonatomic, strong) IBInspectable UIColor *primaryTextColor;

/** The color used to highlight matching text in autocomplete results */
@property(nonatomic, strong) IBInspectable UIColor *primaryTextHighlightColor;

/** The color of the second row of text in autocomplete results. */
@property(nonatomic, strong) IBInspectable UIColor *secondaryTextColor;

/** The tint color applied to controls in the Autocomplete view. */
@property(nonatomic, strong, nullable) IBInspectable UIColor *tintColor;

/**
 * Specify individual place details to fetch for object |GMSPlace|.
 * Defaults to returning all details if not overridden.
 */
@property(nonatomic, assign) GMSPlaceField placeFields;

/**
 * Sets up the autocomplete bounds using the NE and SW corner locations.
 */
- (void)setAutocompleteBoundsUsingNorthEastCorner:(CLLocationCoordinate2D)NorthEastCorner
                                  SouthWestCorner:(CLLocationCoordinate2D)SouthWestCorner
    __GMS_PLACES_AVAILABLE_BUT_DEPRECATED_MSG(
        "use of this method is deprecated in favor of setting autocompleteFilter.locationBias or autocompleteFilter.locationRestriction directly");

@end

NS_ASSUME_NONNULL_END
