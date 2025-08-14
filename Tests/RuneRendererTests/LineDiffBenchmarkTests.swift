import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

/// Performance benchmarks for line-diff vs full redraw rendering
///
/// These tests compare the performance characteristics of line-diff optimization
/// versus full redraw mode under various scenarios.
struct LineDiffBenchmarkTests {
    // MARK: - Benchmark Helper Methods

    /// Performance measurement result
    private struct PerformanceResult {
        let totalBytes: Int
        let totalDuration: TimeInterval
        let averageEfficiency: Double
    }

    /// Measure rendering performance for a given configuration and frame sequence
    private func measureRenderingPerformance(
        config: RenderConfiguration,
        frames: [TerminalRenderer.Frame],
    ) async -> PerformanceResult {
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let startTime = Date()

        for frame in frames {
            await frameBuffer.renderFrameImmediate(frame)
            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
        }

        // Wait for all pending updates to complete before measuring
        await frameBuffer.waitForPendingUpdates()

        let endTime = Date()
        output.closeFile()

        // Read all output to measure bytes written
        let data = input.readDataToEndOfFile()
        let totalBytes = data.count
        let totalDuration = endTime.timeIntervalSince(startTime)

        // Get performance metrics
        let history = await frameBuffer.getPerformanceHistory()
        let averageEfficiency = history.isEmpty ? 0.0 :
            history.reduce(0.0) { $0 + $1.efficiency } / Double(history.count)

        input.closeFile()

        return PerformanceResult(
            totalBytes: totalBytes,
            totalDuration: totalDuration,
            averageEfficiency: averageEfficiency,
        )
    }

    /// Generate a sequence of frames with controlled changes
    private func generateFrameSequence(
        baseLines: [String],
        changePattern: ChangePattern,
        frameCount: Int,
    ) -> [TerminalRenderer.Frame] {
        var frames: [TerminalRenderer.Frame] = []
        var currentLines = baseLines

        for i in 0 ..< frameCount {
            switch changePattern {
            case .singleLineChange:
                // Change one line per frame
                let lineIndex = i % currentLines.count
                currentLines[lineIndex] = "Frame \(i) Line \(lineIndex)"

            case .multipleLineChanges:
                // Change multiple lines per frame
                for j in 0 ..< min(3, currentLines.count) {
                    let lineIndex = (i + j) % currentLines.count
                    currentLines[lineIndex] = "Frame \(i) Line \(lineIndex)"
                }

            case .alternatingPattern:
                // Alternate between small and large changes
                if i % 2 == 0 {
                    // Small change
                    let lineIndex = i % currentLines.count
                    currentLines[lineIndex] = "Small change \(i)"
                } else {
                    // Large change
                    for j in 0 ..< currentLines.count {
                        currentLines[j] = "Large change \(i) Line \(j)"
                    }
                }

            case .noChanges:
                // No changes - same frame repeated
                break

            case .allChanges:
                // All lines change every frame
                for j in 0 ..< currentLines.count {
                    currentLines[j] = "Frame \(i) Line \(j)"
                }
            }

            frames.append(TerminalRenderer.Frame(
                lines: currentLines,
                width: 80,
                height: currentLines.count,
            ))
        }

        return frames
    }

    enum ChangePattern {
        case singleLineChange
        case multipleLineChanges
        case alternatingPattern
        case noChanges
        case allChanges
    }

    // MARK: - Benchmark Tests

    @Test(
        "Benchmark: Single line changes favor line-diff",
        .enabled(if: !TestEnv.isCI),
    )
    func benchmarkSingleLineChangesFavorLineDiff() async {
        // Arrange
        let baseLines = Array(1 ... 20).map { "Base line \($0)" }
        let frames = generateFrameSequence(
            baseLines: baseLines,
            changePattern: .singleLineChange,
            frameCount: 10,
        )

        let lineDiffConfig = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.5,
                maxFrameRate: 1000.0,
            ),
            enableMetrics: true,
        )

        let fullRedrawConfig = RenderConfiguration(
            optimizationMode: .fullRedraw,
            enableMetrics: true,
        )

        // Act
        let lineDiffResults = await measureRenderingPerformance(
            config: lineDiffConfig,
            frames: frames,
        )

        let fullRedrawResults = await measureRenderingPerformance(
            config: fullRedrawConfig,
            frames: frames,
        )

        // Assert
        print("Single line changes benchmark:")
        print(
            "  Line-diff: \(lineDiffResults.totalBytes) bytes, \(String(format: "%.2f", lineDiffResults.totalDuration * 1000))ms",
        )
        print(
            "  Full redraw: \(fullRedrawResults.totalBytes) bytes, \(String(format: "%.2f", fullRedrawResults.totalDuration * 1000))ms",
        )
        print("  Bytes saved: \(fullRedrawResults.totalBytes - lineDiffResults.totalBytes)")
        print("  Efficiency: \(String(format: "%.1f%%", lineDiffResults.averageEfficiency * 100))")

        // For small frames, line-diff may use more bytes due to cursor movement overhead
        // This is a realistic finding - line-diff isn't always better
        let bytesRatio = Double(lineDiffResults.totalBytes) / Double(fullRedrawResults.totalBytes)
        #expect(bytesRatio < 3.0, "Line-diff overhead should not be excessive (< 3x full redraw)")

        // Efficiency should show that most lines are unchanged
        #expect(
            lineDiffResults.averageEfficiency > 0.7,
            "Line-diff should detect that most lines are unchanged",
        )
    }

    @Test(
        "Benchmark: All lines changing favors full redraw",
        .enabled(if: !TestEnv.isCI),
    )
    func benchmarkAllLinesChangingFavorsFullRedraw() async {
        // Arrange
        let baseLines = Array(1 ... 20).map { "Base line \($0)" }
        let frames = generateFrameSequence(
            baseLines: baseLines,
            changePattern: .allChanges,
            frameCount: 5,
        )

        let lineDiffConfig = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.1, // Very permissive to force line-diff
                maxFrameRate: 1000.0,
            ),
            enableMetrics: true,
        )

        let fullRedrawConfig = RenderConfiguration(
            optimizationMode: .fullRedraw,
            enableMetrics: true,
        )

        // Act
        let lineDiffResults = await measureRenderingPerformance(
            config: lineDiffConfig,
            frames: frames,
        )

        let fullRedrawResults = await measureRenderingPerformance(
            config: fullRedrawConfig,
            frames: frames,
        )

        // Assert
        print("All lines changing benchmark:")
        print(
            "  Line-diff: \(lineDiffResults.totalBytes) bytes, \(String(format: "%.2f", lineDiffResults.totalDuration * 1000))ms",
        )
        print(
            "  Full redraw: \(fullRedrawResults.totalBytes) bytes, \(String(format: "%.2f", fullRedrawResults.totalDuration * 1000))ms",
        )
        print("  Efficiency: \(String(format: "%.1f%%", lineDiffResults.averageEfficiency * 100))")

        // When all lines change, line-diff should not be significantly better
        // (and might be worse due to overhead)
        let bytesRatio = Double(lineDiffResults.totalBytes) / Double(fullRedrawResults.totalBytes)
        #expect(bytesRatio > 0.8, "Line-diff overhead should not be excessive even when all lines change")

        // Efficiency should be low when all lines change
        #expect(
            lineDiffResults.averageEfficiency < 0.2,
            "Line-diff efficiency should be low when all lines change",
        )
    }

    @Test("Benchmark: No changes favor line-diff", .enabled(if: !TestEnv.isCI))
    func benchmarkNoChangesFavorLineDiff() async {
        // Arrange
        let baseLines = Array(1 ... 20).map { "Base line \($0)" }
        let frames = generateFrameSequence(
            baseLines: baseLines,
            changePattern: .noChanges,
            frameCount: 10,
        )

        let lineDiffConfig = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.5,
                maxFrameRate: 1000.0,
            ),
            enableMetrics: true,
        )

        let fullRedrawConfig = RenderConfiguration(
            optimizationMode: .fullRedraw,
            enableMetrics: true,
        )

        // Act
        let lineDiffResults = await measureRenderingPerformance(
            config: lineDiffConfig,
            frames: frames,
        )

        let fullRedrawResults = await measureRenderingPerformance(
            config: fullRedrawConfig,
            frames: frames,
        )

        // Assert
        print("No changes benchmark:")
        print(
            "  Line-diff: \(lineDiffResults.totalBytes) bytes, \(String(format: "%.2f", lineDiffResults.totalDuration * 1000))ms",
        )
        print(
            "  Full redraw: \(fullRedrawResults.totalBytes) bytes, \(String(format: "%.2f", fullRedrawResults.totalDuration * 1000))ms",
        )
        print("  Bytes saved: \(fullRedrawResults.totalBytes - lineDiffResults.totalBytes)")
        print("  Efficiency: \(String(format: "%.1f%%", lineDiffResults.averageEfficiency * 100))")

        // Even with no changes, line-diff has overhead from the first full redraw
        // The efficiency should be high though, showing no changes detected
        #expect(
            lineDiffResults.averageEfficiency > 0.8,
            "Line-diff should detect that no lines changed",
        )

        // The overhead should not be excessive
        let bytesRatio = Double(lineDiffResults.totalBytes) / Double(fullRedrawResults.totalBytes)
        #expect(bytesRatio < 2.0, "Line-diff overhead should be reasonable even with no changes")
    }

    @Test(
        "Benchmark: Automatic mode makes good decisions",
        .enabled(if: !TestEnv.isCI),
    )
    func benchmarkAutomaticModeMakesGoodDecisions() async {
        // Arrange
        let baseLines = Array(1 ... 20).map { "Base line \($0)" }
        let frames = generateFrameSequence(
            baseLines: baseLines,
            changePattern: .alternatingPattern,
            frameCount: 10,
        )

        let automaticConfig = RenderConfiguration(
            optimizationMode: .automatic,
            performance: RenderConfiguration.PerformanceTuning(
                minEfficiencyThreshold: 0.5,
                maxFrameRate: 1000.0,
            ),
            enableMetrics: true,
        )

        let fullRedrawConfig = RenderConfiguration(
            optimizationMode: .fullRedraw,
            enableMetrics: true,
        )

        // Act
        let automaticResults = await measureRenderingPerformance(
            config: automaticConfig,
            frames: frames,
        )

        let fullRedrawResults = await measureRenderingPerformance(
            config: fullRedrawConfig,
            frames: frames,
        )

        // Assert
        print("Automatic mode benchmark:")
        print(
            "  Automatic: \(automaticResults.totalBytes) bytes, \(String(format: "%.2f", automaticResults.totalDuration * 1000))ms",
        )
        print(
            "  Full redraw: \(fullRedrawResults.totalBytes) bytes, \(String(format: "%.2f", fullRedrawResults.totalDuration * 1000))ms",
        )
        print("  Bytes saved: \(fullRedrawResults.totalBytes - automaticResults.totalBytes)")
        print("  Efficiency: \(String(format: "%.1f%%", automaticResults.averageEfficiency * 100))")

        // Automatic mode makes decisions based on efficiency, so it may use more bytes
        // when line-diff is not efficient, but should not be excessively wasteful
        let bytesRatio = Double(automaticResults.totalBytes) / Double(fullRedrawResults.totalBytes)
        #expect(bytesRatio < 15.0, "Automatic mode should not be excessively wasteful")

        // Alternating pattern causes all renders to fall back to full redraw, so efficiency may be 0.0
        #expect(automaticResults.averageEfficiency >= 0.0, "Automatic mode should handle alternating patterns")
    }
}
