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

class MapTypesViewController: UIViewController {
  private let types: [GMSMapViewType] = [.normal, .satellite, .hybrid, .terrain]

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(target: .sydney, zoom: 12)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  private lazy var segmentedControl: UISegmentedControl = {
    return UISegmentedControl(items: types.map { "\($0)" })
  }()

  override func loadView() {
    view = mapView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    segmentedControl.addTarget(self, action: #selector(changeMapType), for: .valueChanged)
    navigationItem.titleView = segmentedControl
  }

  @objc func changeMapType(_ sender: UISegmentedControl) {
    mapView.mapType = types[sender.selectedSegmentIndex]
  }
}

extension GMSMapViewType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .normal:
      return "Normal"
    case .satellite:
      return "Satellite"
    case .hybrid:
      return "Hybrid"
    case .terrain:
      return "Terrain"
    default:
      return ""
    }
  }
}
