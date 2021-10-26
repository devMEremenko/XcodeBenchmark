import Foundation
import CoreBluetooth
import RxSwift

/// RxBluetoothKit specific logging class which gives access to its settings.
public class RxBluetoothKitLog: ReactiveCompatible {

    fileprivate static let subject = PublishSubject<String>()

    /// Set new log level.
    /// - Parameter logLevel: New log level to be applied.
    public static func setLogLevel(_ logLevel: RxBluetoothKitLog.LogLevel) {
        RxBluetoothKitLogger.defaultLogger.setLogLevel(logLevel)
    }

    /// Get current log level.
    /// - Returns: Currently set log level.
    public static func getLogLevel() -> RxBluetoothKitLog.LogLevel {
        return RxBluetoothKitLogger.defaultLogger.getLogLevel()
    }

    private init() {
    }

    /// Log levels for internal logging mechanism.
    public enum LogLevel: UInt8 {
        /// Logging is disabled
        case none = 255
        /// All logs are monitored.
        case verbose = 0
        /// Only debug logs and of higher importance are logged.
        case debug = 1
        /// Only info logs and of higher importance are logged.
        case info = 2
        /// Only warning logs and of higher importance are logged.
        case warning = 3
        /// Only error logs and of higher importance are logged.
        case error = 4
    }

    fileprivate static func log(
        with logLevel: LogLevel,
        message: @autoclosure () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        let loggedMessage = message()
        RxBluetoothKitLogger.defaultLogger.log(
            loggedMessage,
            level: logLevel,
            file: file,
            function: function,
            line: line
        )
        if getLogLevel() <= logLevel {
            subject.onNext(loggedMessage)
        }
    }

    static func v(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(with: .verbose, message: message(), file: file, function: function, line: line)
    }

    static func d(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(with: .debug, message: message(), file: file, function: function, line: line)
    }

    static func i(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(with: .info, message: message(), file: file, function: function, line: line)
    }

    static func w(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(with: .warning, message: message(), file: file, function: function, line: line)
    }

    static func e(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(with: .error, message: message(), file: file, function: function, line: line)
    }
}

extension RxBluetoothKitLog.LogLevel: Comparable {
    public static func < (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func <= (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func > (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }

    public static func >= (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }

    public static func == (lhs: RxBluetoothKitLog.LogLevel, rhs: RxBluetoothKitLog.LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

protocol Loggable {
    var logDescription: String { get }
}

extension Data: Loggable {
    var logDescription: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

extension BluetoothState: Loggable {
    var logDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        }
    }
}

extension CBCharacteristicWriteType: Loggable {
    var logDescription: String {
        switch self {
        case .withResponse: return "withResponse"
        case .withoutResponse: return "withoutResponse"
        @unknown default:
            return "unknown write type"
        }
    }
}

extension UUID: Loggable {
    var logDescription: String {
        return uuidString
    }
}

extension CBUUID: Loggable {
    @objc var logDescription: String {
        return uuidString
    }
}

extension CBCentralManager: Loggable {
    @objc var logDescription: String {
        return "CentralManager(\(UInt(bitPattern: ObjectIdentifier(self))))"
    }
}

extension CBPeripheral: Loggable {
    @objc var logDescription: String {
        return "Peripheral(uuid: \(uuidIdentifier), name: \(String(describing: name)))"
    }
}

extension CBCharacteristic: Loggable {
    @objc var logDescription: String {
        return "Characteristic(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self)))))"
    }
}

extension CBService: Loggable {
    @objc var logDescription: String {
        return "Service(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self)))))"
    }
}

extension CBDescriptor: Loggable {
    @objc var logDescription: String {
        return "Descriptor(uuid: \(uuid), id: \((UInt(bitPattern: ObjectIdentifier(self)))))"
    }
}

extension CBPeripheralManager: Loggable {
    @objc var logDescription: String {
        return "PeripheralManager(\(UInt(bitPattern: ObjectIdentifier(self))))"
    }
}

extension CBATTRequest: Loggable {
    @objc var logDescription: String {
        return "ATTRequest(\(UInt(bitPattern: ObjectIdentifier(self)))"
    }
}

extension CBCentral: Loggable {
    @objc var logDescription: String {
        return "CBCentral(uuid: \(uuidIdentifier))"
    }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
extension CBL2CAPChannel: Loggable {
    @objc var logDescription: String {
        return "CBL2CAPChannel(\(UInt(bitPattern: ObjectIdentifier(self)))"
    }
}

extension Array where Element: Loggable {
    var logDescription: String {
        return "[\(map { $0.logDescription }.joined(separator: ", "))]"
    }
}

extension Reactive where Base == RxBluetoothKitLog {
    /**
     * This is continuous value, which emits before a log is printed to standard output.
     *
     * - it never fails
     * - it delivers events on `MainScheduler.instance`
     * - `share(scope: .whileConnected)` sharing strategy
     */
    public var log: Observable<String> {
        return RxBluetoothKitLog.subject.asObserver()
            .observe(on: MainScheduler.instance)
            .catchAndReturn("")
            .share(scope: .whileConnected)
    }
}
