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

enum SampleMapStyle: CustomStringConvertible, CaseIterable {
  case normal
  case retro
  case grayscale
  case night
  case clean

  private static let mapStyleJSON = """
    [
      {
        "featureType" : "poi.business",
        "elementType" : "all",
        "stylers" : [
          {
            "visibility" : "off"
          }
        ]
      },
      {
        "featureType" : "transit",
        "elementType" : "labels.icon",
        "stylers" : [
          {
            "visibility" : "off"
          }
        ]
      }
    ]
    """

  var description: String {
    switch self {
    case .normal:
      return "Normal"
    case .retro:
      return "Retro"
    case .grayscale:
      return "Grayscale"
    case .night:
      return "Night"
    case .clean:
      return "No business points of interest, no transit"
    }
  }

  var mapStyle: GMSMapStyle? {
    switch self {
    case .normal:
      return nil
    case .retro:
      return try? GMSMapStyle(named: "mapstyle-retro")
    case .grayscale:
      return try? GMSMapStyle(named: "mapstyle-silver")
    case .night:
      return try? GMSMapStyle(named: "mapstyle-night")
    case .clean:
      return try? GMSMapStyle(jsonString: SampleMapStyle.mapStyleJSON)
    }
  }
}
