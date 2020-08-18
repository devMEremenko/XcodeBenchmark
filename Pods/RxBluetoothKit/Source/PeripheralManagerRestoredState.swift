import Foundation
import CoreBluetooth

/// Convenience class which helps reading state of restored PeripheralManager.
public struct PeripheralManagerRestoredState {

    /// Restored state dictionary.
    public let restoredStateData: [String: Any]

    /// Creates restored state information based on CoreBluetooth's dictionary
    /// - parameter restoredStateDictionary: Core Bluetooth's restored state data
    init(restoredStateDictionary: [String: Any]) {
        restoredStateData = restoredStateDictionary
    }

    /// An array of CBMutableService objects that contains all of the services that
    /// were published to the local peripheral’s database at the time the app was
    /// terminated by the system.
    public var services: [CBMutableService] {
        let services = restoredStateData[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService]
        return services ?? []
    }

    /// A dictionary containing the data that the peripheral manager was advertising
    /// at the time the app was terminated by the system.
    public var advertisementData: [String: Any]? {
        return restoredStateData[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: AnyObject]
    }
}
