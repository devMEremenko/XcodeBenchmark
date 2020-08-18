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

class PathIterator: IteratorProtocol {
  let path: GMSPath
  private var target: UInt

  init(path: GMSPath) {
    self.path = path
    target = 0
  }

  func next() -> CLLocationCoordinate2D? {
    target = (target + 1) % path.count()
    return path.coordinate(at: target)
  }
}

final class MarkerLayerViewController: UIViewController {

  private var fadedMarker: GMSMarker? {
    didSet {
      oldValue?.opacity = 1
      fadedMarker?.opacity = 0.5
    }
  }

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: 50.6042, longitude: 3.9599, zoom: 5)
    return GMSMapView(frame: .zero, camera: camera)
  }()

  override func loadView() {
    mapView.isMyLocationEnabled = true
    view = mapView
    mapView.delegate = self
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Creates a plane that flies to several airports around western Europe.
    var path = GMSMutablePath()
    path.addLatitude(52.310683, longitude: 4.765121)
    path.addLatitude(51.471386, longitude: -0.457148)
    path.addLatitude(49.01378, longitude: 2.5542943)
    path.addLatitude(50.036194, longitude: 8.554519)
    var marker = GMSMarker(position: path.coordinate(at: 0))
    marker.icon = UIImage(named: "aeroplane")
    marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
    marker.isFlat = true
    marker.map = mapView
    marker.userData = PathIterator(path: path)
    animateToNextCoordinate(marker)

    // Creates a boat that moves around the Baltic Sea.
    path = GMSMutablePath()
    path.addLatitude(57.598335, longitude: 11.290512)
    path.addLatitude(55.665193, longitude: 10.741196)
    path.addLatitude(55.065787, longitude: 11.083488)
    path.addLatitude(54.699234, longitude: 10.863762)

    path.addLatitude(54.482805, longitude: 12.061272)
    path.addLatitude(55.819802, longitude: 16.148186)
    path.addLatitude(54.927142, longitude: 16.455803)
    path.addLatitude(54.482805, longitude: 12.061272)

    path.addLatitude(54.699234, longitude: 10.863762)
    path.addLatitude(55.065787, longitude: 11.083488)
    path.addLatitude(55.665193, longitude: 10.741196)
    marker = GMSMarker(position: path.coordinate(at: 0))
    marker.icon = UIImage(named: "boat")
    marker.map = mapView
    marker.userData = PathIterator(path: path)
    animateToNextCoordinate(marker)
  }

  func animateToNextCoordinate(_ marker: GMSMarker) {
    guard let coordinateList = marker.userData as? PathIterator else { return }
    guard let coordinate = coordinateList.next() else { return }
    let previous = marker.position
    let heading = GMSGeometryHeading(previous, coordinate)
    let distance = GMSGeometryDistance(previous, coordinate)

    // Use CATransaction to set a custom duration for this animation. By default, changes to the
    // position are already animated, but with a very short default duration. When the animation is
    // complete, trigger another animation step.
    CATransaction.begin()
    CATransaction.setAnimationDuration(distance / (50 * 1000))  // custom duration, 50km/sec
    CATransaction.setCompletionBlock {
      self.animateToNextCoordinate(marker)
    }
    marker.position = coordinate
    CATransaction.commit()

    // If this marker is flat, implicitly trigger a change in rotation, which will finish quickly.
    if marker.isFlat {
      marker.rotation = heading
    }
  }
}

extension MarkerLayerViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    fadedMarker = marker
    return true
  }

  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    fadedMarker = nil
  }
}
