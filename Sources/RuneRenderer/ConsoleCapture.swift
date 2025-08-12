import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Actor-based console capture system for stdout/stderr redirection
///
/// This actor provides thread-safe capture of stdout and stderr output,
/// buffering log lines for display above the live application region.
/// It prevents random prints from corrupting the UI while preserving logs.
///
/// Key features:
/// - Thread-safe stdout/stderr capture using pipes
/// - Background reader with line buffering
/// - Ordered log display above live region
/// - Single-writer ensures proper ordering
/// - Optional toggle for enable/disable
/// - Integration with RuneKit's rendering system
///
/// ## Usage
///
/// ```swift
/// let capture = ConsoleCapture()
/// await capture.startCapture()
///
/// // Now all print() calls are captured
/// print("This will appear above the live region")
///
/// // Get captured logs for display
/// let logs = await capture.getBufferedLogs()
///
/// await capture.stopCapture()
/// ```
///
/// ## Integration with FrameBuffer
///
/// The ConsoleCapture is designed to work with FrameBuffer to display
/// logs above the live application region:
///
/// ```swift
/// let config = RenderConfiguration(enableConsoleCapture: true)
/// let frameBuffer = FrameBuffer(configuration: config)
/// // Console capture is automatically managed
/// ```
public actor ConsoleCapture {
    /// Captured log line with timestamp
    public struct LogLine: Sendable {
        public let content: String
        public let timestamp: Date
        public let source: LogSource

        public init(content: String, timestamp: Date = Date(), source: LogSource) {
            self.content = content
            self.timestamp = timestamp
            self.source = source
        }
    }

    /// Source of the log line
    public enum LogSource: Sendable {
        case stdout
        case stderr
    }

    // MARK: - Private State

    /// Whether capture is currently active
    private var isCapturing = false

    /// Saved duplicates of original stdout/stderr file descriptors (for restoration)
    private var savedStdoutFD: Int32 = -1
    private var savedStderrFD: Int32 = -1

    /// Pipe for capturing stdout
    private var stdoutPipe: Pipe?

    /// Pipe for capturing stderr
    private var stderrPipe: Pipe?

    /// Background task for reading stdout
    private var stdoutReaderTask: Task<Void, Never>?

    /// Background task for reading stderr
    private var stderrReaderTask: Task<Void, Never>?

    /// Buffer for captured log lines
    private var logBuffer: [LogLine] = []

    /// Maximum number of log lines to buffer
    private let maxBufferSize: Int

    /// Whether to enable debug logging for the capture system itself
    private let enableDebugLogging: Bool

    /// Previous SIGPIPE handler (for restoration)
    private var previousSigpipeHandler: sig_t?

    // MARK: - Initialization

    /// Initialize console capture with configuration
    /// - Parameters:
    ///   - maxBufferSize: Maximum number of log lines to buffer (default: 1000)
    ///   - enableDebugLogging: Whether to enable debug logging (default: false)
    public init(maxBufferSize: Int = 1000, enableDebugLogging: Bool = false) {
        self.maxBufferSize = maxBufferSize
        self.enableDebugLogging = enableDebugLogging
    }

    /// Deinitializer ensures capture is stopped and handles are restored
    deinit {
        // Note: Cannot perform async operations in deinit
        // But we can do synchronous cleanup to prevent resource leaks
        if isCapturing {
            // Cancel background tasks
            stdoutReaderTask?.cancel()
            stderrReaderTask?.cancel()

            // Restore file descriptors synchronously using saved duplicates
            if savedStdoutFD >= 0 { dup2(savedStdoutFD, STDOUT_FILENO); close(savedStdoutFD); savedStdoutFD = -1 }
            if savedStderrFD >= 0 { dup2(savedStderrFD, STDERR_FILENO); close(savedStderrFD); savedStderrFD = -1 }

            // Close pipes synchronously
            try? stdoutPipe?.fileHandleForWriting.close()
            try? stderrPipe?.fileHandleForWriting.close()
            try? stdoutPipe?.fileHandleForReading.close()
            try? stderrPipe?.fileHandleForReading.close()

            // Restore SIGPIPE handler
            if let previousHandler = previousSigpipeHandler {
                signal(SIGPIPE, previousHandler)
            }
        }
    }

    // MARK: - Public Interface

    /// Whether console capture is currently active
    public var isCaptureActive: Bool {
        isCapturing
    }

    /// Start capturing stdout and stderr
    ///
    /// This redirects stdout and stderr to pipes and starts background
    /// readers to buffer the output. All subsequent print() calls and
    /// stderr writes will be captured.
    ///
    /// Safe to call multiple times - subsequent calls are ignored.
    public func startCapture() async {
        guard !isCapturing else { return }

        debugLog("Starting console capture...")

        // Install SIGPIPE handler to prevent crashes
        previousSigpipeHandler = signal(SIGPIPE, SIG_IGN)

        // Duplicate original stdout/stderr FDs for restoration later
        // Important: dup the raw FDs so restoration doesn't depend on Swift FileHandle objects
        #if os(Linux)
        savedStdoutFD = Glibc.dup(STDOUT_FILENO)
        savedStderrFD = Glibc.dup(STDERR_FILENO)
        #else
        savedStdoutFD = Darwin.dup(STDOUT_FILENO)
        savedStderrFD = Darwin.dup(STDERR_FILENO)
        #endif

        // Create pipes for capture
        stdoutPipe = Pipe()
        stderrPipe = Pipe()

        guard let stdoutPipe,
              let stderrPipe
        else {
            debugLog("Failed to create pipes for console capture")
            return
        }

        // Redirect stdout and stderr to our pipes
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // Start background readers
        stdoutReaderTask = Task { [weak self] in
            await self?.readFromPipe(stdoutPipe.fileHandleForReading, source: .stdout)
        }

        stderrReaderTask = Task { [weak self] in
            await self?.readFromPipe(stderrPipe.fileHandleForReading, source: .stderr)
        }

        isCapturing = true
        debugLog("Console capture started successfully")
    }

    /// Stop capturing stdout and stderr
    ///
    /// This restores the original stdout and stderr handles and stops
    /// the background readers. Subsequent print() calls will go to
    /// the original destinations.
    ///
    /// Safe to call multiple times - subsequent calls are ignored.
    public func stopCapture() async {
        guard isCapturing else { return }

        debugLog("Stopping console capture...")

        // Cancel background readers
        stdoutReaderTask?.cancel()
        stderrReaderTask?.cancel()
        stdoutReaderTask = nil
        stderrReaderTask = nil

        // Restore original file descriptors using saved duplicates
        if savedStdoutFD >= 0 {
            dup2(savedStdoutFD, STDOUT_FILENO)
            close(savedStdoutFD)
            savedStdoutFD = -1
        }
        if savedStderrFD >= 0 {
            dup2(savedStderrFD, STDERR_FILENO)
            close(savedStderrFD)
            savedStderrFD = -1
        }

        // Close pipes safely
        do {
            try stdoutPipe?.fileHandleForWriting.close()
            try stderrPipe?.fileHandleForWriting.close()
            try stdoutPipe?.fileHandleForReading.close()
            try stderrPipe?.fileHandleForReading.close()
        } catch {
            debugLog("Error closing pipes: \(error)")
        }

        // Restore SIGPIPE handler
        if let previousHandler = previousSigpipeHandler {
            signal(SIGPIPE, previousHandler)
            previousSigpipeHandler = nil
        }

        stdoutPipe = nil
        stderrPipe = nil

        isCapturing = false
        debugLog("Console capture stopped successfully")
    }

    /// Get all buffered log lines
    /// - Returns: Array of captured log lines in chronological order
    public func getBufferedLogs() -> [LogLine] {
        logBuffer
    }

    /// Get recent log lines
    /// - Parameter count: Maximum number of recent lines to return
    /// - Returns: Array of most recent log lines
    public func getRecentLogs(count: Int) -> [LogLine] {
        let startIndex = max(0, logBuffer.count - count)
        return Array(logBuffer[startIndex...])
    }

    /// Clear the log buffer
    public func clearBuffer() {
        logBuffer.removeAll()
        debugLog("Log buffer cleared")
    }

    /// Get the current buffer size
    /// - Returns: Number of log lines currently buffered
    public func getBufferSize() -> Int {
        logBuffer.count
    }

    // MARK: - Private Implementation

    /// Read from a pipe and buffer the output
    /// - Parameters:
    ///   - fileHandle: File handle to read from
    ///   - source: Source of the log (stdout or stderr)
    private func readFromPipe(_ fileHandle: FileHandle, source: LogSource) async {
        debugLog("Starting reader for \(source)")

        var buffer = Data()
        let fd = fileHandle.fileDescriptor

        while !Task.isCancelled {
            do {
                // Use non-blocking read with poll to avoid hanging
                if !isDataAvailable(fd: fd) {
                    // No data available, wait a bit and check again
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    continue
                }

                // Try to read available data with a timeout
                let availableData = try readNonBlocking(fileHandle: fileHandle)

                if availableData.isEmpty {
                    // No data available, continue polling
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    continue
                }

                buffer.append(availableData)

                // Process complete lines
                await processBuffer(&buffer, source: source)
            } catch {
                debugLog("Error reading from \(source): \(error)")
                // Check if it's a broken pipe error
                if let posixError = error as? POSIXError, posixError.code == .EPIPE {
                    debugLog("Broken pipe detected for \(source), stopping reader")
                }
                break
            }
        }

        // Process any remaining data in buffer
        if !buffer.isEmpty {
            await processBuffer(&buffer, source: source, forceFlush: true)
        }

        debugLog("Reader for \(source) stopped")
    }

    /// Check if data is available on a file descriptor without blocking
    /// - Parameter fd: File descriptor to check
    /// - Returns: True if data is available to read
    private func isDataAvailable(fd: Int32) -> Bool {
        var pollfd = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
        let result = poll(&pollfd, 1, 0) // 0 timeout = non-blocking
        return result > 0 && (pollfd.revents & Int16(POLLIN)) != 0
    }

    /// Read data from file handle without blocking
    /// - Parameter fileHandle: File handle to read from
    /// - Returns: Available data (may be empty)
    /// - Throws: IO errors
    private func readNonBlocking(fileHandle: FileHandle) throws -> Data {
        let fd = fileHandle.fileDescriptor

        // Set non-blocking mode
        let flags = fcntl(fd, F_GETFL)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        defer {
            // Restore blocking mode
            _ = fcntl(fd, F_SETFL, flags)
        }

        // Try to read up to 4KB at a time
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let bytesRead = read(fd, &buffer, bufferSize)

        if bytesRead < 0 {
            #if os(Linux)
            let errno = Glibc.errno
            #else
            let errno = Darwin.errno
            #endif
            if errno == EAGAIN || errno == EWOULDBLOCK {
                // No data available right now, return empty
                return Data()
            } else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
        } else if bytesRead == 0 {
            // EOF
            return Data()
        } else {
            return Data(buffer.prefix(bytesRead))
        }
    }

    /// Process buffered data and extract complete lines
    /// - Parameters:
    ///   - buffer: Data buffer to process
    ///   - source: Source of the log
    ///   - forceFlush: Whether to flush incomplete lines
    private func processBuffer(_ buffer: inout Data, source: LogSource, forceFlush: Bool = false) async {
        guard let string = String(data: buffer, encoding: .utf8) else { return }

        let lines = string.components(separatedBy: .newlines)

        // Process complete lines (all but the last, unless forceFlush)
        let linesToProcess = forceFlush ? lines : Array(lines.dropLast())

        for line in linesToProcess where !line.isEmpty {
            await addLogLine(LogLine(content: line, source: source))
        }

        // Keep incomplete line in buffer
        if !forceFlush, !lines.isEmpty {
            let remainingLine = lines.last ?? ""
            buffer = remainingLine.data(using: .utf8) ?? Data()
        } else {
            buffer.removeAll()
        }
    }

    /// Add a log line to the buffer
    /// - Parameter logLine: Log line to add
    private func addLogLine(_ logLine: LogLine) async {
        logBuffer.append(logLine)

        // Trim buffer if it exceeds maximum size
        if logBuffer.count > maxBufferSize {
            logBuffer.removeFirst(logBuffer.count - maxBufferSize)
        }

        debugLog("Captured \(logLine.source): \(logLine.content)")
    }

    /// Debug logging for the capture system itself
    /// - Parameter message: Debug message to log
    private func debugLog(_ message: String) {
        if enableDebugLogging {
            // Write directly to saved stderr FD to avoid capture loop
            let fd = (savedStderrFD >= 0) ? savedStderrFD : STDERR_FILENO
            let debugMessage = "[ConsoleCapture] \(message)\n"
            if let data = debugMessage.data(using: .utf8) {
                data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    if let base = ptr.baseAddress {
                        _ = write(fd, base, data.count)
                    }
                }
            }
        }
    }
}
