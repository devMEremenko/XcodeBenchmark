import Foundation

public typealias RestoredAdvertisementData = [String: Any]

/// Enum result that is returned as a result of `PeripheralManager.startAdvertising` method
public enum StartAdvertisingResult {
    /// Advertising started properly with specified `advertisementData`
    case started
    /// This is a special case meaning that there is already ongoing advertising that has been started
    /// outside of `RxBluetoothKit` library and `PeripherlManager.startAdvertising` did only attached
    /// to ongoing advertising without calling `CBPeripheralManager.startAdvertising`.
    /// The reason behind that is that we want to give user possibility to stop advertising in
    /// such state.
    /// In most cases it happens when app went from background with ongoing advertising - in that case you will receive `RestoredAdvertisementData` param, so you can know with what `advertisementData` it was started before app went background.
    /// WARNING: remember that this is not really calling `CBPeripheralManager.startAdvertising`
    /// so it might be not started with `advertisementData` param that you've provided. If you
    /// want to start with different `advertisementData` then you will need to dispose
    /// advertising observable and call `startAdvertising` again.
    case attachedToExternalAdvertising(RestoredAdvertisementData?)
}
