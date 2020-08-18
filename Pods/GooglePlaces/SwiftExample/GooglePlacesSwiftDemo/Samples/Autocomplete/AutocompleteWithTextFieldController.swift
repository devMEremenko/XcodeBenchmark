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

/// Demo showing how to manually present a UITableViewController and supply it with autocomplete
/// text from an arbitrary source, in this case a UITextField. Please refer to:
/// https://developers.google.com/places/ios-sdk/autocomplete
class AutocompleteWithTextFieldController: AutocompleteBaseViewController {
  private let padding: CGFloat = 20
  private lazy var searchField: UITextField = {
    let searchField = UITextField(frame: .zero)
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchField.borderStyle = .none
    searchField.backgroundColor = .white
    searchField.placeholder = NSLocalizedString(
      "Demo.Content.Autocomplete.EnterTextPrompt",
      comment: "Prompt to enter text for autocomplete demo")
    searchField.autocorrectionType = .no
    searchField.keyboardType = .default
    searchField.returnKeyType = .done
    searchField.clearButtonMode = .whileEditing
    searchField.contentVerticalAlignment = .center

    searchField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    return searchField
  }()

  private lazy var resultsController: UITableViewController = UITableViewController(style: .plain)

  private lazy var tableDataSource: GMSAutocompleteTableDataSource = {
    let tableDataSource = GMSAutocompleteTableDataSource()
    tableDataSource.tableCellBackgroundColor = .white
    return tableDataSource
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    navigationController?.navigationBar.isTranslucent = false
    searchField.delegate = self
    tableDataSource.delegate = self
    resultsController.tableView.delegate = tableDataSource
    resultsController.tableView.dataSource = tableDataSource

    view.addSubview(searchField)
    NSLayoutConstraint.activate([
      searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
      searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
    ])

    // Add the results controller
    guard let resultView = resultsController.view else { return }
    resultView.translatesAutoresizingMaskIntoConstraints = false
    resultView.alpha = 0
    view.addSubview(resultView)
    NSLayoutConstraint.activate([
      resultView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: padding),
      resultView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      resultView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      resultView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  @objc func textFieldChanged(sender: UIControl) {
    guard let textField = sender as? UITextField else { return }
    tableDataSource.sourceTextHasChanged(textField.text)
  }

  func dismissResultView() {
    resultsController.willMove(toParent: nil)
    UIView.animate(
      withDuration: 0.5,
      animations: {
        self.resultsController.view.alpha = 0
      }
    ) { (_) in
      self.resultsController.view.removeFromSuperview()
      self.resultsController.removeFromParent()
    }
  }
}

extension AutocompleteWithTextFieldController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    addChild(resultsController)
    resultsController.tableView.reloadData()
    UIView.animate(
      withDuration: 0.5,
      animations: {
        self.resultsController.view.alpha = 1
      }
    ) { (_) in
      self.resultsController.didMove(toParent: self)
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    dismissResultView()
    textField.resignFirstResponder()
    textField.text = ""
    tableDataSource.clearResults()
    return false
  }
}

extension AutocompleteWithTextFieldController: GMSAutocompleteTableDataSourceDelegate {
  func tableDataSource(
    _ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace
  ) {
    dismissResultView()
    searchField.resignFirstResponder()
    searchField.isHidden = true
    autocompleteDidSelectPlace(place)
  }

  func tableDataSource(
    _ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error
  ) {
    dismissResultView()
    searchField.resignFirstResponder()
    searchField.isHidden = true
    autocompleteDidFail(error)
  }

  func didRequestAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    resultsController.tableView.reloadData()

  }
  func didUpdateAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
    resultsController.tableView.reloadData()
  }
}
