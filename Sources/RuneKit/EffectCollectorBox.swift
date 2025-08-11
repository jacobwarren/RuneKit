import Foundation

/// Thread-safe collector used during render to gather effect registrations
/// Exists as a separate file/type to be Sendable-capture friendly in @Sendable closures.
public final class EffectCollectorBox: @unchecked Sendable {
    private var items: [(id: String, deps: String?, effect: @Sendable () async -> (() -> Void)?)] = []
    private let lock = NSLock()
    public init() {}
    public func add(id: String, deps: String?, effect: @Sendable @escaping () async -> (() -> Void)?) {
        lock.lock(); defer { lock.unlock() }
        items.append((id: id, deps: deps, effect: effect))
    }
    public func snapshot() -> [(id: String, deps: String?, effect: @Sendable () async -> (() -> Void)?)] {
        lock.lock(); defer { lock.unlock() }
        return items
    }
}

