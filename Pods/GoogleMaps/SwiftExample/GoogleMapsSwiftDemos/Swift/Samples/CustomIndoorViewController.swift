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
import UIKit

class CustomIndoorViewController: UIViewController {
  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(latitude: 37.78318, longitude: -122.403874, zoom: 18)
    let mapView = GMSMapView(frame: .zero, camera: camera)
    return mapView
  }()
  private lazy var levelPickerView: UIPickerView = UIPickerView()
  private var sampleLevels: [SampleLevel] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .gray

    mapView.settings.myLocationButton = false
    mapView.settings.indoorPicker = false  // We are implementing a custom level picker.
    mapView.isIndoorEnabled = true  // Defaults to true. Set to false to hide indoor maps.
    mapView.indoorDisplay.delegate = self
    mapView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(mapView)

    // This UIPicker will be populated with the levels of the active building.
    levelPickerView.delegate = self
    levelPickerView.dataSource = self
    levelPickerView.showsSelectionIndicator = true
    levelPickerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(levelPickerView)

    let metrics: [String: Float] = ["height": 180]
    let views: [String: UIView] = ["mapView": mapView, "levelPickerView": levelPickerView]
    NSLayoutConstraint.activate(
      NSLayoutConstraint.constraints(
        withVisualFormat: "|[mapView]|", options: [], metrics: metrics, views: views)
        + NSLayoutConstraint.constraints(
          withVisualFormat: "V:|[mapView][levelPickerView(height)]|", options: [], metrics: metrics,
          views: views))
  }

}

extension CustomIndoorViewController: GMSIndoorDisplayDelegate {

  func didChangeActiveBuilding(_ building: GMSIndoorBuilding?) {
    guard let building = building else {
      return
    }

    var sampleLevels: [SampleLevel] = []
    if building.isUnderground {
      // If this building is completely underground, add a fake 'top' floor.
      sampleLevels.append(.fakeGroundLevel)
    }
    sampleLevels.append(contentsOf: building.levels.map({ .actualLevel($0) }))

    self.sampleLevels = sampleLevels

    levelPickerView.reloadAllComponents()
    levelPickerView.selectRow(-1, inComponent: 0, animated: false)
  }

  func didChangeActiveLevel(_ level: GMSIndoorLevel?) {
    // On level change, sync our level picker's selection to the IndoorDisplay.
    // Since a nil level is returned for the "ground level" of an underground only building, default
    // a nil value to the name of the fake ground level enum.
    let sampleLevel = SampleLevel(indoorLevel: level)
    if let index = sampleLevels.firstIndex(of: sampleLevel) {
      let currentlySelectedIndex = levelPickerView.selectedRow(inComponent: 0)
      if index != currentlySelectedIndex {
        levelPickerView.selectRow(index, inComponent: 0, animated: false)
      }
    }
  }

}

extension CustomIndoorViewController: UIPickerViewDelegate {

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    // On user selection of a level in the picker, set the right level in IndoorDisplay
    mapView.indoorDisplay.activeLevel = sampleLevels[row].indoorLevel
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
    -> String?
  {
    return sampleLevels[row].name
  }

}

extension CustomIndoorViewController: UIPickerViewDataSource {

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return sampleLevels.count
  }

}
