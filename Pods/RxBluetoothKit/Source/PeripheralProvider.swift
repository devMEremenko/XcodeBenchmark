import Foundation
import CoreBluetooth

/// Class for providing peripherals and peripheral wrappers
class PeripheralProvider {

    private let peripheralsBox: ThreadSafeBox<[Peripheral]> = ThreadSafeBox(value: [])

    private let delegateWrappersBox: ThreadSafeBox<[UUID: CBPeripheralDelegateWrapper]> = ThreadSafeBox(value: [:])

    /// Provides `CBPeripheralDelegateWrapper` for specified `CBPeripheral`.
    ///
    /// If it was previously created it returns that object, so that there can be only
    /// one `CBPeripheralDelegateWrapper` per `CBPeripheral`.
    ///
    /// If not it creates new one.
    ///
    /// - parameter peripheral: Peripheral for which to provide delegate wrapper
    /// - returns: Delegate wrapper for specified peripheral.
    func provideDelegateWrapper(for peripheral: CBPeripheral) -> CBPeripheralDelegateWrapper {
        if let delegateWrapper = delegateWrappersBox.read({ $0[peripheral.uuidIdentifier] }) {
            return delegateWrapper
        } else {
            delegateWrappersBox.compareAndSet(
                compare: { $0[peripheral.uuidIdentifier] == nil },
                set: { $0[peripheral.uuidIdentifier] = CBPeripheralDelegateWrapper()}
            )
            return delegateWrappersBox.read({ $0[peripheral.uuidIdentifier]! })
        }
    }

    /// Provides `Peripheral` for specified `CBPeripheral`.
    ///
    /// If it was previously created it returns that object, so that there can be only one `Peripheral`
    /// per `CBPeripheral`. If not it creates new one.
    ///
    /// - parameter peripheral: Peripheral for which to provide delegate wrapper
    /// - returns: `Peripheral` for specified peripheral.
    func provide(for cbPeripheral: CBPeripheral, centralManager: CentralManager) -> Peripheral {
        if let peripheral = find(cbPeripheral) {
            return peripheral
        } else {
            return createAndAddToBox(cbPeripheral, manager: centralManager)
        }
    }

    fileprivate func createAndAddToBox(_ cbPeripheral: CBPeripheral, manager: CentralManager) -> Peripheral {
        peripheralsBox.compareAndSet(
            compare: { peripherals in
                return !peripherals.contains(where: { $0.peripheral == cbPeripheral })
            },
            set: { [weak self] peripherals in
                guard let strongSelf = self else { return }
                let delegateWrapper = strongSelf.provideDelegateWrapper(for: cbPeripheral)
                let newPeripheral = Peripheral(
                    manager: manager,
                    peripheral: cbPeripheral,
                    delegateWrapper: delegateWrapper
                )
                peripherals.append(newPeripheral)
            }
        )
        return peripheralsBox.read { peripherals in
            return peripherals.first(where: { $0.peripheral == cbPeripheral })!
        }
    }

    fileprivate func find(_ cbPeripheral: CBPeripheral) -> Peripheral? {
        return peripheralsBox.read { peripherals in
            return peripherals.first(where: { $0.peripheral == cbPeripheral})
        }
    }
}
