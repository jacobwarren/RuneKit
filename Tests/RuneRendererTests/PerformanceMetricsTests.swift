import Foundation
import Testing
@testable import RuneRenderer

/// Tests for the PerformanceMetrics system
///
/// These tests verify the performance tracking functionality that collects
/// metrics about rendering operations for optimization analysis.
struct PerformanceMetricsTests {
    // MARK: - Basic Metrics Tests

    @Test("Initial state is empty")
    func initialStateIsEmpty() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.bytesWritten == 0, "Initial bytes written should be 0")
        #expect(counters.linesChanged == 0, "Initial lines changed should be 0")
        #expect(counters.totalLines == 0, "Initial total lines should be 0")
        #expect(counters.framesDropped == 0, "Initial frames dropped should be 0")
        #expect(counters.renderMode == .fullRedraw, "Initial render mode should be full redraw")
        #expect(counters.renderDuration == 0.0, "Initial render duration should be 0")
    }

    @Test("Start render initializes tracking")
    func startRenderInitializesTracking() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act
        await metrics.startRender(mode: .lineDiff)
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.renderMode == .lineDiff, "Render mode should be set")
        #expect(counters.bytesWritten == 0, "Bytes written should start at 0")
        #expect(counters.linesChanged == 0, "Lines changed should start at 0")
        #expect(counters.totalLines == 0, "Total lines should start at 0")
    }

    @Test("Record bytes written accumulates correctly")
    func recordBytesWrittenAccumulatesCorrectly() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .fullRedraw)

        // Act
        await metrics.recordBytesWritten(100)
        await metrics.recordBytesWritten(50)
        await metrics.recordBytesWritten(25)

        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.bytesWritten == 175, "Bytes written should accumulate")
    }

    @Test("Record lines changed accumulates correctly")
    func recordLinesChangedAccumulatesCorrectly() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)

        // Act
        await metrics.recordLinesChanged(5)
        await metrics.recordLinesChanged(3)
        await metrics.recordLinesChanged(2)

        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.linesChanged == 10, "Lines changed should accumulate")
    }

    @Test("Set total lines updates correctly")
    func setTotalLinesUpdatesCorrectly() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)

        // Act
        await metrics.setTotalLines(25)
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.totalLines == 25, "Total lines should be set")
    }

    @Test("Record dropped frame increments counter")
    func recordDroppedFrameIncrementsCounter() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)

        // Act
        await metrics.recordDroppedFrame()
        await metrics.recordDroppedFrame()

        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.framesDropped == 2, "Dropped frames should be counted")
    }

    // MARK: - Finish Render Tests

    @Test("Finish render records duration and adds to history")
    func finishRenderRecordsDurationAndAddsToHistory() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordBytesWritten(100)
        await metrics.recordLinesChanged(5)
        await metrics.setTotalLines(20)

        // Add a small delay to ensure duration is measurable
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // Act
        let finalCounters = await metrics.finishRender()
        let history = await metrics.getHistory()

        // Assert
        #expect(finalCounters.bytesWritten == 100, "Final bytes should match")
        #expect(finalCounters.linesChanged == 5, "Final lines changed should match")
        #expect(finalCounters.totalLines == 20, "Final total lines should match")
        #expect(finalCounters.renderDuration > 0, "Duration should be measured")
        #expect(history.count == 1, "History should contain one entry")
        #expect(history[0].bytesWritten == 100, "History entry should match")
    }

    @Test("Multiple renders build history")
    func multipleRendersBuildsHistory() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act - Perform multiple renders
        for i in 1 ... 3 {
            await metrics.startRender(mode: .lineDiff)
            await metrics.recordBytesWritten(i * 100)
            await metrics.recordLinesChanged(i * 5)
            await metrics.setTotalLines(i * 10)
            _ = await metrics.finishRender()
        }

        let history = await metrics.getHistory()

        // Assert
        #expect(history.count == 3, "History should contain three entries")
        #expect(history[0].bytesWritten == 100, "First entry should match")
        #expect(history[1].bytesWritten == 200, "Second entry should match")
        #expect(history[2].bytesWritten == 300, "Third entry should match")
    }

    // MARK: - Efficiency Calculation Tests

    @Test("Efficiency calculation is correct")
    func efficiencyCalculationIsCorrect() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordLinesChanged(3)
        await metrics.setTotalLines(10)

        // Act
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.efficiency == 0.7, "Efficiency should be 1.0 - (3/10) = 0.7")
    }

    @Test("Efficiency with zero total lines")
    func efficiencyWithZeroTotalLines() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordLinesChanged(5)
        await metrics.setTotalLines(0)

        // Act
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.efficiency == 1.0, "Efficiency should be 1.0 when total lines is 0")
    }

    @Test("Bytes per line calculation")
    func bytesPerLineCalculation() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordBytesWritten(150)
        await metrics.recordLinesChanged(5)

        // Act
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.bytesPerLine == 30.0, "Bytes per line should be 150/5 = 30.0")
    }

    @Test("Bytes per line with zero lines changed")
    func bytesPerLineWithZeroLinesChanged() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordBytesWritten(100)
        await metrics.recordLinesChanged(0)

        // Act
        let counters = await metrics.getCurrentCounters()

        // Assert
        #expect(counters.bytesPerLine == 0.0, "Bytes per line should be 0.0 when no lines changed")
    }

    // MARK: - Average Performance Tests

    @Test("Average performance calculation")
    func averagePerformanceCalculation() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Add some history
        for i in 1 ... 5 {
            await metrics.startRender(mode: .lineDiff)
            await metrics.recordBytesWritten(i * 100)
            await metrics.recordLinesChanged(i * 2)
            await metrics.setTotalLines(i * 10)
            _ = await metrics.finishRender()
        }

        // Act
        let average = await metrics.getAveragePerformance(over: 3)

        // Assert
        #expect(average != nil, "Average should be calculated")
        if let avg = average {
            // Average of last 3: (300+400+500)/3 = 400
            #expect(avg.bytesWritten == 400, "Average bytes should be 400")
            // Average of last 3: (6+8+10)/3 = 8
            #expect(avg.linesChanged == 8, "Average lines changed should be 8")
            // Average of last 3: (30+40+50)/3 = 40
            #expect(avg.totalLines == 40, "Average total lines should be 40")
        }
    }

    @Test("Average performance with insufficient history")
    func averagePerformanceWithInsufficientHistory() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act
        let average = await metrics.getAveragePerformance(over: 5)

        // Assert
        #expect(average == nil, "Average should be nil with no history")
    }

    // MARK: - Reset Tests

    @Test("Reset clears all metrics")
    func resetClearsAllMetrics() async {
        // Arrange
        let metrics = PerformanceMetrics()
        await metrics.startRender(mode: .lineDiff)
        await metrics.recordBytesWritten(100)
        await metrics.recordLinesChanged(5)
        await metrics.setTotalLines(20)
        _ = await metrics.finishRender()

        // Act
        await metrics.reset()

        let counters = await metrics.getCurrentCounters()
        let history = await metrics.getHistory()

        // Assert
        #expect(counters.bytesWritten == 0, "Bytes written should be reset")
        #expect(counters.linesChanged == 0, "Lines changed should be reset")
        #expect(counters.totalLines == 0, "Total lines should be reset")
        #expect(counters.framesDropped == 0, "Frames dropped should be reset")
        #expect(history.isEmpty, "History should be cleared")
    }

    // MARK: - History Limit Tests

    @Test("History respects maximum size limit")
    func historyRespectsMaximumSizeLimit() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act - Add more than the maximum history size (100)
        for i in 1 ... 105 {
            await metrics.startRender(mode: .lineDiff)
            await metrics.recordBytesWritten(i)
            _ = await metrics.finishRender()
        }

        let history = await metrics.getHistory()

        // Assert
        #expect(history.count == 100, "History should be limited to 100 entries")
        #expect(history[0].bytesWritten == 6, "Oldest entry should be from iteration 6 (1-5 removed)")
        #expect(history[99].bytesWritten == 105, "Newest entry should be from iteration 105")
    }

    // MARK: - Concurrent Access Tests

    @Test("Concurrent access is thread-safe")
    func concurrentAccessIsThreadSafe() async {
        // Arrange
        let metrics = PerformanceMetrics()

        // Act - Perform sequential operations to avoid interference
        // (Concurrent operations on the same metrics instance would interfere)
        for i in 1 ... 10 {
            await metrics.startRender(mode: .lineDiff)
            await metrics.recordBytesWritten(i * 10)
            await metrics.recordLinesChanged(i)
            await metrics.setTotalLines(i * 5)
            _ = await metrics.finishRender()
        }

        let history = await metrics.getHistory()

        // Assert
        #expect(history.count == 10, "All operations should complete")

        // Verify total bytes across all operations
        let totalBytes = history.reduce(0) { $0 + $1.bytesWritten }
        let expectedTotal = (1 ... 10).reduce(0) { $0 + $1 * 10 } // 10+20+30+...+100 = 550
        #expect(totalBytes == expectedTotal, "Total bytes should match expected sum")
    }
}
