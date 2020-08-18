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

class FitBoundsViewController: UIViewController {

  private let markerImageName = "glow-marker"

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(target: .victoria, zoom: 4)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  // Creates a list of markers, adding the Sydney marker.
  private lazy var markers: [GMSMarker] = {
    // Adds default markers around Sydney.
    let sydneyMarker = GMSMarker(position: .sydney)
    sydneyMarker.title = "Sydney!"
    sydneyMarker.icon = UIImage(named: markerImageName)
    sydneyMarker.map = mapView

    let anotherSydneyMarker = GMSMarker()
    anotherSydneyMarker.title = "Sydney 2!"
    anotherSydneyMarker.icon = UIImage(named: markerImageName)
    anotherSydneyMarker.position = .sydney
    anotherSydneyMarker.map = mapView
    return [sydneyMarker, anotherSydneyMarker]
  }()

  override func loadView() {
    mapView.delegate = self
    view = mapView

    // Creates a button that, when pressed, updates the camera to fit the bounds.
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Fit Bounds", style: .plain, target: self, action: #selector(fitBounds))
  }

  @objc func fitBounds() {
    var bounds = GMSCoordinateBounds()
    for marker in markers {
      bounds = bounds.includingCoordinate(marker.position)
    }
    guard bounds.isValid else { return }
    mapView.moveCamera(GMSCameraUpdate.fit(bounds, withPadding: 50))
  }
}

extension FitBoundsViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
    let marker = GMSMarker(position: coordinate)
    marker.title = "Marker at: \(coordinate.latitude), \(coordinate.longitude)"
    marker.appearAnimation = .pop
    marker.map = mapView
    markers.append(marker)
  }
}
