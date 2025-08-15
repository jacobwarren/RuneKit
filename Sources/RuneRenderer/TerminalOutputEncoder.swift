import Foundation

public protocol TerminalOutputEncoder: Sendable {
    func write(_ string: String) async
    func flush() async
}

public final class FileHandleOutputEncoder: TerminalOutputEncoder, @unchecked Sendable {
    private let handle: FileHandle
    public init(handle: FileHandle) { self.handle = handle }
    public func write(_ string: String) async {
        if let data = string.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
    public func flush() async { /* no-op for file handle encoder */ }
}

/// Encoder that routes writes through the single OutputWriter actor
public final class OutputWriterTerminalEncoder: TerminalOutputEncoder, @unchecked Sendable {
    private let writer: OutputWriter
    // Serialize encoder->writer calls to preserve ordering across mixed sources
    private actor Serializer {
        private var pendingTask: Task<Void, Never>?
        private var operations: [() async -> Void] = []

        func enqueue(_ op: @escaping @Sendable () async -> Void) async {
            operations.append(op)

            // If no task is running, start one
            if pendingTask == nil {
                pendingTask = Task { [weak self] in
                    await self?.processAllOperations()
                }
            }

            // Wait for the current processing task to complete
            await pendingTask?.value
        }

        func waitAll() async {
            // Simply wait for the current task to complete (if any)
            await pendingTask?.value
        }

        private func processAllOperations() async {
            while !operations.isEmpty {
                let op = operations.removeFirst()
                await op()
            }
            // Clear the task reference when done
            pendingTask = nil
        }
    }
    private let serializer = Serializer()

    public init(writer: OutputWriter) { self.writer = writer }

    public func write(_ string: String) async {
        // Await serialization to ensure strict ordering relative to callers
        await serializer.enqueue { [writer] in await writer.write(string) }
    }

    public func flush() async {
        // First wait for all pending writes to complete
        await serializer.waitAll()
        // Then flush the writer directly (no serialization needed since all writes are done)
        await writer.flush()
    }
}
