import CoreBluetooth
import Foundation

/// It should be deleted when `RestoredState` will be deleted
protocol CentralManagerRestoredStateType {
    var restoredStateData: [String: Any] { get }
    var centralManager: CentralManager { get }
    var peripherals: [Peripheral] { get }
    var scanOptions: [String: AnyObject]? { get }
    var services: [Service] { get }
}

/// Convenience class which helps reading state of restored CentralManager.
public struct CentralManagerRestoredState: CentralManagerRestoredStateType {

    /// Restored state dictionary.
    public let restoredStateData: [String: Any]

    public unowned let centralManager: CentralManager
    /// Creates restored state information based on CoreBluetooth's dictionary
    /// - parameter restoredStateDictionary: Core Bluetooth's restored state data
    /// - parameter centralManager: `CentralManager` instance of which state has been restored.
    init(restoredStateDictionary: [String: Any], centralManager: CentralManager) {
        restoredStateData = restoredStateDictionary
        self.centralManager = centralManager
    }

    /// Array of `Peripheral` objects which have been restored.
    /// These are peripherals that were connected to the central manager (or had a connection pending)
    /// at the time the app was terminated by the system.
    public var peripherals: [Peripheral] {
        let objects = restoredStateData[CBCentralManagerRestoredStatePeripheralsKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }

        #if swift(>=4.1)
        let cbPeripherals = arrayOfAnyObjects.compactMap { $0 as? CBPeripheral }
        #else
        let cbPeripherals = arrayOfAnyObjects.flatMap { $0 as? CBPeripheral }
        #endif

        return cbPeripherals.map { centralManager.retrievePeripheral(for: $0) }
    }

    /// Dictionary that contains all of the peripheral scan options that were being used
    /// by the central manager at the time the app was terminated by the system.
    public var scanOptions: [String: AnyObject]? {
        return restoredStateData[CBCentralManagerRestoredStatePeripheralsKey]
            as? [String: AnyObject]
    }

    /// Array of `Service` objects which have been restored.
    /// These are all the services the central manager was scanning for at the time the app
    /// was terminated by the system.
    public var services: [Service] {
        let objects =
            restoredStateData[CBCentralManagerRestoredStateScanServicesKey] as? [AnyObject]
        guard let arrayOfAnyObjects = objects else { return [] }

        #if swift(>=4.1)
        let cbServices = arrayOfAnyObjects.compactMap { $0 as? CBService }
        #else
        let cbServices = arrayOfAnyObjects.flatMap { $0 as? CBService }
        #endif

        return cbServices.compactMap {
            let maybePeripheral: CBPeripheral? = $0.peripheral
            guard let peripheral = maybePeripheral else {
                return nil
            }
            
            return Service(
                peripheral: centralManager.retrievePeripheral(for: peripheral),
                service: $0
            )
        }
    }
}
