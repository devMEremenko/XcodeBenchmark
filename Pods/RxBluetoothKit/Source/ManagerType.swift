import Foundation
import RxSwift
import CoreBluetooth

public protocol ManagerType: AnyObject {
    associatedtype Manager

    /// Implementation of CBManager
    var manager: Manager { get }
    /// Current state of `CentralManager` instance described by `BluetoothState` which is equivalent to
    /// [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    var state: BluetoothState { get }

    /// Continuous state of `CBManager` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    /// - returns: Observable that emits `next` event whenever state changes.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    func observeState() -> Observable<BluetoothState>

    /// Continuous state of `CBManager` instance described by `BluetoothState` which is equivalent to  [CBManagerState](https://developer.apple.com/documentation/corebluetooth/cbmanagerstate).
    /// - returns: Observable that emits `next` event starting with current state and whenever state changes.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    func observeStateWithInitialValue() -> Observable<BluetoothState>
}

public extension ManagerType {
    /// Ensure that `state` is and will be the only state of `CentralManager` during subscription.
    /// Otherwise error is emitted.
    /// - parameter state: `BluetoothState` which should be present during subscription.
    /// - parameter observable: Observable into which potential errors should be merged.
    /// - returns: New observable which merges errors with source observable.
    func ensure<T>(_ state: BluetoothState, observable: Observable<T>) -> Observable<T> {
        return .deferred { [weak self] in
            guard let strongSelf = self else { throw BluetoothError.destroyed }
            let statesObservable = strongSelf.observeStateWithInitialValue()
                .filter { $0 != state && BluetoothError(state: $0) != nil }
                .map { state -> T in throw BluetoothError(state: state)! }
            return .absorb(statesObservable, observable)
        }
    }
}
