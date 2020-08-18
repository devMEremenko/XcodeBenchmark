import Foundation

class WeakBox<T: AnyObject>: CustomDebugStringConvertible {
    weak var value: T?
    init() {}
    init(value: T) {
        self.value = value
    }
}

extension WeakBox {
    var debugDescription: String {
        return "WeakBox(\(String(describing: value)))"
    }
}

/// `ThreadSafeBox` is a helper class that allows use of resource (value) in a thread safe manner.
/// All read and write calls are wrapped in concurrent `DispatchQueue` which protects writing to
/// resource from more than 1 thread at a time.
class ThreadSafeBox<T>: CustomDebugStringConvertible {
    private let queue = DispatchQueue(label: "com.polidea.RxBluetoothKit.ThreadSafeBox")
    fileprivate var value: T
    init(value: T) {
        self.value = value
    }

    func read<Result: Any>(_ block: (T) -> Result) -> Result {
        var result: Result! = nil
        queue.sync {
            result = block(value)
        }
        return result
    }

    func write(_ block: @escaping (inout T) -> Void) {
        queue.async {
            block(&self.value)
        }
    }

    func writeSync(_ block: @escaping (inout T) -> Void) {
        queue.sync {
            block(&self.value)
        }
    }

    @discardableResult func compareAndSet(compare: (T) -> Bool, set: @escaping (inout T) -> Void) -> Bool {
        var result: Bool = false
        queue.sync {
            result = compare(value)
            if result {
                set(&self.value)
            }
        }
        return result
    }
}

extension ThreadSafeBox {
    var debugDescription: String {
        return "ThreadSafeBox(\(String(describing: value)))"
    }
}
