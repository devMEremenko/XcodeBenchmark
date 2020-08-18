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

final class MarkerInfoWindowViewController: UIViewController {

  private let sydneyMarker = GMSMarker(
    position: CLLocationCoordinate2D(latitude: -33.8683, longitude: 151.2086))

  private let melbourneMarker = GMSMarker(
    position: CLLocationCoordinate2D(latitude: -37.81969, longitude: 144.966085))

  private let brisbaneMarker = GMSMarker(
    position: CLLocationCoordinate2D(latitude: -27.4710107, longitude: 153.0234489))

  private lazy var contentView: UIImageView = {
    return UIImageView(image: UIImage(named: "aeroplane"))
  }()

  override func loadView() {
    let cameraPosition = GMSCameraPosition(latitude: -37.81969, longitude: 144.966085, zoom: 4)
    let mapView = GMSMapView(frame: .zero, camera: cameraPosition)
    mapView.delegate = self
    view = mapView

    sydneyMarker.title = "Sydney"
    sydneyMarker.snippet = "Population: 4,605,992"
    sydneyMarker.map = mapView

    melbourneMarker.title = "Melbourne"
    melbourneMarker.snippet = "Population: 4,169,103"
    melbourneMarker.map = mapView

    brisbaneMarker.title = "Brisbane"
    brisbaneMarker.snippet = "Population: 2,189,878"
    brisbaneMarker.map = mapView
  }
}

extension MarkerInfoWindowViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
    if marker == sydneyMarker {
      return contentView
    }
    return nil
  }

  func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
    if marker == brisbaneMarker {
      return contentView
    }
    return nil
  }

  func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
    showToast(message: "Info window for marker \(marker.title ?? "") closed.")
  }

  func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
    showToast(message: "Info window for marker \(marker.title ?? "") long pressed.")
  }
}

extension UIViewController {
  func showToast(message: String) {
    let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(
      toast, animated: true,
      completion: {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
          toast.dismiss(animated: true)
        }
      })
  }
}
