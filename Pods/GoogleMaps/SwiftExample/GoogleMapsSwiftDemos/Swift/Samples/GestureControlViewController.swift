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

class GestureControlViewController: UIViewController {
  private let holderHeight: CGFloat = 60
  private let zoomLabelInset: CGFloat = 16

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -25.5605, longitude: 133.605097, zoom: 3)
    return GMSMapView(frame: .zero, camera: camera)
  }()
  private lazy var zoomSwitch: UISwitch = UISwitch(frame: .zero)

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(mapView)

    let holder = UIView(frame: .zero)
    holder.backgroundColor = UIColor(white: 1, alpha: 0.8)
    view.addSubview(holder)

    let zoomLabel = UILabel(frame: .zero)
    zoomLabel.text = "Zoom gestures"
    zoomLabel.font = .boldSystemFont(ofSize: 18)
    holder.addSubview(zoomLabel)

    // Control zooming.
    holder.addSubview(zoomSwitch)
    zoomSwitch.addTarget(self, action: #selector(toggleZoom), for: .valueChanged)
    zoomSwitch.isOn = true

    [mapView, holder, zoomLabel, zoomSwitch].forEach({
      $0.translatesAutoresizingMaskIntoConstraints = false
    })
    NSLayoutConstraint.activate([
      mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
      mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
      mapView.topAnchor.constraint(equalTo: view.topAnchor),
      mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      holder.heightAnchor.constraint(equalToConstant: holderHeight),
      holder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      holder.widthAnchor.constraint(equalTo: view.widthAnchor),
      zoomLabel.leftAnchor.constraint(equalTo: holder.leftAnchor, constant: zoomLabelInset),
      zoomLabel.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
      zoomSwitch.rightAnchor.constraint(equalTo: holder.rightAnchor, constant: -zoomLabelInset),
      zoomSwitch.centerYAnchor.constraint(
        equalTo: holder.centerYAnchor),
    ])
    NSLayoutConstraint.activate([
      holder.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
    ])
  }

  @objc func toggleZoom() {
    mapView.settings.zoomGestures = zoomSwitch.isOn
  }

}
