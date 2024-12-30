import CoreBluetooth
import Foundation
import RxSwift

/// Descriptor is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with
/// [CBDescriptor](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBDescriptor_Class/)
/// Descriptors provide more information about a characteristic’s value.
public class Descriptor {

    /// Intance of CoreBluetooth descriptor class
    public let descriptor: CBDescriptor

    /// Characteristic to which this descriptor belongs.
    public let characteristic: Characteristic

    /// The Bluetooth UUID of the `Descriptor` instance.
    public var uuid: CBUUID {
        return descriptor.uuid
    }

    /// The value of the descriptor. It can be written and read through functions on `Descriptor` instance.
    public var value: Any? {
        return descriptor.value
    }

    init(descriptor: CBDescriptor, characteristic: Characteristic) {
        self.descriptor = descriptor
        self.characteristic = characteristic
    }

    convenience init(descriptor: CBDescriptor, peripheral: Peripheral) throws {
        let maybeCharacteristic: CBCharacteristic? = descriptor.characteristic
        let maybeService: CBService? = maybeCharacteristic?.service
        
        guard
            let characteristic = maybeCharacteristic,
            let service = maybeService
        else {
            throw BluetoothError.serviceDestroyed
        }

        self.init(
            descriptor: descriptor,
            characteristic: Characteristic(
                characteristic: characteristic,
                service: Service(peripheral: peripheral, service: service)
            )
        )
    }

    /// Function that allow to observe writes that happened for descriptor.
    /// - Returns: Observable that emits `next` with `Descriptor` instance every time when write has happened.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.descriptorWriteFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeWrite() -> Observable<Descriptor> {
        return characteristic.service.peripheral.observeWrite(for: self)
    }

    /// Function that triggers write of data to descriptor. Write is called after subscribtion to `Observable` is made.
    /// - Parameter data: `Data` that'll be written to `Descriptor` instance
    /// - Returns: `Single` that emits `Next` with `Descriptor` instance, once value is written successfully.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.descriptorWriteFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func writeValue(_ data: Data) -> Single<Descriptor> {
        return characteristic.service.peripheral.writeValue(data, for: self)
    }

    /// Function that allow to observe value updates for `Descriptor` instance.
    /// - Returns: Observable that emits `next` with `Descriptor` instance every time when value has changed.
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.descriptorReadFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeValueUpdate() -> Observable<Descriptor> {
        return characteristic.service.peripheral.observeValueUpdate(for: self)
    }

    /// Function that triggers read of current value of the `Descriptor` instance.
    /// Read is called after subscription to `Observable` is made.
    /// - Returns: `Single` which emits `next` with given descriptor when value is ready to read.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.descriptorReadFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func readValue() -> Single<Descriptor> {
        return characteristic.service.peripheral.readValue(for: self)
    }
}

extension Descriptor: Equatable {}

/// Compare two descriptors. Descriptors are the same when their UUIDs are the same.
///
/// - parameter lhs: First descriptor to compare
/// - parameter rhs: Second descriptor to compare
/// - returns: True if both descriptor are the same.
public func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
    return lhs.descriptor == rhs.descriptor
}
