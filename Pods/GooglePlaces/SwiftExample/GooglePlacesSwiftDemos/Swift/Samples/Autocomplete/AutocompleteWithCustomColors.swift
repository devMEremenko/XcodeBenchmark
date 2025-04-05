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

enum ColorTheme: Int, CaseIterable, CustomStringConvertible {
  case black = 0
  case blue = 1
  case brown = 2
  case hotDog = 3

  var backgroundColor: UIColor {
    switch self {
    case .black:
      return UIColor(white: 0.25, alpha: 1)
    case .blue:
      return UIColor(red: 225 / 255, green: 241 / 255, blue: 252 / 255, alpha: 1)
    case .brown:
      return UIColor(red: 215 / 255, green: 204 / 255, blue: 200 / 255, alpha: 1)
    case .hotDog:
      return .yellow
    }
  }

  var selectedTableCellBackgroundColor: UIColor {
    switch self {
    case .black:
      return UIColor(white: 0.35, alpha: 1)
    case .blue:
      return UIColor(red: 213 / 255, green: 219 / 255, blue: 230 / 255, alpha: 1)
    case .brown:
      return UIColor(red: 236 / 255, green: 225 / 255, blue: 220 / 255, alpha: 1)
    case .hotDog:
      return .white
    }
  }

  var darkBackgroundColor: UIColor {
    switch self {
    case .black:
      return UIColor(white: 0.2, alpha: 1)
    case .blue:
      return UIColor(red: 187 / 255, green: 222 / 255, blue: 248 / 255, alpha: 1)
    case .brown:
      return UIColor(red: 93 / 255, green: 64 / 255, blue: 55 / 255, alpha: 1)
    case .hotDog:
      return .red
    }
  }

  var primaryTextColor: UIColor {
    switch self {
    case .black:
      return .white
    case .blue:
      return UIColor(white: 0.5, alpha: 1)
    case .brown:
      return UIColor(white: 0.33, alpha: 1)
    case .hotDog:
      return .black
    }
  }

  var highlightColor: UIColor {
    switch self {
    case .black:
      return UIColor(red: 0.75, green: 1, blue: 0.75, alpha: 1)
    case .blue:
      return UIColor(red: 76 / 255, green: 175 / 255, blue: 248 / 255, alpha: 1)
    case .brown:
      return UIColor(red: 255 / 255, green: 235 / 255, blue: 0 / 255, alpha: 1)
    case .hotDog:
      return .red
    }
  }

  var secondaryColor: UIColor {
    switch self {
    case .black:
      return UIColor(white: 1, alpha: 0.5)
    case .blue:
      return UIColor(white: 0.5, alpha: 1)
    case .brown:
      return UIColor(white: 114 / 255, alpha: 1)
    case .hotDog:
      return UIColor(white: 0, alpha: 0.6)
    }
  }

  var tintColor: UIColor {
    switch self {
    case .black:
      return .white
    case .blue:
      return UIColor(red: 0 / 255, green: 142 / 255, blue: 248 / 255, alpha: 1)
    case .brown:
      return UIColor(red: 219 / 255, green: 207 / 255, blue: 28 / 255, alpha: 1)
    case .hotDog:
      return .red
    }
  }

  var searchBarTintColor: UIColor {
    switch self {
    case .black:
      return .white
    case .blue:
      return UIColor(red: 0 / 255, green: 142 / 255, blue: 248 / 255, alpha: 1)
    case .brown:
      return .yellow
    case .hotDog:
      return .white
    }
  }

  var separatorColor: UIColor {
    switch self {
    case .black:
      return UIColor(red: 0.5, green: 0.75, blue: 0.5, alpha: 0.3)
    case .blue:
      return UIColor(white: 0.5, alpha: 0.65)
    case .brown:
      return UIColor(white: 182 / 255, alpha: 1)
    case .hotDog:
      return .red
    }
  }

  var description: String {
    switch self {
    case .black:
      return NSLocalizedString(
        "Demo.Content.Autocomplete.Styling.Colors.WhiteOnBlack",
        comment: "Button title for the 'WhiteOnBlack' styled autocomplete widget.")
    case .blue:
      return NSLocalizedString(
        "Demo.Content.Autocomplete.Styling.Colors.BlueColors",
        comment: "Button title for the 'BlueColors' styled autocomplete widget.")
    case .brown:
      return NSLocalizedString(
        "Demo.Content.Autocomplete.Styling.Colors.YellowAndBrown",
        comment: "Button title for the 'Yellow and Brown' styled autocomplete widget.")
    case .hotDog:
      return NSLocalizedString(
        "Demo.Content.Autocomplete.Styling.Colors.HotDogStand",
        comment: "Button title for the 'Hot Dog Stand' styled autocomplete widget.")
    }
  }
}

/// Demo showing how to customise colors in the full-screen Autocomplete Widget. Please refer to
/// https://developers.google.com/places/ios-sdk/autocomplete
class AutocompleteWithCustomColors: AutocompleteBaseViewController {
  private let buttonHeight: CGFloat = 40.0
  private var currentTheme: ColorTheme?

  override func viewDidLoad() {
    super.viewDidLoad()
    ColorTheme.allCases.forEach { color in
      let button = UIButton(type: .system)
      button.tag = color.rawValue
      button.setTitle(color.description, for: .normal)
      button.addTarget(self, action: #selector(showAutoComplete), for: .touchUpInside)
      view.addSubview(button)
      button.translatesAutoresizingMaskIntoConstraints = false
      let topPadding = CGFloat(color.rawValue) * buttonHeight * 2.0 + 100
      NSLayoutConstraint.activate([
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding),
        button.heightAnchor.constraint(equalToConstant: buttonHeight),
        button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      ])
    }
  }

  @objc func showAutoComplete(sender: UIButton) {
    guard let colorTheme = ColorTheme(rawValue: sender.tag) else { return }
    UIActivityIndicatorView.appearance(
      whenContainedInInstancesOf: [GMSStyledAutocompleteViewController.self]
    ).color = colorTheme.primaryTextColor
    let navigationBarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [
      GMSStyledAutocompleteViewController.self
    ])
    navigationBarAppearance.barTintColor = colorTheme.darkBackgroundColor
    navigationBarAppearance.tintColor = colorTheme.searchBarTintColor

    // Color of typed text in search bar.
    let textFieldAppearance = UITextField.appearance(
      whenContainedInInstancesOf: [GMSStyledAutocompleteViewController.self]
    )
    textFieldAppearance.defaultTextAttributes = [
      .foregroundColor: colorTheme.searchBarTintColor,
      .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
    ]

    // Color of the "Search" placeholder text in search bar. For this example, we'll make it the
    // same as the bar tint color but with added transparency.
    textFieldAppearance.attributedPlaceholder = NSAttributedString(
      string: "Search",
      attributes: [
        .foregroundColor: colorTheme.searchBarTintColor.withAlphaComponent(
          colorTheme.searchBarTintColor.cgColor.alpha * 0.75),
        .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
      ])

    // Change the background color of selected table cells.
    let backgroundView = UIView()
    backgroundView.backgroundColor = colorTheme.selectedTableCellBackgroundColor
    UITableViewCell.appearance(
      whenContainedInInstancesOf: [GMSStyledAutocompleteViewController.self]
    ).selectedBackgroundView = backgroundView

    // Depending on the navigation bar background color, it might also be necessary to customise the
    // icons displayed in the search bar to something other than the default. The
    // setupSearchBarCustomIcons method contains example code to do this.
    let controller = GMSStyledAutocompleteViewController()
    controller.delegate = self
    if let config = autocompleteConfiguration {
      controller.autocompleteFilter = config.autocompleteFilter
      controller.placeFields = config.placeFields
    }
    controller.tableCellBackgroundColor = colorTheme.backgroundColor
    controller.tableCellSeparatorColor = colorTheme.separatorColor
    controller.primaryTextColor = colorTheme.primaryTextColor
    controller.primaryTextHighlightColor = colorTheme.highlightColor
    controller.secondaryTextColor = colorTheme.secondaryColor
    controller.tintColor = colorTheme.tintColor

    // Customize the navigation bar appearance.
    let navBar = UINavigationBar.appearance(whenContainedInInstancesOf: [
      GMSStyledAutocompleteViewController.self
    ])
    navBar.barTintColor = colorTheme.darkBackgroundColor
    navBar.tintColor = colorTheme.searchBarTintColor

    let consistentAppearance = UINavigationBarAppearance()
    consistentAppearance.backgroundColor = colorTheme.darkBackgroundColor
    navBar.standardAppearance = consistentAppearance
    navBar.scrollEdgeAppearance = consistentAppearance
    navBar.compactAppearance = consistentAppearance

    if #available(iOS 15.0, *) {
      navBar.compactScrollEdgeAppearance = consistentAppearance
    }

    present(controller, animated: true)

    view.subviews.forEach { subview in
      if subview is UIButton {
        subview.removeFromSuperview()
      }
    }
  }
}

extension AutocompleteWithCustomColors: GMSAutocompleteViewControllerDelegate {
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
}

// Simple subclass of GMSAutocompleteViewController solely for the purpose of localising appearance
// proxy changes to this part of the demo app.
private class GMSStyledAutocompleteViewController: GMSAutocompleteViewController {}
