import Foundation
import CoreBluetooth

/// Represents instance of scanned peripheral - containing it's advertisment data, rssi and peripheral itself.
/// To perform further actions `peripheral` instance variable can be used ia. to maintain connection.
public class ScannedPeripheral {

    /// `Peripheral` instance, that allows to perform further bluetooth actions.
    public let peripheral: Peripheral

    /// Advertisement data of scanned peripheral
    public let advertisementData: AdvertisementData

    /// Scanned peripheral's RSSI value.
    public let rssi: NSNumber

    init(peripheral: Peripheral, advertisementData: AdvertisementData, rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
}
