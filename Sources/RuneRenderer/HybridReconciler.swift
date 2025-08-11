import Foundation

/// Hybrid reconciler that intelligently chooses between rendering strategies
/// Based on the recommendations for high-performance terminal rendering
public actor HybridReconciler {
    /// The underlying terminal renderer
    private let renderer: TerminalRenderer

    /// Current grid state
    private var currentGrid: TerminalGrid?

    /// Metrics and policies delegated to collaborators
    private let metricsRecorder: RenderMetricsRecorder
    private var adaptiveThresholds = AdaptiveThresholds()
    private var fullRedrawPolicy = FullRedrawPolicy()
    private var strategyDeterminer: StrategyDeterminer

    /// Legacy performance metrics for test compatibility
    private var legacyMetrics: PerformanceMetrics

    /// Update coalescing with backpressure handling
    private var pendingUpdate: TerminalGrid?
    // Timing derived from configuration.performance.maxFrameRate
    private let maxUpdateRate: TimeInterval
    private var lastUpdateTime = Date.distantPast
    private var coalescingWindow: TimeInterval
    private var lastCoalescingTime = Date.distantPast
    private var updateTask: Task<Void, Never>?

    /// Backpressure handling
    private var queueDepth = 0
    private let maxQueueDepth = 5
    private var droppedFrames = 0
    private var qualityController = AdaptiveQualityController() // manages adaptive quality

    /// Configuration for rendering behavior
    private let configuration: RenderConfiguration
    private let differ: TerminalDiffer

    public init(
        renderer: TerminalRenderer,
        configuration: RenderConfiguration,
        differ: TerminalDiffer = SimpleLineDiffer(),
    ) {
        self.renderer = renderer
        self.configuration = configuration
        self.differ = differ
        legacyMetrics = PerformanceMetrics()
        metricsRecorder = RenderMetricsRecorder(thresholds: adaptiveThresholds, legacyMetrics: legacyMetrics)
        strategyDeterminer = StrategyDeterminer(configuration: configuration, adaptiveThresholds: adaptiveThresholds)
        // Derive timing from configuration
        let fps = max(1.0, configuration.performance.maxFrameRate)
        maxUpdateRate = 1.0 / fps
        // Choose a coalescing window as a fraction of frame interval (e.g., ~1/2 frame)
        coalescingWindow = max(0.0, (1.0 / fps) * 0.5)
        Task { [weak self] in
            guard let strongSelf = self else { return }
            await strongSelf.metricsRecorder.updateProviders(
                droppedFramesProvider: { [weak strongSelf] in
                    guard let strong = strongSelf else { return 0 }
                    return await strong.droppedFrames
                },
                currentGridHeightProvider: { [weak strongSelf] in
                    guard let strong = strongSelf else { return 0 }
                    guard let grid = await strong.currentGrid else { return 0 }
                    return grid.height
                },
            )
        }
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
        await legacyMetrics.shutdown() // kept for compatibility

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
            await qualityController.reduceQualityOnBackpressure(current: getAdaptiveQuality())
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
            let window = coalescingWindow // Capture the value
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
        await metricsRecorder.updateProviders(
            droppedFramesProvider: { [weak self] in
                guard let strong = self else { return 0 }
                return await strong.droppedFrames
            },
            currentGridHeightProvider: { [weak self] in
                guard let strong = self else { return 0 }
                let grid = await strong.currentGrid
                return grid?.height ?? 0
            },
        )
        await metricsRecorder.record(stats)
        fullRedrawPolicy.updateCounters(afterFullRedrawAt: Date())
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
        fullRedrawPolicy = FullRedrawPolicy()
    }

    /// Reset internal diff state (used when view identity changes)
    public func resetDiffState() async {
        // Cancel any pending update task and drop pending grid to ensure a clean slate
        updateTask?.cancel()
        updateTask = nil
        pendingUpdate = nil
        // Clear current grid so next render becomes a full redraw
        currentGrid = nil
        // Reset policy objects to initial state
        fullRedrawPolicy = FullRedrawPolicy()
        adaptiveThresholds = AdaptiveThresholds()
        qualityController = AdaptiveQualityController()
        droppedFrames = 0
        queueDepth = 0
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
        await legacyMetrics.getHistory()
    }

    /// Reset performance metrics for testing
    public func resetMetrics() async {
        droppedFrames = 0
        await metricsRecorder.reset()
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
        updateTask = nil // Clear the task reference
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
    public func getPerformanceMetrics() async -> HybridPerformanceMetrics {
        let averageEfficiency = await metricsRecorder.getAverages()
        return await HybridPerformanceMetrics(
            averageEfficiency: averageEfficiency,
            totalRenders: 0, // TODO: expose if needed from metricsRecorder
            framesSinceFullRedraw: 0, // could derive from fullRedrawPolicy if exposed
            adaptiveThresholds: adaptiveThresholds,
            droppedFrames: droppedFrames,
            currentQueueDepth: queueDepth,
            adaptiveQuality: getAdaptiveQuality(),
            maxUpdateRate: maxUpdateRate,
            coalescingWindow: coalescingWindow,
        )
    }

    /// Legacy applyAdaptiveQuality retained for compatibility (now delegates to controller)
    private func applyAdaptiveQuality(_ grid: TerminalGrid) async -> TerminalGrid {
        await qualityController.apply(to: grid)
    }

    // MARK: - Private Methods

    /// Perform the actual rendering with strategy selection
    private func performRender(_ grid: TerminalGrid) async {
        let startTime = Date()

        // Enhanced periodic full redraw logic
        _ = fullRedrawPolicy.snapshot() // maintain local variables removed
        let forceFullRedraw = await fullRedrawPolicy.shouldForceFullRedraw(
            now: startTime,
            adaptiveQuality: getAdaptiveQuality(),
        )

        // Apply adaptive quality - reduce grid resolution if under pressure
        let processedGrid = await qualityController.apply(to: grid)

        // Determine strategy using hybrid logic
        // Determine strategy using hybrid policy
        let strategy = await strategyDeterminer.determineStrategy(
            newGrid: processedGrid,
            currentGrid: currentGrid,
            forceFullRedraw: forceFullRedraw,
        )

        // Render using the chosen strategy
        let stats = await renderer.render(processedGrid, strategy: strategy, previousGrid: currentGrid)

        // Update state
        currentGrid = processedGrid
        if strategy == .fullRedraw {
            fullRedrawPolicy.updateCounters(afterFullRedrawAt: startTime)
        } else {
            fullRedrawPolicy.incrementFrames()
        }

        // Record performance and adapt thresholds
        await metricsRecorder.updateProviders(
            droppedFramesProvider: { [weak self] in
                guard let strong = self else { return 0 }
                return await strong.droppedFrames
            },
            currentGridHeightProvider: { [weak self] in
                guard let strong = self else { return 0 }
                let grid = await strong.currentGrid
                return grid?.height ?? 0
            },
        )
        await metricsRecorder.record(stats)
        adaptiveThresholds = await metricsRecorder.getThresholds()
        strategyDeterminer.updateAdaptiveThresholds(adaptiveThresholds)

        // Decrement queue depth after successful render
        queueDepth = max(0, queueDepth - 1)
    }

    /// Get current adaptive quality value (for tests/metrics)
    private func getAdaptiveQuality() async -> Double {
        // AdaptiveQualityController exposes state synchronously; wrap for actor context
        await withCheckedContinuation { continuation in
            continuation.resume(returning: self.qualityController.adaptiveQuality)
        }
    }

    /// Determine the optimal rendering strategy using hybrid logic (moved to StrategyDeterminer)
    private func determineOptimalStrategy(
        newGrid: TerminalGrid,
        currentGrid: TerminalGrid?,
        forceFullRedraw: Bool,
    ) async -> RenderingStrategy { // Backwards-compat shim
        await strategyDeterminer.determineStrategy(
            newGrid: newGrid,
            currentGrid: currentGrid,
            forceFullRedraw: forceFullRedraw,
        )
    }

    /// Estimate bytes needed for full redraw
    private func estimateFullRedrawBytes(grid: TerminalGrid) -> Int {
        // Rough estimate: each cell is ~1-3 bytes on average
        grid.width * grid.height * 2
    }

    /// Estimate bytes needed for delta update
    private func estimateDeltaBytes(changedLines: [Int], grid: TerminalGrid) -> Int {
        // Cursor movement + line clearing + content
        let cursorMovementBytes = changedLines.count * 10 // Rough estimate
        let contentBytes = changedLines.count * grid.width * 2
        return cursorMovementBytes + contentBytes
    }

    /// Detect scroll patterns (simplified)
    private func detectScrollPattern(newGrid _: TerminalGrid, currentGrid _: TerminalGrid) async -> Bool {
        // TODO: Implement sophisticated scroll detection
        // For now, return false
        false
    }
}

/// Adaptive thresholds for strategy selection
public struct AdaptiveThresholds: Sendable {
    /// Minimum bytes saved percentage to use delta update
    public var deltaThreshold = 0.3

    /// Maximum change percentage for delta update
    public var maxChangePercentage = 0.5
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
    // Expose timing (for CI-safe assertions)
    public let maxUpdateRate: TimeInterval
    public let coalescingWindow: TimeInterval
}
