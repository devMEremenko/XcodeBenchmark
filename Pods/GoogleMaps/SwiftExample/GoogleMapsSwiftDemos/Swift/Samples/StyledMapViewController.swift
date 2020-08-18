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

class StyledMapViewController: UIViewController {
  lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 12)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  override func loadView() {
    view = mapView

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Style", style: .plain, target: self, action: #selector(changeMapStyle))

    updateUI(style: .retro)
  }

  func updateUI(style: SampleMapStyle) {
    navigationItem.title = "\(style)"
    mapView.mapStyle = style.mapStyle
  }

  @objc func changeMapStyle(_ sender: UIBarButtonItem) {
    let alert = UIAlertController(
      title: "Select map style", message: nil, preferredStyle: .actionSheet)
    for style in SampleMapStyle.allCases {
      alert.addAction(
        UIAlertAction(
          title: style.description, style: .default
        ) { _ in
          self.updateUI(style: style)
        })
    }
    present(alert, animated: true)
  }
}
