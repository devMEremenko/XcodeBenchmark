import Foundation
import CoreBluetooth

/// Deprecated, use CentralManager.init(queue:options:onWillRestoreCentralManagerState:) instead
@available(*, deprecated, renamed: "CentralManagerRestoredStateType")
public struct RestoredState: CentralManagerRestoredStateType {
    let centralManagerRestoredState: CentralManagerRestoredState

    public var restoredStateData: [String: Any] { return centralManagerRestoredState.restoredStateData }

    public var centralManager: CentralManager { return centralManagerRestoredState.centralManager }

    public var peripherals: [Peripheral] { return centralManagerRestoredState.peripherals }

    public var scanOptions: [String: AnyObject]? { return centralManagerRestoredState.scanOptions }

    public var services: [Service] { return centralManagerRestoredState.services }

    init(centralManagerRestoredState: CentralManagerRestoredState) {
        self.centralManagerRestoredState = centralManagerRestoredState
    }
}
