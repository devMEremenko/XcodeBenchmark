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

final class PolylinesViewController: UIViewController {
  private lazy var styles: [GMSStrokeStyle] = {
    let greenStyle = GMSStrokeStyle.gradient(from: .green, to: UIColor.green.withAlphaComponent(0))
    let redStyle = GMSStrokeStyle.gradient(from: UIColor.red.withAlphaComponent(0), to: .red)
    return [greenStyle, redStyle, GMSStrokeStyle.solidColor(UIColor(white: 0, alpha: 0))]
  }()
  private var pathLength: Double = 0
  private var pos: Double = 0
  private var polylines: [GMSPolyline] = []

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -30, longitude: -175, zoom: 3)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  override func loadView() {
    view = mapView
    mapView.accessibilityElementsHidden = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var path = GMSMutablePath()
    path.addLatitude(-33.866901, longitude: 151.195988)
    path.addLatitude(-18, longitude: 179)
    path.addLatitude(21.291982, longitude: -157.821856)
    path.addLatitude(37.423802, longitude: -122.091859)
    path.addLatitude(-12, longitude: -77)
    path.addLatitude(-33.866901, longitude: 151.195988)
    path = path.pathOffset(byLatitude: -30, longitude: 0)
    pathLength = path.length(of: .geodesic) / 21
    for i in 0..<30 {
      let polyline = GMSPolyline(path: path.pathOffset(byLatitude: Double(i) * 1.5, longitude: 0))
      polyline.strokeWidth = 8
      polyline.geodesic = true
      polyline.map = mapView
      polylines.append(polyline)
    }
    animatePath()
  }

  // Updates the path style every 0.1 seconds.
  private func animatePath() {
    polylines.forEach {
      if let path = $0.path {
        $0.spans = GMSStyleSpansOffset(path, styles, [NSNumber(value: pathLength)], .geodesic, pos)
      }
    }
    pos -= 50000

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      self.animatePath()
    }
  }
}
