import Foundation

/// Line-based diffing system for efficient terminal rendering
///
/// This system compares frames line-by-line to identify changes and minimize
/// terminal I/O by only rewriting lines that have actually changed.
public enum LineDiff {
    /// Represents a change to a specific line
    public struct LineChange: Sendable {
        /// Zero-based line index
        public let lineIndex: Int

        /// New content for the line
        public let newContent: String

        /// Previous content (for debugging/logging)
        public let previousContent: String?

        public init(lineIndex: Int, newContent: String, previousContent: String? = nil) {
            self.lineIndex = lineIndex
            self.newContent = newContent
            self.previousContent = previousContent
        }
    }

    /// Result of a line-diff comparison
    public struct DiffResult: Sendable {
        /// Lines that need to be updated
        public let changes: [LineChange]

        /// Total number of lines in the new frame
        public let totalLines: Int

        /// Total number of lines in the previous frame
        public let previousTotalLines: Int

        /// Whether the frame size changed
        public var frameSizeChanged: Bool {
            totalLines != previousTotalLines
        }

        /// Efficiency ratio (0.0 = all lines changed, 1.0 = no lines changed)
        public var efficiency: Double {
            guard totalLines > 0 else { return 1.0 }
            return 1.0 - (Double(changes.count) / Double(totalLines))
        }

        public init(changes: [LineChange], totalLines: Int, previousTotalLines: Int) {
            self.changes = changes
            self.totalLines = totalLines
            self.previousTotalLines = previousTotalLines
        }
    }

    /// Fast line hashing for change detection
    private struct LineHash: Hashable, Sendable {
        let hash: String

        init(_ line: String) {
            // Use built-in Hasher for cross-platform compatibility
            var hasher = Hasher()
            hasher.combine(line)
            hash = String(hasher.finalize())
        }

        /// Fast hash for simple ASCII content (optimization)
        init(fastHash line: String) {
            // For ASCII-only content, use a simpler hash
            var hasher = Hasher()
            hasher.combine(line)
            hash = String(hasher.finalize())
        }
    }

    /// Cached frame state for efficient comparison
    private struct FrameState: Sendable {
        let lines: [String]
        let hashes: [LineHash]

        init(lines: [String], useSimpleHash: Bool = false) {
            self.lines = lines
            if useSimpleHash {
                hashes = lines.map { LineHash(fastHash: $0) }
            } else {
                hashes = lines.map { LineHash($0) }
            }
        }
    }

    // MARK: - Public Interface

    /// Compare two frames and return the differences
    /// - Parameters:
    ///   - currentFrame: The new frame to render
    ///   - previousFrame: The previous frame (if any)
    ///   - useSimpleHash: Whether to use simple hashing for ASCII content
    /// - Returns: Diff result containing the changes needed
    public static func compare(
        currentFrame: TerminalRenderer.Frame,
        previousFrame: TerminalRenderer.Frame?,
        useSimpleHash: Bool = false,
    ) -> DiffResult {
        guard let previousFrame else {
            // No previous frame - all lines are changes
            let changes = currentFrame.lines.enumerated().map { index, line in
                LineChange(lineIndex: index, newContent: line)
            }
            return DiffResult(
                changes: changes,
                totalLines: currentFrame.lines.count,
                previousTotalLines: 0,
            )
        }

        let currentState = FrameState(lines: currentFrame.lines, useSimpleHash: useSimpleHash)
        let previousState = FrameState(lines: previousFrame.lines, useSimpleHash: useSimpleHash)

        return compareStates(current: currentState, previous: previousState)
    }

    /// Compare two frame states efficiently
    private static func compareStates(current: FrameState, previous: FrameState) -> DiffResult {
        var changes: [LineChange] = []

        let maxLines = max(current.lines.count, previous.lines.count)

        for lineIndex in 0 ..< maxLines {
            let currentLine = lineIndex < current.lines.count ? current.lines[lineIndex] : ""
            let currentHash = lineIndex < current.hashes.count ? current.hashes[lineIndex] : LineHash("")

            let previousLine = lineIndex < previous.lines.count ? previous.lines[lineIndex] : ""
            let previousHash = lineIndex < previous.hashes.count ? previous.hashes[lineIndex] : LineHash("")

            // Compare hashes first for efficiency
            if currentHash != previousHash {
                changes.append(LineChange(
                    lineIndex: lineIndex,
                    newContent: currentLine,
                    previousContent: lineIndex < previous.lines.count ? previousLine : nil,
                ))
            }
        }

        return DiffResult(
            changes: changes,
            totalLines: current.lines.count,
            previousTotalLines: previous.lines.count,
        )
    }

    /// Generate ANSI sequences for applying line changes
    /// - Parameters:
    ///   - changes: The line changes to apply
    ///   - currentCursorLine: Current cursor position (0-based)
    /// - Returns: ANSI sequence string to apply the changes
    public static func generateANSISequences(
        for changes: [LineChange],
        currentCursorLine: Int = 0,
    ) -> String {
        guard !changes.isEmpty else { return "" }

        var sequences: [String] = []
        var currentLine = currentCursorLine

        // Sort changes by line index for efficient cursor movement
        let sortedChanges = changes.sorted { $0.lineIndex < $1.lineIndex }

        for change in sortedChanges {
            // Move cursor to the target line
            if change.lineIndex != currentLine {
                let lineDiff = change.lineIndex - currentLine
                if lineDiff > 0 {
                    // Move down
                    sequences.append("\u{001B}[\(lineDiff)B")
                } else {
                    // Move up
                    sequences.append("\u{001B}[\(-lineDiff)A")
                }
                currentLine = change.lineIndex
            }

            // Move to beginning of line and clear it
            sequences.append("\u{001B}[G") // Move to column 1
            sequences.append("\u{001B}[K") // Clear from cursor to end of line (EL)

            // Write the new content
            sequences.append(change.newContent)
        }

        return sequences.joined()
    }

    /// Estimate the byte savings of using line-diff vs full redraw
    /// - Parameters:
    ///   - diffResult: The diff result to analyze
    ///   - fullFrameSize: Size in bytes of a full frame redraw
    /// - Returns: Estimated bytes saved (positive = savings, negative = overhead)
    public static func estimateByteSavings(
        diffResult: DiffResult,
        fullFrameSize: Int,
    ) -> Int {
        // Estimate overhead for cursor movement and line clearing
        let cursorOverheadPerLine = 10 // Approximate ANSI sequence overhead
        let diffSize = diffResult.changes.reduce(0) { total, change in
            total + change.newContent.utf8.count + cursorOverheadPerLine
        }

        return fullFrameSize - diffSize
    }
}

// MARK: - Debug and Testing Support

public extension LineDiff {
    /// Create a human-readable description of changes (for debugging)
    /// - Parameter diffResult: The diff result to describe
    /// - Returns: Multi-line string describing the changes
    static func describeChanges(_ diffResult: DiffResult) -> String {
        var description: [String] = []

        description.append("Frame diff: \(diffResult.changes.count) changes out of \(diffResult.totalLines) lines")
        description.append("Efficiency: \(String(format: "%.1f%%", diffResult.efficiency * 100))")

        if diffResult.frameSizeChanged {
            description.append("Frame size changed: \(diffResult.previousTotalLines) → \(diffResult.totalLines)")
        }

        for (index, change) in diffResult.changes.enumerated() {
            if index < 5 { // Show first 5 changes
                let preview = change.newContent.prefix(40)
                description.append("  Line \(change.lineIndex): \"\(preview)\"")
            } else if index == 5 {
                description.append("  ... and \(diffResult.changes.count - 5) more changes")
                break
            }
        }

        return description.joined(separator: "\n")
    }
}
