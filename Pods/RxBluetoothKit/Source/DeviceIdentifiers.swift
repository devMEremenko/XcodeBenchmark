import CoreBluetooth

/// ServiceIdentifier protocol specifies how information about services of device should look like.
/// Sample implementation could look like:
///
/// ```
/// enum DeviceService: String, ServiceIdentifier {
///     case deviceInformation = "180A"
///     var uuid: CBUUID {
///         return CBUUID(string: self.rawValue)
///     }
/// }
/// ```
/// After implementing this and other protocol `CharacteristicIdentifier, you could call methods even easier
/// thanks to convenience methods in library. This methods do all of the heavy lifting like discovering services, taking
/// them from cache etc. for you. We really recommend you to use it.
public protocol ServiceIdentifier {
    /// Unique identifier of a service.
    var uuid: CBUUID { get }
}

/// Characteristic protocol specifies how information about characteristics of device should look like.
/// Sample implementation could look like:
/// ```
/// enum DeviceCharacteristic: String, CharacteristicIdentifier {
///     case manufacturerName = "2A29"
///     var uuid: CBUUID {
///         return CBUUID(string: self.rawValue)
///     }
///     var service: ServiceIdentifier {
///         switch self {
///         case .ManufacturerName:
///             return XXXService.DeviceInformation
///         }
///     }
/// }
/// ```
public protocol CharacteristicIdentifier {
    /// Unique identifier of a characteristic.
    var uuid: CBUUID { get }
    /// `ServiceIdentifier` instance that this characteristic belongs to.
    var service: ServiceIdentifier { get }
}

/// DescriptorIdentifier protocol specifies how information about descriptors of device should look like.
public protocol DescriptorIdentifier {
    /// Unique identifier of a descriptor.
    var uuid: CBUUID { get }
    /// `CharacteristicIdentifier` instance that this descriptor belongs to.
    var characteristic: CharacteristicIdentifier { get }
}
