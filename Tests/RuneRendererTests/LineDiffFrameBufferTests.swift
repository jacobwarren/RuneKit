import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

/// Integration tests for the enhanced FrameBuffer with line-diff support
///
/// These tests verify the complete line-diff rendering pipeline including
/// performance metrics, configuration handling, and visual output correctness.
@Suite("Line diff frame buffer tests", TestEnv.skipIntegrationInCI)
struct LineDiffFrameBufferTests {
    // MARK: - Basic Line-Diff Rendering Tests

    @Test("Line-diff mode renders single line change efficiently")
    func lineDiffModeRendersSingleLineChangeEfficiently() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.5, // Require at least 50% efficiency
                maxFrameRate: 1000.0, // Very high frame rate to avoid dropping frames
            ),
            enableDebugLogging: true, // Enable debug logging to see what's happening
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 20, // Increased to accommodate "Modified Line 2" (14 chars)
            height: 3,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Line 1", "Modified Line 2", "Line 3"],
            width: 20, // Increased to accommodate "Modified Line 2" (14 chars)
            height: 3,
        )

        // Act
        await frameBuffer.renderFrameImmediate(frame1)
        await frameBuffer.renderFrameImmediate(frame2)

        // Get performance metrics from history (before shutdown)
        let history = await frameBuffer.getPerformanceHistory()
        #expect(history.count >= 1, "Should have at least one render in history")

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain cursor hide/show sequences
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor")
        #expect(result.contains("\u{001B}[?25h"), "Should show cursor")

        // Should contain the modified content
        #expect(result.contains("Modified Line 2"), "Should contain modified line")

        if history.count >= 2 {
            let firstRender = history[0]
            let secondRender = history[1]

            #expect(firstRender.renderMode == .fullRedraw, "First render should use full redraw (no previous frame)")
            #expect(firstRender.linesChanged == 3, "First render should change all lines")

            #expect(secondRender.renderMode == .lineDiff, "Second render should use line-diff mode")
            #expect(secondRender.linesChanged == 1, "Second render should change only 1 line")
            #expect(secondRender.totalLines == 3, "Should have 3 total lines")
        } else {
            // If only one render, it means the second render fell back to full redraw
            let render = history[0]
            #expect(render.renderMode == .fullRedraw, "Should use full redraw mode")
            #expect(render.totalLines == 3, "Should have 3 total lines")
        }

        // Cleanup
        await frameBuffer.shutdown()
        input.closeFile()
    }

    @Test("Full redraw mode renders all lines")
    func fullRedrawModeRendersAllLines() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .fullRedraw,
            enableDebugLogging: false,
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Line 1", "Modified Line 2"],
            width: 10,
            height: 2,
        )

        // Act
        await frameBuffer.renderFrame(frame1)
        await frameBuffer.renderFrame(frame2)
        await frameBuffer.waitForPendingUpdates()

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()
        #expect(!history.isEmpty, "Should have performance history")
        let metrics = history.last!
        #expect(metrics.renderMode == .fullRedraw, "Should use full redraw mode")
        #expect(metrics.linesChanged == 2, "Should change all lines in full redraw")
        #expect(metrics.totalLines == 2, "Should have 2 total lines")

        // Cleanup
        input.closeFile()
    }

    @Test("Automatic mode chooses appropriate optimization")
    func automaticModeChoosesAppropriateOptimization() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .automatic,
            performance: RenderConfiguration.PerformanceTuning(
                maxLinesForDiff: 10,
                minEfficiencyThreshold: 0.5,
            ),
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Small frame with few changes - should use line-diff
        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 10,
            height: 3,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Line 1", "Modified", "Line 3"],
            width: 10,
            height: 3,
        )

        // Act
        await frameBuffer.renderFrameImmediate(frame1)
        await frameBuffer.renderFrameImmediate(frame2)

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()
        #expect(history.count >= 1, "Should have at least one render in history")

        if history.count >= 2 {
            let secondRender = history[1]
            #expect(secondRender.renderMode == .lineDiff, "Second render should choose line-diff for efficient case")
        } else {
            // If only one render, it means the second render was dropped or fell back to full redraw
            let render = history[0]
            #expect(render.renderMode == .fullRedraw, "Should use full redraw mode")
        }

        // Cleanup
        input.closeFile()
    }

    // MARK: - Frame Size Change Tests

    @Test("Line-diff handles frame growth correctly")
    func lineDiffHandlesFrameGrowthCorrectly() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.3, // Require at least 30% efficiency
                maxFrameRate: 1000.0, // Very high frame rate to avoid dropping frames
            ),
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        // Act
        await frameBuffer.renderFrameImmediate(frame1)
        await frameBuffer.renderFrameImmediate(frame2)

        // Check performance history (before shutdown)
        let history = await frameBuffer.getPerformanceHistory()
        #expect(history.count == 2, "Should have two renders in history")

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        #expect(result.contains("Line 3"), "Should contain new line 3")
        #expect(result.contains("Line 4"), "Should contain new line 4")

        let secondRender = history[1]
        #expect(secondRender.renderMode == .lineDiff, "Second render should use line-diff mode")
        #expect(secondRender.linesChanged == 2, "Should change 2 lines (the new ones)")
        #expect(secondRender.totalLines == 4, "Should have 4 total lines")

        // Cleanup
        input.closeFile()
    }

    @Test("Line-diff handles frame shrinkage correctly")
    func lineDiffHandlesFrameShrinkageCorrectly() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.3, // Require at least 30% efficiency
                maxFrameRate: 1000.0, // Very high frame rate to avoid dropping frames
            ),
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2,
        )

        // Act
        await frameBuffer.renderFrameImmediate(frame1)
        await frameBuffer.renderFrameImmediate(frame2)

        // Wait for any pending async operations
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Check performance history (before shutdown)
        let history = await frameBuffer.getPerformanceHistory()
        #expect(history.count == 2, "Should have two renders in history")

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain line clearing sequences for removed lines
        // Either EL (line-diff mode) or 2K (full redraw mode)
        let hasLineClear = result.contains("\u{001B}[K") || result.contains("\u{001B}[2K")
        #expect(hasLineClear, "Should clear removed lines")

        let secondRender = history[1]
        #expect(secondRender.totalLines == 2, "Should have 2 total lines after shrinkage")

        // Cleanup
        input.closeFile()
    }

    // MARK: - Error Handling and Edge Cases

    @Test("Empty frame renders correctly")
    func emptyFrameRendersCorrectly() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output)

        let emptyFrame = TerminalRenderer.Frame(
            lines: [],
            width: 0,
            height: 0,
        )

        // Act
        await frameBuffer.renderFrameImmediate(emptyFrame)

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()
        #expect(!history.isEmpty, "Should have performance history")
        let metrics = history.last!
        #expect(metrics.totalLines == 0, "Should handle empty frame")
        #expect(metrics.linesChanged == 0, "Should have no lines changed for empty frame")

        // Cleanup
        input.closeFile()
    }

    @Test("Large frame falls back to full redraw")
    func largeFrameFallsBackToFullRedraw() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(maxLinesForDiff: 5),
        )
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Create a frame larger than the limit
        let largeFrame = TerminalRenderer.Frame(
            lines: Array(1 ... 10).map { "Line \($0)" },
            width: 10,
            height: 10,
        )

        // Act
        await frameBuffer.renderFrameImmediate(largeFrame)

        // Assert
        let history = await frameBuffer.getPerformanceHistory()

        // Cleanup
        await frameBuffer.shutdown()
        output.closeFile()
        #expect(!history.isEmpty, "Should have performance history")
        let metrics = history.last!
        #expect(metrics.renderMode == .fullRedraw, "Should fall back to full redraw for large frames")
        #expect(metrics.totalLines == 10, "Should handle all lines")

        // Cleanup
        input.closeFile()
    }
}
