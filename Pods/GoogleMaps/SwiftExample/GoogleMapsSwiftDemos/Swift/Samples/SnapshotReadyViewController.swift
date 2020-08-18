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

class SnapshotReadyViewController: UIViewController {
  lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 6)
    return GMSMapView(frame: .zero, camera: camera)
  }()
  private lazy var statusLabel: UILabel = UILabel()
  private lazy var waitButton: UIBarButtonItem = UIBarButtonItem()
  private var isAwaitingSnapshot = false {
    didSet {
      waitButton.isEnabled = !isAwaitingSnapshot
      if isAwaitingSnapshot {
        waitButton.title = "Waiting"
      } else {
        waitButton.title = "Wait for snapshot"
      }
    }
  }

  override func loadView() {
    view = mapView

    mapView.delegate = self

    // Add status label, initially hidden.
    statusLabel.alpha = 0
    statusLabel.autoresizingMask = .flexibleWidth
    statusLabel.backgroundColor = .blue
    statusLabel.textColor = .white
    statusLabel.textAlignment = .center
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      statusLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      statusLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      statusLabel.heightAnchor.constraint(equalToConstant: 30),
    ])
    if #available(iOS 11, *) {
      NSLayoutConstraint.activate([
        statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
      ])
    } else {
      NSLayoutConstraint.activate([
        statusLabel.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor)
      ])
    }

    // Add a wait button to signify on the next SnapshotReady event, a screenshot of the map will
    // be taken.
    waitButton = UIBarButtonItem(
      title: "Wait for snapshot", style: .plain, target: self, action: #selector(didTapWait))
    navigationItem.rightBarButtonItem = waitButton

  }

  @objc func didTapWait() {
    isAwaitingSnapshot = true
  }

  func takeSnapshot() {
    // Take a snapshot of the map.
    UIGraphicsBeginImageContextWithOptions(mapView.bounds.size, true, 0)
    mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
    let mapSnapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    // Put snapshot image into an UIImageView and overlay on top of map.
    let imageView = UIImageView(image: mapSnapshot)
    imageView.layer.borderColor = UIColor.red.cgColor
    imageView.layer.borderWidth = 10
    mapView.addSubview(imageView)

    // Remove imageView after 1 second.
    DispatchQueue.main.asyncAfter(
      deadline: .now() + 1
    ) {
      UIView.animate(
        withDuration: 1,
        animations: {
          imageView.alpha = 0
        },
        completion: { _ in
          imageView.removeFromSuperview()
        })
    }
  }

}

extension SnapshotReadyViewController: GMSMapViewDelegate {

  func mapViewSnapshotReady(_ mapView: GMSMapView) {
    if isAwaitingSnapshot {
      isAwaitingSnapshot = false
      takeSnapshot()
    }

    statusLabel.alpha = 0.8
    statusLabel.text = "Snapshot Ready"
    // Remove status label after 1 second.
    DispatchQueue.main.asyncAfter(
      deadline: .now() + 1
    ) {
      self.statusLabel.alpha = 0
    }
  }

}
