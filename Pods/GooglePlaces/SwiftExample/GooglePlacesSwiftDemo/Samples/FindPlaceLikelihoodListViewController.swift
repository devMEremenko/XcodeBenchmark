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

import CoreLocation
import GooglePlaces
import UIKit

/// Demo that exposes the findPlaceLikelihoodsForLocation API. Please refer to
/// https://developers.google.com/places/ios-sdk/current-place
class FindPlaceLikelihoodListViewController: UIViewController {
  private let cellIdentifier = "LikelihoodCellIdentifier"
  private let padding: CGFloat = 20
  private var placeLikelihoods: [GMSPlaceLikelihood]?
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    return manager
  }()
  private lazy var errorLabel: UILabel = UILabel()
  private lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    tableView.dataSource = self
    return tableView
  }()
  private lazy var placeClient: GMSPlacesClient = GMSPlacesClient.shared()
  private var areLocationServicesEnabledAndAuthorized: Bool {
    guard CLLocationManager.locationServicesEnabled() else {
      return false
    }

    let status = CLLocationManager.authorizationStatus()
    return status == .authorizedAlways || status == .authorizedWhenInUse
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.navigationBar.isTranslucent = false
    view.backgroundColor = .white
    let button = UIButton()
    button.setTitle("Find from current location", for: .normal)
    button.setTitleColor(.blue, for: .normal)
    button.addTarget(
      self, action: #selector(loadLikelihoodFromCurrentLocation), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(button)
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
      button.heightAnchor.constraint(equalToConstant: 40),
      button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
    ])

    errorLabel.isHidden = true
    errorLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(errorLabel)
    NSLayoutConstraint.activate([
      errorLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: padding),
      errorLabel.heightAnchor.constraint(equalToConstant: 40),
      errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
    ])

    tableView.isHidden = true
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: padding),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    loadLikelihoodFromCurrentLocation()
  }

  @objc func loadLikelihoodFromCurrentLocation() {
    guard areLocationServicesEnabledAndAuthorized else {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    locationManager.startUpdatingLocation()

    placeClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: .all) {
      [weak self] (list, error) -> Void in
      guard let strongSelf = self else { return }
      guard error == nil else {
        strongSelf.errorLabel.text = "There was an error fetching likelihoods."
        strongSelf.errorLabel.isHidden = false
        strongSelf.tableView.isHidden = true
        return
      }

      strongSelf.placeLikelihoods = list?.filter { likelihood in
        !(likelihood.place.name?.isEmpty ?? true)
      }

      strongSelf.errorLabel.isHidden = true
      strongSelf.tableView.isHidden = false
      strongSelf.tableView.reloadData()
    }
  }
}

extension FindPlaceLikelihoodListViewController: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    if status == .authorizedWhenInUse {
      // Retry current location fetch once user enables Location Services.
      loadLikelihoodFromCurrentLocation()
    } else {
      errorLabel.text = "Please make sure location services are enabled."
    }
  }
}

extension FindPlaceLikelihoodListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let likelihoods = placeLikelihoods else {
      return 0
    }
    return likelihoods.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    cell.textLabel?.numberOfLines = 0
    cell.selectionStyle = .none
    guard let likelihoods = placeLikelihoods else {
      return cell
    }
    if likelihoods.count >= 0 && indexPath.row < likelihoods.count {
      cell.textLabel?.text = likelihoods[indexPath.row].place.name
    }
    return cell
  }
}
