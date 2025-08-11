import Foundation

/// Records render stats, maintains history, and adapts thresholds.
public actor RenderMetricsRecorder {
    private var renderHistory: [RenderPerformance] = []
    private let maxHistorySize = 10
    private var thresholds: AdaptiveThresholds
    private var legacyMetrics: PerformanceMetrics
    private var droppedFramesProvider: () async -> Int
    private var currentGridHeightProvider: () async -> Int

    public init(
        thresholds: AdaptiveThresholds,
        legacyMetrics: PerformanceMetrics,
        droppedFramesProvider: @escaping () async -> Int,
        currentGridHeightProvider: @escaping () async -> Int,
    ) {
        self.thresholds = thresholds
        self.legacyMetrics = legacyMetrics
        self.droppedFramesProvider = droppedFramesProvider
        self.currentGridHeightProvider = currentGridHeightProvider
    }

    public init(
        thresholds: AdaptiveThresholds,
        legacyMetrics: PerformanceMetrics,
    ) {
        self.thresholds = thresholds
        self.legacyMetrics = legacyMetrics
        droppedFramesProvider = { 0 }
        currentGridHeightProvider = { 0 }
    }

    public func updateProviders(
        droppedFramesProvider: @escaping () async -> Int,
        currentGridHeightProvider: @escaping () async -> Int,
    ) {
        self.droppedFramesProvider = droppedFramesProvider
        self.currentGridHeightProvider = currentGridHeightProvider
    }

    public func record(_ stats: RenderStats) async {
        let performance = RenderPerformance(
            strategy: stats.strategy,
            linesChanged: stats.linesChanged,
            bytesWritten: stats.bytesWritten,
            duration: stats.duration,
            efficiency: stats.efficiency,
            timestamp: Date(),
        )
        renderHistory.append(performance)
        if renderHistory.count > maxHistorySize { renderHistory.removeFirst() }
        await recordLegacy(stats)
        await adaptThresholdsIfNeeded()
    }

    public func getThresholds() async -> AdaptiveThresholds { thresholds }

    public func getAverages() async -> Double {
        let recent = Array(renderHistory.suffix(5))
        guard !recent.isEmpty else { return 0.0 }
        return recent.reduce(0.0) { $0 + $1.efficiency } / Double(recent.count)
    }

    public func reset() async {
        renderHistory.removeAll()
        _ = await legacyMetrics.reset()
    }

    public func getLegacyHistory() async -> [PerformanceMetrics.Counters] {
        await legacyMetrics.getHistory()
    }

    private func recordLegacy(_ stats: RenderStats) async {
        let renderMode: PerformanceMetrics.RenderMode = stats.strategy == .fullRedraw ? .fullRedraw : .lineDiff
        await legacyMetrics.startRender(mode: renderMode)
        await legacyMetrics.recordBytesWritten(stats.bytesWritten)
        await legacyMetrics.recordLinesChanged(stats.linesChanged)
        let totalLines = await currentGridHeightProvider()
        await legacyMetrics.recordTotalLines(totalLines)
        if await droppedFramesProvider() > 0 { await legacyMetrics.recordDroppedFrame() }
        _ = await legacyMetrics.finishRender()
    }

    private func adaptThresholdsIfNeeded() async {
        let recent = Array(renderHistory.suffix(5))
        guard recent.count >= 3 else { return }
        let avg = recent.reduce(0.0) { $0 + $1.efficiency } / Double(recent.count)
        if avg < 0.3 {
            thresholds.deltaThreshold = min(0.6, thresholds.deltaThreshold + 0.05)
        } else if avg > 0.7 {
            thresholds.deltaThreshold = max(0.2, thresholds.deltaThreshold - 0.05)
        }
    }
}

// Internal model mirrors the private one in HybridReconciler
struct RenderPerformance: Sendable {
    let strategy: RenderingStrategy
    let linesChanged: Int
    let bytesWritten: Int
    let duration: TimeInterval
    let efficiency: Double
    let timestamp: Date
}
