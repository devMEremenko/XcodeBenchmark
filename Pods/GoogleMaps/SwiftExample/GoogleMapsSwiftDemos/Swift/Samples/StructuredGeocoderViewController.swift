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

// Sample code for GeoCoder service.
class StructuredGeocoderViewController: UIViewController {

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: -33.868, longitude: 151.2086, zoom: 12)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  private lazy var geocoder = GMSGeocoder()

  override func loadView() {
    view = mapView
    mapView.delegate = self
  }

}

extension StructuredGeocoderViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
    // On a long press, reverse geocode this location.
    geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
      guard let address = response?.firstResult() else {
        let errorMessage = error.map { String(describing: $0) } ?? "<no error>"
        print(
          """
          Could not reverse geocode point (\(coordinate.latitude), \(coordinate.longitude)): \
           \(errorMessage)
          """
        )
        return
      }
      print("Geocoder result: \(address)")
      let marker = GMSMarker(position: address.coordinate)
      marker.appearAnimation = .pop
      marker.map = mapView
      marker.title = address.thoroughfare
      mapView.selectedMarker = marker

      var snippet = ""
      if let subLocality = address.subLocality {
        snippet.append("subLocality: \(subLocality)\n")
      }
      if let locality = address.locality {
        snippet.append("locality: \(locality)\n")
      }
      if let administrativeArea = address.administrativeArea {
        snippet.append("administrativeArea: \(administrativeArea)\n")
      }
      if let country = address.country {
        snippet.append("country: \(country)\n")
      }
      marker.snippet = snippet
    }
  }
}
