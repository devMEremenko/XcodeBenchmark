/// Simple logging interface.
///
/// An application that wants RxBluetoothKit to use its logging solution will
/// need to provide a type that conforms to this signature and assign it to
/// `RxBluetoothKitLogger.defaultLogger`.
public protocol Logger {
    /// Logs the given message (using StaticString parameters).
    ///
    /// - Parameters:
    ///   - message: The message to be logger.
    ///              Provided as a closure to avoid performing interpolation if
    ///              the message is not going to be logged.
    ///   - level: The severity of the message.
    ///            A logger can use this flag to decide if to log or ignore
    ///            this specific message.
    ///   - file: The file name of the file where the message was created.
    ///   - function: The function name where the message was created.
    ///   - line: The line number in the file where the message was created.
    func log(
        _ message: @autoclosure () -> String,
        level: RxBluetoothKitLog.LogLevel,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    /// Logs the given message (using regular String parameters).
    ///
    /// - Parameters:
    ///   - message: The message to be logger.
    ///              Provided as a closure to avoid performing interpolation if
    ///              the message is not going to be logged.
    ///   - level: The severity of the message.
    ///            A logger can use this flag to decide if to log or ignore
    ///            this specific message.
    ///   - file: The file name of the file where the message was created.
    ///   - function: The function name where the message was created.
    ///   - line: The line number in the file where the message was created.
    func log(
        _ message: @autoclosure () -> String,
        level: RxBluetoothKitLog.LogLevel,
        file: String,
        function: String,
        line: UInt
    )

    /// Set new log level.
    /// - Parameter logLevel: New log level to be applied.
    func setLogLevel(_ logLevel: RxBluetoothKitLog.LogLevel)

    /// Get current log level.
    /// - Returns: Currently set log level.
    func getLogLevel() -> RxBluetoothKitLog.LogLevel
}
