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

import GoogleMaps
import UIKit

class SampleListViewController: UIViewController {
  static let sampleCellIdentifier = "sampleCellIdentifier"

  let sampleSections = Samples.allSamples()
  lazy var tableView: UITableView = UITableView()
  var shouldCollapseDetailViewController = true

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    tableView.register(
      UITableViewCell.self, forCellReuseIdentifier: SampleListViewController.sampleCellIdentifier)
    tableView.dataSource = self
    tableView.delegate = self
  }
}

extension SampleListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sampleSections[section].samples.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: SampleListViewController.sampleCellIdentifier, for: indexPath)
    if let sample = sample(at: indexPath) {
      cell.textLabel?.text = sample.title
    }
    return cell
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return sampleSections.count
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sampleSections[section].name
  }

  func sample(at indexPath: IndexPath) -> Sample? {
    guard indexPath.section >= 0 && indexPath.section < sampleSections.count else { return nil }
    let section = sampleSections[indexPath.section]
    guard indexPath.row >= 0 && indexPath.row < section.samples.count else { return nil }
    return section.samples[indexPath.row]
  }
}

extension SampleListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    shouldCollapseDetailViewController = false
    tableView.deselectRow(at: indexPath, animated: true)
    if let sample = sample(at: indexPath) {
      let viewController = sample.viewControllerClass.init()
      viewController.title = sample.title
      let navController = UINavigationController(rootViewController: viewController)
      navController.navigationBar.isTranslucent = false
      showDetailViewController(navController, sender: self)
    }
  }
}

extension SampleListViewController: UISplitViewControllerDelegate {
  func primaryViewController(forExpanding splitViewController: UISplitViewController)
    -> UIViewController?
  {
    tableView.reloadData()
    return nil
  }

  func primaryViewController(forCollapsing splitViewController: UISplitViewController)
    -> UIViewController?
  {
    tableView.reloadData()
    return nil
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    collapseSecondary secondaryViewController: UIViewController,
    onto primaryViewController: UIViewController
  ) -> Bool {
    return shouldCollapseDetailViewController
  }
}
