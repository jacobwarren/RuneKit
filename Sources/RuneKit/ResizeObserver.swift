import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// Global bridge for SIGWINCH -> ResizeObserver
@MainActor private var globalResizeObserver: ResizeObserver?

/// C signal trampoline for SIGWINCH
private func handleWinchC(_ signal: Int32) {
    Task { @MainActor in
        await globalResizeObserver?.handleSignal(signal)
    }
}

/// Actor that coalesces resize (SIGWINCH) events and invokes a debounced callback
public actor ResizeObserver {
    private var isInstalled = false
    private var callback: (@Sendable () async -> Void)?
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: Duration
    private var previousHandler: sig_t?

    public init(debounceInterval: Duration = .milliseconds(25)) {
        self.debounceInterval = debounceInterval
    }

    /// Install SIGWINCH handler and set callback
    public func install(callback: @escaping @Sendable () async -> Void) async {
        guard !isInstalled else { return }
        self.callback = callback
        await MainActor.run { globalResizeObserver = self }
        previousHandler = signal(SIGWINCH, handleWinchC)
        isInstalled = true
    }

    /// Manually notify a resize event (useful for tests); debounced
    public func notifyResizeEvent() async {
        // Cancel existing scheduled task
        debounceTask?.cancel()
        // Schedule new debounced trigger
        let cb = callback
        let interval = debounceInterval
        debounceTask = Task {
            // Coalesce multiple events within interval
            try? await Task.sleep(for: interval)
            if Task.isCancelled { return }
            await cb?()
        }
    }

    /// Internal: invoked by C signal trampoline
    public func handleSignal(_ signal: Int32) async {
        guard signal == SIGWINCH else { return }
        await notifyResizeEvent()
    }

    /// Cleanup and restore previous handler
    public func cleanup() async {
        guard isInstalled else { return }
        debounceTask?.cancel()
        debounceTask = nil
        if let prev = previousHandler { _ = signal(SIGWINCH, prev) }
        previousHandler = nil
        isInstalled = false
        await MainActor.run { globalResizeObserver = nil }
    }

    /// Await completion of the currently scheduled debounced callback, if any.
    /// Useful in tests to avoid brittle fixed-duration sleeps under variable CI load.
    public func waitForPendingCallback() async {
        if let task = debounceTask {
            _ = await task.result
        }
    }

}

