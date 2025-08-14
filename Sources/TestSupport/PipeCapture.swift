import Foundation

/// Simple helper to drain a Pipe concurrently during tests to avoid writer-side blocking.
/// Usage:
///   let cap = PipeCapture()
///   let out = cap.start()    // pass `out` to code under test
///   ... perform writes ...
///   let s = await cap.finishAndReadString()
public final class PipeCapture {
    private let pipe = Pipe()
    private var readerTask: Task<Data, Never>?

    public init() {}

    /// Returns the writable FileHandle for the code under test and starts draining the read side.
    public func start() -> FileHandle {
        let readHandle = pipe.fileHandleForReading
        readerTask = Task {
            // Blocking read in background task; this continuously drains the pipe
            readHandle.readDataToEndOfFile()
        }
        return pipe.fileHandleForWriting
    }

    /// Close the writer, await the reader, and return captured UTF-8 string.
    public func finishAndReadString() async -> String {
        // Close writer to signal EOF
        pipe.fileHandleForWriting.closeFile()
        let data = await readerTask?.value ?? Data()
        pipe.fileHandleForReading.closeFile()
        return String(decoding: data, as: UTF8.self)
    }
}

