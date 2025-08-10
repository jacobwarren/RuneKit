import Foundation
import RuneANSI
import RuneUnicode

/// LogLane manages the display of captured console logs above the live application region
///
/// This component handles the formatting and positioning of log lines captured
/// by ConsoleCapture, ensuring they appear above the live region without
/// interfering with the application's UI.
///
/// Key features:
/// - Formats log lines with timestamps and source indicators
/// - Manages log display area above live region
/// - Handles terminal width constraints and wrapping
/// - Provides ANSI-aware text formatting
/// - Integrates with FrameBuffer for coordinated rendering
///
/// ## Usage
///
/// ```swift
/// let logLane = LogLane(maxDisplayLines: 10)
/// let logs = await consoleCapture.getBufferedLogs()
/// let logLines = logLane.formatLogs(logs, terminalWidth: 80)
/// ```
public struct LogLane {
    /// Configuration for log display
    public struct Configuration: Sendable {
        /// Maximum number of log lines to display
        public let maxDisplayLines: Int

        /// Whether to show timestamps in log output
        public let showTimestamps: Bool

        /// Whether to show source indicators (stdout/stderr)
        public let showSourceIndicators: Bool

        /// Format for timestamp display
        public let timestampFormat: TimestampFormat

        /// Prefix for stdout logs
        public let stdoutPrefix: String

        /// Prefix for stderr logs
        public let stderrPrefix: String

        /// Whether to use ANSI colors for formatting
        public let useColors: Bool

        public init(
            maxDisplayLines: Int = 10,
            showTimestamps: Bool = true,
            showSourceIndicators: Bool = true,
            timestampFormat: TimestampFormat = .time,
            stdoutPrefix: String = "│",
            stderrPrefix: String = "⚠",
            useColors: Bool = true
        ) {
            self.maxDisplayLines = maxDisplayLines
            self.showTimestamps = showTimestamps
            self.showSourceIndicators = showSourceIndicators
            self.timestampFormat = timestampFormat
            self.stdoutPrefix = stdoutPrefix
            self.stderrPrefix = stderrPrefix
            self.useColors = useColors
        }
    }

    /// Timestamp format options
    public enum TimestampFormat: Sendable {
        case none
        case time           // HH:mm:ss
        case timeWithMs     // HH:mm:ss.SSS
        case relative       // +1.234s

        func format(_ date: Date, relativeTo baseDate: Date? = nil) -> String {
            switch self {
            case .none:
                return ""
            case .time:
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter.string(from: date)
            case .timeWithMs:
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss.SSS"
                return formatter.string(from: date)
            case .relative:
                guard let baseDate = baseDate else {
                    return "+0.000s"
                }
                let interval = date.timeIntervalSince(baseDate)
                return String(format: "+%.3fs", interval)
            }
        }
    }

    // MARK: - Properties

    /// Configuration for log display
    public let configuration: Configuration

    /// Base timestamp for relative formatting
    private let baseTimestamp: Date

    // MARK: - Initialization

    /// Initialize LogLane with configuration
    /// - Parameter configuration: Display configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.baseTimestamp = Date()
    }

    /// Initialize LogLane with simple parameters
    /// - Parameters:
    ///   - maxDisplayLines: Maximum number of lines to display
    ///   - showTimestamps: Whether to show timestamps
    ///   - useColors: Whether to use ANSI colors
    public init(maxDisplayLines: Int = 10, showTimestamps: Bool = true, useColors: Bool = true) {
        self.configuration = Configuration(
            maxDisplayLines: maxDisplayLines,
            showTimestamps: showTimestamps,
            useColors: useColors
        )
        self.baseTimestamp = Date()
    }

    // MARK: - Public Interface

    /// Format captured logs for display above the live region
    /// - Parameters:
    ///   - logs: Array of captured log lines
    ///   - terminalWidth: Width of the terminal for wrapping
    ///   - maxLines: Optional override for maximum lines to display
    /// - Returns: Array of formatted strings ready for display
    public func formatLogs(
        _ logs: [ConsoleCapture.LogLine],
        terminalWidth: Int,
        maxLines: Int? = nil
    ) -> [String] {
        let displayLimit = maxLines ?? configuration.maxDisplayLines

        // Get the most recent logs up to the display limit
        let recentLogs = Array(logs.suffix(displayLimit))

        // Format each log line
        var formattedLines: [String] = []

        for log in recentLogs {
            let formatted = formatLogLine(log, terminalWidth: terminalWidth)
            formattedLines.append(contentsOf: formatted)
        }

        // Trim to display limit if wrapping caused overflow
        if formattedLines.count > displayLimit {
            formattedLines = Array(formattedLines.suffix(displayLimit))
        }

        return formattedLines
    }

    /// Format a single log line with wrapping if necessary
    /// - Parameters:
    ///   - log: Log line to format
    ///   - terminalWidth: Width of the terminal for wrapping
    /// - Returns: Array of formatted strings (may be multiple lines if wrapped)
    public func formatLogLine(_ log: ConsoleCapture.LogLine, terminalWidth: Int) -> [String] {
        var prefix = ""

        // Add timestamp if enabled
        if configuration.showTimestamps {
            let timestamp = configuration.timestampFormat.format(log.timestamp, relativeTo: baseTimestamp)
            if !timestamp.isEmpty {
                prefix += "[\(timestamp)] "
            }
        }

        // Add source indicator if enabled
        if configuration.showSourceIndicators {
            let sourcePrefix = log.source == .stdout ? configuration.stdoutPrefix : configuration.stderrPrefix
            prefix += "\(sourcePrefix) "
        }

        // Apply colors if enabled
        let coloredContent = configuration.useColors ? applyColors(log.content, source: log.source) : log.content

        // Combine prefix and content
        let fullLine = prefix + coloredContent

        // Handle wrapping if the line is too long
        return wrapLine(fullLine, width: terminalWidth, prefixLength: prefix.count)
    }

    /// Calculate the height needed for displaying logs
    /// - Parameters:
    ///   - logs: Array of captured log lines
    ///   - terminalWidth: Width of the terminal
    ///   - maxLines: Optional override for maximum lines
    /// - Returns: Number of lines needed for display
    public func calculateDisplayHeight(
        _ logs: [ConsoleCapture.LogLine],
        terminalWidth: Int,
        maxLines: Int? = nil
    ) -> Int {
        let formattedLines = formatLogs(logs, terminalWidth: terminalWidth, maxLines: maxLines)
        return formattedLines.count
    }

    /// Create a separator line for visual separation
    /// - Parameter terminalWidth: Width of the terminal
    /// - Returns: Separator line string
    public func createSeparator(terminalWidth: Int) -> String {
        let char = configuration.useColors ? "─" : "-"
        let color = configuration.useColors ? "\u{001B}[90m" : ""  // Dark gray
        let reset = configuration.useColors ? "\u{001B}[0m" : ""

        return color + String(repeating: char, count: terminalWidth) + reset
    }

    // MARK: - Private Implementation

    /// Apply ANSI colors based on log source
    /// - Parameters:
    ///   - content: Log content to colorize
    ///   - source: Source of the log (stdout/stderr)
    /// - Returns: Colorized content
    private func applyColors(_ content: String, source: ConsoleCapture.LogSource) -> String {
        guard configuration.useColors else { return content }

        switch source {
        case .stdout:
            // Normal text color (no change)
            return content
        case .stderr:
            // Red color for stderr
            return "\u{001B}[31m\(content)\u{001B}[0m"
        }
    }

    /// Wrap a line to fit within terminal width
    /// - Parameters:
    ///   - line: Line to wrap
    ///   - width: Terminal width
    ///   - prefixLength: Length of prefix for continuation lines
    /// - Returns: Array of wrapped lines
    private func wrapLine(_ line: String, width: Int, prefixLength: Int) -> [String] {
        // ANSI-aware wrapping by display columns (ignore ANSI when measuring)
        if ANSISafeTruncation.displayWidthIgnoringANSI(line) <= width { return [line] }

        var wrappedLines: [String] = []
        var remainingStyled: StyledText = {
            let tok = ANSITokenizer().tokenize(line)
            return ANSISpanConverter().tokensToStyledText(tok)
        }()
        let continuationPrefix = String(repeating: " ", count: prefixLength)

        while !remainingStyled.spans.isEmpty {
            let isFirstLine = wrappedLines.isEmpty
            let availableWidth = isFirstLine ? width : max(0, width - prefixLength)
            if availableWidth <= 0 {
                // Nothing fits besides the continuation prefix; emit one line of prefix and stop
                wrappedLines.append(continuationPrefix)
                break
            }

            // Split styled text by display width to preserve SGR and grapheme integrity
            let (headStyled, tailStyled) = remainingStyled.splitByDisplayWidth(at: availableWidth)

            // Encode head back to ANSI string
            let headEncoded = ANSITokenizer().encode(ANSISpanConverter().styledTextToTokens(headStyled))
            let finalHead = isFirstLine ? headEncoded : (continuationPrefix + headEncoded)
            wrappedLines.append(finalHead)

            // Advance
            if tailStyled.spans.isEmpty { break }
            remainingStyled = tailStyled
        }

        return wrappedLines
    }
}

// MARK: - Extensions

public extension LogLane.Configuration {
    /// Default configuration for development/debugging
    static let debug = LogLane.Configuration(
        maxDisplayLines: 15,
        showTimestamps: true,
        showSourceIndicators: true,
        timestampFormat: .timeWithMs,
        useColors: true
    )

    /// Minimal configuration for production
    static let minimal = LogLane.Configuration(
        maxDisplayLines: 5,
        showTimestamps: false,
        showSourceIndicators: false,
        timestampFormat: .none,
        useColors: false
    )

    /// Compact configuration with relative timestamps
    static let compact = LogLane.Configuration(
        maxDisplayLines: 8,
        showTimestamps: true,
        showSourceIndicators: true,
        timestampFormat: .relative,
        stdoutPrefix: "│",
        stderrPrefix: "!",
        useColors: true
    )
}
