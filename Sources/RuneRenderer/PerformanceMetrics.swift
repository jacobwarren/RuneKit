import Foundation

/// Performance metrics for terminal rendering operations
///
/// This actor provides thread-safe collection and reporting of rendering
/// performance metrics including bytes written, lines changed, and frames dropped.
/// Used by the line-diff renderer to track optimization effectiveness.
public actor PerformanceMetrics {
    /// Rendering mode for performance tracking
    public enum RenderMode: String, Sendable {
        case fullRedraw = "full_redraw"
        case lineDiff = "line_diff"
    }

    /// Performance counters for a rendering session
    public struct Counters: Sendable {
        /// Total bytes written to terminal
        public let bytesWritten: Int

        /// Number of lines that were rewritten
        public let linesChanged: Int

        /// Total number of lines in the frame
        public let totalLines: Int

        /// Number of frames that were dropped due to performance
        public let framesDropped: Int

        /// Rendering mode used
        public let renderMode: RenderMode

        /// Duration of the rendering operation in seconds
        public let renderDuration: TimeInterval

        /// Timestamp when the metrics were recorded
        public let timestamp: Date

        public init(
            bytesWritten: Int,
            linesChanged: Int,
            totalLines: Int,
            framesDropped: Int,
            renderMode: RenderMode,
            renderDuration: TimeInterval,
            timestamp: Date = Date()
        ) {
            self.bytesWritten = bytesWritten
            self.linesChanged = linesChanged
            self.totalLines = totalLines
            self.framesDropped = framesDropped
            self.renderMode = renderMode
            self.renderDuration = renderDuration
            self.timestamp = timestamp
        }

        /// Efficiency ratio (0.0 to 1.0) - higher is better for line-diff
        /// 1.0 means no lines changed, 0.0 means all lines changed
        public var efficiency: Double {
            guard totalLines > 0 else { return 1.0 }
            return 1.0 - (Double(linesChanged) / Double(totalLines))
        }

        /// Bytes per line changed
        public var bytesPerLine: Double {
            guard linesChanged > 0 else { return 0.0 }
            return Double(bytesWritten) / Double(linesChanged)
        }
    }

    // MARK: - Private State

    /// Current session counters
    private var currentCounters = Counters(
        bytesWritten: 0,
        linesChanged: 0,
        totalLines: 0,
        framesDropped: 0,
        renderMode: .fullRedraw,
        renderDuration: 0.0
    )

    /// Historical performance data (last 100 frames)
    private var history: [Counters] = []
    private let maxHistorySize = 100

    /// Start time for current render operation
    private var renderStartTime: Date?

    // MARK: - Public Interface

    /// Start tracking a new render operation
    /// - Parameter mode: The rendering mode being used
    public func startRender(mode: RenderMode) {
        renderStartTime = Date()
        currentCounters = Counters(
            bytesWritten: 0,
            linesChanged: 0,
            totalLines: 0,
            framesDropped: currentCounters.framesDropped, // Preserve dropped count
            renderMode: mode,
            renderDuration: 0.0
        )
    }

    /// Record bytes written during rendering
    /// - Parameter bytes: Number of bytes written
    public func recordBytesWritten(_ bytes: Int) {
        currentCounters = Counters(
            bytesWritten: currentCounters.bytesWritten + bytes,
            linesChanged: currentCounters.linesChanged,
            totalLines: currentCounters.totalLines,
            framesDropped: currentCounters.framesDropped,
            renderMode: currentCounters.renderMode,
            renderDuration: currentCounters.renderDuration
        )
    }

    /// Record lines changed during rendering
    /// - Parameter lines: Number of lines that were rewritten
    public func recordLinesChanged(_ lines: Int) {
        currentCounters = Counters(
            bytesWritten: currentCounters.bytesWritten,
            linesChanged: currentCounters.linesChanged + lines,
            totalLines: currentCounters.totalLines,
            framesDropped: currentCounters.framesDropped,
            renderMode: currentCounters.renderMode,
            renderDuration: currentCounters.renderDuration
        )
    }

    /// Set total lines in the frame
    /// - Parameter total: Total number of lines in the frame
    public func setTotalLines(_ total: Int) {
        currentCounters = Counters(
            bytesWritten: currentCounters.bytesWritten,
            linesChanged: currentCounters.linesChanged,
            totalLines: total,
            framesDropped: currentCounters.framesDropped,
            renderMode: currentCounters.renderMode,
            renderDuration: currentCounters.renderDuration
        )
    }

    /// Record a dropped frame
    public func recordDroppedFrame() {
        currentCounters = Counters(
            bytesWritten: currentCounters.bytesWritten,
            linesChanged: currentCounters.linesChanged,
            totalLines: currentCounters.totalLines,
            framesDropped: currentCounters.framesDropped + 1,
            renderMode: currentCounters.renderMode,
            renderDuration: currentCounters.renderDuration
        )
    }

    /// Record total lines in the frame
    /// - Parameter lines: Total number of lines in the frame
    public func recordTotalLines(_ lines: Int) {
        currentCounters = Counters(
            bytesWritten: currentCounters.bytesWritten,
            linesChanged: currentCounters.linesChanged,
            totalLines: lines,
            framesDropped: currentCounters.framesDropped,
            renderMode: currentCounters.renderMode,
            renderDuration: currentCounters.renderDuration
        )
    }

    /// Finish the current render operation and record final metrics
    /// - Returns: Final counters for the completed render
    public func finishRender() -> Counters {
        let duration = renderStartTime?.timeIntervalSinceNow.magnitude ?? 0.0

        let finalCounters = Counters(
            bytesWritten: currentCounters.bytesWritten,
            linesChanged: currentCounters.linesChanged,
            totalLines: currentCounters.totalLines,
            framesDropped: currentCounters.framesDropped,
            renderMode: currentCounters.renderMode,
            renderDuration: duration
        )

        // Add to history
        history.append(finalCounters)
        if history.count > maxHistorySize {
            history.removeFirst()
        }

        renderStartTime = nil
        return finalCounters
    }

    /// Get current counters (without finishing the render)
    /// - Returns: Current counters snapshot
    public func getCurrentCounters() -> Counters {
        return currentCounters
    }

    /// Get performance history
    /// - Returns: Array of historical performance counters
    public func getHistory() -> [Counters] {
        return history
    }

    /// Get average performance over recent history
    /// - Parameter count: Number of recent frames to average (default: 10)
    /// - Returns: Average counters or nil if insufficient history
    public func getAveragePerformance(over count: Int = 10) -> Counters? {
        let recentHistory = Array(history.suffix(count))
        guard !recentHistory.isEmpty else { return nil }

        let totalBytes = recentHistory.reduce(0) { $0 + $1.bytesWritten }
        let totalLinesChanged = recentHistory.reduce(0) { $0 + $1.linesChanged }
        let totalLines = recentHistory.reduce(0) { $0 + $1.totalLines }
        let totalDropped = recentHistory.reduce(0) { $0 + $1.framesDropped }
        let totalDuration = recentHistory.reduce(0.0) { $0 + $1.renderDuration }

        let count = recentHistory.count
        return Counters(
            bytesWritten: totalBytes / count,
            linesChanged: totalLinesChanged / count,
            totalLines: totalLines / count,
            framesDropped: totalDropped / count,
            renderMode: recentHistory.last?.renderMode ?? .fullRedraw,
            renderDuration: totalDuration / Double(count)
        )
    }

    /// Reset all metrics
    public func reset() {
        currentCounters = Counters(
            bytesWritten: 0,
            linesChanged: 0,
            totalLines: 0,
            framesDropped: 0,
            renderMode: .fullRedraw,
            renderDuration: 0.0
        )
        history.removeAll()
        renderStartTime = nil
    }

    /// Shutdown the metrics actor and clean up resources
    public func shutdown() {
        // Clear all data
        history.removeAll()
        renderStartTime = nil
        currentCounters = Counters(
            bytesWritten: 0,
            linesChanged: 0,
            totalLines: 0,
            framesDropped: 0,
            renderMode: .fullRedraw,
            renderDuration: 0.0
        )
    }
}
