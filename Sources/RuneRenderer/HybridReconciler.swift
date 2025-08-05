import Foundation

/// Hybrid reconciler that intelligently chooses between rendering strategies
/// Based on the recommendations for high-performance terminal rendering
public actor HybridReconciler {
    /// The underlying terminal renderer
    private let renderer: TerminalRenderer

    /// Current grid state
    private var currentGrid: TerminalGrid?

    /// Performance tracking
    private var renderHistory: [RenderPerformance] = []
    private let maxHistorySize = 10

    /// Legacy performance metrics for test compatibility
    private var legacyMetrics: PerformanceMetrics

    /// Adaptive thresholds
    private var adaptiveThresholds = AdaptiveThresholds()

    /// Safety valve - force full redraw periodically
    private var framesSinceFullRedraw = 0
    private var lastFullRedrawTime = Date.distantPast
    private let maxFramesBetweenFullRedraws = 100
    private let maxTimeBetweenFullRedraws: TimeInterval = 30.0  // 30 seconds max

    /// Update coalescing with backpressure handling
    private var pendingUpdate: TerminalGrid?
    private let maxUpdateRate: TimeInterval = 1.0 / 60.0  // 60 FPS max
    private var lastUpdateTime = Date.distantPast
    private var coalescingWindow: TimeInterval = 0.016  // 16ms batching window
    private var lastCoalescingTime = Date.distantPast
    private var updateTask: Task<Void, Never>?

    /// Backpressure handling
    private var queueDepth = 0
    private let maxQueueDepth = 5
    private var droppedFrames = 0
    private var adaptiveQuality = 1.0  // 1.0 = full quality, 0.5 = reduced quality

    /// Configuration for rendering behavior
    private let configuration: RenderConfiguration

    public init(renderer: TerminalRenderer, configuration: RenderConfiguration) {
        self.renderer = renderer
        self.configuration = configuration
        self.legacyMetrics = PerformanceMetrics()
    }

    deinit {
        // Cancel any pending update task
        updateTask?.cancel()

        // Clear any pending update
        pendingUpdate = nil

        // Clear current grid to break any potential reference cycles
        currentGrid = nil
    }

    /// Cancel background tasks without clearing performance history
    /// This prevents hanging while preserving test data
    public func cancelBackgroundTasks() async {
        // Cancel any pending update task
        updateTask?.cancel()
        updateTask = nil

        // Clear any pending update
        pendingUpdate = nil
    }

    /// Shutdown the reconciler and wait for all tasks to complete
    /// This must be called before the actor is deallocated to prevent hanging
    public func shutdown() async {
        // Cancel background tasks first
        await cancelBackgroundTasks()

        // Shutdown the renderer
        await renderer.shutdown()

        // Shutdown performance metrics
        await legacyMetrics.shutdown()

        // Clear current grid
        currentGrid = nil
    }

    /// Render a frame using the hybrid reconciler
    /// - Parameter frame: The frame to render
    public func render(_ frame: TerminalRenderer.Frame) async {
        await render(frame.toGrid())
    }

    /// Render a grid using the hybrid reconciler
    /// - Parameter grid: The grid to render
    public func render(_ grid: TerminalGrid) async {
        // Backpressure handling - check queue depth
        queueDepth += 1

        if queueDepth > maxQueueDepth {
            // Drop this frame to prevent overwhelming the terminal
            droppedFrames += 1
            queueDepth -= 1

            // Reduce quality temporarily to catch up
            adaptiveQuality = max(0.3, adaptiveQuality * 0.9)
            return
        }

        // Coalescing logic: if no pending update, render immediately
        // If there's already a pending update, replace it and schedule a flush
        if pendingUpdate == nil {
            // No pending update, render immediately
            await performRender(grid)
            lastUpdateTime = Date()
        } else {
            // Replace the pending update (coalescing effect)
            pendingUpdate = grid

            // Cancel any existing update task
            updateTask?.cancel()

            // Schedule a new update task with coalescing window
            let window = coalescingWindow  // Capture the value
            updateTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(window * 1_000_000_000))
                await self?.performCoalescedUpdate()
            }
        }
    }

    /// Force a full redraw
    public func forceFullRedraw() async {
        guard let grid = currentGrid else { return }

        let stats = await renderer.render(grid, forceFullRedraw: true)
        await recordPerformance(stats)
        framesSinceFullRedraw = 0
    }

    /// Clear the screen
    public func clear() async {
        // Cancel any pending update task
        updateTask?.cancel()
        updateTask = nil

        // Clear any pending update
        pendingUpdate = nil

        await renderer.clear()
        currentGrid = nil
        framesSinceFullRedraw = 0
    }

    /// Restore cursor on cleanup
    public func restoreCursor() async {
        await renderer.showCursor()
    }

    /// Get current frame for testing
    /// - Returns: Current frame being displayed (if any)
    public func getCurrentFrame() async -> TerminalRenderer.Frame? {
        guard let grid = currentGrid else { return nil }
        return TerminalRenderer.Frame(from: grid)
    }

    /// Get legacy performance history for test compatibility
    /// - Returns: Array of legacy performance counters
    public func getLegacyPerformanceHistory() async -> [PerformanceMetrics.Counters] {
        return await legacyMetrics.getHistory()
    }

    /// Reset performance metrics for testing
    public func resetMetrics() async {
        renderHistory.removeAll()
        droppedFrames = 0
        adaptiveQuality = 1.0
        await legacyMetrics.reset()
    }

    /// Wait for any pending updates to complete (for testing)
    public func waitForPendingUpdates() async {
        // Process any pending update immediately
        await flushPendingUpdate()
    }

    /// Flush any pending update immediately
    private func flushPendingUpdate() async {
        guard let grid = pendingUpdate else { return }
        pendingUpdate = nil
        await performRender(grid)
        lastUpdateTime = Date()
    }

    /// Perform a coalesced update (called by the background task)
    private func performCoalescedUpdate() async {
        guard let grid = pendingUpdate else { return }
        pendingUpdate = nil
        updateTask = nil  // Clear the task reference
        await performRender(grid)
        lastUpdateTime = Date()
    }

    /// Process any pending updates if coalescing window has elapsed
    public func processPendingUpdates() async {
        guard pendingUpdate != nil else { return }

        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)

        if timeSinceLastUpdate >= coalescingWindow {
            await flushPendingUpdate()
        }
    }

    /// Render immediately without coalescing (for testing)
    public func renderImmediate(_ frame: TerminalRenderer.Frame) async {
        await renderImmediate(frame.toGrid())
    }

    /// Render immediately without coalescing (for testing)
    public func renderImmediate(_ grid: TerminalGrid) async {
        // Cancel any pending update task
        updateTask?.cancel()
        updateTask = nil

        // Clear any pending updates
        pendingUpdate = nil

        // Render immediately
        await performRender(grid)
    }

    /// Get performance metrics
    public func getPerformanceMetrics() -> HybridPerformanceMetrics {
        let recentPerformance = Array(renderHistory.suffix(5))
        let averageEfficiency = recentPerformance.isEmpty ? 0.0 :
            recentPerformance.reduce(0.0) { $0 + $1.efficiency } / Double(recentPerformance.count)

        return HybridPerformanceMetrics(
            averageEfficiency: averageEfficiency,
            totalRenders: renderHistory.count,
            framesSinceFullRedraw: framesSinceFullRedraw,
            adaptiveThresholds: adaptiveThresholds,
            droppedFrames: droppedFrames,
            currentQueueDepth: queueDepth,
            adaptiveQuality: adaptiveQuality
        )
    }

    /// Apply adaptive quality reduction when under backpressure
    /// - Parameter grid: Original grid
    /// - Returns: Potentially simplified grid for faster rendering
    private func applyAdaptiveQuality(_ grid: TerminalGrid) async -> TerminalGrid {
        // If quality is high or grid is small, return as-is
        if adaptiveQuality >= 0.9 || grid.height <= 10 {
            return grid
        }

        // For reduced quality, we could implement various optimizations:
        // 1. Skip every other row for very low quality
        // 2. Reduce color depth
        // 3. Simplify complex characters

        // For now, return the original grid
        // In a full implementation, this would create a simplified version
        return grid
    }

    // MARK: - Private Methods

    /// Perform the actual rendering with strategy selection
    private func performRender(_ grid: TerminalGrid) async {
        let startTime = Date()

        // Enhanced periodic full redraw logic
        let timeSinceLastFullRedraw = startTime.timeIntervalSince(lastFullRedrawTime)
        let forceFullRedraw = framesSinceFullRedraw >= maxFramesBetweenFullRedraws ||
            timeSinceLastFullRedraw >= maxTimeBetweenFullRedraws ||
            adaptiveQuality < 0.7  // Force full redraw when quality is degraded

        // Apply adaptive quality - reduce grid resolution if under pressure
        let processedGrid = await applyAdaptiveQuality(grid)

        // Determine strategy using hybrid logic
        let strategy = await determineOptimalStrategy(
            newGrid: processedGrid,
            currentGrid: currentGrid,
            forceFullRedraw: forceFullRedraw
        )

        // Render using the chosen strategy
        let stats = await renderer.render(processedGrid, strategy: strategy, previousGrid: currentGrid)

        // Update state
        currentGrid = processedGrid
        if strategy == .fullRedraw {
            framesSinceFullRedraw = 0
            lastFullRedrawTime = startTime
        } else {
            framesSinceFullRedraw += 1
        }

        // Record performance and adapt thresholds
        await recordPerformance(stats)
        await adaptThresholds(stats)

        // Decrement queue depth after successful render
        queueDepth = max(0, queueDepth - 1)
    }

    /// Determine the optimal rendering strategy using hybrid logic
    private func determineOptimalStrategy(
        newGrid: TerminalGrid,
        currentGrid: TerminalGrid?,
        forceFullRedraw: Bool
    ) async -> RenderingStrategy {
        if forceFullRedraw || currentGrid == nil {
            return .fullRedraw
        }

        // Respect explicit configuration mode
        switch configuration.optimizationMode {
        case .fullRedraw:
            return .fullRedraw
        case .lineDiff:
            // Force line-diff mode unless impossible
            guard currentGrid != nil else {
                return .fullRedraw
            }
            // Line-diff can handle dimension changes with improved logic
            return .deltaUpdate
        case .automatic:
            break  // Continue with hybrid logic below
        }

        guard let current = currentGrid else {
            return .fullRedraw
        }

        // Check dimensions
        if newGrid.width != current.width || newGrid.height != current.height {
            return .fullRedraw
        }

        // Calculate change metrics
        let changedLines = newGrid.changedLines(comparedTo: current)
        let changePercentage = Double(changedLines.count) / Double(newGrid.height)

        // Estimate bytes for different strategies
        let fullRedrawBytes = estimateFullRedrawBytes(grid: newGrid)
        let deltaBytes = estimateDeltaBytes(changedLines: changedLines, grid: newGrid)

        // Use adaptive threshold
        let threshold = adaptiveThresholds.deltaThreshold
        let bytesSaved = Double(fullRedrawBytes - deltaBytes) / Double(fullRedrawBytes)

        // Decision logic based on multiple factors
        if changePercentage > 0.7 {
            // Too many changes - full redraw is more efficient
            return .fullRedraw
        }

        if bytesSaved < threshold {
            // Not enough bytes saved - use full redraw
            return .fullRedraw
        }

        // Check for scroll patterns (simplified detection)
        if await detectScrollPattern(newGrid: newGrid, currentGrid: current) {
            return .scrollOptimized
        }

        return .deltaUpdate
    }

    /// Estimate bytes needed for full redraw
    private func estimateFullRedrawBytes(grid: TerminalGrid) -> Int {
        // Rough estimate: each cell is ~1-3 bytes on average
        return grid.width * grid.height * 2
    }

    /// Estimate bytes needed for delta update
    private func estimateDeltaBytes(changedLines: [Int], grid: TerminalGrid) -> Int {
        // Cursor movement + line clearing + content
        let cursorMovementBytes = changedLines.count * 10  // Rough estimate
        let contentBytes = changedLines.count * grid.width * 2
        return cursorMovementBytes + contentBytes
    }

    /// Detect scroll patterns (simplified)
    private func detectScrollPattern(newGrid: TerminalGrid, currentGrid: TerminalGrid) async -> Bool {
        // TODO: Implement sophisticated scroll detection
        // For now, return false
        return false
    }

    /// Record performance metrics
    private func recordPerformance(_ stats: RenderStats) async {
        let performance = RenderPerformance(
            strategy: stats.strategy,
            linesChanged: stats.linesChanged,
            bytesWritten: stats.bytesWritten,
            duration: stats.duration,
            efficiency: stats.efficiency,
            timestamp: Date()
        )

        renderHistory.append(performance)

        // Keep history size manageable
        if renderHistory.count > maxHistorySize {
            renderHistory.removeFirst()
        }

        // Also record in legacy metrics for test compatibility
        await recordLegacyMetrics(stats)
    }

    /// Record metrics in legacy format for test compatibility
    private func recordLegacyMetrics(_ stats: RenderStats) async {
        // Convert strategy to legacy render mode
        let renderMode: PerformanceMetrics.RenderMode = stats.strategy == .fullRedraw ? .fullRedraw : .lineDiff

        await legacyMetrics.startRender(mode: renderMode)
        await legacyMetrics.recordBytesWritten(stats.bytesWritten)
        await legacyMetrics.recordLinesChanged(stats.linesChanged)

        // Record total lines by setting the counter directly
        let totalLines = currentGrid?.height ?? 0
        await legacyMetrics.recordTotalLines(totalLines)

        // Record dropped frames if any
        if droppedFrames > 0 {
            await legacyMetrics.recordDroppedFrame()
        }

        _ = await legacyMetrics.finishRender()
    }

    /// Adapt thresholds based on performance
    private func adaptThresholds(_ stats: RenderStats) async {
        // Simple adaptive logic - adjust thresholds based on recent performance
        let recentPerformance = Array(renderHistory.suffix(5))

        if recentPerformance.count >= 3 {
            let averageEfficiency = recentPerformance.reduce(0.0) { $0 + $1.efficiency } / Double(recentPerformance.count)

            // If efficiency is consistently low, lower the threshold to prefer full redraws
            if averageEfficiency < 0.3 {
                adaptiveThresholds.deltaThreshold = min(0.6, adaptiveThresholds.deltaThreshold + 0.05)
            } else if averageEfficiency > 0.7 {
                // If efficiency is high, we can be more aggressive with delta updates
                adaptiveThresholds.deltaThreshold = max(0.2, adaptiveThresholds.deltaThreshold - 0.05)
            }
        }
    }
}

/// Adaptive thresholds for strategy selection
public struct AdaptiveThresholds: Sendable {
    /// Minimum bytes saved percentage to use delta update
    public var deltaThreshold: Double = 0.3

    /// Maximum change percentage for delta update
    public var maxChangePercentage: Double = 0.5
}

/// Performance tracking for a single render
private struct RenderPerformance: Sendable {
    let strategy: RenderingStrategy
    let linesChanged: Int
    let bytesWritten: Int
    let duration: TimeInterval
    let efficiency: Double
    let timestamp: Date
}

/// Comprehensive performance metrics
public struct HybridPerformanceMetrics: Sendable {
    public let averageEfficiency: Double
    public let totalRenders: Int
    public let framesSinceFullRedraw: Int
    public let adaptiveThresholds: AdaptiveThresholds
    public let droppedFrames: Int
    public let currentQueueDepth: Int
    public let adaptiveQuality: Double
}
