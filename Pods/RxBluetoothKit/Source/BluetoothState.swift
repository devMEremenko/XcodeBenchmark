import Foundation

/// Type describing bluetooth state, equivalent to
/// [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
public enum BluetoothState: Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}
