import Testing
import Foundation
@testable import RuneRenderer

/// Tests for the RenderConfiguration system
///
/// These tests verify the configuration system that controls rendering
/// behavior and optimization modes.
struct RenderConfigurationTests {
    // MARK: - Default Configuration Tests

    @Test("Default configuration has expected values")
    func defaultConfigurationHasExpectedValues() {
        // Arrange & Act
        let config = RenderConfiguration.default

        // Assert
        #expect(config.optimizationMode == .lineDiff, "Default should use line-diff optimization")
        #expect(config.enableMetrics == true, "Default should enable metrics")
        #expect(config.enableDebugLogging == false, "Default should disable debug logging")
        #expect(config.hideCursorDuringRender == true, "Default should hide cursor during render")
        #expect(config.useAlternateScreen == false, "Default should not use alternate screen")

        // Performance tuning defaults
        #expect(config.performance.maxLinesForDiff == 1000, "Default max lines should be 1000")
        #expect(config.performance.minEfficiencyThreshold == 0.7, "Default efficiency threshold should be 0.7")
        #expect(config.performance.maxFrameRate == 60.0, "Default max frame rate should be 60 FPS")
        #expect(config.performance.writeBufferSize == 8192, "Default buffer size should be 8192")
    }

    @Test("High performance configuration has aggressive settings")
    func highPerformanceConfigurationHasAggressiveSettings() {
        // Arrange & Act
        let config = RenderConfiguration.highPerformance

        // Assert
        #expect(config.optimizationMode == .lineDiff, "High performance should use line-diff")
        #expect(config.performance.maxLinesForDiff == 2000, "Should allow more lines for diff")
        #expect(config.performance.minEfficiencyThreshold == 0.8, "Should have higher efficiency threshold")
        #expect(config.performance.maxFrameRate == 120.0, "Should allow higher frame rate")
        #expect(config.performance.writeBufferSize == 16384, "Should have larger buffer")
    }

    @Test("Conservative configuration has safe settings")
    func conservativeConfigurationHasSafeSettings() {
        // Arrange & Act
        let config = RenderConfiguration.conservative

        // Assert
        #expect(config.optimizationMode == .fullRedraw, "Conservative should use full redraw")
        #expect(config.performance.maxLinesForDiff == 100, "Should limit lines for diff")
        #expect(config.performance.minEfficiencyThreshold == 0.5, "Should have lower efficiency threshold")
        #expect(config.performance.maxFrameRate == 30.0, "Should limit frame rate")
        #expect(config.performance.writeBufferSize == 4096, "Should have smaller buffer")
        #expect(config.enableDebugLogging == true, "Should enable debug logging")
    }

    @Test("Debug configuration enables extensive logging")
    func debugConfigurationEnablesExtensiveLogging() {
        // Arrange & Act
        let config = RenderConfiguration.debug

        // Assert
        #expect(config.optimizationMode == .automatic, "Debug should use automatic mode")
        #expect(config.enableMetrics == true, "Debug should enable metrics")
        #expect(config.enableDebugLogging == true, "Debug should enable logging")
        #expect(config.performance.writeBufferSize == 1024, "Debug should have small buffer for testing")
    }

    // MARK: - Custom Configuration Tests

    @Test("Custom configuration accepts all parameters")
    func customConfigurationAcceptsAllParameters() {
        // Arrange
        let customPerformance = RenderConfiguration.PerformanceTuning(
            maxLinesForDiff: 500,
            minEfficiencyThreshold: 0.6,
            maxFrameRate: 45.0,
            writeBufferSize: 2048
        )

        // Act
        let config = RenderConfiguration(
            optimizationMode: .automatic,
            performance: customPerformance,
            enableMetrics: false,
            enableDebugLogging: true,
            hideCursorDuringRender: false,
            useAlternateScreen: true
        )

        // Assert
        #expect(config.optimizationMode == .automatic, "Should use specified optimization mode")
        #expect(config.performance.maxLinesForDiff == 500, "Should use custom max lines")
        #expect(config.performance.minEfficiencyThreshold == 0.6, "Should use custom efficiency threshold")
        #expect(config.performance.maxFrameRate == 45.0, "Should use custom frame rate")
        #expect(config.performance.writeBufferSize == 2048, "Should use custom buffer size")
        #expect(config.enableMetrics == false, "Should use specified metrics setting")
        #expect(config.enableDebugLogging == true, "Should use specified debug setting")
        #expect(config.hideCursorDuringRender == false, "Should use specified cursor setting")
        #expect(config.useAlternateScreen == true, "Should use specified screen setting")
    }

    // MARK: - Optimization Mode Resolution Tests

    @Test("Full redraw mode always returns full redraw")
    func fullRedrawModeAlwaysReturnsFullRedraw() {
        // Arrange
        let config = RenderConfiguration(optimizationMode: .fullRedraw)

        // Act & Assert
        let result1 = config.resolveOptimizationMode(frameLines: 10)
        #expect(result1 == .fullRedraw, "Should always return full redraw")

        let result2 = config.resolveOptimizationMode(frameLines: 2000)
        #expect(result2 == .fullRedraw, "Should return full redraw even for large frames")

        let result3 = config.resolveOptimizationMode(frameLines: 10, changedLines: 1)
        #expect(result3 == .fullRedraw, "Should return full redraw even with few changes")
    }

    @Test("Line diff mode respects frame size limits")
    func lineDiffModeRespectsFrameSizeLimits() {
        // Arrange
        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(maxLinesForDiff: 100)
        )

        // Act & Assert
        let result1 = config.resolveOptimizationMode(frameLines: 50)
        #expect(result1 == .lineDiff, "Should use line diff for small frames")

        let result2 = config.resolveOptimizationMode(frameLines: 150)
        #expect(result2 == .fullRedraw, "Should fall back to full redraw for large frames")
    }

    @Test("Line diff mode respects efficiency threshold")
    func lineDiffModeRespectsEfficiencyThreshold() {
        // Arrange
        let config = RenderConfiguration(
            optimizationMode: .lineDiff,
            performance: RenderConfiguration.PerformanceTuning(minEfficiencyThreshold: 0.5)
        )

        // Act & Assert
        let result1 = config.resolveOptimizationMode(frameLines: 10, changedLines: 3)
        #expect(result1 == .lineDiff, "Should use line diff when efficiency is good (3/10 = 0.3 < 0.5)")

        let result2 = config.resolveOptimizationMode(frameLines: 10, changedLines: 8)
        #expect(result2 == .fullRedraw, "Should use full redraw when efficiency is poor (8/10 = 0.8 > 0.5)")
    }

    @Test("Automatic mode makes intelligent decisions")
    func automaticModeMakesIntelligentDecisions() {
        // Arrange
        let config = RenderConfiguration(
            optimizationMode: .automatic,
            performance: RenderConfiguration.PerformanceTuning(
                maxLinesForDiff: 100,
                minEfficiencyThreshold: 0.6
            )
        )

        // Act & Assert
        let result1 = config.resolveOptimizationMode(frameLines: 50)
        #expect(result1 == .lineDiff, "Should default to line diff for reasonable frame size")

        let result2 = config.resolveOptimizationMode(frameLines: 150)
        #expect(result2 == .fullRedraw, "Should use full redraw for large frames")

        // Test with previous metrics showing poor efficiency
        let poorMetrics = PerformanceMetrics.Counters(
            bytesWritten: 1000,
            linesChanged: 80,
            totalLines: 100,
            framesDropped: 0,
            renderMode: .lineDiff,
            renderDuration: 0.1
        )

        let result3 = config.resolveOptimizationMode(
            frameLines: 50,
            previousMetrics: poorMetrics
        )
        #expect(result3 == .fullRedraw, "Should use full redraw when previous efficiency was poor")
    }

    // MARK: - Frame Rate Limiting Tests

    @Test("Frame rate limiting works correctly")
    func frameRateLimitingWorksCorrectly() {
        // Arrange
        let config = RenderConfiguration(
            performance: RenderConfiguration.PerformanceTuning(maxFrameRate: 30.0)
        )

        let now = Date()
        let recentFrame = now.addingTimeInterval(-0.01) // 10ms ago
        let oldFrame = now.addingTimeInterval(-0.1) // 100ms ago

        // Act & Assert
        let shouldDrop1 = config.shouldDropFrame(lastFrameTime: recentFrame)
        #expect(shouldDrop1 == true, "Should drop frame when too recent (10ms < 33ms for 30 FPS)")

        let shouldDrop2 = config.shouldDropFrame(lastFrameTime: oldFrame)
        #expect(shouldDrop2 == false, "Should not drop frame when enough time has passed")
    }

    @Test("High frame rate allows more frequent updates")
    func highFrameRateAllowsMoreFrequentUpdates() {
        // Arrange
        let config = RenderConfiguration(
            performance: RenderConfiguration.PerformanceTuning(maxFrameRate: 120.0)
        )

        let now = Date()
        let recentFrame = now.addingTimeInterval(-0.005) // 5ms ago

        // Act & Assert
        let shouldDrop = config.shouldDropFrame(lastFrameTime: recentFrame)
        #expect(shouldDrop == true, "Should still drop frame when too recent (5ms < 8.3ms for 120 FPS)")

        let slightlyOlderFrame = now.addingTimeInterval(-0.01) // 10ms ago
        let shouldNotDrop = config.shouldDropFrame(lastFrameTime: slightlyOlderFrame)
        #expect(shouldNotDrop == false, "Should not drop frame when enough time has passed for high FPS")
    }

    // MARK: - Environment Configuration Tests

    @Test("Environment configuration reads render mode")
    func environmentConfigurationReadsRenderMode() {
        // Note: This test would need to mock environment variables in a real implementation
        // For now, we'll test the structure exists and handles the case where no env vars are set

        // Act
        let config = RenderConfiguration.fromEnvironment()

        // Assert
        // Should return default configuration when no environment variables are set
        #expect(config.optimizationMode == .lineDiff, "Should default to line-diff when no env vars")
        #expect(config.enableMetrics == true, "Should use default metrics setting")
    }

    // MARK: - Performance Tuning Tests

    @Test("Performance tuning has reasonable defaults")
    func performanceTuningHasReasonableDefaults() {
        // Arrange & Act
        let tuning = RenderConfiguration.PerformanceTuning()

        // Assert
        #expect(tuning.maxLinesForDiff > 0, "Max lines should be positive")
        #expect(tuning.minEfficiencyThreshold > 0.0, "Efficiency threshold should be positive")
        #expect(tuning.minEfficiencyThreshold < 1.0, "Efficiency threshold should be less than 1.0")
        #expect(tuning.maxFrameRate > 0.0, "Frame rate should be positive")
        #expect(tuning.writeBufferSize > 0, "Buffer size should be positive")
    }

    @Test("Performance tuning accepts custom values")
    func performanceTuningAcceptsCustomValues() {
        // Arrange & Act
        let tuning = RenderConfiguration.PerformanceTuning(
            maxLinesForDiff: 2500,
            minEfficiencyThreshold: 0.85,
            maxFrameRate: 144.0,
            writeBufferSize: 32768
        )

        // Assert
        #expect(tuning.maxLinesForDiff == 2500, "Should use custom max lines")
        #expect(tuning.minEfficiencyThreshold == 0.85, "Should use custom efficiency threshold")
        #expect(tuning.maxFrameRate == 144.0, "Should use custom frame rate")
        #expect(tuning.writeBufferSize == 32768, "Should use custom buffer size")
    }

    // MARK: - Optimization Mode Enum Tests

    @Test("Optimization mode enum has all expected cases")
    func optimizationModeEnumHasAllExpectedCases() {
        // Arrange & Act
        let allCases = RenderConfiguration.OptimizationMode.allCases

        // Assert
        #expect(allCases.count == 3, "Should have exactly 3 optimization modes")
        #expect(allCases.contains(.fullRedraw), "Should include full redraw mode")
        #expect(allCases.contains(.lineDiff), "Should include line diff mode")
        #expect(allCases.contains(.automatic), "Should include automatic mode")
    }

    @Test("Optimization mode raw values are correct")
    func optimizationModeRawValuesAreCorrect() {
        // Act & Assert
        #expect(RenderConfiguration.OptimizationMode.fullRedraw.rawValue == "full_redraw", "Full redraw raw value should match")
        #expect(RenderConfiguration.OptimizationMode.lineDiff.rawValue == "line_diff", "Line diff raw value should match")
        #expect(RenderConfiguration.OptimizationMode.automatic.rawValue == "automatic", "Automatic raw value should match")
    }
}
