import Foundation

public protocol TerminalOutputEncoder: Sendable {
    func write(_ string: String)
}

public final class FileHandleOutputEncoder: TerminalOutputEncoder, @unchecked Sendable {
    private let handle: FileHandle
    public init(handle: FileHandle) { self.handle = handle }
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
}

/// Encoder that routes writes through the single OutputWriter actor
public final class OutputWriterTerminalEncoder: TerminalOutputEncoder, @unchecked Sendable {
    private let writer: OutputWriter
    public init(writer: OutputWriter) { self.writer = writer }
    public func write(_ string: String) {
        // Fire-and-forget; ordering is preserved by the writer actor
        Task.detached { [writer] in await writer.write(string) }
    }
    public func flush() async { await writer.flush() }
}
