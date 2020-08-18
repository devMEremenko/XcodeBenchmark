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

// Sample code for customizing the marker.
class AnimatedUIViewMarkerViewController: UIViewController {

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.8683, longitude: 151.2086, zoom: 5)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  private var infoView: UIImageView?

  override func loadView() {
    view = mapView
    mapView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    mapView.clear()
    addDefaultMarkers()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.addObserver(
      self, selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification, object: nil)
  }

  @objc func applicationWillEnterForeground() {
    mapView.clear()
    addDefaultMarkers()
  }

  func addDefaultMarkers() {
    // Add a custom 'glow' marker with a pulsing blue shadow on Sydney.
    let sydneyMarker = GMSMarker(
      position: CLLocationCoordinate2D(latitude: -33.8683, longitude: 151.2086))
    sydneyMarker.title = "Sydney!"
    sydneyMarker.iconView = UIImageView(image: UIImage(named: "glow-marker"))
    sydneyMarker.iconView?.contentMode = .center
    sydneyMarker.map = mapView
    guard let oldBounds = sydneyMarker.iconView?.bounds else { return }
    sydneyMarker.iconView?.bounds = CGRect(
      origin: oldBounds.origin,
      size: CGSize(width: oldBounds.size.width * 2, height: oldBounds.size.height * 2))
    sydneyMarker.groundAnchor = CGPoint(x: 0.5, y: 0.75)
    sydneyMarker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.25)
    let sydneyGlow = UIImageView(image: UIImage(named: "glow-marker"))
    sydneyGlow.layer.shadowColor = UIColor.blue.cgColor
    sydneyGlow.layer.shadowOffset = .zero
    sydneyGlow.layer.shadowRadius = 8
    sydneyGlow.layer.shadowOpacity = 1.0
    sydneyGlow.layer.opacity = 0.0
    sydneyMarker.iconView?.addSubview(sydneyGlow)
    sydneyGlow.center = CGPoint(x: oldBounds.size.width, y: oldBounds.size.height)
    UIView.animate(
      withDuration: 1, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat],
      animations: {
        sydneyGlow.layer.opacity = 1.0
      },
      completion: { _ in
        // If the animation is ever terminated, no need to keep tracking the view for changes.
        sydneyMarker.tracksViewChanges = false
      })
  }
}

extension AnimatedUIViewMarkerViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
    marker.tracksInfoWindowChanges = true
    let infoView = UIImageView(image: UIImage(named: "arrow"))
    infoView.backgroundColor = .clear
    UIView.animate(
      withDuration: 1, delay: 0, options: [.curveLinear],
      animations: {
        infoView.backgroundColor = UIColor(
          hue: CGFloat.random(in: 0..<1), saturation: 1, brightness: 1, alpha: 1)
      },
      completion: { _ in
        UIView.animate(
          withDuration: 1, delay: 0, options: [.curveLinear],
          animations: {
            infoView.backgroundColor = .clear
          },
          completion: { _ in
            marker.tracksInfoWindowChanges = false
          })
      })
    self.infoView = infoView
    return infoView
  }

  func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
    infoView = nil
    marker.tracksInfoWindowChanges = false
  }
}
