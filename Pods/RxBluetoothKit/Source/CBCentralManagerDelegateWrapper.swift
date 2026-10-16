import Foundation
import CoreBluetooth
import RxSwift

class CBCentralManagerDelegateWrapper: NSObject, CBCentralManagerDelegate {

    let didUpdateState = PublishSubject<BluetoothState>()
    let willRestoreState = ReplaySubject<[String: Any]>.create(bufferSize: 1)
    let didDiscoverPeripheral = PublishSubject<(CBPeripheral, [String: Any], NSNumber)>()
    let didConnectPeripheral = PublishSubject<CBPeripheral>()
    let didFailToConnectPeripheral = PublishSubject<(CBPeripheral, Error?)>()
    let didDisconnectPeripheral = PublishSubject<(CBPeripheral, Error?)>()
    let didUpdateANCSAuthorizationForPeripheral = PublishSubject<(CBPeripheral)>()

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let bleState = BluetoothState(rawValue: central.state.rawValue) else { return }
        RxBluetoothKitLog.d("\(central.logDescription) didUpdateState(state: \(bleState.logDescription))")
        didUpdateState.onNext(bleState)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        RxBluetoothKitLog.d("\(central.logDescription) willRestoreState(restoredState: \(dict))")
        willRestoreState.onNext(dict)
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi: NSNumber) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didDiscover(peripheral: \(peripheral.logDescription),
            rssi: \(rssi))
            """)
        didDiscoverPeripheral.onNext((peripheral, advertisementData, rssi))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didConnect(to: \(peripheral.logDescription))
            """)
        didConnectPeripheral.onNext(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didFailToConnect(to: \(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        didFailToConnectPeripheral.onNext((peripheral, error))
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didDisconnect(from: \(peripheral.logDescription),
            error: \(String(describing: error)))
            """)
        didDisconnectPeripheral.onNext((peripheral, error))
    }

    #if !os(macOS)
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func centralManager(_ central: CBCentralManager,
                        didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        RxBluetoothKitLog.d("""
            \(central.logDescription) didUpdateANCSAuthorizationFor
            (peripheral: \(peripheral.logDescription)
            """)
        didUpdateANCSAuthorizationForPeripheral.onNext(peripheral)
    }
    #endif
}
