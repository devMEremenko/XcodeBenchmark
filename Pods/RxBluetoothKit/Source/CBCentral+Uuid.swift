import Foundation
import CoreBluetooth

extension CBCentral {
    /// There is still no identifier property for macOS, that's why we need to retrieve it by value method
    var uuidIdentifier: UUID {
        return value(forKey: "identifier") as! NSUUID as UUID
    }
}
