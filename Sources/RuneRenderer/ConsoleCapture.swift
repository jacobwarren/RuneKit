import Foundation

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
    private var isCapturing: Bool = false

    /// Original stdout file handle (saved for restoration)
    private var originalStdout: FileHandle?

    /// Original stderr file handle (saved for restoration)
    private var originalStderr: FileHandle?

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
        // Capture cleanup must be done explicitly via stopCapture()
    }

    // MARK: - Public Interface

    /// Whether console capture is currently active
    public var isCaptureActive: Bool {
        return isCapturing
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

        // Save original file handles
        originalStdout = FileHandle.standardOutput
        originalStderr = FileHandle.standardError

        // Create pipes for capture
        stdoutPipe = Pipe()
        stderrPipe = Pipe()

        guard let stdoutPipe = stdoutPipe,
              let stderrPipe = stderrPipe else {
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

        // Restore original file handles
        if let originalStdout = originalStdout {
            dup2(originalStdout.fileDescriptor, STDOUT_FILENO)
        }
        if let originalStderr = originalStderr {
            dup2(originalStderr.fileDescriptor, STDERR_FILENO)
        }

        // Close pipes
        stdoutPipe?.fileHandleForWriting.closeFile()
        stderrPipe?.fileHandleForWriting.closeFile()
        stdoutPipe?.fileHandleForReading.closeFile()
        stderrPipe?.fileHandleForReading.closeFile()

        stdoutPipe = nil
        stderrPipe = nil
        originalStdout = nil
        originalStderr = nil

        isCapturing = false
        debugLog("Console capture stopped successfully")
    }

    /// Get all buffered log lines
    /// - Returns: Array of captured log lines in chronological order
    public func getBufferedLogs() -> [LogLine] {
        return logBuffer
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
        return logBuffer.count
    }

    // MARK: - Private Implementation

    /// Read from a pipe and buffer the output
    /// - Parameters:
    ///   - fileHandle: File handle to read from
    ///   - source: Source of the log (stdout or stderr)
    private func readFromPipe(_ fileHandle: FileHandle, source: LogSource) async {
        debugLog("Starting reader for \(source)")

        var buffer = Data()

        while !Task.isCancelled {
            do {
                // Read available data
                let data = try fileHandle.read(upToCount: 4096) ?? Data()

                if data.isEmpty {
                    // No more data available, wait a bit
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    continue
                }

                buffer.append(data)

                // Process complete lines
                await processBuffer(&buffer, source: source)
            } catch {
                debugLog("Error reading from \(source): \(error)")
                break
            }
        }

        // Process any remaining data in buffer
        if !buffer.isEmpty {
            await processBuffer(&buffer, source: source, forceFlush: true)
        }

        debugLog("Reader for \(source) stopped")
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
        if !forceFlush && !lines.isEmpty {
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
            // Write directly to original stderr to avoid capture loop
            if let originalStderr = originalStderr {
                let debugMessage = "[ConsoleCapture] \(message)\n"
                if let data = debugMessage.data(using: .utf8) {
                    originalStderr.write(data)
                }
            }
        }
    }
}
