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

class IndoorViewController: UIViewController {

  let mapStyleOptions: [SampleMapStyle] = [.retro, .grayscale, .night, .normal]
  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: 37.78318, longitude: -122.403874, zoom: 18)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.settings.myLocationButton = true
    return mapView
  }()

  override func loadView() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Style", style: .plain, target: self, action: #selector(changeMapStyle(_:)))

    view = mapView
  }

  func alertAction(_ sampleMapStyle: SampleMapStyle) -> UIAlertAction {
    return UIAlertAction(title: sampleMapStyle.description, style: .default) { [weak self] _ in
      self?.mapView.mapStyle = sampleMapStyle.mapStyle
    }
  }

  @objc func changeMapStyle(_ sender: UIBarButtonItem) {
    let alert = UIAlertController(
      title: "Select map style", message: nil, preferredStyle: .actionSheet)
    for style in mapStyleOptions {
      alert.addAction(alertAction(style))
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.popoverPresentationController?.barButtonItem = sender
    present(alert, animated: true, completion: nil)
  }

}
