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

class PaddingBehaviorViewController: UIViewController {

  private static let panoramaCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
    latitude: 40.761388, longitude: -73.978133)

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 6)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.padding = UIEdgeInsets(top: 0, left: 20, bottom: 40, right: 60)
    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return mapView
  }()
  private lazy var panoramaView: GMSPanoramaView = GMSPanoramaView()
  lazy private var statusLabel: UILabel = UILabel()
  lazy private var changeBehaviorButton: UIButton = UIButton(type: .system)
  lazy private var toggleViewButton: UIBarButtonItem = UIBarButtonItem(
    title: "Toggle View", style: .plain, target: self, action: #selector(toggleViewType))
  lazy private var toggleFrameButton: UIButton = UIButton(type: .system)
  var hasShrunk = false

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.frame = view.bounds
    view.addSubview(mapView)

    // Add status label.
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    let navigationHeight = navigationController?.navigationBar.frame.height ?? 0
    let topYOffset = statusBarHeight + navigationHeight
    statusLabel.frame = CGRect(x: 30, y: topYOffset, width: 0, height: 30)
    statusLabel.textColor = .brown
    statusLabel.textAlignment = .left
    statusLabel.text = "Behavior: Always"
    statusLabel.sizeToFit()

    // Add behavior modifier button.
    changeBehaviorButton.frame = CGRect(x: 30, y: 30 + topYOffset, width: 0, height: 0)
    changeBehaviorButton.setTitle("Next Behavior", for: .normal)
    changeBehaviorButton.sizeToFit()
    changeBehaviorButton.addTarget(self, action: #selector(nextBehavior), for: .touchUpInside)

    // Add frame animation button.
    navigationItem.rightBarButtonItem = toggleViewButton

    // Add change view type button.
    toggleFrameButton.frame = CGRect(x: 30, y: 60 + topYOffset, width: 0, height: 0)
    toggleFrameButton.setTitle("Animate Frame", for: .normal)
    toggleFrameButton.sizeToFit()
    toggleFrameButton.addTarget(self, action: #selector(toggleFrame), for: .touchUpInside)

    mapView.addSubview(statusLabel)
    mapView.addSubview(changeBehaviorButton)
    mapView.addSubview(toggleFrameButton)

    hasShrunk = false

    // Pre-load PanoramaView
    panoramaView = GMSPanoramaView.panorama(
      withFrame: view.bounds, nearCoordinate: PaddingBehaviorViewController.panoramaCoordinate)
    panoramaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  @objc func toggleFrame() {
    let size = view.bounds.size
    let point = view.bounds.origin
    UIView.animate(withDuration: 2) { [unowned self] in
      if self.hasShrunk {
        self.mapView.frame = self.view.bounds
        self.panoramaView.frame = self.mapView.frame
      } else {
        self.mapView.frame = CGRect(
          x: point.x, y: point.y, width: size.width / 2, height: size.height / 2)
        self.panoramaView.frame = self.mapView.frame
      }
      self.hasShrunk = !self.hasShrunk
      self.view.setNeedsLayout()
      self.view.layoutIfNeeded()
    }
  }

  @objc func toggleViewType() {
    if view.subviews.contains(mapView) {
      mapView.removeFromSuperview()
      view.addSubview(panoramaView)
      panoramaView.addSubview(toggleFrameButton)
    } else {
      panoramaView.removeFromSuperview()
      view.addSubview(mapView)
      mapView.addSubview(toggleFrameButton)
    }
  }

  @objc func nextBehavior() {
    switch mapView.paddingAdjustmentBehavior {
    case .always:
      mapView.paddingAdjustmentBehavior = .automatic
      statusLabel.text = "Behavior: Automatic"
    case .automatic:
      mapView.paddingAdjustmentBehavior = .never
      statusLabel.text = "Behavior: Never"
    default:
      mapView.paddingAdjustmentBehavior = .always
      statusLabel.text = "Behavior: Always"
    }
  }

}
