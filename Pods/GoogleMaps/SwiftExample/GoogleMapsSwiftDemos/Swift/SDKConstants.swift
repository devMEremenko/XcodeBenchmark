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

import CoreLocation

enum SDKConstants {

  #error("Register for API Key and insert here. Then delete this line.")
  static let apiKey = ""
}

extension CLLocationCoordinate2D {
  static let sydney = CLLocationCoordinate2D(latitude: -33.8683, longitude: 151.2086)
  // Victoria, Australia
  static let victoria = CLLocationCoordinate2D(latitude: -37.81969, longitude: 144.966085)
  static let newYork = CLLocationCoordinate2D(latitude: 40.761388, longitude: -73.978133)
  static let mountainSceneLocation = CLLocationCoordinate2D(
    latitude: -33.732022, longitude: 150.312114)
}
