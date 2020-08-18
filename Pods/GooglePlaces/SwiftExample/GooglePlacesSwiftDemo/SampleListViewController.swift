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

import UIKit

/// The class which displays the list of demos.
class SampleListViewController: UIViewController {

  static let sampleCellIdentifier = "sampleCellIdentifier"

  let sampleSections = Samples.allSamples()
  var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView = UITableView()
    view.addSubview(tableView)
    tableView.register(
      UITableViewCell.self, forCellReuseIdentifier: SampleListViewController.sampleCellIdentifier)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    tableView.dataSource = self
    tableView.delegate = self
  }
}

extension SampleListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard section <= sampleSections.count else {
      return 0
    }
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
    guard section <= sampleSections.count else {
      return nil
    }
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
    if let sample = sample(at: indexPath) {
      let viewController = sample.viewControllerClass.init()
      navigationController?.pushViewController(viewController, animated: true)
    }
  }
}
