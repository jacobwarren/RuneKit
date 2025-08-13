import Foundation

// Thread-safe append-only collector optimized for use from callbacks that may run on different contexts.
// In our usage, focusRecorder is invoked during render on the same task, but to satisfy the compiler's
// concurrency checks, we avoid mutating a captured Array from a TaskLocal closure by providing an object.
final class HooksFocusCollector: @unchecked Sendable {
    private var storage: [String] = []
    private let lock = NSLock()

    func record(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        storage.append(path)
    }

    func snapshot() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }
}
