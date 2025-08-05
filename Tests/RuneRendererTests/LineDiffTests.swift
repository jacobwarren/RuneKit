import Foundation
import Testing
@testable import RuneRenderer

/// Tests for the LineDiff system
///
/// These tests verify the line-based diffing functionality that enables
/// efficient terminal rendering by only updating changed lines.
struct LineDiffTests {
    // MARK: - Basic Diff Tests

    @Test("No previous frame - all lines are changes")
    func noPreviousFrameAllLinesAreChanges() {
        // Arrange
        let currentFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 10,
            height: 3,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: currentFrame,
            previousFrame: nil,
        )

        // Assert
        #expect(result.changes.count == 3, "All lines should be changes when no previous frame")
        #expect(result.totalLines == 3, "Total lines should match current frame")
        #expect(result.previousTotalLines == 0, "Previous total should be 0")
        #expect(result.frameSizeChanged == true, "Frame size should be considered changed")
        #expect(result.efficiency == 0.0, "Efficiency should be 0 (all lines changed)")

        // Verify change details
        for (index, change) in result.changes.enumerated() {
            #expect(change.lineIndex == index, "Line index should match")
            #expect(change.newContent == currentFrame.lines[index], "Content should match")
            #expect(change.previousContent == nil, "Previous content should be nil")
        }
    }

    @Test("Identical frames - no changes")
    func identicalFramesNoChanges() {
        // Arrange
        let frame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 10,
            height: 3,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: frame,
            previousFrame: frame,
        )

        // Assert
        #expect(result.changes.isEmpty, "No changes should be detected for identical frames")
        #expect(result.totalLines == 3, "Total lines should match")
        #expect(result.previousTotalLines == 3, "Previous total should match")
        #expect(result.frameSizeChanged == false, "Frame size should not be changed")
        #expect(result.efficiency == 1.0, "Efficiency should be 1.0 (no lines changed)")
    }

    @Test("Single line change")
    func singleLineChange() {
        // Arrange
        let previousFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 10,
            height: 3,
        )

        let currentFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Modified Line 2", "Line 3"],
            width: 10,
            height: 3,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: currentFrame,
            previousFrame: previousFrame,
        )

        // Assert
        #expect(result.changes.count == 1, "Only one line should be changed")
        #expect(result.totalLines == 3, "Total lines should match")
        #expect(result.previousTotalLines == 3, "Previous total should match")
        #expect(result.frameSizeChanged == false, "Frame size should not be changed")
        #expect(abs(result.efficiency - 2.0 / 3.0) < 0.0001, "Efficiency should be 2/3 (1 of 3 lines changed)")

        let change = result.changes[0]
        #expect(change.lineIndex == 1, "Changed line should be index 1")
        #expect(change.newContent == "Modified Line 2", "New content should match")
        #expect(change.previousContent == "Line 2", "Previous content should match")
    }

    @Test("Multiple line changes")
    func multipleLineChanges() {
        // Arrange
        let previousFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        let currentFrame = TerminalRenderer.Frame(
            lines: ["Modified Line 1", "Line 2", "Modified Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: currentFrame,
            previousFrame: previousFrame,
        )

        // Assert
        #expect(result.changes.count == 2, "Two lines should be changed")
        #expect(result.efficiency == 0.5, "Efficiency should be 0.5 (2 of 4 lines changed)")

        // Verify specific changes
        let sortedChanges = result.changes.sorted { $0.lineIndex < $1.lineIndex }
        #expect(sortedChanges[0].lineIndex == 0, "First change should be line 0")
        #expect(sortedChanges[0].newContent == "Modified Line 1", "First change content should match")
        #expect(sortedChanges[1].lineIndex == 2, "Second change should be line 2")
        #expect(sortedChanges[1].newContent == "Modified Line 3", "Second change content should match")
    }

    // MARK: - Frame Size Change Tests

    @Test("Frame grows - new lines added")
    func frameGrowsNewLinesAdded() {
        // Arrange
        let previousFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2,
        )

        let currentFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: currentFrame,
            previousFrame: previousFrame,
        )

        // Assert
        #expect(result.changes.count == 2, "Two new lines should be detected as changes")
        #expect(result.totalLines == 4, "Total lines should be 4")
        #expect(result.previousTotalLines == 2, "Previous total should be 2")
        #expect(result.frameSizeChanged == true, "Frame size should be changed")

        // Verify new lines are detected
        let sortedChanges = result.changes.sorted { $0.lineIndex < $1.lineIndex }
        #expect(sortedChanges[0].lineIndex == 2, "First new line should be index 2")
        #expect(sortedChanges[0].newContent == "Line 3", "First new line content should match")
        #expect(sortedChanges[1].lineIndex == 3, "Second new line should be index 3")
        #expect(sortedChanges[1].newContent == "Line 4", "Second new line content should match")
    }

    @Test("Frame shrinks - lines removed")
    func frameShrinks() {
        // Arrange
        let previousFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4,
        )

        let currentFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2,
        )

        // Act
        let result = LineDiff.compare(
            currentFrame: currentFrame,
            previousFrame: previousFrame,
        )

        // Assert
        #expect(result.changes.count == 2, "Two removed lines should be detected as changes")
        #expect(result.totalLines == 2, "Total lines should be 2")
        #expect(result.previousTotalLines == 4, "Previous total should be 4")
        #expect(result.frameSizeChanged == true, "Frame size should be changed")

        // Verify removed lines are detected (they become empty)
        let sortedChanges = result.changes.sorted { $0.lineIndex < $1.lineIndex }
        #expect(sortedChanges[0].lineIndex == 2, "First removed line should be index 2")
        #expect(sortedChanges[0].newContent.isEmpty, "Removed line should be empty")
        #expect(sortedChanges[1].lineIndex == 3, "Second removed line should be index 3")
        #expect(sortedChanges[1].newContent.isEmpty, "Removed line should be empty")
    }

    // MARK: - ANSI Sequence Generation Tests

    @Test("Generate ANSI sequences for single change")
    func generateANSISequencesForSingleChange() {
        // Arrange
        let changes = [
            LineDiff.LineChange(lineIndex: 2, newContent: "New content"),
        ]

        // Act
        let sequences = LineDiff.generateANSISequences(for: changes, currentCursorLine: 0)

        // Assert
        #expect(sequences.contains("\u{001B}[2B"), "Should move cursor down 2 lines")
        #expect(sequences.contains("\u{001B}[G"), "Should move to beginning of line")
        #expect(sequences.contains("\u{001B}[K"), "Should clear line")
        #expect(sequences.contains("New content"), "Should contain new content")
    }

    @Test("Generate ANSI sequences for multiple changes")
    func generateANSISequencesForMultipleChanges() {
        // Arrange
        let changes = [
            LineDiff.LineChange(lineIndex: 1, newContent: "Content 1"),
            LineDiff.LineChange(lineIndex: 3, newContent: "Content 3"),
        ]

        // Act
        let sequences = LineDiff.generateANSISequences(for: changes, currentCursorLine: 0)

        // Assert
        #expect(sequences.contains("Content 1"), "Should contain first content")
        #expect(sequences.contains("Content 3"), "Should contain second content")
        #expect(sequences.contains("\u{001B}[1B"), "Should move down to line 1")
        #expect(sequences.contains("\u{001B}[2B"), "Should move down 2 more lines to line 3")
    }

    @Test("Empty changes produce empty sequences")
    func emptyChangesProduceEmptySequences() {
        // Arrange
        let changes: [LineDiff.LineChange] = []

        // Act
        let sequences = LineDiff.generateANSISequences(for: changes)

        // Assert
        #expect(sequences.isEmpty, "Empty changes should produce empty sequences")
    }

    // MARK: - Performance Estimation Tests

    @Test("Estimate byte savings for efficient diff")
    func estimateByteSavingsForEfficientDiff() {
        // Arrange
        let changes = [
            LineDiff.LineChange(lineIndex: 1, newContent: "Short"),
        ]
        let diffResult = LineDiff.DiffResult(
            changes: changes,
            totalLines: 10,
            previousTotalLines: 10,
        )
        let fullFrameSize = 1000

        // Act
        let savings = LineDiff.estimateByteSavings(
            diffResult: diffResult,
            fullFrameSize: fullFrameSize,
        )

        // Assert
        #expect(savings > 0, "Should show positive savings for efficient diff")
        #expect(savings < fullFrameSize, "Savings should be less than full frame size")
    }

    @Test("Estimate byte savings for inefficient diff")
    func estimateByteSavingsForInefficientDiff() {
        // Arrange - Many changes that might not be worth the overhead
        let changes = (0 ..< 8).map { index in
            LineDiff.LineChange(lineIndex: index, newContent: String(repeating: "X", count: 100))
        }
        let diffResult = LineDiff.DiffResult(
            changes: changes,
            totalLines: 10,
            previousTotalLines: 10,
        )
        let fullFrameSize = 500 // Smaller than the diff

        // Act
        let savings = LineDiff.estimateByteSavings(
            diffResult: diffResult,
            fullFrameSize: fullFrameSize,
        )

        // Assert
        #expect(savings < 0, "Should show negative savings (overhead) for inefficient diff")
    }

    // MARK: - Debug Description Tests

    @Test("Describe changes produces readable output")
    func describeChangesProducesReadableOutput() {
        // Arrange
        let changes = [
            LineDiff.LineChange(lineIndex: 0, newContent: "First line"),
            LineDiff.LineChange(lineIndex: 2, newContent: "Third line"),
        ]
        let diffResult = LineDiff.DiffResult(
            changes: changes,
            totalLines: 5,
            previousTotalLines: 5,
        )

        // Act
        let description = LineDiff.describeChanges(diffResult)

        // Assert
        #expect(description.contains("2 changes"), "Should mention number of changes")
        #expect(description.contains("5 lines"), "Should mention total lines")
        #expect(description.contains("60.0%"), "Should show efficiency percentage")
        #expect(description.contains("Line 0"), "Should show first change")
        #expect(description.contains("Line 2"), "Should show second change")
    }
}
