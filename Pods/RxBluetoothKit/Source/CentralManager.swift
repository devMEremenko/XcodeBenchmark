import Foundation
import RxSwift
import CoreBluetooth

/// Error received when device disconnection event occurs
public typealias DisconnectionReason = Error

/// CentralManager is a class implementing ReactiveX API which wraps all Core Bluetooth Manager's functions allowing to
/// discover, connect to remote peripheral devices and more.
/// You can start using this class by discovering available services of nearby peripherals. Before calling any
/// public `CentralManager`'s functions you should make sure that Bluetooth is turned on and powered on.
/// It can be done by calling and observing returned value of `observeStateWithInitialValue()` and then
/// chaining it with `scanForPeripherals(_:options:)`:
/// ```
/// let disposable = centralManager.observeStateWithInitialValue()
///     .filter { $0 == .poweredOn }
///     .take(1)
///     .flatMap { centralManager.scanForPeripherals(nil) }
/// ```
/// As a result you will receive `ScannedPeripheral` which contains `Peripheral` object, `AdvertisementData` and
/// peripheral's RSSI registered during discovery. You can then `establishConnection(_:options:)` and do other operations.
/// You can also simply stop scanning with just disposing it:
/// ```
/// disposable.dispose()
/// ```
/// - seealso: `Peripheral`
public class CentralManager: ManagerType {

    /// Implementation of CBCentralManager
    public let manager: CBCentralManager

    @available(*, deprecated, renamed: "CentralManager.manager")
    public var centralManager: CBCentralManager { return manager }

    let peripheralProvider: PeripheralProvider

    let delegateWrapper: CBCentralManagerDelegateWrapper

    /// Lock which should be used before accessing any internal structures
    private let lock = NSLock()

    /// Ongoing scan disposable
    private var scanDisposable: Disposable?

    /// Connector instance is used for establishing connection with peripherals
    private let connector: Connector

    // MARK: Initialization

    /// Creates new `CentralManager`
    /// - parameter centralManager: Central instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's central manager callbacks.
    /// - parameter peripheralProvider: Provider for providing peripherals and peripheral wrappers
    /// - parameter connector: Connector instance which is used for establishing connection with peripherals.
    init(
        centralManager: CBCentralManager,
        delegateWrapper: CBCentralManagerDelegateWrapper,
        peripheralProvider: PeripheralProvider,
        connector: Connector
    ) {
        self.manager = centralManager
        self.delegateWrapper = delegateWrapper
        self.peripheralProvider = peripheralProvider
        self.connector = connector
        centralManager.delegate = delegateWrapper
    }

    /// Creates new `CentralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a central manager.
    /// For more info about it please refer to [Central Manager initialization options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/index.html)
    /// - parameter cbCentralManager: Optional instance of `CBCentralManager` to be used as a `manager`. If you
    /// skip this parameter, there will be created an instance of `CBCentralManager` using given queue and options.
    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            cbCentralManager: CBCentralManager? = nil) {
        let delegateWrapper = CBCentralManagerDelegateWrapper()
        let centralManager = cbCentralManager ??
            CBCentralManager(delegate: delegateWrapper, queue: queue, options: options)
        self.init(
            centralManager: centralManager,
            delegateWrapper: delegateWrapper,
            peripheralProvider: PeripheralProvider(),
            connector: Connector(centralManager: centralManager, delegateWrapper: delegateWrapper)
        )
    }

    /// Attaches RxBluetoothKit delegate to CBCentralManager.
    /// This method is useful in cases when delegate of CBCentralManager was reassigned outside of
    /// RxBluetoothKit library (e.g. CBCentralManager was used in some other library or used in non-reactive way)
    public func attach() {
        manager.delegate = delegateWrapper
    }

    // MARK: State

    public var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unknown
    }

    public func observeState() -> Observable<BluetoothState> {
        return self.delegateWrapper.didUpdateState.asObservable()
    }

    public func observeStateWithInitialValue() -> Observable<BluetoothState> {
        return Observable.deferred { [weak self] in
            guard let self = self else {
                RxBluetoothKitLog.w("observeState - CentralManager deallocated")
                return .never()
            }

            return self.delegateWrapper.didUpdateState.asObservable()
                .startWith(self.state)
        }
    }

    // MARK: Scanning

    /// Value indicating if manager is currently scanning.
    public var isScanInProgress: Bool {
        lock.lock(); defer { lock.unlock() }
        return scanDisposable != nil
    }

    /// Scans for `Peripheral`s after subscription to returned observable. First parameter `serviceUUIDs` is
    /// an array of `Service` UUIDs which needs to be implemented by a peripheral to be discovered. If user don't want to
    /// filter any peripherals, `nil` can be used instead. Additionally dictionary of
    /// [CBCentralManager specific options](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options)
    /// can be passed to allow further customisation.
    /// Scans by default are infinite streams of `ScannedPeripheral` structures which need to be stopped by the user. For
    /// example this can be done by limiting scanning to certain number of peripherals or time:
    /// ```
    /// centralManager.scanForPeripherals(withServices: nil)
    ///     .timeout(3.0, timeoutScheduler)
    ///     .take(2)
    /// ```
    ///
    /// There can be only one ongoing scanning. It will return `BluetoothError.scanInProgress` error if
    /// this method will be called when there is already ongoing scan.
    /// As a result you will receive `ScannedPeripheral` which contains `Peripheral` object, `AdvertisementData` and
    /// peripheral's RSSI registered during discovery. You can then `establishConnection(_:options:)` and do other
    /// operations.
    ///
    /// - seealso: `Peripheral`
    ///
    /// - parameter serviceUUIDs: Services of peripherals to search for. Nil value will accept all peripherals.
    /// - parameter options: Optional scanning options.
    /// - returns: Infinite stream of scanned peripherals.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.scanInProgress`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil)
                    -> Observable<ScannedPeripheral> {
        let observable: Observable<ScannedPeripheral> = Observable.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(BluetoothError.destroyed)
                return Disposables.create()
            }
            strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
            if strongSelf.scanDisposable != nil {
                observer.onError(BluetoothError.scanInProgress)
                return Disposables.create()
            }
            strongSelf.scanDisposable = strongSelf.delegateWrapper.didDiscoverPeripheral
                    .flatMap { [weak self] (cbPeripheral, advertisment, rssi) -> Observable<ScannedPeripheral> in
                        guard let strongSelf = self else {
                            throw BluetoothError.destroyed
                        }
                        let peripheral = strongSelf.retrievePeripheral(for: cbPeripheral)
                        let advertismentData = AdvertisementData(advertisementData: advertisment)
                        return .just(ScannedPeripheral(peripheral: peripheral,
                                advertisementData: advertismentData, rssi: rssi))
                    }
                    .subscribe(observer)

            strongSelf.manager.scanForPeripherals(withServices: serviceUUIDs, options: options)

            return Disposables.create { [weak self] in
                guard let strongSelf = self else { return }
                // When disposed, stop scan and dispose scanning
                if strongSelf.state == .poweredOn {
                    strongSelf.manager.stopScan()
                }
                do { strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
                    strongSelf.scanDisposable?.dispose()
                    strongSelf.scanDisposable = nil
                }
            }
        }

        return ensure(.poweredOn, observable: observable)
    }

    // MARK: Peripheral's Connection Management

    /// Establishes connection with a given `Peripheral`.
    /// When connection did succeded it sends event with `Peripheral` - from now on it is possible to call all other methods that require connection.
    /// The connection is automatically disconnected when resulting Observable is unsubscribed.
    /// On the other hand when the connection is interrupted or failed by the device or the system, the Observable will be unsubscribed as well
    /// following `BluetoothError.peripheralConnectionFailed` or `BluetoothError.peripheralDisconnected` emission.
    /// Additionally you can pass optional [dictionary](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Connection_Options)
    /// to customise the behaviour of connection.
    ///
    /// - parameter peripheral: The `Peripheral` to which `CentralManager` is attempting to establish connection.
    /// - parameter options: Dictionary to customise the behaviour of connection.
    /// - returns: `Observable` which emits next event after connection is established.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.peripheralIsAlreadyObservingConnection`
    /// * `BluetoothError.peripheralConnectionFailed`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func establishConnection(_ peripheral: Peripheral, options: [String: Any]? = nil) -> Observable<Peripheral> {
        let observable = connector.establishConnection(with: peripheral, options: options)
        return ensure(.poweredOn, observable: observable)
    }

    // MARK: Retrieving Lists of Peripherals

    /// Returns list of the `Peripheral`s which are currently connected to the `CentralManager` and contain
    /// all of the specified `Service`'s UUIDs.
    ///
    /// - parameter serviceUUIDs: A list of `Service` UUIDs
    /// - returns: Retrieved `Peripheral`s. They are in connected state and contain all of the
    /// `Service`s with UUIDs specified in the `serviceUUIDs` parameter.
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
        return manager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
            .map { self.retrievePeripheral(for: $0) }
    }

    /// Returns list of `Peripheral`s by their identifiers which are known to `CentralManager`.
    ///
    /// - parameter identifiers: List of `Peripheral`'s identifiers which should be retrieved.
    /// - returns: Retrieved `Peripheral`s.
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        return manager.retrievePeripherals(withIdentifiers: identifiers)
            .map { self.retrievePeripheral(for: $0) }
    }

    // MARK: Connection and disconnection observing

    /// Emits `Peripheral` instance when it's connected.
    ///
    /// - parameter peripheral: Optional `Peripheral` which is observed for connection. When not specified it will observe fo any `Peripheral`.
    /// - returns: Observable which emits next events when `peripheral` was connected.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeConnect(for peripheral: Peripheral? = nil) -> Observable<Peripheral> {
        let observable = delegateWrapper.didConnectPeripheral
            .filter { peripheral != nil ? ($0 == peripheral!.peripheral) : true }
            .map { [weak self] (cbPeripheral: CBPeripheral) -> Peripheral in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return peripheral ?? strongSelf.retrievePeripheral(for: cbPeripheral)
            }
      return ensure(.poweredOn, observable: observable)
    }

    /// Emits `Peripheral` instance when it's disconnected.
    /// - parameter peripheral: Optional `Peripheral` which is observed for disconnection. When not specified it will observe for any `Peripheral`.
    /// - returns: Observable which emits next events when `Peripheral` instance was disconnected.
    /// It provides optional error which may contain more information about the cause of the disconnection
    /// if it wasn't the `cancelPeripheralConnection` call.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeDisconnect(for peripheral: Peripheral? = nil) -> Observable<(Peripheral, DisconnectionReason?)> {
        let observable = delegateWrapper.didDisconnectPeripheral
            .filter { peripheral != nil ? ($0.0 == peripheral!.peripheral) : true }
            .map { [weak self] (cbPeripheral, error) -> (Peripheral, DisconnectionReason?) in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                let peripheral = peripheral ?? strongSelf.retrievePeripheral(for: cbPeripheral)
                return (peripheral, error)
            }
        return ensure(.poweredOn, observable: observable)
                .catch { error in
                    if error is BluetoothError, let peripheral = peripheral {
                        return .concat(.just((peripheral, error)), .error(error))
                    } else {
                        return .error(error)
                    }
                }
    }

    // MARK: ANCS

    /// Emits boolean values according to ancsAuthorized property on a CBPeripheral.
    ///
    /// - parameter peripheral: `Peripheral` which is observed for ancsAuthorized chances.
    /// - returns: Observable which emits next events when `ancsAuthorized` property changes on a peripheral.
    #if !os(macOS)
    @available(iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func observeANCSAuthorized(for peripheral: Peripheral) -> Observable<Bool> {
        let observable = delegateWrapper.didUpdateANCSAuthorizationForPeripheral
            .asObservable()
            .filter { $0 == peripheral.peripheral }
            // ancsAuthorized is a Bool by default, but the testing framework
            // will use Bool! instead. In order to support that we are converting
            // to optional and unwrapping the value.
            .map { ($0.ancsAuthorized as Bool?)! }

        return ensure(.poweredOn, observable: observable)
    }
    #endif

    // MARK: Internal functions

    /// Ensure that specified `peripheral` is connected during subscription.
    /// - parameter peripheral: `Peripheral` which should be connected during subscription.
    /// - returns: Observable which emits error when `peripheral` is disconnected during subscription.
    func ensurePeripheralIsConnected<T>(_ peripheral: Peripheral) -> Observable<T> {
        return .deferred {
            if !peripheral.isConnected {
                throw BluetoothError.peripheralDisconnected(peripheral, nil)
            }
            return self.delegateWrapper.didDisconnectPeripheral
                .filter { $0.0 == peripheral.peripheral }
                .map { (_, error) -> T in
                    throw BluetoothError.peripheralDisconnected(peripheral, error)
            }
        }
    }

    func retrievePeripheral(for cbPeripheral: CBPeripheral) -> Peripheral {
        return peripheralProvider.provide(for: cbPeripheral, centralManager: self)
    }
}
