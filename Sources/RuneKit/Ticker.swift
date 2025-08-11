import Foundation

/// A small cooperative ticker that invokes an async closure at a fixed interval until cancelled
///
/// - Lightweight and generic: no spinner-specific logic
/// - Cancellation-safe: cancelling the ticker stops future ticks; deinit also cancels
/// - Intended for driving periodic rerenders or small housekeeping tasks
public final class Ticker: @unchecked Sendable {
    private var task: Task<Void, Never>?
    private let id = UUID()

    public init(every interval: Duration, action: @escaping @Sendable () async -> Void) {
        task = Task { [interval] in
            // Run until cancelled
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                if Task.isCancelled { break }
                await action()
            }
        }
    }

    /// Cancel the ticker; idempotent
    public func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancel()
    }
}
