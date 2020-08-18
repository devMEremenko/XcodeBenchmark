/*
 * Copyright 2016 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteWithSearchViewController.h"

#import <GooglePlaces/GooglePlaces.h>

NSString *const kSearchBarAccessibilityIdentifier = @"searchBarAccessibilityIdentifier";

@interface AutocompleteWithSearchViewController () <GMSAutocompleteResultsViewControllerDelegate,
                                                    UISearchBarDelegate>
@end

@implementation AutocompleteWithSearchViewController {
  UISearchController *_searchController;
  GMSAutocompleteResultsViewController *_acViewController;
}

+ (NSString *)demoTitle {
  return NSLocalizedString(
      @"Demo.Title.Autocomplete.UISearchController",
      @"Title of the UISearchController autocomplete demo for display in a list or nav header");
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  _acViewController = [[GMSAutocompleteResultsViewController alloc] init];
  _acViewController.autocompleteFilter = self.autocompleteFilter;
  _acViewController.placeFields = self.placeFields;
  _acViewController.delegate = self;

  _searchController =
      [[UISearchController alloc] initWithSearchResultsController:_acViewController];
  _searchController.hidesNavigationBarDuringPresentation = NO;
  _searchController.dimsBackgroundDuringPresentation = YES;

  _searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
  _searchController.searchBar.delegate = self;
  _searchController.searchBar.accessibilityIdentifier = kSearchBarAccessibilityIdentifier;

  [_searchController.searchBar sizeToFit];
  self.navigationItem.titleView = _searchController.searchBar;
  self.definesPresentationContext = YES;

  // Work around a UISearchController bug that doesn't reposition the table view correctly when
  // rotating to landscape.
  self.edgesForExtendedLayout = UIRectEdgeAll;
  self.extendedLayoutIncludesOpaqueBars = YES;

  _searchController.searchResultsUpdater = _acViewController;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    _searchController.modalPresentationStyle = UIModalPresentationPopover;
  } else {
    _searchController.modalPresentationStyle = UIModalPresentationFullScreen;
  }
}

#pragma mark - UISearcBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  // Inform user that the autocomplete query has been cancelled and dismiss the search bar.
  [_searchController setActive:NO];
  [_searchController.searchBar setHidden:YES];
  [self autocompleteDidCancel];
}

#pragma mark - GMSAutocompleteResultsViewControllerDelegate

- (void)resultsController:(GMSAutocompleteResultsViewController *)resultsController
    didAutocompleteWithPlace:(GMSPlace *)place {
  // Display the results and dismiss the search controller.
  [_searchController setActive:NO];
  [self autocompleteDidSelectPlace:place];
}

- (void)resultsController:(GMSAutocompleteResultsViewController *)resultsController
    didFailAutocompleteWithError:(NSError *)error {
  // Display the error and dismiss the search controller.
  [_searchController setActive:NO];
  [self autocompleteDidFail:error];
}

// Show and hide the network activity indicator when we start/stop loading results.

- (void)didRequestAutocompletePredictionsForResultsController:
    (GMSAutocompleteResultsViewController *)resultsController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  // Reset the text and photos view when we are requesting for predictions.
  [self resetViews];
}

- (void)didUpdateAutocompletePredictionsForResultsController:
    (GMSAutocompleteResultsViewController *)resultsController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
