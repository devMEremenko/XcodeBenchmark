// Copyright 2021 Google LLC. All rights reserved.
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

import GooglePlaces
import UIKit

/// The section of configuration.
struct ConfigSection {
  let name: String
  let samples: [ConfigData]
}

/// The configuration data.
struct ConfigData {
  let name: String
  let tag: Int
  let action: Selector
}

/// The location option for autocomplete search.
enum LocationOption: Int {
  case unspecified = 100
  case canada = 101
  case kansas = 102

  var northEast: CLLocationCoordinate2D {
    switch self {
    case .canada:
      return CLLocationCoordinate2D(latitude: 70.0, longitude: -60.0)
    case .kansas:
      return CLLocationCoordinate2D(latitude: 39.0, longitude: -95.0)
    default:
      return CLLocationCoordinate2D()
    }
  }

  var southWest: CLLocationCoordinate2D {
    switch self {
    case .canada:
      return CLLocationCoordinate2D(latitude: 50.0, longitude: -140.0)
    case .kansas:
      return CLLocationCoordinate2D(latitude: 37.5, longitude: -100.0)
    default:
      return CLLocationCoordinate2D()
    }
  }
}

/// Manages the configuration options view for the demo app.
class ConfigurationViewController: UIViewController {
  // MARK: - Properties

  private let cellIdentifier = "cellIdentifier"
  private let filterTagBase = 1000

  private lazy var configurationSections: [ConfigSection] = {
    var sections: [ConfigSection] = []

    let autocompleteFiltersSelector = #selector(autocompleteFiltersSwitch)
    let geocode = ConfigData(
      name: "Geocode", tag: filterTagBase + GMSPlacesAutocompleteTypeFilter.geocode.rawValue,
      action: autocompleteFiltersSelector)
    let address = ConfigData(
      name: "Address", tag: filterTagBase + GMSPlacesAutocompleteTypeFilter.address.rawValue,
      action: autocompleteFiltersSelector)
    let establishment = ConfigData(
      name: "Establishment",
      tag: filterTagBase + GMSPlacesAutocompleteTypeFilter.establishment.rawValue,
      action: autocompleteFiltersSelector)
    let region = ConfigData(
      name: "Region", tag: filterTagBase + GMSPlacesAutocompleteTypeFilter.region.rawValue,
      action: autocompleteFiltersSelector)
    let city = ConfigData(
      name: "City", tag: filterTagBase + GMSPlacesAutocompleteTypeFilter.city.rawValue,
      action: autocompleteFiltersSelector)

    sections.append(
      ConfigSection(
        name: "Autocomplete filters", samples: [geocode, address, establishment, region, city]))

    let canada = ConfigData(
      name: "Canada", tag: LocationOption.canada.rawValue, action: #selector(canadaSwitch))
    let kansas = ConfigData(
      name: "Kansas", tag: LocationOption.kansas.rawValue, action: #selector(kansasSwitch))
    sections.append(
      ConfigSection(name: "Autocomplete Restriction Bounds", samples: [canada, kansas]))

    let placesFieldsSelector = #selector(placesFieldsSwitch)
    let name = ConfigData(
      name: "Name", tag: Int(GMSPlaceField.name.rawValue), action: placesFieldsSelector)
    let placeId = ConfigData(
      name: "Place ID", tag: Int(GMSPlaceField.placeID.rawValue),
      action: placesFieldsSelector)
    let plusCode = ConfigData(
      name: "Plus Code", tag: Int(GMSPlaceField.plusCode.rawValue),
      action: placesFieldsSelector)
    let coordinate = ConfigData(
      name: "Coordinate", tag: Int(GMSPlaceField.coordinate.rawValue),
      action: placesFieldsSelector)
    let openingHours = ConfigData(
      name: "Opening Hours", tag: Int(GMSPlaceField.openingHours.rawValue),
      action: placesFieldsSelector)
    let phoneNumber = ConfigData(
      name: "Phone Number", tag: Int(GMSPlaceField.phoneNumber.rawValue),
      action: placesFieldsSelector)
    let formattedAddress = ConfigData(
      name: "Formatted Address", tag: Int(GMSPlaceField.formattedAddress.rawValue),
      action: placesFieldsSelector)
    let rating = ConfigData(
      name: "Rating", tag: Int(GMSPlaceField.rating.rawValue), action: placesFieldsSelector)
    let priceLevel = ConfigData(
      name: "Price Level", tag: Int(GMSPlaceField.priceLevel.rawValue),
      action: placesFieldsSelector)
    let types = ConfigData(
      name: "Types", tag: Int(GMSPlaceField.types.rawValue), action: placesFieldsSelector)
    let website = ConfigData(
      name: "Website", tag: Int(GMSPlaceField.website.rawValue),
      action: placesFieldsSelector)
    let viewPort = ConfigData(
      name: "Viewport", tag: Int(GMSPlaceField.viewport.rawValue),
      action: placesFieldsSelector)
    let addressComponents = ConfigData(
      name: "Address Components", tag: Int(GMSPlaceField.addressComponents.rawValue),
      action: placesFieldsSelector)
    let photos = ConfigData(
      name: "Photos", tag: Int(GMSPlaceField.photos.rawValue), action: placesFieldsSelector)
    let ratingsTotal = ConfigData(
      name: "User Ratings Total", tag: Int(GMSPlaceField.userRatingsTotal.rawValue),
      action: placesFieldsSelector)
    let minutes = ConfigData(
      name: "UTC Offset Minutes", tag: Int(GMSPlaceField.utcOffsetMinutes.rawValue),
      action: placesFieldsSelector)
    let status = ConfigData(
      name: "Business Status", tag: Int(GMSPlaceField.businessStatus.rawValue),
      action: placesFieldsSelector)
    let iconImageURL = ConfigData(
      name: "Icon Image URL", tag: Int(GMSPlaceField.iconImageURL.rawValue),
      action: placesFieldsSelector)
    let iconBackgroundColor = ConfigData(
      name: "Icon Background Color", tag: Int(GMSPlaceField.iconBackgroundColor.rawValue),
      action: placesFieldsSelector)
    let takeout = ConfigData(
      name: "Takeout", tag: Int(GMSPlaceField.takeout.rawValue),
      action: placesFieldsSelector)
    let delivery = ConfigData(
      name: "Delivery", tag: Int(GMSPlaceField.delivery.rawValue),
      action: placesFieldsSelector)
    let dineIn = ConfigData(
      name: "Dine In", tag: Int(GMSPlaceField.dineIn.rawValue),
      action: placesFieldsSelector)
    let curbsidePickup = ConfigData(
      name: "Curbside Pickup", tag: Int(GMSPlaceField.curbsidePickup.rawValue),
      action: placesFieldsSelector)
    let reservable = ConfigData(
      name: "Reservable", tag: Int(GMSPlaceField.reservable.rawValue),
      action: placesFieldsSelector)
    let servesBreakfast = ConfigData(
      name: "Serves Breakfast", tag: Int(GMSPlaceField.servesBreakfast.rawValue),
      action: placesFieldsSelector)
    let servesLunch = ConfigData(
      name: "Serves Lunch", tag: Int(GMSPlaceField.servesLunch.rawValue),
      action: placesFieldsSelector)
    let servesDinner = ConfigData(
      name: "Serves Dinner", tag: Int(GMSPlaceField.servesDinner.rawValue),
      action: placesFieldsSelector)
    let servesBeer = ConfigData(
      name: "Serves Beer", tag: Int(GMSPlaceField.servesBeer.rawValue),
      action: placesFieldsSelector)
    let servesWine = ConfigData(
      name: "Serves Wine", tag: Int(GMSPlaceField.servesWine.rawValue),
      action: placesFieldsSelector)
    let servesBrunch = ConfigData(
      name: "Serves Brunch", tag: Int(GMSPlaceField.servesBrunch.rawValue),
      action: placesFieldsSelector)
    let servesVegetarianFood = ConfigData(
      name: "Serves Vegetarian Food", tag: Int(GMSPlaceField.servesVegetarianFood.rawValue),
      action: placesFieldsSelector)
    let wheelchairAccessibleEntrance = ConfigData(
      name: "Wheelchair Accessible Entrance",
      tag: Int(GMSPlaceField.wheelchairAccessibleEntrance.rawValue),
      action: placesFieldsSelector)
    let currentOpeningHours = ConfigData(
      name: "Current Opening Hours", tag: Int(GMSPlaceField.currentOpeningHours.rawValue),
      action: placesFieldsSelector)
    let secondaryOpeningHours = ConfigData(
      name: "Secondary Opening Hours", tag: Int(GMSPlaceField.secondaryOpeningHours.rawValue),
      action: placesFieldsSelector)
    let editorialSummary = ConfigData(
      name: "Editorial Summary", tag: Int(GMSPlaceField.editorialSummary.rawValue),
      action: placesFieldsSelector)
    var placeFieldSamples = [
      name, placeId, plusCode, coordinate, openingHours, phoneNumber, formattedAddress, rating,
      ratingsTotal, priceLevel, types, website, viewPort, addressComponents, photos, minutes,
      status, iconImageURL, iconBackgroundColor,
    ]
    placeFieldSamples += [
      takeout, delivery, dineIn, curbsidePickup, reservable, servesBreakfast,
      servesLunch, servesDinner, servesBeer, servesWine, servesBrunch, servesVegetarianFood,
      wheelchairAccessibleEntrance,
    ]
    placeFieldSamples += [
      currentOpeningHours, secondaryOpeningHours,
    ]
    placeFieldSamples += [
      editorialSummary
    ]
    sections.append(ConfigSection(name: "Place Fields", samples: placeFieldSamples))
    return sections
  }()

  private var configuration: AutocompleteConfiguration

  private lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  }()

  private lazy var closeButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .systemBlue
    button.setTitle("Close", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(tapCloseButton(_:)), for: .touchUpInside)
    return button
  }()

  // MARK: - Public functions

  public init(configuration: AutocompleteConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  required init(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(tableView)
    view.addSubview(closeButton)
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: guide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: closeButton.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
    ])
    NSLayoutConstraint.activate([
      closeButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      closeButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      closeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
    ])
  }

  // MARK: - Private functions

  @objc private func tapCloseButton(_ sender: UISwitch) {
    dismiss(animated: true)
    guard let location = configuration.location else { return }
    let northEast = location.northEast
    let southWest = location.southWest
    // Update configuration
    switch location {
    case .canada:
      configuration.autocompleteFilter.origin = CLLocation(
        latitude: northEast.latitude, longitude: northEast.longitude)
      configuration.autocompleteFilter.locationRestriction =
        GMSPlaceRectangularLocationOption(northEast, southWest)
    case .kansas:
      configuration.autocompleteFilter.origin = CLLocation(
        latitude: northEast.latitude, longitude: northEast.longitude)
      configuration.autocompleteFilter.locationRestriction =
        GMSPlaceRectangularLocationOption(northEast, southWest)
    default:
      configuration.autocompleteFilter.origin = nil
      configuration.autocompleteFilter.locationRestriction = nil
    }
  }

  @objc private func autocompleteFiltersSwitch(_ sender: UISwitch) {
    for sample in configurationSections[0].samples {
      guard let switchView = view.viewWithTag(sample.tag) as? UISwitch else { continue }
      if switchView.tag != sender.tag {
        switchView.setOn(false, animated: true)
      }
    }
    // The value of the type is tag - filterTagBase
    guard let type = GMSPlacesAutocompleteTypeFilter(rawValue: sender.tag - filterTagBase) else {
      return
    }
    configuration.autocompleteFilter.type = type
  }

  @objc private func canadaSwitch(_ sender: UISwitch) {
    if sender.isOn {
      // Turn off the Kansas switch
      guard let switchView = view.viewWithTag(LocationOption.kansas.rawValue) as? UISwitch else {
        return
      }
      switchView.setOn(false, animated: true)
      configuration.location = .canada
    } else {
      configuration.location = .unspecified
    }
  }

  @objc private func kansasSwitch(_ sender: UISwitch) {
    if sender.isOn {
      // Turn off the Canada switch
      guard let switchView = view.viewWithTag(LocationOption.canada.rawValue) as? UISwitch else {
        return
      }
      switchView.setOn(false, animated: true)
      configuration.location = .kansas
    } else {
      configuration.location = .unspecified
    }
  }

  @objc private func placesFieldsSwitch(_ sender: UISwitch) {
    var field = UInt64(sender.tag)
    if sender.isOn {
      field |= configuration.placeFields.rawValue
    } else {
      field = ~field & configuration.placeFields.rawValue
    }
    configuration.placeFields = GMSPlaceField(rawValue: field)
  }
}

extension ConfigurationViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard section <= configurationSections.count else {
      return 0
    }
    return configurationSections[section].samples.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: cellIdentifier, for: indexPath)
    guard
      indexPath.section < configurationSections.count
        && indexPath.row < configurationSections[indexPath.section].samples.count
    else { return cell }
    let sample = configurationSections[indexPath.section].samples[indexPath.row]
    cell.textLabel?.text = sample.name
    let switchView = UISwitch(frame: .zero)
    switchView.tag = Int(sample.tag)
    switch indexPath.section {
    case 0:
      if sample.tag - filterTagBase == configuration.autocompleteFilter.type.rawValue {
        switchView.setOn(true, animated: false)
      }
    case 1:
      let isOn = (sample.tag == configuration.location?.rawValue)
      switchView.setOn(isOn, animated: false)
    case 2:
      if configuration.placeFields == .all {
        switchView.setOn(true, animated: false)
      } else {
        let field = Int(configuration.placeFields.rawValue)
        if (field & switchView.tag) != 0 {
          switchView.setOn(true, animated: false)
        }
      }
    default:
      break
    }
    switchView.addTarget(self, action: sample.action, for: .valueChanged)
    cell.accessoryView = switchView
    return cell
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    configurationSections.count
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard section <= configurationSections.count else {
      return ""
    }
    return configurationSections[section].name
  }
}

extension ConfigurationViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let sample = configurationSections[indexPath.section].samples[indexPath.row]
    let cell = tableView.cellForRow(at: indexPath)
    guard let switchView = cell?.accessoryView as? UISwitch else { return }
    switchView.setOn(!switchView.isOn, animated: true)
    perform(sample.action, with: switchView)
  }
}
