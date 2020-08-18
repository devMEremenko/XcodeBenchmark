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

class MapLayerViewController: UIViewController {
  private let duration: TimeInterval = 2

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(target: .victoria, zoom: 4)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  override func loadView() {
    mapView.isMyLocationEnabled = true
    view = mapView

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Fly to My Location", style: .plain, target: self, action: #selector(tapMyLocation))
  }

  @objc func tapMyLocation() {
    guard let location = mapView.myLocation, CLLocationCoordinate2DIsValid(location.coordinate)
    else {
      return
    }
    mapView.layer.cameraLatitude = location.coordinate.latitude
    mapView.layer.cameraLongitude = location.coordinate.longitude
    mapView.layer.cameraBearing = 0

    // Access the GMSMapLayer directly to modify the following properties with a
    // specified timing function and duration.
    addMapViewAnimation(key: kGMSLayerCameraLatitudeKey, toValue: location.coordinate.latitude)
    addMapViewAnimation(key: kGMSLayerCameraLongitudeKey, toValue: location.coordinate.longitude)
    addMapViewAnimation(key: kGMSLayerCameraBearingKey, toValue: 0)

    // Fly out to the minimum zoom and then zoom back to the current zoom!
    let keyFrameAnimation = CAKeyframeAnimation(keyPath: kGMSLayerCameraZoomLevelKey)
    keyFrameAnimation.duration = duration
    let zoom = mapView.camera.zoom
    keyFrameAnimation.values = [zoom, kGMSMinZoomLevel, zoom]
    mapView.layer.add(keyFrameAnimation, forKey: kGMSLayerCameraZoomLevelKey)
  }

  func addMapViewAnimation(key: String, toValue: Double) {
    let animation = CABasicAnimation(keyPath: key)
    animation.duration = duration
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.toValue = toValue
    mapView.layer.add(animation, forKey: key)
  }
}
