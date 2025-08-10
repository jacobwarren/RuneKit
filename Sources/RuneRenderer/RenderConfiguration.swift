import Foundation

/// Configuration for terminal rendering behavior
///
/// This struct provides configuration options for controlling how frames
/// are rendered to the terminal, including optimization modes and performance
/// tuning parameters.
public struct RenderConfiguration: Sendable {
    /// Rendering optimization mode
    public enum OptimizationMode: String, Sendable, CaseIterable {
        /// Full redraw mode - always rewrite entire frame (Ink.js default)
        case fullRedraw = "full_redraw"

        /// Line-diff mode - only rewrite changed lines
        case lineDiff = "line_diff"

        /// Automatic mode - choose based on frame characteristics
        case automatic = "automatic"
    }

    /// Performance tuning parameters
    public struct PerformanceTuning: Sendable {
        /// Maximum number of lines to consider for line-diff optimization
        /// Above this threshold, fall back to full redraw
        public let maxLinesForDiff: Int

        /// Minimum efficiency threshold for line-diff mode
        /// If efficiency (changed_lines/total_lines) is above this, use full redraw
        public let minEfficiencyThreshold: Double

        /// Maximum frame rate (frames per second) to prevent overwhelming terminal
        public let maxFrameRate: Double

        /// Buffer size for batching terminal writes
        public let writeBufferSize: Int

        public init(
            maxLinesForDiff: Int = 1000,
            minEfficiencyThreshold: Double = 0.7,
            maxFrameRate: Double = 60.0,
            writeBufferSize: Int = 8192
        ) {
            self.maxLinesForDiff = maxLinesForDiff
            self.minEfficiencyThreshold = minEfficiencyThreshold
            self.maxFrameRate = maxFrameRate
            self.writeBufferSize = writeBufferSize
        }
    }

    // MARK: - Configuration Properties

    /// Primary optimization mode
    public let optimizationMode: OptimizationMode

    /// Performance tuning parameters
    public let performance: PerformanceTuning

    /// Whether to collect detailed performance metrics
    public let enableMetrics: Bool

    /// Whether to enable debug logging for rendering operations
    public let enableDebugLogging: Bool

    /// Whether to use cursor hiding during rendering (recommended)
    public let hideCursorDuringRender: Bool

    /// Whether to use alternate screen buffer if available
    public let useAlternateScreen: Bool

    /// Whether to capture stdout/stderr and display logs above live region
    public let enableConsoleCapture: Bool

    /// Feature flag: allow public injection of OutputEncoder/CursorManager
    public let enablePluggableIO: Bool


    // MARK: - Initialization

    public init(
        optimizationMode: OptimizationMode = .lineDiff,
        performance: PerformanceTuning = PerformanceTuning(),
        enableMetrics: Bool = true,
        enableDebugLogging: Bool = false,
        hideCursorDuringRender: Bool = true,
        useAlternateScreen: Bool = false,
        enableConsoleCapture: Bool = false,
        enablePluggableIO: Bool = false
    ) {
        self.optimizationMode = optimizationMode
        self.performance = performance
        self.enableMetrics = enableMetrics
        self.enableDebugLogging = enableDebugLogging
        self.hideCursorDuringRender = hideCursorDuringRender
        self.useAlternateScreen = useAlternateScreen
        self.enableConsoleCapture = enableConsoleCapture
        self.enablePluggableIO = enablePluggableIO
    }

    /// Backward-compatible initializer without the pluggable IO flag
    public init(
        optimizationMode: OptimizationMode = .lineDiff,
        performance: PerformanceTuning = PerformanceTuning(),
        enableMetrics: Bool = true,
        enableDebugLogging: Bool = false,
        hideCursorDuringRender: Bool = true,
        useAlternateScreen: Bool = false,
        enableConsoleCapture: Bool = false
    ) {
        self.init(
            optimizationMode: optimizationMode,
            performance: performance,
            enableMetrics: enableMetrics,
            enableDebugLogging: enableDebugLogging,
            hideCursorDuringRender: hideCursorDuringRender,
            useAlternateScreen: useAlternateScreen,
            enableConsoleCapture: enableConsoleCapture,
            enablePluggableIO: false
        )
    }

    // MARK: - Predefined Configurations

    /// Default configuration optimized for most use cases
    /// Uses line-diff optimization with balanced performance settings
    public static let `default` = RenderConfiguration(enablePluggableIO: false)

    /// High-performance configuration for fast terminals
    /// Aggressive optimization settings for maximum throughput
    public static let highPerformance = RenderConfiguration(
        optimizationMode: .lineDiff,
        performance: PerformanceTuning(
            maxLinesForDiff: 2000,
            minEfficiencyThreshold: 0.8,
            maxFrameRate: 120.0,
            writeBufferSize: 16384
        ),
        enableMetrics: true,
        enableDebugLogging: false,
        enableConsoleCapture: false
    )

    /// Conservative configuration for slow terminals or debugging
    /// Uses full redraw with conservative settings
    public static let conservative = RenderConfiguration(
        optimizationMode: .fullRedraw,
        performance: PerformanceTuning(
            maxLinesForDiff: 100,
            minEfficiencyThreshold: 0.5,
            maxFrameRate: 30.0,
            writeBufferSize: 4096
        ),
        enableMetrics: true,
        enableDebugLogging: true,
        enableConsoleCapture: false
    )

    /// Debug configuration with extensive logging and metrics
    /// Useful for development and troubleshooting
    public static let debug = RenderConfiguration(
        optimizationMode: .automatic,
        performance: PerformanceTuning(
            maxLinesForDiff: 500,
            minEfficiencyThreshold: 0.6,
            maxFrameRate: 30.0,
            writeBufferSize: 1024
        ),
        enableMetrics: true,
        enableDebugLogging: true,
        hideCursorDuringRender: true,
        useAlternateScreen: false,
        enableConsoleCapture: true
    )

    // MARK: - Decision Logic

    /// Determine the actual optimization mode to use for a given frame
    /// - Parameters:
    ///   - frameLines: Number of lines in the frame
    ///   - changedLines: Number of lines that changed (if known)
    ///   - previousMetrics: Previous performance metrics for automatic mode
    /// - Returns: The optimization mode to use for this frame
    public func resolveOptimizationMode(
        frameLines: Int,
        changedLines: Int? = nil,
        previousMetrics: PerformanceMetrics.Counters? = nil
    ) -> OptimizationMode {
        switch optimizationMode {
        case .fullRedraw:
            return .fullRedraw

        case .lineDiff:
            // Check if frame is too large for line-diff
            if frameLines > performance.maxLinesForDiff {
                return .fullRedraw
            }

            // Check efficiency threshold if we know changed lines
            if let changedLines = changedLines {
                let efficiency = 1.0 - (Double(changedLines) / Double(frameLines))
                if efficiency < performance.minEfficiencyThreshold {
                    return .fullRedraw
                }
            }

            return .lineDiff

        case .automatic:
            // Use previous metrics to make intelligent decision
            if let metrics = previousMetrics {
                // If previous line-diff was inefficient, use full redraw
                if metrics.efficiency < performance.minEfficiencyThreshold {
                    return .fullRedraw
                }

                // If frame is getting large, consider full redraw
                if frameLines > performance.maxLinesForDiff {
                    return .fullRedraw
                }
            }

            // Default to line-diff for automatic mode
            return frameLines <= performance.maxLinesForDiff ? .lineDiff : .fullRedraw
        }
    }

    /// Check if frame rate limiting should be applied
    /// - Parameter lastFrameTime: Time of the last frame
    /// - Returns: True if this frame should be dropped to maintain frame rate
    public func shouldDropFrame(lastFrameTime: Date) -> Bool {
        let minFrameInterval = 1.0 / performance.maxFrameRate
        let timeSinceLastFrame = Date().timeIntervalSince(lastFrameTime)
        return timeSinceLastFrame < minFrameInterval
    }
}

// MARK: - Configuration Extensions

public extension RenderConfiguration {
    /// Create a configuration from environment variables
    /// Useful for runtime configuration without code changes
    static func fromEnvironment() -> RenderConfiguration {
        return fromEnvironment(ProcessInfo.processInfo.environment)
    }

    /// Create a configuration from provided environment dictionary
    /// Internal method for testing with custom environment variables
    static func fromEnvironment(_ environment: [String: String]) -> RenderConfiguration {
        var config = RenderConfiguration.default

        // Check for optimization mode override
        if let modeString = environment["RUNE_RENDER_MODE"],
           let mode = OptimizationMode(rawValue: modeString) {
            config = RenderConfiguration(
                optimizationMode: mode,
                performance: config.performance,
                enableMetrics: config.enableMetrics,
                enableDebugLogging: config.enableDebugLogging,
                hideCursorDuringRender: config.hideCursorDuringRender,
                useAlternateScreen: config.useAlternateScreen,
                enableConsoleCapture: config.enableConsoleCapture
            )
        }

        // Check for alternate screen buffer override
        if let altScreenString = environment["RUNE_ALT_SCREEN"] {
            let useAltScreen = altScreenString.lowercased() == "true" || altScreenString == "1"
            config = RenderConfiguration(
                optimizationMode: config.optimizationMode,
                performance: config.performance,
                enableMetrics: config.enableMetrics,
                enableDebugLogging: config.enableDebugLogging,
                hideCursorDuringRender: config.hideCursorDuringRender,
                useAlternateScreen: useAltScreen,
                enableConsoleCapture: config.enableConsoleCapture
            )
        }

        // Check for console capture override
        if let captureString = environment["RUNE_CONSOLE_CAPTURE"] {
            let enableCapture = captureString.lowercased() == "true" || captureString == "1"
            config = RenderConfiguration(
                optimizationMode: config.optimizationMode,
                performance: config.performance,
                enableMetrics: config.enableMetrics,
                enableDebugLogging: config.enableDebugLogging,
                hideCursorDuringRender: config.hideCursorDuringRender,
                useAlternateScreen: config.useAlternateScreen,
                enableConsoleCapture: enableCapture
            )
        }

        // Check for debug mode
        if environment["RUNE_DEBUG"] == "1" {
            config = RenderConfiguration.debug
        }

        return config
    }
}
