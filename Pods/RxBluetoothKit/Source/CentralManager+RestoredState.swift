import Foundation
import RxSwift
import CoreBluetooth

@available(*, deprecated, renamed: "OnWillRestoreCentralManagerState")
public typealias OnWillRestoreState = (RestoredState) -> Void
/// Closure that receives `RestoredState` as a parameter
public typealias OnWillRestoreCentralManagerState = (CentralManagerRestoredState) -> Void

extension CentralManager {

    // MARK: State restoration

    /// Deprecated, use CentralManager.init(queue:options:onWillRestoreCentralManagerState:) instead
    @available(*, deprecated, renamed: "CentralManager.init(queue:options:onWillRestoreCentralManagerState:)")
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            cbCentralManager: CBCentralManager? = nil,
                            onWillRestoreState: OnWillRestoreState? = nil) {
        self.init(queue: queue, options: options, cbCentralManager: cbCentralManager)
        if let onWillRestoreState = onWillRestoreState {
            listenOnWillRestoreState(onWillRestoreState)
        }
    }

    /// Creates new `CentralManager` instance, which supports bluetooth state restoration.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread
    /// for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used
    /// and all operations and events are executed and received on main thread.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    /// - parameter cbCentralManager: Optional instance of `CBCentralManager` to be used as a `manager`.
    /// If you skip this parameter, there will be created an instance of `CBCentralManager` using given queue and options.
    /// - parameter onWillRestoreCentralManagerState: Closure called when state has been restored.
    ///
    /// - seealso: `OnWillRestoreCentralManagerState`
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            cbCentralManager: CBCentralManager? = nil,
                            onWillRestoreCentralManagerState: OnWillRestoreCentralManagerState? = nil) {
        self.init(queue: queue, options: options, cbCentralManager: cbCentralManager)
        if let onWillRestoreCentralManagerState = onWillRestoreCentralManagerState {
            listenOnWillRestoreState(onWillRestoreCentralManagerState)
        }
    }

    /// Creates new `CentralManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    /// - parameter peripheralProvider: Provider for providing peripherals and peripheral wrappers
    /// - parameter connector: Connector instance which is used for establishing connection with peripherals
    /// - parameter onWillRestoreState: Closure called when state has been restored.
    convenience init(
        centralManager: CBCentralManager,
        delegateWrapper: CBCentralManagerDelegateWrapper,
        peripheralProvider: PeripheralProvider,
        connector: Connector,
        onWillRestoreCentralManagerState: @escaping OnWillRestoreCentralManagerState
        ) {
        self.init(
            centralManager: centralManager,
            delegateWrapper: delegateWrapper,
            peripheralProvider: peripheralProvider,
            connector: connector
        )
        listenOnWillRestoreState(onWillRestoreCentralManagerState)
    }

    @available(*, deprecated, message: "listenOnWillRestoreState(:OnWillRestoreCentralManagerState) instead")
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreState) {
        _ = restoreStateObservable
            .map { RestoredState(centralManagerRestoredState: $0) }
            .subscribe(onNext: { handler($0) })
    }

    /// Emits `RestoredState` instance, when state of `CentralManager` has been restored,
    /// Should only be called once in the lifetime of the app
    /// - returns: Observable which emits next events state has been restored
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreCentralManagerState) {
        _ = restoreStateObservable
            .subscribe(onNext: { handler($0) })
    }

    var restoreStateObservable: Observable<CentralManagerRestoredState> {
        return delegateWrapper
            .willRestoreState
            .take(1)
            .flatMap { [weak self] dict -> Observable<CentralManagerRestoredState> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return .just(CentralManagerRestoredState(restoredStateDictionary: dict, centralManager: strongSelf))
            }
    }
}
