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
class CustomMarkersViewController: UIViewController {
  private var markerCount = 0

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -37.81969, longitude: 144.966085, zoom: 4)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  override func loadView() {
    view = mapView
    addDefaultMarkers()
    navigationController?.navigationBar.isTranslucent = false
    let addButton = UIBarButtonItem(
      barButtonSystemItem: .add, target: self, action: #selector(tapAdd))
    let clearButton = UIBarButtonItem(
      title: "Clear Markers", style: .plain, target: self, action: #selector(tapClear))
    navigationItem.rightBarButtonItems = [addButton, clearButton]
  }

  func addDefaultMarkers() {
    // Add a custom 'glow' marker around Sydney.
    let sydneyMarker = GMSMarker(
      position: CLLocationCoordinate2D(latitude: -33.8683, longitude: 151.2086))
    sydneyMarker.title = "Sydney!"
    sydneyMarker.icon = UIImage(named: "glow-marker")
    sydneyMarker.map = mapView

    // Add a custom 'arrow' marker pointing to Melbourne.
    let melbourneMarker = GMSMarker(
      position: CLLocationCoordinate2D(latitude: -37.81969, longitude: 144.966085))
    melbourneMarker.title = "Melbourne!"
    melbourneMarker.icon = UIImage(named: "arrow")
    melbourneMarker.map = mapView
  }

  @objc func tapAdd() {
    let bounds = GMSCoordinateBounds(region: mapView.projection.visibleRegion())
    // Add a marker every 0.25 seconds for the next ten markers, randomly
    // within the bounds of the camera as it is at that point.
    for count in 1...10 {
      DispatchQueue.main.asyncAfter(
        deadline: .now() + Double(count) * 0.25,
        execute: {
          self.addMarker(inBounds: bounds)
        })
    }
  }

  @objc func tapClear() {
    mapView.clear()
    addDefaultMarkers()
  }

  @objc func addMarker(inBounds bounds: GMSCoordinateBounds) {
    let coordinate = bounds.randomLocation()
    let marker = GMSMarker(
      position: CLLocationCoordinate2D(
        latitude: coordinate.latitude, longitude: coordinate.longitude))
    markerCount += 1
    marker.title = "Marker #\(markerCount)"
    marker.appearAnimation = .pop
    marker.icon = GMSMarker.markerImage(
      with: UIColor(hue: CGFloat.random(in: 0..<1), saturation: 1, brightness: 1, alpha: 1))
    marker.rotation = Double.random(in: -10...10)
    marker.map = mapView
  }
}

extension GMSCoordinateBounds {
  func randomLocation() -> CLLocationCoordinate2D {
    let randomLatitude = CLLocationDegrees.random(
      in: southWest.latitude..<northEast.latitude)
    // If the visible region crosses the antimeridian (the right-most point is
    // "smaller" than the left-most point), adjust the longitude accordingly.
    var maxLongitude = northEast.longitude
    if maxLongitude < southWest.longitude { maxLongitude += 360 }
    let randomLongitude = CLLocationDegrees.random(in: southWest.longitude..<maxLongitude)
    return CLLocationCoordinate2D(
      latitude: randomLatitude, longitude: randomLongitude.remainder(dividingBy: 360))
  }
}
