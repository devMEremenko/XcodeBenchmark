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

class TrafficMapViewController: UIViewController {

  private var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 12)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.isTrafficEnabled = true
    return mapView
  }()

  override func loadView() {
    view = mapView
  }

}
