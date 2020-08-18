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

final class PolygonsViewController: UIViewController {

  private lazy var mapView: GMSMapView = {
    let cameraPosition = GMSCameraPosition(latitude: 39.13006, longitude: -77.508545, zoom: 4)
    return GMSMapView(frame: .zero, camera: cameraPosition)
  }()

  override func loadView() {
    mapView.delegate = self
    view = mapView
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Create renderer related objects after view appears, so a renderer will be available;
    let polygon = GMSPolygon()
    polygon.path = GMSPath.newYorkState()
    polygon.holes = [GMSPath.newYorkStateHole()]
    polygon.title = "New York"
    polygon.fillColor = UIColor(red: 0.25, green: 0, blue: 0, alpha: 0.2)
    polygon.strokeColor = .black
    polygon.strokeWidth = 2
    polygon.isTappable = true
    polygon.map = mapView

    // Copy the existing polygon and its settings and use it as a base for the
    // second polygon.
    let carolina = polygon.copy() as! GMSPolygon
    carolina.title = "North Carolina"
    carolina.path = GMSPath.northCarolina()
    carolina.fillColor = UIColor(red: 0, green: 0.25, blue: 0, alpha: 0.5)
    carolina.map = mapView
  }
}

extension GMSPath {
  static func newYorkState() -> GMSPath {
    let data: [[CLLocationDegrees]] = [
      [42.5142, -79.7624],
      [42.7783, -79.0672],
      [42.8508, -78.9313],
      [42.9061, -78.9024],
      [42.9554, -78.9313],
      [42.9584, -78.9656],
      [42.9886, -79.0219],
      [43.0568, -79.0027],
      [43.0769, -79.0727],
      [43.1220, -79.0713],
      [43.1441, -79.0302],
      [43.1801, -79.0576],
      [43.2482, -79.0604],
      [43.2812, -79.0837],
      [43.4509, -79.2004],
      [43.6311, -78.6909],
      [43.6321, -76.7958],
      [43.9987, -76.4978],
      [44.0965, -76.4388],
      [44.1349, -76.3536],
      [44.1989, -76.3124],
      [44.2049, -76.2437],
      [44.2413, -76.1655],
      [44.2973, -76.1353],
      [44.3327, -76.0474],
      [44.3553, -75.9856],
      [44.3749, -75.9196],
      [44.3994, -75.8730],
      [44.4308, -75.8221],
      [44.4740, -75.8098],
      [44.5425, -75.7288],
      [44.6647, -75.5585],
      [44.7672, -75.4088],
      [44.8101, -75.3442],
      [44.8383, -75.3058],
      [44.8676, -75.2399],
      [44.9211, -75.1204],
      [44.9609, -74.9995],
      [44.9803, -74.9899],
      [44.9852, -74.9103],
      [45.0017, -74.8856],
      [45.0153, -74.8306],
      [45.0046, -74.7633],
      [45.0027, -74.7070],
      [45.0007, -74.5642],
      [44.9920, -74.1467],
      [45.0037, -73.7306],
      [45.0085, -73.4203],
      [45.0109, -73.3430],
      [44.9874, -73.3547],
      [44.9648, -73.3379],
      [44.9160, -73.3396],
      [44.8354, -73.3739],
      [44.8013, -73.3324],
      [44.7419, -73.3667],
      [44.6139, -73.3873],
      [44.5787, -73.3736],
      [44.4916, -73.3049],
      [44.4289, -73.2953],
      [44.3513, -73.3365],
      [44.2757, -73.3118],
      [44.1980, -73.3818],
      [44.1142, -73.4079],
      [44.0511, -73.4367],
      [44.0165, -73.4065],
      [43.9375, -73.4079],
      [43.8771, -73.3749],
      [43.8167, -73.3914],
      [43.7790, -73.3557],
      [43.6460, -73.4244],
      [43.5893, -73.4340],
      [43.5655, -73.3969],
      [43.6112, -73.3818],
      [43.6271, -73.3049],
      [43.5764, -73.3063],
      [43.5675, -73.2582],
      [43.5227, -73.2445],
      [43.2582, -73.2582],
      [42.9715, -73.2733],
      [42.8004, -73.2898],
      [42.7460, -73.2664],
      [42.4630, -73.3708],
      [42.0840, -73.5095],
      [42.0218, -73.4903],
      [41.8808, -73.4999],
      [41.2953, -73.5535],
      [41.2128, -73.4834],
      [41.1011, -73.7275],
      [41.0237, -73.6644],
      [40.9851, -73.6578],
      [40.9509, -73.6132],
      [41.1869, -72.4823],
      [41.2551, -72.0950],
      [41.3005, -71.9714],
      [41.3108, -71.9193],
      [41.1838, -71.7915],
      [41.1249, -71.7929],
      [41.0462, -71.7517],
      [40.6306, -72.9465],
      [40.5368, -73.4628],
      [40.4887, -73.8885],
      [40.5232, -73.9490],
      [40.4772, -74.2271],
      [40.4861, -74.2532],
      [40.6468, -74.1866],
      [40.6556, -74.0547],
      [40.7618, -74.0156],
      [40.8699, -73.9421],
      [40.9980, -73.8934],
      [41.0343, -73.9854],
      [41.3268, -74.6274],
      [41.3583, -74.7084],
      [41.3811, -74.7101],
      [41.4386, -74.8265],
      [41.5075, -74.9913],
      [41.6000, -75.0668],
      [41.6719, -75.0366],
      [41.7672, -75.0545],
      [41.8808, -75.1945],
      [42.0013, -75.3552],
      [42.0003, -75.4266],
      [42.0013, -77.0306],
      [41.9993, -79.7250],
      [42.0003, -79.7621],
      [42.1827, -79.7621],
      [42.5146, -79.7621],
    ]
    let path = GMSMutablePath()
    for degrees in data {
      path.addLatitude(degrees[0], longitude: degrees[1])
    }
    return path
  }

  static func newYorkStateHole() -> GMSPath {
    let path = GMSMutablePath()
    path.addLatitude(43.5000, longitude: -76.3651)
    path.addLatitude(43.5000, longitude: -74.3651)
    path.addLatitude(42.0000, longitude: -74.3651)
    return path
  }

  static func northCarolina() -> GMSPath {
    let path = GMSMutablePath()
    let data = [
      [33.7963, -78.4850],
      [34.8037, -79.6742],
      [34.8206, -80.8003],
      [34.9377, -80.7880],
      [35.1019, -80.9377],
      [35.0356, -81.0379],
      [35.1457, -81.0324],
      [35.1660, -81.3867],
      [35.1985, -82.2739],
      [35.2041, -82.3933],
      [35.0637, -82.7765],
      [35.0817, -82.7861],
      [34.9996, -83.1075],
      [34.9918, -83.6183],
      [34.9918, -84.3201],
      [35.2131, -84.2885],
      [35.2680, -84.2226],
      [35.2310, -84.1113],
      [35.2815, -84.0454],
      [35.4058, -84.0248],
      [35.4719, -83.9424],
      [35.5166, -83.8559],
      [35.5512, -83.6938],
      [35.5680, -83.5181],
      [35.6327, -83.3849],
      [35.7142, -83.2475],
      [35.7799, -82.9962],
      [35.8445, -82.9276],
      [35.9224, -82.8191],
      [35.9958, -82.7710],
      [36.0613, -82.6419],
      [35.9702, -82.6103],
      [35.9547, -82.5677],
      [36.0236, -82.4730],
      [36.0669, -82.4194],
      [36.1168, -82.3535],
      [36.1345, -82.2862],
      [36.1467, -82.1461],
      [36.1035, -82.1228],
      [36.1268, -82.0267],
      [36.2797, -81.9360],
      [36.3527, -81.7987],
      [36.3361, -81.7081],
      [36.5880, -81.6724],
      [36.5659, -80.7234],
      [36.5438, -80.2977],
      [36.5449, -79.6729],
      [36.5449, -77.2559],
      [36.5505, -75.7562],
      [36.3129, -75.7068],
      [35.7131, -75.4129],
      [35.2041, -75.4720],
      [34.9794, -76.0748],
      [34.5258, -76.4951],
      [34.5880, -76.8109],
      [34.5314, -77.1378],
      [34.3910, -77.4481],
      [34.0481, -77.7983],
      [33.7666, -77.9260],
      [33.7963, -78.4863],
    ]
    for degrees in data {
      path.addLatitude(degrees[0], longitude: degrees[1])
    }
    return path
  }
}

extension PolygonsViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
    // When a polygon is tapped, randomly change its fill color to a new hue.
    guard let polygon = overlay as? GMSPolygon else { return }
    polygon.fillColor = UIColor(
      hue: CGFloat.random(in: 0..<1), saturation: 1, brightness: 1, alpha: 0.5)
  }
}
