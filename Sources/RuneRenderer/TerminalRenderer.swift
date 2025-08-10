import Foundation

/// High-performance terminal renderer with SGR optimization and scroll support
public actor TerminalRenderer {
    /// Represents a frame of terminal content (legacy compatibility)
    public struct Frame: Sendable {
        public let lines: [String]
        public let width: Int
        public let height: Int

        public init(lines: [String], width: Int, height: Int) {
            self.lines = lines
            self.width = width
            self.height = height
        }

        /// Create frame from terminal grid
        public init(from grid: TerminalGrid) {
            self.lines = grid.getLines()
            self.width = grid.width
            self.height = grid.height
        }

        /// Convert frame to terminal grid
        public func toGrid() -> TerminalGrid {
            return TerminalGrid(lines: lines, width: width)
        }
    }

    /// Current terminal state for SGR optimization
    private var terminalState = TerminalState.default

    /// Current grid being displayed
    private var currentGrid: TerminalGrid?

    /// Output handle for writing to terminal
    private let output: FileHandle
    private let outEncoder: OutputEncoder?
    private let cursorMgr: CursorManager?
    /// Optional configuration for policy decisions (cursor, etc.)
    private let configuration: RenderConfiguration?

    /// Current cursor position
    private var cursorRow: Int = 0
    private var cursorColumn: Int = 0

    /// Whether cursor is currently hidden
    private var cursorHidden: Bool = false

    /// Performance metrics
    private var bytesWritten: Int = 0
    private var lastRenderTime = Date()

    /// Track previous render for clean updates (Ink-style)
    private var previousLineCount = 0

    public init(output: FileHandle = .standardOutput) {
        self.output = output
        self.outEncoder = nil
        self.cursorMgr = nil
        self.configuration = nil
    }

    /// New convenience initializer allowing pluggable abstractions (public when enabled)
    public init(output: FileHandle = .standardOutput, encoder: OutputEncoder?, cursor: CursorManager?, configuration: RenderConfiguration = .default) {
        self.output = output
        self.configuration = configuration
        // Feature flag: only honor injected encoder/cursor when enabled via configuration
        if configuration.enablePluggableIO {
            self.outEncoder = encoder
            self.cursorMgr = cursor
        } else {
            self.outEncoder = nil
            self.cursorMgr = nil
        }
    }

    /// Legacy render method for Frame compatibility
    /// - Parameter frame: The frame content to display
    public func render(_ frame: Frame) async {
        let grid = frame.toGrid()
        await render(grid)
    }

    /// Render a grid to the terminal with explicit strategy
    /// - Parameters:
    ///   - grid: The grid to render
    ///   - strategy: The rendering strategy to use
    ///   - previousGrid: The previous grid for delta comparison (optional)
    /// - Returns: Rendering statistics
    @discardableResult
    public func render(_ grid: TerminalGrid, strategy: RenderingStrategy, previousGrid: TerminalGrid? = nil) async -> RenderStats {
        let startTime = Date()
        var stats = RenderStats()

        // Hide cursor during rendering for cleaner output if enabled by configuration
        let policyHide = configuration?.hideCursorDuringRender ?? true
        let shouldRestoreCursor = policyHide && !cursorHidden
        if shouldRestoreCursor {
            await hideCursor()
        }

        // Use the provided strategy
        stats.strategy = strategy

        // Render based on strategy
        switch strategy {
        case .fullRedraw:
            stats = await renderInkStyle(grid)
        case .deltaUpdate:
            stats = await renderDelta(grid, previousGrid: previousGrid)
        case .scrollOptimized:
            stats = await renderScrollOptimized(grid, previousGrid: previousGrid)
        }

        // Update state
        currentGrid = grid

        // Update performance metrics
        stats.duration = Date().timeIntervalSince(startTime)
        bytesWritten += stats.bytesWritten
        lastRenderTime = Date()

        // Restore cursor if we hid it
        if policyHide && shouldRestoreCursor && cursorHidden {
            await showCursor()
        }

        return stats
    }

    /// Render a grid to the terminal using hybrid diff algorithm (legacy)
    /// - Parameters:
    ///   - grid: The grid to render
    ///   - forceFullRedraw: Force a complete redraw regardless of diff
    /// - Returns: Rendering statistics
    @discardableResult
    public func render(_ grid: TerminalGrid, forceFullRedraw: Bool = false) async -> RenderStats {
        let startTime = Date()
        var stats = RenderStats()

        // Hide cursor during rendering for cleaner output if enabled by configuration
        let policyHide = configuration?.hideCursorDuringRender ?? true
        let shouldRestoreCursor = policyHide && !cursorHidden
        if shouldRestoreCursor {
            await hideCursor()
        }

        // Determine rendering strategy
        let strategy: RenderingStrategy
        if forceFullRedraw {
            strategy = .fullRedraw
        } else {
            strategy = determineRenderingStrategy(
                newGrid: grid,
                currentGrid: currentGrid,
                forceFullRedraw: false
            )
        }

        stats.strategy = strategy

        switch strategy {
        case .fullRedraw:
            stats = await renderInkStyle(grid)

        case .deltaUpdate:
            stats = await renderDelta(grid, previousGrid: currentGrid)

        case .scrollOptimized:
            // For now, fall back to delta update
            stats = await renderDelta(grid, previousGrid: currentGrid)
        }

        // Update current grid
        currentGrid = grid

        // Update performance metrics
        stats.duration = Date().timeIntervalSince(startTime)
        bytesWritten += stats.bytesWritten
        lastRenderTime = Date()

        // Restore cursor if we hid it
        if policyHide && shouldRestoreCursor && cursorHidden {
            await showCursor()
        }

        return stats
    }

    /// Clear the terminal screen
    public func clear() async {
        await writeSequence("\u{001B}[2J\u{001B}[H")
        terminalState = .default
        cursorRow = 0
        cursorColumn = 0
        currentGrid = nil
        previousLineCount = 0

        // Always ensure cursor is visible after clearing, regardless of current state
        await writeSequence("\u{001B}[?25h")
        cursorHidden = false
    }

    /// Hide the cursor
    public func hideCursor() async {
        if !cursorHidden {
            await writeSequence("\u{001B}[?25l")
            cursorHidden = true
        }
    }

    /// Show the cursor
    public func showCursor() async {
        if cursorHidden {
            await writeSequence("\u{001B}[?25h")
            cursorHidden = false
        }
    }

    /// Move cursor to specific position (legacy compatibility)
    /// - Parameters:
    ///   - row: Row position (1-based)
    ///   - column: Column position (1-based)
    public func moveCursor(to row: Int, column: Int) async {
        await moveCursorInternal(to: row - 1, column - 1)  // Convert to 0-based
    }

    /// Get current performance metrics
    public func getPerformanceMetrics() -> RendererPerformanceMetrics {
        return RendererPerformanceMetrics(
            totalBytesWritten: bytesWritten,
            lastRenderTime: lastRenderTime
        )
    }

    /// Shutdown the renderer and clean up resources
    public func shutdown() async {
        // Show cursor if it was hidden
        if cursorHidden {
            await showCursor()
        }

        // Reset state
        currentGrid = nil
        terminalState = TerminalState.default
        bytesWritten = 0
        previousLineCount = 0
    }

    // MARK: - Private Rendering Methods

    /// Determine the optimal rendering strategy
    private func determineRenderingStrategy(
        newGrid: TerminalGrid,
        currentGrid: TerminalGrid?,
        forceFullRedraw: Bool
    ) -> RenderingStrategy {
        if forceFullRedraw || currentGrid == nil {
            return .fullRedraw
        }

        guard let current = currentGrid else {
            return .fullRedraw
        }

        // Check if dimensions changed
        if newGrid.width != current.width || newGrid.height != current.height {
            return .fullRedraw
        }

        // Calculate change percentage
        let changedLines = newGrid.changedLines(comparedTo: current)
        let changePercentage = Double(changedLines.count) / Double(newGrid.height)

        // Use adaptive threshold: if more than 50% changed, full redraw is more efficient
        if changePercentage > 0.5 {
            return .fullRedraw
        }

        // Check for scroll patterns (TODO: implement scroll detection)
        // For now, use delta update
        return .deltaUpdate
    }

    /// Render using Ink-style approach: erase previous + write new
    private func renderInkStyle(_ grid: TerminalGrid) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .fullRedraw

        // For the first render, just clear screen and start fresh
        if previousLineCount == 0 {
            await writeSequence("\u{001B}[2J\u{001B}[H")  // Clear screen, go to top
            stats.bytesWritten += 7
        } else {
            // For subsequent renders, erase exactly the number of lines we wrote last time
            // Move cursor to beginning of line, then erase the exact number of lines
            await writeSequence("\r")  // Move to beginning of current line

            // Erase the previous output by moving up and clearing
            if previousLineCount > 1 {
                await writeSequence("\u{001B}[\(previousLineCount - 1)A")  // Move up (N-1) lines
                stats.bytesWritten += 5 + String(previousLineCount - 1).count
            }

            // Use line-by-line clearing for better test compatibility
            for lineIndex in 0..<previousLineCount {
                if lineIndex > 0 {
                    await writeSequence("\u{001B}[\(lineIndex + 1);1H")  // Move to line
                    stats.bytesWritten += 6 + String(lineIndex + 1).count
                }
                await writeSequence("\u{001B}[2K")  // Clear entire line
                stats.bytesWritten += 4
            }

            // Move back to start
            await writeSequence("\u{001B}[1;1H")
            stats.bytesWritten += 6
        }

        // Reset terminal state
        await writeSequence(TerminalState.resetSequence)
        terminalState = .default

        // Build complete output
        var output = ""
        for row in 0..<grid.height {
            if let rowCells = grid.getRow(row) {
                let sequence = await renderRow(rowCells, optimizeState: true)
                output += sequence
            }

            // Move to next line explicitly to avoid right-edge autowrap artifacts
            if row < grid.height - 1 {
                output += "\r\n"
            }
        }

        // Write the complete output
        await writeSequence(output)
        stats.bytesWritten += output.utf8.count

        // CRITICAL: Position cursor after the frame for proper subsequent rendering
        // This ensures that subsequent frames start from the correct position
        let cursorRestoreSequence = "\u{001B}[\(grid.height + 1);1H"  // Move to line after frame
        await writeSequence(cursorRestoreSequence)
        stats.bytesWritten += cursorRestoreSequence.utf8.count

        // Update tracking
        previousLineCount = grid.height
        stats.linesChanged = grid.height
        // Populate totalLines for consistent metrics
        stats.totalLines = grid.height

        return stats
    }

    /// Render using delta update: only changed lines
    private func renderDelta(_ grid: TerminalGrid, previousGrid: TerminalGrid? = nil) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .deltaUpdate

        // Use provided previous grid or fall back to currentGrid
        let current = previousGrid ?? currentGrid
        guard let current = current else {
            // No previous grid - fall back to full redraw
            return await renderInkStyle(grid)
        }

        // Find changed lines via differ (SimpleLineDiffer for now)
        let changedLines = SimpleLineDiffer().diff(from: current, to: grid)
        stats.linesChanged = changedLines.count

        // If no changes, do nothing
        guard !changedLines.isEmpty else {
            // Even if no changes, still restore cursor position per policy
            let restoreCursorSequence = "\u{001B}[\(grid.height + 1);1H"
            await writeSequence(restoreCursorSequence)
            stats.bytesWritten += restoreCursorSequence.utf8.count
            // Populate totalLines for accurate efficiency
            stats.totalLines = grid.height
            return stats
        }

        // Render each changed line
        for lineIndex in changedLines {
            // Move cursor to the line
            let moveSequence = "\u{001B}[\(lineIndex + 1);1H"  // Move to line (1-based), column 1
            await writeSequence(moveSequence)
            stats.bytesWritten += moveSequence.utf8.count

            // Clear the entire line (for test compatibility)
            let clearSequence = "\u{001B}[2K"  // Clear entire line
            await writeSequence(clearSequence)
            stats.bytesWritten += clearSequence.utf8.count

            // Move cursor back to column 1
            let columnSequence = "\u{001B}[G"  // Move to column 1
            await writeSequence(columnSequence)
            stats.bytesWritten += columnSequence.utf8.count

            // Render the new line content
            if lineIndex < grid.height,
               let cells = grid.getRow(lineIndex) {
                let lineSequence = await renderRow(cells, optimizeState: true)
                await writeSequence(lineSequence)
                stats.bytesWritten += lineSequence.utf8.count
            }
        }

        // Handle frame shrinkage: clear lines that are beyond the new frame
        if grid.height < current.height {
            for lineIndex in grid.height..<current.height {
                // Move cursor to the line that needs to be cleared
                let moveSequence = "\u{001B}[\(lineIndex + 1);1H"  // Move to line (1-based), column 1
                await writeSequence(moveSequence)
                stats.bytesWritten += moveSequence.utf8.count

                // Clear the entire line
                let clearSequence = "\u{001B}[2K"  // Clear entire line
                await writeSequence(clearSequence)
                stats.bytesWritten += clearSequence.utf8.count

                // Move cursor back to column 1
                let columnSequence = "\u{001B}[G"  // Move to column 1
                await writeSequence(columnSequence)
                stats.bytesWritten += columnSequence.utf8.count
            }
        }

        // CRITICAL: Always restore cursor to the end position after delta updates
        // This ensures the cursor returns to the proper typing position regardless
        // of which lines were updated during the delta rendering
        let restoreCursorSequence = "\u{001B}[\(grid.height + 1);1H"  // Move to line after frame
        await writeSequence(restoreCursorSequence)
        stats.bytesWritten += restoreCursorSequence.utf8.count

        // Populate totalLines for accurate efficiency
        stats.totalLines = grid.height

        return stats
    }

    /// Render using scroll-optimized updates when grid is an N-line shift
    private func renderScrollOptimized(_ grid: TerminalGrid, previousGrid: TerminalGrid?) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .scrollOptimized
        guard let current = previousGrid else { return await renderInkStyle(grid) }
        // Determine direction: try match of current shifted
        let h = grid.height
        // Detect largest n for down/up shift
        func detectDownShift() -> Int {
            var best = 0
            if h > 1 {
                for n in 1..<h {
                    var ok = true
                    for r in 0..<(h - n) {
                        if grid.getRow(r)! != current.getRow(r + n)! { ok = false; break }
                    }
                    if ok { best = n; break }
                }
            }
            return best
        }
        func detectUpShift() -> Int {
            var best = 0
            if h > 1 {
                for n in 1..<h {
                    var ok = true
                    for r in n..<h {
                        if grid.getRow(r)! != current.getRow(r - n)! { ok = false; break }
                    }
                    if ok { best = n; break }
                }
            }
            return best
        }
        let nDown = detectDownShift()
        if nDown > 0 {
            // Scroll up by n: ESC[nS] moves the viewport up; new lines to render at bottom
            let seq = "\u{001B}[\(nDown)S"
            await writeSequence(seq); stats.bytesWritten += seq.utf8.count
            for j in 0..<nDown {
                let rowIndex = h - nDown + j
                let move = "\u{001B}[\(rowIndex + 1);1H"
                await writeSequence(move); stats.bytesWritten += move.utf8.count
                if let row = grid.getRow(rowIndex) {
                    let line = await renderRow(row, optimizeState: true)
                    await writeSequence(line); stats.bytesWritten += line.utf8.count
                }
            }
            let restore = "\u{001B}[\(h + 1);1H"
            await writeSequence(restore); stats.bytesWritten += restore.utf8.count
            stats.totalLines = h
            return stats
        }
        let nUp = detectUpShift()
        if nUp > 0 {
            // Scroll down by n: ESC[nT]; new lines to render at top
            let seq = "\u{001B}[\(nUp)T"
            await writeSequence(seq); stats.bytesWritten += seq.utf8.count
            for j in 0..<nUp {
                let move = "\u{001B}[\(j + 1);1H"
                await writeSequence(move); stats.bytesWritten += move.utf8.count
                if let row = grid.getRow(j) {
                    let line = await renderRow(row, optimizeState: true)
                    await writeSequence(line); stats.bytesWritten += line.utf8.count
                }
            }
            let restore = "\u{001B}[\(h + 1);1H"
            await writeSequence(restore); stats.bytesWritten += restore.utf8.count
            stats.totalLines = h
            return stats
        }
        // Fallback
        return await renderDelta(grid, previousGrid: previousGrid)
    }


    /// Render a row of cells with SGR optimization
    private func renderRow(_ cells: [TerminalCell], optimizeState: Bool) async -> String {
        var sequence = ""
        var currentState = optimizeState ? terminalState : .default

        for cell in cells {
            let (cellSequence, newState) = cell.renderSequence(from: currentState)
            sequence += cellSequence
            currentState = newState
        }

        // Update our terminal state if we're optimizing
        if optimizeState {
            terminalState = currentState
        }

        return sequence
    }

    /// Move cursor to specific position (internal, 0-based)
    private func moveCursorInternal(to row: Int, _ column: Int) async {
        if cursorRow != row || cursorColumn != column {
            await writeSequence("\u{001B}[\(row + 1);\(column + 1)H")
            cursorRow = row
            cursorColumn = column
        }
    }

    /// Write a sequence to the output
    private func writeSequence(_ sequence: String) async {
        if let out = outEncoder {
            out.write(sequence)
            return
        }
        if let data = sequence.data(using: .utf8) {
            do {
                try output.write(contentsOf: data)
            } catch {
                // Silently ignore write errors (e.g., closed file handle in tests)
                // This prevents crashes when tests close file handles before async operations complete
            }
        }
    }
}

/// Rendering strategy options
public enum RenderingStrategy: Sendable {
    case fullRedraw
    case deltaUpdate
    case scrollOptimized
}

/// Statistics from a rendering operation
public struct RenderStats: Sendable {
    public var strategy: RenderingStrategy = .fullRedraw
    public var linesChanged: Int = 0
    public var bytesWritten: Int = 0
    public var duration: TimeInterval = 0
    /// Total lines in the frame (for accurate efficiency computation)
    public var totalLines: Int? = nil

    public var efficiency: Double {
        // If no changes, efficiency is perfect
        if linesChanged == 0 { return 1.0 }
        // Prefer accurate calculation when total is known
        if let total = totalLines, total > 0 {
            let e = 1.0 - (Double(linesChanged) / Double(total))
            return max(0.0, min(1.0, e))
        }
        // Fallback heuristic by strategy
        return strategy == .deltaUpdate ? 0.8 : 0.0
    }
}

/// Overall performance metrics for the renderer
public struct RendererPerformanceMetrics: Sendable {
    public let totalBytesWritten: Int
    public let lastRenderTime: Date
}
