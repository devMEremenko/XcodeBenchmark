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

/// The class which displays the list of demos.
class SampleListViewController: UITableViewController {

  static let sampleCellIdentifier = "sampleCellIdentifier"

  let sampleSections = Samples.allSamples()

  let configuration: AutocompleteConfiguration = {
    var fields: [GMSPlaceField] = [
      .name, .placeID, .plusCode, .coordinate, .openingHours, .phoneNumber, .formattedAddress,
      .rating, .userRatingsTotal, .priceLevel, .types, .website, .viewport, .addressComponents,
      .photos, .utcOffsetMinutes, .businessStatus, .iconImageURL, .iconBackgroundColor,
    ]
    return AutocompleteConfiguration(
      autocompleteFilter: GMSAutocompleteFilter(),
      placeFields: GMSPlaceField(rawValue: fields.reduce(0) { $0 | $1.rawValue }))
  }()
  private lazy var editButton: UIBarButtonItem = {
    UIBarButtonItem(
      title: "Edit", style: .plain, target: self, action: #selector(showConfiguration))
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(
      UITableViewCell.self, forCellReuseIdentifier: SampleListViewController.sampleCellIdentifier)

    tableView.dataSource = self
    tableView.delegate = self

    navigationItem.rightBarButtonItem = editButton

    let navBar = navigationController?.navigationBar

    let navBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithOpaqueBackground()
    navBarAppearance.backgroundColor = .systemBackground
    navBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]

    navBar?.standardAppearance = navBarAppearance
    navBar?.scrollEdgeAppearance = navBarAppearance
  }

  func sample(at indexPath: IndexPath) -> Sample? {
    guard indexPath.section >= 0 && indexPath.section < sampleSections.count else { return nil }
    let section = sampleSections[indexPath.section]
    guard indexPath.row >= 0 && indexPath.row < section.samples.count else { return nil }
    return section.samples[indexPath.row]
  }

  @objc private func showConfiguration(_sender: UIButton) {
    navigationController?.present(
      ConfigurationViewController(configuration: configuration), animated: true)
  }

  // MARK: - Override UITableView
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard section <= sampleSections.count else {
      return 0
    }
    return sampleSections[section].samples.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: SampleListViewController.sampleCellIdentifier, for: indexPath)
    if let sample = sample(at: indexPath) {
      cell.textLabel?.text = sample.title
    }
    return cell
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return sampleSections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    guard section <= sampleSections.count else {
      return nil
    }
    return sampleSections[section].name
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if let sample = sample(at: indexPath) {
      let viewController = sample.viewControllerClass.init()
      if let controller = viewController as? AutocompleteBaseViewController {
        controller.autocompleteConfiguration = configuration
      }
      navigationController?.pushViewController(viewController, animated: true)
    }
  }
}
