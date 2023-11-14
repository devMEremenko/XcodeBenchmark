// Copyright 2020 Google LLC. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import GooglePlaces
import UIKit

/// Demo showing the use of GMSAutocompleteViewController with a UISearchController. Please refer to
/// https://developers.google.com/places/ios-sdk/autocomplete
class AutocompleteWithSearchViewController: AutocompleteBaseViewController {
  let searchBarAccessibilityIdentifier = "searchBarAccessibilityIdentifier"

  private lazy var autoCompleteController: GMSAutocompleteResultsViewController = {
    let controller = GMSAutocompleteResultsViewController()
    if let config = autocompleteConfiguration {
      controller.autocompleteFilter = config.autocompleteFilter
      controller.placeFields = config.placeFields
    }
    controller.delegate = self
    return controller
  }()

  private lazy var searchController: UISearchController = {
    let controller =
      UISearchController(searchResultsController: autoCompleteController)
    controller.hidesNavigationBarDuringPresentation = false
    controller.searchBar.autoresizingMask = .flexibleWidth
    controller.searchBar.searchBarStyle = .minimal
    controller.searchBar.delegate = self
    controller.searchBar.accessibilityIdentifier = searchBarAccessibilityIdentifier
    controller.searchBar.sizeToFit()
    return controller
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    autoCompleteController.delegate = self
    navigationItem.titleView = searchController.searchBar
    definesPresentationContext = true

    searchController.searchResultsUpdater = autoCompleteController
    searchController.modalPresentationStyle =
      UIDevice.current.userInterfaceIdiom == .pad ? .popover : .fullScreen

    // Prevents the tableview goes under the navigation bar.
    automaticallyAdjustsScrollViewInsets = true
  }
}

extension AutocompleteWithSearchViewController: GMSAutocompleteResultsViewControllerDelegate {
  func resultsController(
    _ resultsController: GMSAutocompleteResultsViewController,
    didAutocompleteWith place: GMSPlace
  ) {
    searchController.isActive = false
    super.autocompleteDidSelectPlace(place)
  }

  func resultsController(
    _ resultsController: GMSAutocompleteResultsViewController,
    didFailAutocompleteWithError error: Error
  ) {
    searchController.isActive = false
    super.autocompleteDidFail(error)
  }
}

extension AutocompleteWithSearchViewController: UISearchBarDelegate {
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    // Inform user that the autocomplete query has been cancelled and dismiss the search bar.
    searchController.isActive = false
    searchController.searchBar.isHidden = true
    super.autocompleteDidCancel()
  }
}
