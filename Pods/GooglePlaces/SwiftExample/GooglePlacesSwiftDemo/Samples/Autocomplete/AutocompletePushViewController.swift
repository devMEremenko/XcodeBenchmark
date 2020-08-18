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

/// Demo showing a Autocomplete view controller pushed on the navigation stack. Please refer to
/// https://developers.google.com/places/ios-sdk/autocomplete
class AutocompletePushViewController: AutocompleteBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let autocompleteViewController = GMSAutocompleteViewController()
    autocompleteViewController.delegate = self
    navigationController?.pushViewController(autocompleteViewController, animated: true)
  }
}

extension AutocompletePushViewController: GMSAutocompleteViewControllerDelegate {
  func viewController(
    _ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace
  ) {
    navigationController?.popToViewController(self, animated: true)
    super.autocompleteDidSelectPlace(place)
  }

  func viewController(
    _ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error
  ) {
    navigationController?.popToViewController(self, animated: true)
    super.autocompleteDidFail(error)
  }

  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    navigationController?.popToViewController(self, animated: true)
    super.autocompleteDidCancel()
  }

  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
}
