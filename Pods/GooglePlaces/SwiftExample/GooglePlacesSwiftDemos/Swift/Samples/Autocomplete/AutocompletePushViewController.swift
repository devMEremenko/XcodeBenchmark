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
  private let margin: CGFloat = 80
  private let buttonHeight: CGFloat = 50

  private lazy var showWidgetButton: UIButton = {
    let button = UIButton()
    button.setTitle(
      NSLocalizedString(
        "Demo.Content.Autocomplete.ShowWidgetButton",
        comment: "Button title for 'show autocomplete widget'"), for: .normal)
    button.setTitleColor(.darkGray, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(showAutocompleteWidget), for: .touchUpInside)

    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    automaticallyAdjustsScrollViewInsets = true

    view.addSubview(showWidgetButton)
    NSLayoutConstraint.activate([
      showWidgetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      showWidgetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      showWidgetButton.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
      showWidgetButton.heightAnchor.constraint(equalToConstant: buttonHeight),
    ])
  }

  @objc func showAutocompleteWidget() {
    showWidgetButton.isHidden = true

    let autocompleteViewController = GMSAutocompleteViewController()
    autocompleteViewController.delegate = self
    if let config = autocompleteConfiguration {
      autocompleteViewController.autocompleteFilter = config.autocompleteFilter
      autocompleteViewController.placeFields = config.placeFields
    }
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
}
