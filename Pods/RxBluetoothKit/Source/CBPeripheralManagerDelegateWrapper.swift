import Foundation
import CoreBluetooth
import RxSwift

class CBPeripheralManagerDelegateWrapper: NSObject, CBPeripheralManagerDelegate {

    let didUpdateState = PublishSubject<BluetoothState>()
    let isReady = PublishSubject<Void>()
    let didStartAdvertising = PublishSubject<Error?>()
    let didReceiveRead = PublishSubject<CBATTRequest>()
    let willRestoreState = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    let didAddService = PublishSubject<(CBService, Error?)>()
    let didReceiveWrite = PublishSubject<[CBATTRequest]>()
    let didSubscribeTo = PublishSubject<(CBCentral, CBCharacteristic)>()
    let didUnsubscribeFrom = PublishSubject<(CBCentral, CBCharacteristic)>()
    let didPublishL2CAPChannel = PublishSubject<(CBL2CAPPSM, Error?)>()
    let didUnpublishL2CAPChannel = PublishSubject<(CBL2CAPPSM, Error?)>()
    private var _didOpenChannel: Any?
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    var didOpenChannel: PublishSubject<(CBL2CAPChannel?, Error?)> {
        if _didOpenChannel == nil {
            _didOpenChannel = PublishSubject<(CBL2CAPChannel?, Error?)>()
        }
        return _didOpenChannel as! PublishSubject<(CBL2CAPChannel?, Error?)>
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard let bleState = BluetoothState(rawValue: peripheral.state.rawValue) else { return }
        RxBluetoothKitLog.d("\(peripheral.logDescription) didUpdateState(state: \(bleState.logDescription))")
        didUpdateState.onNext(bleState)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        RxBluetoothKitLog.d("\(peripheral.logDescription) isReady()")
        isReady.onNext(())
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        RxBluetoothKitLog.d("\(peripheral.logDescription) didStartAdvertising(error: \(String(describing: error)))")
        didStartAdvertising.onNext(error)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        RxBluetoothKitLog.d("\(peripheral.logDescription) didReceiveRead(request: \(request.logDescription))")
        didReceiveRead.onNext(request)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        RxBluetoothKitLog.d("\(peripheral.logDescription) willRestoreState(dict: \(dict))")
        willRestoreState.onNext(dict)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription)
            didAdd(service: \(service.logDescription), error: \(String(describing: error))
            """)
        didAddService.onNext((service, error))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let requestsLog = requests.reduce("[", { $0 + $1.logDescription + "," }).dropLast().appending("]")
        RxBluetoothKitLog.d("\(peripheral.logDescription) didReceiveWrite(requests: \(requestsLog))")
        didReceiveWrite.onNext(requests)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription)
            didSubscribeTo(central: \(central.logDescription), characteristic: \(characteristic.logDescription))
            """)
        didSubscribeTo.onNext((central, characteristic))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription)
            didUnsubscribeFrom(central: \(central.logDescription), characteristic: \(characteristic.logDescription))
            """)
        didUnsubscribeFrom.onNext((central, characteristic))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didPublishL2CAPChannel(PSM: \(PSM), error: \(String(describing: error))
            """)
        didPublishL2CAPChannel.onNext((PSM, error))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription) didUnpublishL2CAPChannel(PSM: \(PSM), error: \(String(describing: error))
            """)
        didUnpublishL2CAPChannel.onNext((PSM, error))
    }

    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        RxBluetoothKitLog.d("""
            \(peripheral.logDescription)
            didOpen(channel: \(channel?.logDescription ?? "nil"), error: \(String(describing: error))
            """)
        didOpenChannel.onNext((channel, error))
    }
}
