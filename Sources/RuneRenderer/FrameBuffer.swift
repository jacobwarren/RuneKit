import Foundation

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
        // Use the hybrid reconciler for optimal rendering
        await reconciler.render(frame)
    }

    /// Render a grid to the terminal using the hybrid reconciler
    /// - Parameter grid: Grid to render
    public func renderGrid(_ grid: TerminalGrid) async {
        await reconciler.render(grid)
    }

    /// Clear the frame buffer and show cursor (for cleanup)
    public func clear() async {
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
        await reconciler.shutdown()
    }
}
