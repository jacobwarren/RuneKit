import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// Actor-based frame buffer with hybrid reconciler for optimal terminal rendering
///
/// This actor provides a high-level interface for terminal rendering that automatically
/// chooses the most efficient rendering strategy based on content changes and performance.
///
/// Key features:
/// - Hybrid reconciler with adaptive thresholds
/// - Cell-based grid system with SGR optimization
/// - Line hashing and dirty rectangle detection
/// - Update coalescing and rate limiting
/// - Periodic safety valve (full redraws)
/// - Performance metrics and adaptive tuning
/// - Legacy Frame compatibility
/// - Thread-safe operation
public actor FrameBuffer {
    /// The hybrid reconciler that handles rendering strategy
    private let reconciler: HybridReconciler

    /// Configuration for rendering behavior (legacy compatibility)
    private let configuration: RenderConfiguration

    /// Performance metrics tracker (legacy compatibility)
    private let metrics: PerformanceMetrics

    /// Alternate screen buffer for full-screen applications (optional)
    private let alternateScreenBuffer: AlternateScreenBuffer?

    /// Whether alternate screen has been entered
    private var alternateScreenActive: Bool = false

    /// Console capture for stdout/stderr redirection (optional)
    private let consoleCapture: ConsoleCapture?

    /// Log lane for formatting captured logs
    private let logLane: LogLane

    /// Original output handle (saved when console capture is active)
    private let originalOutput: FileHandle

    /// Initialize frame buffer with output handle and configuration
    /// - Parameters:
    ///   - output: File handle for terminal output (defaults to stdout)
    ///   - configuration: Rendering configuration (defaults to .default)
    public init(
        output: FileHandle = .standardOutput,
        configuration: RenderConfiguration = .default
    ) {
        self.configuration = configuration
        self.metrics = PerformanceMetrics()
        self.originalOutput = output

        // Create alternate screen buffer if enabled in configuration
        if configuration.useAlternateScreen {
            self.alternateScreenBuffer = AlternateScreenBuffer(output: output)
        } else {
            self.alternateScreenBuffer = nil
        }

        self.alternateScreenActive = false

        // Create console capture if enabled in configuration
        if configuration.enableConsoleCapture {
            self.consoleCapture = ConsoleCapture(enableDebugLogging: configuration.enableDebugLogging)
        } else {
            self.consoleCapture = nil
        }

        // Create log lane for formatting captured logs
        self.logLane = LogLane(useColors: true)

        // Create the terminal renderer and hybrid reconciler
        let renderer = TerminalRenderer(output: output)
        self.reconciler = HybridReconciler(renderer: renderer, configuration: configuration)
    }

    /// Deinitializer ensures cursor is restored on cleanup
    deinit {
        // Note: Cannot perform async operations in deinit
        // Cursor restoration must be done explicitly via clear() or restoreCursor()
    }

    /// Render a frame to the terminal using the hybrid reconciler
    /// - Parameter frame: Frame to render
    public func renderFrame(_ frame: TerminalRenderer.Frame) async {
        // Enter alternate screen on first render if configured
        await enterAlternateScreenIfNeeded()

        // Start console capture if configured and not already active
        await startConsoleCaptureIfNeeded()

        // Render logs above the frame if console capture is active
        await renderWithLogs(frame)
    }

    /// Render a grid to the terminal using the hybrid reconciler
    /// - Parameter grid: Grid to render
    public func renderGrid(_ grid: TerminalGrid) async {
        // Enter alternate screen on first render if configured
        await enterAlternateScreenIfNeeded()

        // Start console capture if configured and not already active
        await startConsoleCaptureIfNeeded()

        // Render logs above the grid if console capture is active
        await renderGridWithLogs(grid)
    }

    /// Clear the frame buffer and show cursor (for cleanup)
    public func clear() async {
        // Stop console capture if active
        await stopConsoleCaptureIfNeeded()

        // Leave alternate screen if active
        await leaveAlternateScreenIfNeeded()

        // Cancel background tasks to prevent hanging in CI
        // This preserves performance history for tests
        await reconciler.cancelBackgroundTasks()

        await reconciler.clear()
    }

    /// Get current performance metrics
    /// - Returns: Current performance counters
    public func getPerformanceMetrics() async -> HybridPerformanceMetrics {
        return await reconciler.getPerformanceMetrics()
    }

    /// Get legacy performance metrics for compatibility
    /// - Returns: Legacy performance counters
    public func getLegacyPerformanceMetrics() async -> PerformanceMetrics.Counters {
        return await metrics.getCurrentCounters()
    }

    /// Get performance history for testing and analysis
    /// - Returns: Array of performance counters from recent renders
    public func getPerformanceHistory() async -> [PerformanceMetrics.Counters] {
        return await reconciler.getLegacyPerformanceHistory()
    }

    /// Get current frame for testing
    /// - Returns: Current frame being displayed (if any)
    public func getCurrentFrame() async -> TerminalRenderer.Frame? {
        return await reconciler.getCurrentFrame()
    }

    /// Reset performance metrics for testing
    public func resetMetrics() async {
        await reconciler.resetMetrics()
    }

    /// Get current configuration for testing
    /// - Returns: Current render configuration
    public func getConfiguration() -> RenderConfiguration {
        return configuration
    }

    /// Wait for any pending updates to complete (for testing)
    public func waitForPendingUpdates() async {
        await reconciler.waitForPendingUpdates()
    }

    /// Render immediately without coalescing (for testing)
    public func renderFrameImmediate(_ frame: TerminalRenderer.Frame) async {
        await reconciler.renderImmediate(frame)
    }

    /// Restore cursor visibility (for cleanup)
    public func restoreCursor() async {
        await reconciler.restoreCursor()
    }

    /// Shutdown the frame buffer and clean up all resources
    /// This ensures all async tasks are properly cancelled and awaited
    public func shutdown() async {
        // Stop console capture before shutdown
        await stopConsoleCaptureIfNeeded()

        // Leave alternate screen before shutdown
        await leaveAlternateScreenIfNeeded()

        await reconciler.shutdown()
    }

    // MARK: - Console Capture Management

    /// Start console capture if configured and not already active
    private func startConsoleCaptureIfNeeded() async {
        guard let capture = consoleCapture else { return }

        let isActive = await capture.isCaptureActive
        guard !isActive else { return }

        await capture.startCapture()
    }

    /// Stop console capture if active
    private func stopConsoleCaptureIfNeeded() async {
        guard let capture = consoleCapture else { return }

        let isActive = await capture.isCaptureActive
        guard isActive else { return }

        await capture.stopCapture()
    }

    /// Render frame with logs displayed above the live region
    /// - Parameter frame: Frame to render
    private func renderWithLogs(_ frame: TerminalRenderer.Frame) async {
        guard let capture = consoleCapture,
              await capture.isCaptureActive else {
            // No console capture, render normally
            await reconciler.render(frame)
            return
        }

        // Get captured logs
        let logs = await capture.getBufferedLogs()

        // Only proceed if we have logs to display
        guard !logs.isEmpty else {
            await reconciler.render(frame)
            return
        }

        // Get terminal size for formatting
        let terminalSize = getTerminalSize()

        // Format logs for display
        let logLines = logLane.formatLogs(logs, terminalWidth: terminalSize.width)

        // Create combined frame with logs above the live region
        let combinedFrame = createCombinedFrame(logLines: logLines, liveFrame: frame, terminalWidth: terminalSize.width)

        // Render the combined frame
        await reconciler.render(combinedFrame)
    }

    /// Render grid with logs displayed above the live region
    /// - Parameter grid: Grid to render
    private func renderGridWithLogs(_ grid: TerminalGrid) async {
        guard let capture = consoleCapture,
              await capture.isCaptureActive else {
            // No console capture, render normally
            await reconciler.render(grid)
            return
        }

        // Get captured logs
        let logs = await capture.getBufferedLogs()

        // Only proceed if we have logs to display
        guard !logs.isEmpty else {
            await reconciler.render(grid)
            return
        }

        // Get terminal size for formatting
        let terminalSize = getTerminalSize()

        // Format logs for display
        let logLines = logLane.formatLogs(logs, terminalWidth: terminalSize.width)

        // Create combined grid with logs above the live region
        let combinedGrid = createCombinedGrid(logLines: logLines, liveGrid: grid, terminalWidth: terminalSize.width)

        // Render the combined grid
        await reconciler.render(combinedGrid)
    }

    /// Create a combined grid with logs above the live region
    /// - Parameters:
    ///   - logLines: Formatted log lines
    ///   - liveGrid: Live application grid
    ///   - terminalWidth: Terminal width
    /// - Returns: Combined grid
    private func createCombinedGrid(logLines: [String], liveGrid: TerminalGrid, terminalWidth: Int) -> TerminalGrid {
        let logHeight = logLines.count
        let separatorHeight = logLines.isEmpty ? 0 : 1
        let totalHeight = logHeight + separatorHeight + liveGrid.height

        // Create new grid with combined height
        var combinedGrid = TerminalGrid(width: max(terminalWidth, liveGrid.width), height: totalHeight)

        var currentRow = 0

        // Add log lines by converting strings to cells
        for logLine in logLines {
            let cells = stringToCells(logLine)
            combinedGrid.setRow(currentRow, to: cells)
            currentRow += 1
        }

        // Add separator if we have logs
        if !logLines.isEmpty {
            let separator = logLane.createSeparator(terminalWidth: terminalWidth)
            let separatorCells = stringToCells(separator)
            combinedGrid.setRow(currentRow, to: separatorCells)
            currentRow += 1
        }

        // Copy live grid content
        for row in 0..<liveGrid.height {
            if let liveRow = liveGrid.getRow(row) {
                combinedGrid.setRow(currentRow + row, to: liveRow)
            }
        }

        return combinedGrid
    }

    /// Convert a string to an array of TerminalCells
    /// - Parameter string: String to convert
    /// - Returns: Array of TerminalCells
    private func stringToCells(_ string: String) -> [TerminalCell] {
        return string.map { char in
            TerminalCell(content: String(char))
        }
    }

    /// Create a combined frame with logs above the live region
    /// - Parameters:
    ///   - logLines: Formatted log lines
    ///   - liveFrame: Live application frame
    ///   - terminalWidth: Terminal width
    /// - Returns: Combined frame
    private func createCombinedFrame(logLines: [String], liveFrame: TerminalRenderer.Frame, terminalWidth: Int) -> TerminalRenderer.Frame {
        var combinedLines: [String] = []

        // Add log lines
        combinedLines.append(contentsOf: logLines)

        // Add separator if we have logs
        if !logLines.isEmpty {
            combinedLines.append(logLane.createSeparator(terminalWidth: terminalWidth))
        }

        // Add live frame lines
        combinedLines.append(contentsOf: liveFrame.lines)

        return TerminalRenderer.Frame(
            lines: combinedLines,
            width: max(terminalWidth, liveFrame.width),
            height: combinedLines.count
        )
    }

    /// Get terminal size
    /// - Returns: Terminal size (width, height)
    private func getTerminalSize() -> (width: Int, height: Int) {
        // Try to get terminal size using ioctl
        #if os(Linux)
        var winsize = Glibc.winsize()
        let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &winsize)
        #else
        var winsize = Darwin.winsize()
        let result = ioctl(STDOUT_FILENO, TIOCGWINSZ, &winsize)
        #endif

        if result == 0 && winsize.ws_col > 0 && winsize.ws_row > 0 {
            return (width: Int(winsize.ws_col), height: Int(winsize.ws_row))
        }

        // Fallback to default size
        return (width: 80, height: 24)
    }

    /// Get console capture status (for testing)
    public func isConsoleCaptureActive() async -> Bool {
        guard let capture = consoleCapture else { return false }
        return await capture.isCaptureActive
    }

    /// Get captured logs (for testing)
    public func getCapturedLogs() async -> [ConsoleCapture.LogLine] {
        guard let capture = consoleCapture else { return [] }
        return await capture.getBufferedLogs()
    }

    /// Clear captured logs (for testing)
    public func clearCapturedLogs() async {
        guard let capture = consoleCapture else { return }
        await capture.clearBuffer()
    }

    // MARK: - Alternate Screen Buffer Management

    /// Enter alternate screen buffer if configured and not already active
    private func enterAlternateScreenIfNeeded() async {
        guard let altScreen = alternateScreenBuffer,
              !alternateScreenActive else { return }

        await altScreen.enter()
        alternateScreenActive = true
    }

    /// Leave alternate screen buffer if active
    private func leaveAlternateScreenIfNeeded() async {
        guard let altScreen = alternateScreenBuffer,
              alternateScreenActive else { return }

        await altScreen.leave()
        alternateScreenActive = false
    }

    /// Get alternate screen buffer status (for testing)
    public func isAlternateScreenActive() async -> Bool {
        return alternateScreenActive
    }
}
