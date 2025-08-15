import Foundation

public enum BackpressurePolicy: Sendable {
    case dropNewest
    case dropOldest
    case block
}

public struct OutputWriterMetrics: Sendable {
    public let writeSyscalls: Int
    public let bytesWritten: Int
    public let droppedMessages: Int
}

/// Single-writer actor that serializes all terminal writes and batches them to reduce syscalls.
/// Provides optional backpressure to avoid unbounded memory growth when producers outpace the terminal.
public actor OutputWriter {
    private let handle: FileHandle
    private let bufferSize: Int
    private let maxBufferedBytes: Int
    private let policy: BackpressurePolicy

    // Accumulation buffer
    private var buffer = Data()
    // Metrics
    private var syscalls = 0
    private var totalBytes = 0
    private var dropped = 0

    public init(handle: FileHandle, bufferSize: Int = 8192, maxQueueDepth: Int = 8, policy: BackpressurePolicy = .dropNewest) {
        self.handle = handle
        self.bufferSize = max(512, bufferSize)
        self.maxBufferedBytes = max(self.bufferSize, self.bufferSize * max(1, maxQueueDepth))
        self.policy = policy
    }

    /// Non-atomic write: appended to the internal buffer; flushed when thresholds are exceeded.
    public func write(_ string: String) async {
        guard let data = string.data(using: .utf8) else { return }

        // If a single write is larger than the cap, bypass buffer and write directly
        if data.count >= maxBufferedBytes {
            if !buffer.isEmpty { flush() }
            performSyscall(data)
            return
        }

        // Backpressure: ensure capacity based on policy
        if buffer.count + data.count > maxBufferedBytes {
            switch policy {
            case .dropNewest:
                dropped &+= 1
                return
            case .dropOldest:
                buffer.removeAll(keepingCapacity: true)
            case .block:
                // True blocking: flush immediately to make space
                flush()
                // If still insufficient capacity after flush, the data is too large for our buffer.
                // In this case, fall back to dropping the oldest data to make room.
                if buffer.count + data.count > maxBufferedBytes {
                    buffer.removeAll(keepingCapacity: true)
                }
            }
        }

        buffer.append(data)
        if buffer.count >= bufferSize {
            flush()
        }
    }

    /// Atomic write: flushes the buffer first then writes the string in a single syscall.
    public func writeAtomic(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        if !buffer.isEmpty { flush() }
        performSyscall(data)
    }

    /// Flush the buffer (if non-empty) to the handle.
    public func flush() {
        guard !buffer.isEmpty else { return }
        let data = buffer
        buffer.removeAll(keepingCapacity: true)
        performSyscall(data)
    }

    /// Shutdown writer, ensuring remaining bytes are flushed.
    public func shutdown() {
        flush()
    }

    public func metrics() -> OutputWriterMetrics {
        OutputWriterMetrics(writeSyscalls: syscalls, bytesWritten: totalBytes, droppedMessages: dropped)
    }

    // MARK: - Private
    private func performSyscall(_ data: Data) {
        guard !data.isEmpty else { return }
        do {
            try handle.write(contentsOf: data)
            syscalls &+= 1
            totalBytes &+= data.count
        } catch {
            // Ignore write errors (e.g., closed handle in tests)
        }
    }
}