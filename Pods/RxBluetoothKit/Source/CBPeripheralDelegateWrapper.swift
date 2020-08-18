import Foundation
import CoreBluetooth
import RxSwift

class CBPeripheralDelegateWrapper: NSObject, CBPeripheralDelegate {

    let peripheralDidUpdateName = PublishSubject<String?>()
    let peripheralDidModifyServices = PublishSubject<([CBService])>()
    let peripheralDidReadRSSI = PublishSubject<(Int, Error?)>()
    let peripheralDidDiscoverServices = PublishSubject<([CBService]?, Error?)>()
    let peripheralDidDiscoverIncludedServicesForService = PublishSubject<(CBService, Error?)>()
    let peripheralDidDiscoverCharacteristicsForService = PublishSubject<(CBService, Error?)>()
    let peripheralDidUpdateValueForCharacteristic = PublishSubject<(CBCharacteristic, Error?)>()
    let peripheralDidWriteValueForCharacteristic = PublishSubject<(CBCharacteristic, Error?)>()
    let peripheralDidUpdateNotificationStateForCharacteristic =
        PublishSubject<(CBCharacteristic, Error?)>()
    let peripheralDidDiscoverDescriptorsForCharacteristic =
        PublishSubject<(CBCharacteristic, Error?)>()
    let peripheralDidUpdateValueForDescriptor = PublishSubject<(CBDescriptor, Error?)>()
    let peripheralDidWriteValueForDescriptor = PublishSubject<(CBDescriptor, Error?)>()
    let peripheralIsReadyToSendWriteWithoutResponse = PublishSubject<Void>()
    let peripheralDidOpenL2CAPChannel = PublishSubject<(Any?, Error?)>()

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateName(name: \(String(describing: peripheral.name)))
            """)
        peripheralDidUpdateName.onNext(peripheral.name)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didModifyServices(services:
            [\(invalidatedServices.logDescription))]
            """)
        peripheralDidModifyServices.onNext(invalidatedServices)
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI rssi: NSNumber, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didReadRSSI(rssi: \(rssi),
            error: \(String(describing: error)))
            """)
        peripheralDidReadRSSI.onNext((rssi.intValue, error))
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverServices(services
            : \(String(describing: peripheral.services?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverServices.onNext((peripheral.services, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverIncludedServicesFor service: CBService,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverIncludedServices(for:
            \(service.logDescription), includedServices:
            \(String(describing: service.includedServices?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverIncludedServicesForService.onNext((service, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverCharacteristicsFor(for:
            \(service.logDescription), characteristics:
            \(String(describing: service.characteristics?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverCharacteristicsForService.onNext((service, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateValueFor(for:\(characteristic.logDescription),
            value: \(String(describing: characteristic.value?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidUpdateValueForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didWriteValueFor(for:\(characteristic.logDescription),
            value: \(String(describing: characteristic.value?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidWriteValueForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateNotificationStateFor(
            for:\(characteristic.logDescription), isNotifying: \(characteristic.isNotifying),
            error: \(String(describing: error)))
            """)
        peripheralDidUpdateNotificationStateForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didDiscoverDescriptorsFor
            (for:\(characteristic.logDescription), descriptors:
            \(String(describing: characteristic.descriptors?.logDescription)),
            error: \(String(describing: error)))
            """)
        peripheralDidDiscoverDescriptorsForCharacteristic
            .onNext((characteristic, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor descriptor: CBDescriptor,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUpdateValueFor(for:\(descriptor.logDescription),
            value: \(String(describing: descriptor.value)), error: \(String(describing: error)))
            """)
        peripheralDidUpdateValueForDescriptor.onNext((descriptor, error))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor descriptor: CBDescriptor,
                    error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didWriteValueFor(for:\(descriptor.logDescription),
            error: \(String(describing: error)))
            """)
        peripheralDidWriteValueForDescriptor.onNext((descriptor, error))
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) peripheralIsReady(toSendWriteWithoutResponse)
            """)
        peripheralIsReadyToSendWriteWithoutResponse.onNext(())
    }

    @available(OSX 10.13, iOS 11, *)
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didOpenL2CAPChannel(for:\(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        peripheralDidOpenL2CAPChannel.onNext((channel, error))
    }
}
