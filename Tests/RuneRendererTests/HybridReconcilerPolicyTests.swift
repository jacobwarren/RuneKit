import Foundation
import Testing
@testable import RuneRenderer

struct HybridReconcilerPolicyTests {
    @Test("StrategyDeterminer chooses full redraw on nil current or forced")
    func strategyDeterminerBasics() async {
        let config = RenderConfiguration(optimizationMode: .automatic)
        var determiner = StrategyDeterminer(configuration: config, adaptiveThresholds: AdaptiveThresholds())
        let grid = TerminalGrid(width: 10, height: 5)
        let s1 = await determiner.determineStrategy(newGrid: grid, currentGrid: nil, forceFullRedraw: false)
        #expect(s1 == .fullRedraw)
        let s2 = await determiner.determineStrategy(newGrid: grid, currentGrid: grid, forceFullRedraw: true)
        #expect(s2 == .fullRedraw)
    }

    @Test("FullRedrawPolicy triggers by time/frames/quality")
    func fullRedrawPolicy() {
        var policy = FullRedrawPolicy(
            framesSinceFullRedraw: 99,
            lastFullRedrawTime: Date().addingTimeInterval(-1),
            maxFramesBetweenFullRedraws: 100,
            maxTimeBetweenFullRedraws: 30,
        )
        #expect(!policy.shouldForceFullRedraw(now: Date(), adaptiveQuality: 1.0))
        policy.incrementFrames()
        #expect(policy.shouldForceFullRedraw(now: Date(), adaptiveQuality: 1.0))
        policy.updateCounters(afterFullRedrawAt: Date())
        #expect(!policy.shouldForceFullRedraw(now: Date(), adaptiveQuality: 1.0))
        // Quality low
        #expect(policy.shouldForceFullRedraw(now: Date(), adaptiveQuality: 0.5))
    }

    @Test("RenderMetricsRecorder records and adapts thresholds")
    func metricsRecorderRecords() async {
        let metrics = PerformanceMetrics()
        let recorder = RenderMetricsRecorder(thresholds: AdaptiveThresholds(), legacyMetrics: metrics)
        var stats = RenderStats()
        stats.strategy = .deltaUpdate
        stats.linesChanged = 1
        stats.bytesWritten = 10
        stats.duration = 0.01
        await recorder.record(stats)
        // Average from one record equals its efficiency per current RenderStats impl
        let avg = await recorder.getAverages()
        #expect(avg >= 0.0)
        let thresholds = await recorder.getThresholds()
        #expect(thresholds.deltaThreshold >= 0.2 && thresholds.deltaThreshold <= 0.6)
        await recorder.reset()
    }

    @Test("AdaptiveQualityController reduces quality on backpressure and applies no-op")
    func qualityController() async {
        var controller = AdaptiveQualityController()
        controller.reduceQualityOnBackpressure(current: 1.0)
        let grid = TerminalGrid(width: 5, height: 5)
        let out = await controller.apply(to: grid)
        #expect(out.width == grid.width && out.height == grid.height)
    }
}
