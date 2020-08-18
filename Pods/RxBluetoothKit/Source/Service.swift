import Foundation
import CoreBluetooth
import RxSwift

/// Service is a class implementing ReactiveX which wraps CoreBluetooth functions related to interaction with [CBService](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBService_Class/)
public class Service {
    /// Intance of CoreBluetooth service class
    public let service: CBService

    /// Peripheral to which this service belongs
    public let peripheral: Peripheral

    /// True if service is primary service
    public var isPrimary: Bool {
        return service.isPrimary
    }

    /// Service's UUID
    public var uuid: CBUUID {
        return service.uuid
    }

    /// Service's included services
    public var includedServices: [Service]? {
        return service.includedServices?.map {
            Service(peripheral: peripheral, service: $0)
        }
    }

    /// Service's characteristics
    public var characteristics: [Characteristic]? {
        return service.characteristics?.map {
            Characteristic(characteristic: $0, service: self)
        }
    }

    init(peripheral: Peripheral, service: CBService) {
        self.service = service
        self.peripheral = peripheral
    }

    /// Function that triggers characteristics discovery for specified Services and identifiers. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// - Parameter identifiers: Identifiers of characteristics that should be discovered. If `nil` - all of the
    /// characteristics will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Returns: `Single` that emits `next` with array of `Characteristic` instances, once they're discovered.
    /// If not all requested characteristics are discovered, `RxError.noElements` error is emmited.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.characteristicsDiscoveryFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?) -> Single<[Characteristic]> {
        return peripheral.discoverCharacteristics(characteristicUUIDs, for: self)
    }

    /// Function that triggers included services discovery for specified services. Discovery is called after
    /// subscribtion to `Observable` is made.
    /// - Parameter includedServiceUUIDs: Identifiers of included services that should be discovered. If `nil` - all of the
    /// included services will be discovered. If you'll pass empty array - none of them will be discovered.
    /// - Returns: `Single` that emits `next` with array of `Service` instances, once they're discovered.
    /// If not all requested services are discovered, `RxError.noElements` error is emmited.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.includedServicesDiscoveryFailed`
    /// * `BluetoothError.peripheralDisconnected`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?) -> Single<[Service]> {
        return peripheral.discoverIncludedServices(includedServiceUUIDs, for: self)
    }
}

extension Service: Equatable {}
extension Service: UUIDIdentifiable {}

/// Compare if services are equal. They are if theirs uuids are the same.
/// - parameter lhs: First service
/// - parameter rhs: Second service
/// - returns: True if services are the same.
public func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.service == rhs.service
}
