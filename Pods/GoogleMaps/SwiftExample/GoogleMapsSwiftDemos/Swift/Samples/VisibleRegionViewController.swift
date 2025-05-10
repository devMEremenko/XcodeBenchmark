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

class VisibleRegionViewController: UIViewController {

  static let overlayHeight: CGFloat = 140
  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -37.81969, longitude: 144.966085, zoom: 4)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.settings.myLocationButton = true
    mapView.isMyLocationEnabled = true
    mapView.padding = UIEdgeInsets(
      top: 0, left: 0, bottom: VisibleRegionViewController.overlayHeight, right: 0)
    return mapView
  }()
  private lazy var overlay: UIView = {
    let overlay = UIView(frame: .zero)
    overlay.backgroundColor = UIColor(hue: 0, saturation: 1, brightness: 1, alpha: 0.5)
    return overlay
  }()
  private lazy var flyInButton: UIBarButtonItem = {
    return UIBarButtonItem(
      title: "Toggle Overlay", style: .plain, target: self, action: #selector(didTapToggleOverlay))
  }()

  override func loadView() {
    view = mapView
    navigationItem.rightBarButtonItem = flyInButton

    let overlayFrame = CGRect(
      x: 0, y: -VisibleRegionViewController.overlayHeight, width: 0,
      height: VisibleRegionViewController.overlayHeight)
    overlay.frame = overlayFrame
    overlay.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
    view.addSubview(overlay)
  }

  @objc func didTapToggleOverlay() {
    let padding = mapView.padding
    UIView.animate(withDuration: 2) { [unowned self] in
      let size = self.view.bounds.size
      if padding.bottom == 0 {
        self.overlay.frame = CGRect(
          x: 0, y: size.height - VisibleRegionViewController.overlayHeight, width: size.width,
          height: VisibleRegionViewController.overlayHeight)
        self.mapView.padding = UIEdgeInsets(
          top: 0, left: 0, bottom: VisibleRegionViewController.overlayHeight, right: 0)
      } else {
        self.overlay.frame = CGRect(
          x: 0, y: self.mapView.bounds.size.height, width: size.width, height: 0)
        self.mapView.padding = .zero
      }
    }
  }

}
