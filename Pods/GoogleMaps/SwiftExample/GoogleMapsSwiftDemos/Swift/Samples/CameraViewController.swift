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

class CameraViewController: UIViewController {

  private let interval: TimeInterval = 1 / 30

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(target: .victoria, zoom: 20, bearing: 0, viewingAngle: 0)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  private var timer: Timer?

  override func loadView() {
    mapView.settings.zoomGestures = false
    mapView.settings.scrollGestures = false
    mapView.settings.rotateGestures = false
    mapView.settings.tiltGestures = false
    view = mapView
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Every 0.033 seconds, adjust the position of the camera.
    timer = Timer.scheduledTimer(
      timeInterval: interval, target: self, selector: #selector(moveCamera), userInfo: nil,
      repeats: true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    timer?.invalidate()
  }

  // Updates zoom and viewing angle, the map zoom out and the map appears in perspective, with
  // far-away features appearing smaller, and nearby features appearing larger.
  @objc func moveCamera() {
    let zoom = max(mapView.camera.zoom - 0.1, 17.5)
    let newPosition = GMSCameraPosition(
      target: mapView.camera.target, zoom: zoom, bearing: mapView.camera.bearing,
      viewingAngle: mapView.camera.viewingAngle + 10)
    mapView.animate(to: newPosition)
  }
}
