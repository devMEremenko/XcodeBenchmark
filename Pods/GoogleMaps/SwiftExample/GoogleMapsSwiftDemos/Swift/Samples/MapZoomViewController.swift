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

enum ModeEnum: String {
  case defaultMode = "Default"
  case zoomedIn = "Zoomed in"
  case zoomedOut = "Zoomed out"
  case smallRange = "Small range"

  init(index: UInt) {
    switch index {
    case 0: self = .defaultMode
    case 1: self = .zoomedIn
    case 2: self = .zoomedOut
    case 3: self = .smallRange
    default: self = .defaultMode
    }
  }

  var minZoom: Float {
    switch self {
    case .zoomedIn:
      return 18
    case .smallRange:
      return 10
    default:
      return kGMSMinZoomLevel
    }
  }

  var maxZoom: Float {
    switch self {
    case .zoomedOut:
      return 8
    case .smallRange:
      return 11.5
    default:
      return kGMSMaxZoomLevel
    }
  }

}

class MapZoomViewController: UIViewController {

  private let backgroundColor = UIColor(white: 1, alpha: 0.8)

  private let zoomRangeViewHeight: CGFloat = 30

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 6)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.settings.scrollGestures = false
    return mapView
  }()

  private lazy var zoomRangeView: UITextView = {
    let view = UITextView()
    view.text = ""
    view.textAlignment = .center
    view.backgroundColor = backgroundColor
    view.autoresizingMask = .flexibleWidth
    view.isEditable = false
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private var nextMode: UInt = 0

  override func loadView() {
    view = mapView
    navigationController?.navigationBar.isTranslucent = false
    // Add a display for the current zoom range restriction.
    view.addSubview(zoomRangeView)
    NSLayoutConstraint.activate([
      zoomRangeView.topAnchor.constraint(equalTo: view.topAnchor),
      zoomRangeView.heightAnchor.constraint(equalToConstant: zoomRangeViewHeight),
      zoomRangeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      zoomRangeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    didTapNext()

    // Add a button toggling through modes.
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .play, target: self, action: #selector(didTapNext))
  }

  @objc func didTapNext() {
    let nextModeEnum = ModeEnum(index: nextMode)
    mapView.setMinZoom(nextModeEnum.minZoom, maxZoom: nextModeEnum.maxZoom)
    zoomRangeView.text = String(
      format: "%@ (%.2f - %.2f)", nextModeEnum.rawValue, mapView.minZoom, mapView.maxZoom)
    nextMode = (nextMode + 1) % 4
  }

}
