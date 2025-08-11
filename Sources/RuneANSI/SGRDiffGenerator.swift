import Foundation

/// Computes minimal SGR parameter sequences to transition between attribute states.
struct SGRDiffGenerator {
    // Tiny LRU cache for attributes -> SGR parameters
    private struct CacheEntry { let key: TextAttributes; let value: [Int] }
    private var cache: [CacheEntry] = []
    private let cacheCapacity = 16

    var profile: TerminalProfile = .trueColor

    mutating func attributesToParameters(_ attrs: TextAttributes) -> [Int] {
        if let idx = cache.firstIndex(where: { $0.key == attrs }) {
            let entry = cache.remove(at: idx)
            cache.insert(entry, at: 0)
            return entry.value
        }
        var gen = SGRParameterGenerator()
        gen.profile = profile
        let params = gen.attributesToSGRParameters(attrs)
        // Insert into LRU
        cache.insert(CacheEntry(key: attrs, value: params), at: 0)
        if cache.count > cacheCapacity { _ = cache.popLast() }
        return params
    }

    /// Compute minimal parameter sequence from 'from' -> 'to'.
    /// Current policy: emit parameters for 'to' (no per-attribute off toggles), or [0] when returning to default.
    mutating func diff(from: TextAttributes, to: TextAttributes) -> [Int] {
        if from == to { return [] }
        if to.isDefault { return [0] }
        return attributesToParameters(to)
    }
}
