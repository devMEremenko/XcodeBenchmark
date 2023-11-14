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

enum SampleLevel: Equatable {
  case fakeGroundLevel
  case actualLevel(GMSIndoorLevel)

  init(indoorLevel: GMSIndoorLevel?) {
    if let level = indoorLevel {
      self = .actualLevel(level)
    } else {
      self = .fakeGroundLevel
    }
  }

  var name: String {
    switch self {
    case .fakeGroundLevel:
      return "\u{2014}"  // use an em dash for 'above ground'
    case .actualLevel(let level):
      return level.name ?? ""
    }
  }

  var shortName: String? {
    switch self {
    case .fakeGroundLevel:
      return nil
    case .actualLevel(let level):
      return level.shortName ?? ""
    }
  }

  var indoorLevel: GMSIndoorLevel? {
    switch self {
    case .fakeGroundLevel:
      return nil
    case .actualLevel(let level):
      return level
    }
  }

}
