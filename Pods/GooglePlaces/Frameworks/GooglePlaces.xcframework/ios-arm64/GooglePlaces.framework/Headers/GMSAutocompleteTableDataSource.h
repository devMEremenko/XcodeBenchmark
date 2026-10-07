//
//  GMSAutocompleteTableDataSource.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <UIKit/UIKit.h>

#import "GMSPlaceFieldMask.h"
#import "GMSPlacesDeprecationUtils.h"

@class GMSAutocompleteFilter;
@class GMSAutocompletePrediction;
@class GMSAutocompleteTableDataSource;
@class GMSPlace;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol used by |GMSAutocompleteTableDataSource|, to communicate the user's interaction with the
 * data source to the application.
 */
@protocol GMSAutocompleteTableDataSourceDelegate <NSObject>

@required

/**
 * Called when a place has been selected from the available autocomplete predictions.
 *
 * @param tableDataSource The |GMSAutocompleteTableDataSource| that generated the event.
 * @param place The |GMSPlace| that was returned.
 */
- (void)tableDataSource:(GMSAutocompleteTableDataSource *)tableDataSource
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
 *
 * @param tableDataSource The |GMSAutocompleteTableDataSource| that generated the event.
 * @param error The |NSError| that was returned.
 */
- (void)tableDataSource:(GMSAutocompleteTableDataSource *)tableDataSource
    didFailAutocompleteWithError:(NSError *)error;

@optional

/**
 * Called when the user selects an autocomplete prediction from the list but before requesting
 * place details. Returning NO from this method will suppress the place details fetch and
 * didAutocompleteWithPlace will not be called.
 *
 * @param tableDataSource The |GMSAutocompleteTableDataSource| that generated the event.
 * @param prediction The |GMSAutocompletePrediction| that was selected.
 */
- (BOOL)tableDataSource:(GMSAutocompleteTableDataSource *)tableDataSource
    didSelectPrediction:(GMSAutocompletePrediction *)prediction;

/**
 * Called once every time new autocomplete predictions are received.
 *
 * @param tableDataSource The |GMSAutocompleteTableDataSource| that generated the event.
 */
- (void)didUpdateAutocompletePredictionsForTableDataSource:
    (GMSAutocompleteTableDataSource *)tableDataSource;

/**
 * Called once immediately after a request for autocomplete predictions is made.
 *
 * @param tableDataSource The |GMSAutocompleteTableDataSource| that generated the event.
 */
- (void)didRequestAutocompletePredictionsForTableDataSource:
    (GMSAutocompleteTableDataSource *)tableDataSource;

@end

/**
 * GMSAutocompleteTableDataSource provides an interface for providing place autocomplete
 * predictions to populate a UITableView by implementing the UITableViewDataSource and
 * UITableViewDelegate protocols.
 *
 * GMSAutocompleteTableDataSource is designed to be used as the data source for a
 * UISearchDisplayController.
 *
 * NOTE: UISearchDisplayController has been deprecated since iOS 8. It is now recommended to use
 * UISearchController with |GMSAutocompleteResultsViewController| to display autocomplete results
 * using the iOS search UI.
 *
 * Set an instance of GMSAutocompleteTableDataSource as the searchResultsDataSource and
 * searchResultsDelegate properties of UISearchDisplayController. In your implementation of
 * shouldReloadTableForSearchString, call sourceTextHasChanged with the current search string.
 *
 * Use the |GMSAutocompleteTableDataSourceDelegate| delegate protocol to be notified when a place is
 * selected from the list. Because autocomplete predictions load asynchronously, it is necessary
 * to implement didUpdateAutocompletePredictions and call reloadData on the
 * UISearchDisplayController's table view.
 *
 */
@interface GMSAutocompleteTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>

/** Delegate to be notified when a place is selected or picking is cancelled. */
@property(nonatomic, weak, nullable) IBOutlet id<GMSAutocompleteTableDataSourceDelegate> delegate;

/** Filter to apply to autocomplete suggestions (can be nil). */
@property(nonatomic, strong, nullable) GMSAutocompleteFilter *autocompleteFilter;

/** The background color of table cells. */
@property(nonatomic, strong) UIColor *tableCellBackgroundColor;

/** The color of the separator line between table cells. */
@property(nonatomic, strong) UIColor *tableCellSeparatorColor;

/** The color of result name text in autocomplete results */
@property(nonatomic, strong) UIColor *primaryTextColor;

/** The color used to highlight matching text in autocomplete results */
@property(nonatomic, strong) UIColor *primaryTextHighlightColor;

/** The color of the second row of text in autocomplete results. */
@property(nonatomic, strong) UIColor *secondaryTextColor;

/** The tint color applied to controls in the Autocomplete view. */
@property(nonatomic, strong, nullable) UIColor *tintColor;

/**
 * The |GMSPlaceField| for specifying explicit place details to be requested. Default returns
 * all available fields.
 */
@property(nonatomic, assign) GMSPlaceField placeFields;


/** Initializes a data source. */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Notify the data source that the source text to autocomplete has changed.
 *
 * This method should only be called from the main thread. Calling this method from another thread
 * will result in undefined behavior. Calls to |GMSAutocompleteTableDataSourceDelegate| methods will
 * also be called on the main thread.
 *
 * This method is non-blocking.
 * @param text The partial text to autocomplete.
 */
- (void)sourceTextHasChanged:(nullable NSString *)text;

/**
 * Clear all predictions.
 *
 *  NOTE: This will call the two delegate methods below:
 *
 *  - |didUpdateAutocompletePredictionsForResultsController:|
 *  - |didRequestAutocompletePredictionsForResultsController:|
 *
 *  The implementation of this method is guaranteed to call these synchronously and in-order.
 */
- (void)clearResults;

@end

NS_ASSUME_NONNULL_END
