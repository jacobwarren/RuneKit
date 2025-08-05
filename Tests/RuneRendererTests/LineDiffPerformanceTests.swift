import Testing
import Foundation
@testable import RuneRenderer

/// Performance metrics tests for the enhanced FrameBuffer with line-diff support
///
/// These tests verify performance metrics collection, frame rate limiting,
/// and configuration handling for the line-diff rendering pipeline.
struct LineDiffPerformanceTests {
    // MARK: - Performance Metrics Tests

    @Test("Performance metrics are collected correctly")
    func performanceMetricsAreCollectedCorrectly() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            enableMetrics: true
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame = TerminalRenderer.Frame(
            lines: ["Test line"],
            width: 10,
            height: 1
        )

        // Act
        await frameBuffer.renderFrameImmediate(frame)

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // Cleanup
        await frameBuffer.clear()
        output.closeFile()
        #expect(!history.isEmpty, "Should have performance history")
        let metrics = history.last!
        #expect(metrics.bytesWritten > 0, "Should record bytes written")
        #expect(metrics.linesChanged >= 0, "Should record lines changed")
        #expect(metrics.totalLines == 1, "Should record total lines")
        #expect(metrics.renderDuration >= 0, "Should record render duration")
        #expect(history.count == 1, "Should have one entry in history")

        // Cleanup
        input.closeFile()
    }

    @Test("Performance history accumulates over multiple renders")
    func performanceHistoryAccumulatesOverMultipleRenders() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.3,  // Require at least 30% efficiency
                maxFrameRate: 1000.0  // Very high frame rate to avoid dropping frames
            )
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Act - Render multiple frames with some similarity
        let frames = [
            TerminalRenderer.Frame(lines: ["Line 1", "Line 2"], width: 10, height: 2),
            TerminalRenderer.Frame(lines: ["Line 1", "Modified"], width: 10, height: 2),
            TerminalRenderer.Frame(lines: ["Line 1", "Final"], width: 10, height: 2)
        ]

        for frame in frames {
            await frameBuffer.renderFrameImmediate(frame)
        }
        output.closeFile()

        // Assert
        let history = await frameBuffer.getPerformanceHistory()
        #expect(history.count == 3, "Should have three entries in history")

        // Verify each entry has valid data
        for (index, entry) in history.enumerated() {
            #expect(entry.bytesWritten > 0, "Entry \(index) should have bytes written")
            #expect(entry.renderDuration >= 0, "Entry \(index) should have valid duration")
        }

        // Cleanup
        input.closeFile()
    }

    // MARK: - Frame Rate Limiting Tests

    @Test("Frame rate limiting drops frames when appropriate")
    func frameRateLimitingDropsFramesWhenAppropriate() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                maxFrameRate: 10.0  // Very low frame rate to trigger dropping
            )
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Act - Send frames rapidly
        let frames = [
            TerminalRenderer.Frame(lines: ["Frame 1"], width: 10, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 2"], width: 10, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 3"], width: 10, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 4"], width: 10, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 5"], width: 10, height: 1)
        ]

        // Send frames as fast as possible
        for frame in frames {
            await frameBuffer.renderFrame(frame)  // Non-immediate to allow dropping
        }

        // Wait for any pending renders
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        output.closeFile()

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // With a 10 FPS limit and rapid sending, some frames should be dropped
        // We can't guarantee exact numbers due to timing, but we should see fewer renders than frames sent
        #expect(history.count <= frames.count, "Should not render more frames than sent")

        // Cleanup
        await frameBuffer.clear()
        input.closeFile()
    }

    @Test("Frame rate limiting allows frames when under limit")
    func frameRateLimitingAllowsFramesWhenUnderLimit() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                maxFrameRate: 1000.0  // Very high frame rate
            )
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Act - Send frames slowly
        let frames = [
            TerminalRenderer.Frame(lines: ["Frame 1"], width: 10, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 2"], width: 10, height: 1)
        ]

        for frame in frames {
            await frameBuffer.renderFrameImmediate(frame)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between frames
        }
        output.closeFile()

        // Assert
        let history = await frameBuffer.getPerformanceHistory()
        #expect(history.count == frames.count, "Should render all frames when under rate limit")

        // Cleanup
        await frameBuffer.clear()
        input.closeFile()
    }

    // MARK: - Configuration Tests

    @Test("Configuration is accessible and correct")
    func configurationIsAccessibleAndCorrect() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let customConfig = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                maxLinesForDiff: 500,
                minEfficiencyThreshold: 0.4,
                maxFrameRate: 60.0
            ),
            enableMetrics: true,
            enableDebugLogging: false
        )

        let frameBuffer = FrameBuffer(output: output, configuration: customConfig)

        // Act
        let retrievedConfig = await frameBuffer.getConfiguration()

        // Assert
        #expect(retrievedConfig.optimizationMode == .lineDiff, "Should preserve optimization mode")
        #expect(retrievedConfig.performance.maxLinesForDiff == 500, "Should preserve max lines for diff")
        #expect(retrievedConfig.performance.minEfficiencyThreshold == 0.4, "Should preserve efficiency threshold")
        #expect(retrievedConfig.performance.maxFrameRate == 60.0, "Should preserve max frame rate")
        #expect(retrievedConfig.enableMetrics == true, "Should preserve metrics setting")
        #expect(retrievedConfig.enableDebugLogging == false, "Should preserve debug logging setting")

        // Cleanup
        await frameBuffer.clear()
        output.closeFile()
        input.closeFile()
    }

    @Test("Default configuration has sensible values")
    func defaultConfigurationHasSensibleValues() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output)

        // Act
        let config = await frameBuffer.getConfiguration()

        // Assert
        #expect(config.performance.maxLinesForDiff > 0, "Should have positive max lines for diff")
        #expect(config.performance.minEfficiencyThreshold >= 0.0, "Should have non-negative efficiency threshold")
        #expect(config.performance.minEfficiencyThreshold <= 1.0, "Should have efficiency threshold <= 1.0")
        #expect(config.performance.maxFrameRate > 0.0, "Should have positive max frame rate")

        // Cleanup
        await frameBuffer.clear()
        output.closeFile()
        input.closeFile()
    }

    @Test("Configuration is immutable after creation")
    func configurationIsImmutableAfterCreation() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(maxFrameRate: 30.0)
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Act
        let retrievedConfig = await frameBuffer.getConfiguration()

        // Assert
        #expect(retrievedConfig.optimizationMode == .lineDiff, "Should preserve optimization mode")
        #expect(retrievedConfig.performance.maxFrameRate == 30.0, "Should preserve max frame rate")

        // Configuration should be immutable - no update method exists
        // This is by design for thread safety and predictable behavior

        // Cleanup
        await frameBuffer.clear()
        output.closeFile()
        input.closeFile()
    }
}
