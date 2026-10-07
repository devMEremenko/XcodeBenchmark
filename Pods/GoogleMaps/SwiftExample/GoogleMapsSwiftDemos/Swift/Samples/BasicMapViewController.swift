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

class BasicMapViewController: UIViewController {
  var statusLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Seattle coordinates
    let camera = GMSCameraPosition(latitude: 47.6089945, longitude: -122.3410462, zoom: 14)
    let mapView = GMSMapView(frame: view.bounds, camera: camera)
    mapView.delegate = self
    view = mapView
    navigationController?.navigationBar.isTranslucent = false

    statusLabel = UILabel(frame: .zero)
    statusLabel.alpha = 0.0
    statusLabel.backgroundColor = .blue
    statusLabel.textColor = .white
    statusLabel.textAlignment = .center
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: view.topAnchor),
      statusLabel.heightAnchor.constraint(equalToConstant: 30),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }
}

extension BasicMapViewController: GMSMapViewDelegate {
  func mapViewDidStartTileRendering(_ mapView: GMSMapView) {
    statusLabel.alpha = 0.8
    statusLabel.text = "Rendering"
  }

  func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
    statusLabel.alpha = 0.0
  }
}
