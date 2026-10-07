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

/// Demo showing a modally presented Autocomplete view controller. Please refer to
/// https://developers.google.com/places/ios-sdk/autocomplete
class AutocompleteModalViewController: AutocompleteBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let autocompleteViewController = GMSAutocompleteViewController()
    autocompleteViewController.delegate = self
    if let config = autocompleteConfiguration {
      autocompleteViewController.autocompleteFilter = config.autocompleteFilter
      autocompleteViewController.placeFields = config.placeFields
    }
    navigationController?.present(autocompleteViewController, animated: true)
  }
}

extension AutocompleteModalViewController: GMSAutocompleteViewControllerDelegate {
  func viewController(
    _ viewController: GMSAutocompleteViewController,
    didAutocompleteWith place: GMSPlace
  ) {
    navigationController?.dismiss(animated: true)
    super.autocompleteDidSelectPlace(place)
  }

  func viewController(
    _ viewController: GMSAutocompleteViewController,
    didFailAutocompleteWithError error: Error
  ) {
    navigationController?.dismiss(animated: true)
    super.autocompleteDidFail(error)
  }

  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    navigationController?.dismiss(animated: true)
    super.autocompleteDidCancel()
  }

  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    print("Request autocomplete predictions.")
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    print("Updated autocomplete predictions.")
  }
}
