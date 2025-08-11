import Foundation

// Minimal view-state system for preserving component-local state across rerenders
// keyed by stable identity paths. Synchronous and thread-safe via a serial queue
// to support use within property wrappers without async context.

public final class StateRegistry: @unchecked Sendable {
    public nonisolated(unsafe) static let shared = StateRegistry()
    private let queue = DispatchQueue(label: "rk.state.registry")

    // Keyed by identityPath -> key -> Any state
    private var storage: [String: [String: Any]] = [:]

    public func get<T>(path: String, key: String, initial: @autoclosure () -> T) -> T {
        queue.sync {
            if let dict = storage[path], let value = dict[key] as? T {
                return value
            }
            let initialValue = initial()
            var dict = storage[path] ?? [:]
            dict[key] = initialValue
            storage[path] = dict
            return initialValue
        }
    }

    public func set(path: String, key: String, value: some Any) {
        queue.sync {
            var dict = storage[path] ?? [:]
            dict[key] = value
            storage[path] = dict
        }
    }

    public func reset(path: String) {
        queue.sync { storage[path] = [:] }
    }

    public func clearAll() {
        queue.sync { storage.removeAll() }
    }
}

@propertyWrapper
public struct State<T> {
    private let key: String
    private let initialProvider: () -> T

    public init(_ key: String, initial: @autoclosure @escaping () -> T) {
        self.key = key
        initialProvider = initial
    }

    public var wrappedValue: T {
        get {
            let path = RuntimeStateContext.currentPath
            return StateRegistry.shared.get(path: path, key: key, initial: initialProvider())
        }
        mutating set {
            let path = RuntimeStateContext.currentPath
            StateRegistry.shared.set(path: path, key: key, value: newValue)
        }
    }
}
