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

class DoubleMapViewController: UIViewController {

  private lazy var sanFranciscoCamera = GMSCameraPosition(
    latitude: 37.7847, longitude: -122.41, zoom: 5)
  private lazy var mapView: GMSMapView = {
    let mapView = GMSMapView(frame: .zero, camera: sanFranciscoCamera)
    return mapView
  }()
  private lazy var boundMapView: GMSMapView = {
    let mapView = GMSMapView(frame: .zero, camera: sanFranciscoCamera)
    return mapView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self
    mapView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(mapView)

    boundMapView.settings.scrollGestures = false
    boundMapView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(boundMapView)

    NSLayoutConstraint.activate([
      mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
      mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
      boundMapView.leftAnchor.constraint(equalTo: view.leftAnchor),
      boundMapView.rightAnchor.constraint(equalTo: view.rightAnchor),
      mapView.topAnchor.constraint(equalTo: view.topAnchor),
      boundMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
      boundMapView.topAnchor.constraint(equalTo: mapView.bottomAnchor),
    ])
  }

}

extension DoubleMapViewController: GMSMapViewDelegate {

  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    let previousCamera = boundMapView.camera
    boundMapView.camera = GMSCameraPosition(
      target: position.target, zoom: previousCamera.zoom, bearing: previousCamera.bearing,
      viewingAngle: previousCamera.viewingAngle)
  }

}
