import Foundation

/// Thread-safe collector used during render to gather effect registrations
/// Exists as a separate file/type to be Sendable-capture friendly in @Sendable closures.
public final class EffectCollectorBox: @unchecked Sendable {
    public struct Entry: Sendable {
        public let id: String
        public let deps: String?
        public let effect: @Sendable () async -> (() -> Void)?
    }
    private var items: [Entry] = []
    private let lock = NSLock()
    public init() {}
    public func add(id: String, deps: String?, effect: @Sendable @escaping () async -> (() -> Void)?) {
        lock.lock(); defer { lock.unlock() }
        items.append(Entry(id: id, deps: deps, effect: effect))
    }
    public func snapshot() -> [Entry] {
        lock.lock(); defer { lock.unlock() }
        return items
    }
}
