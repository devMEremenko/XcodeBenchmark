/*
* Copyright 2020 Google LLC. All rights reserved.
*
*
* Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
* file except in compliance with the License. You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software distributed under
* the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
* ANY KIND, either express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

import GoogleMaps
import UIKit

class FrameRateViewController: UIViewController {

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 6)
    return GMSMapView(frame: .zero, camera: camera)
  }()
  private lazy var statusTextView: UITextView = UITextView()

  override func loadView() {
    view = mapView

    statusTextView.text = ""
    statusTextView.textAlignment = .center
    statusTextView.backgroundColor = UIColor(white: 1, alpha: 0.8)
    statusTextView.isEditable = false
    view.addSubview(statusTextView)
    statusTextView.sizeToFit()

    // Add a button toggling through modes.
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .play, target: self, action: #selector(changeFrameRate))

    updateStatus()

    statusTextView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      statusTextView.leftAnchor.constraint(equalTo: view.leftAnchor),
      statusTextView.rightAnchor.constraint(equalTo: view.rightAnchor),
      statusTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
    ])
    if #available(iOS 11, *) {
      NSLayoutConstraint.activate([
        statusTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
      ])
    } else {
      NSLayoutConstraint.activate([
        statusTextView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor)
      ])
    }
  }

  @objc func changeFrameRate() {
    mapView.preferredFrameRate = nextFrameRate()
    updateStatus()
  }

  func nextFrameRate() -> GMSFrameRate {
    switch mapView.preferredFrameRate {
    case .powerSave:
      return .conservative
    case .conservative:
      return .maximum
    default:
      return .powerSave
    }
  }

  func updateStatus() {
    statusTextView.text = "Preferred frame rate: \(mapView.preferredFrameRate.name)"
  }

}

extension GMSFrameRate {

  var name: String {
    switch self {
    case .powerSave:
      return "PowerSave"
    case .conservative:
      return "Conservative"
    default:
      return "Maximum"
    }
  }

}
