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

struct Exhibit: Decodable {
  let key: String
  let name: String
  let latitude: Double
  let longitude: Double
  let level: String

  private enum CodingKeys: String, CodingKey {
    case key, name
    case latitude = "lat"
    case longitude = "lng"
    case level
  }

  var position: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

class IndoorMuseumNavigationViewController: UIViewController {
  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: 38.8879, longitude: -77.0200, zoom: 17)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.settings.myLocationButton = false
    mapView.settings.indoorPicker = false
    return mapView
  }()
  private lazy var segmentedControl = UISegmentedControl()
  private var exhibits: [Exhibit]?
  private var selectedExhibit: Exhibit?
  private var selectedExhibitMarker: GMSMarker?
  private var sampleLevels: [SampleLevel] = []

  override func loadView() {
    view = mapView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self
    mapView.indoorDisplay.delegate = self

    segmentedControl.tintColor = UIColor(red: 0.373, green: 0.667, blue: 0.882, alpha: 1.0)
    segmentedControl.translatesAutoresizingMaskIntoConstraints = false
    segmentedControl.addTarget(
      self, action: #selector(changeExhibit), for: .valueChanged)
    view.addSubview(segmentedControl)

    NSLayoutConstraint.activate([
      segmentedControl.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      segmentedControl.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
    ])

    // Load the exhibits configuration from JSON
    if let jsonPath = Bundle.main.path(forResource: "museum-exhibits", ofType: "json") {
      if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
        exhibits = try? JSONDecoder().decode([Exhibit].self, from: data)
      }
    }

    if let exhibits = exhibits {
      for (i, exhibit) in exhibits.enumerated() {
        segmentedControl.insertSegment(
          with: UIImage(named: exhibit.key), at: i, animated: false)
      }
    }
  }

  func moveMarker() {
    guard let selectedExhibit = selectedExhibit else {
      return
    }

    if let selectedExhibitMarker = selectedExhibitMarker {
      selectedExhibitMarker.position = selectedExhibit.position
    } else {
      selectedExhibitMarker = GMSMarker(position: selectedExhibit.position)
      selectedExhibitMarker?.map = mapView
    }
    selectedExhibitMarker?.title = selectedExhibit.name
    mapView.animate(toLocation: selectedExhibit.position)
    mapView.animate(toZoom: 19)
  }

  @objc func changeExhibit() {
    guard let exhibits = exhibits else {
      return
    }

    selectedExhibit = exhibits[segmentedControl.selectedSegmentIndex]
    moveMarker()
  }

}

extension IndoorMuseumNavigationViewController: GMSMapViewDelegate {

  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    guard let selectedExhibit = selectedExhibit,
      let selectedSampleLevel = sampleLevels.first(where: { $0.shortName == selectedExhibit.level }
      ),
      let activeLevel = selectedSampleLevel.indoorLevel
    else {
      return
    }

    if mapView.projection.contains(selectedExhibit.position) {
      mapView.indoorDisplay.activeLevel = activeLevel
    }
  }

}

extension IndoorMuseumNavigationViewController: GMSIndoorDisplayDelegate {

  func didChangeActiveBuilding(_ building: GMSIndoorBuilding?) {
    guard let building = building else {
      return
    }

    var sampleLevels: [SampleLevel] = []
    sampleLevels.append(contentsOf: building.levels.map({ .actualLevel($0) }))
    self.sampleLevels = sampleLevels
  }

}
