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
            lines = grid.getLines()
            width = grid.width
            height = grid.height
        }

        /// Convert frame to terminal grid
        public func toGrid() -> TerminalGrid {
            TerminalGrid(lines: lines, width: width)
        }
    }

    /// Current terminal state for SGR optimization
    private var terminalState = TerminalState.default

    /// Current grid being displayed
    private var currentGrid: TerminalGrid?

    /// Output handle for writing to terminal
    private let output: FileHandle
    private let outEncoder: TerminalOutputEncoder?
    private let cursorMgr: CursorManager?
    /// Optional configuration for policy decisions (cursor, etc.)
    private let configuration: RenderConfiguration?
    /// Optional single-writer for serialized/buffered output
    private let writer: OutputWriter?

    /// Current cursor position
    private var cursorRow = 0
    private var cursorColumn = 0

    /// Whether cursor is currently hidden
    private var cursorHidden = false

    /// Whether autowrap is currently disabled by the renderer
    private var autowrapDisabled = false

    /// Performance metrics
    private var bytesWritten = 0
    private var lastRenderTime = Date()

    /// Track previous render for clean updates (Ink-style)
    private var previousLineCount = 0

    public init(output: FileHandle = .standardOutput) {
        self.output = output
        outEncoder = nil
        cursorMgr = nil
        configuration = nil
        writer = OutputWriter(handle: output)
    }

    /// Initializer that accepts a shared OutputWriter for single-writer routing
    public init(output: FileHandle = .standardOutput, writer: OutputWriter, configuration: RenderConfiguration = .default) {
        self.output = output
        self.configuration = configuration
        self.outEncoder = nil
        self.cursorMgr = nil
        self.writer = writer
    }

    /// New convenience initializer allowing pluggable abstractions (public when enabled)
    public init(
        output: FileHandle = .standardOutput,
        encoder: TerminalOutputEncoder?,
        cursor: CursorManager?,
        configuration: RenderConfiguration = .default,
    ) {
        self.output = output
        self.configuration = configuration
        // Feature flag: only honor injected encoder/cursor when enabled via configuration
        if configuration.enablePluggableIO {
            outEncoder = encoder
            cursorMgr = cursor
            writer = nil
        } else {
            outEncoder = nil
            cursorMgr = nil
            writer = OutputWriter(handle: output, bufferSize: configuration.performance.writeBufferSize)
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
    public func render(
        _ grid: TerminalGrid,
        strategy: RenderingStrategy,
        previousGrid: TerminalGrid? = nil,
    ) async -> RenderStats {
        let startTime = Date()
        var stats = RenderStats()

        // Hide cursor during rendering for cleaner output if enabled by configuration
        let policyHide = configuration?.hideCursorDuringRender ?? true
        let shouldRestoreCursor = policyHide && !cursorHidden
        if shouldRestoreCursor {
            await hideCursor()
        }

        // Optionally disable autowrap to prevent last-column spill
        let shouldDisableAutowrap = configuration?.disableAutowrapDuringRender ?? false
        if shouldDisableAutowrap { await disableAutowrapIfNeeded() }

        // Use the provided strategy regardless of screen buffer; strategy determiner
        // and higher-level policies decide between full redraw, delta, or scroll-optimized.
        stats.strategy = strategy
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
        if policyHide, shouldRestoreCursor, cursorHidden {
            await showCursor()
        }

        // Re-enable autowrap if we disabled it
        if shouldDisableAutowrap { await enableAutowrapIfNeeded() }

        // Ensure buffered writes are visible to tests/terminal
        await flushOutput()
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

        // Optionally disable autowrap to prevent last-column spill
        let shouldDisableAutowrap = configuration?.disableAutowrapDuringRender ?? false
        if shouldDisableAutowrap { await disableAutowrapIfNeeded() }

        // Determine rendering strategy
        let strategy: RenderingStrategy = if forceFullRedraw {
            .fullRedraw
        } else {
            determineRenderingStrategy(
                newGrid: grid,
                currentGrid: currentGrid,
                forceFullRedraw: false,
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
        if policyHide, shouldRestoreCursor, cursorHidden {
            await showCursor()
        }

        // Re-enable autowrap if we disabled it
        if shouldDisableAutowrap { await enableAutowrapIfNeeded() }

        // Ensure buffered writes are visible to tests/terminal
        await flushOutput()
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

        // Ensure sequences are visible promptly in tests/pipes
        await flushOutput()

        // Restore autowrap if we had disabled it
        await enableAutowrapIfNeeded()
    }

    /// Hide the cursor
    public func hideCursor() async {
        if !cursorHidden {
            await writeSequence("\u{001B}[?25l")
            cursorHidden = true
            // Ensure visibility in tests/pipes when using buffered writer
            await flushOutput()
        }
    }

    /// Show the cursor
    public func showCursor() async {
        if cursorHidden {
            await writeSequence("\u{001B}[?25h")
            cursorHidden = false
            // Ensure visibility in tests/pipes when using buffered writer
            await flushOutput()
        }
    }

    /// Move cursor to specific position (legacy compatibility)
    /// - Parameters:
    ///   - row: Row position (1-based)
    ///   - column: Column position (1-based)
    public func moveCursor(to row: Int, column: Int) async {
        await moveCursorInternal(to: row - 1, column - 1) // Convert to 0-based
        await flushOutput()
    }

    /// Get current performance metrics
    public func getPerformanceMetrics() -> RendererPerformanceMetrics {
        RendererPerformanceMetrics(
            totalBytesWritten: bytesWritten,
            lastRenderTime: lastRenderTime,
        )
    }

    /// Shutdown the renderer and clean up resources
    public func shutdown() async {
        // Show cursor if it was hidden
        if cursorHidden {
            await showCursor()
        }
        // Restore autowrap if we had disabled it
        await enableAutowrapIfNeeded()

        // Shutdown the OutputWriter to ensure all background tasks complete
        if let writer {
            await writer.shutdown()
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
        forceFullRedraw: Bool,
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
    func renderInkStyle(_ grid: TerminalGrid) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .fullRedraw

        // Avoid toggling autowrap; render with explicit line clearing and cursor moves

        // For the first render, just clear screen and start fresh
        if previousLineCount == 0 {
            await writeSequence("\u{001B}[2J\u{001B}[H") // Clear screen, go to top
            stats.bytesWritten += 7
        } else {
            // For subsequent renders, erase exactly the number of lines we wrote last time
            // Move cursor to beginning of line, then erase the exact number of lines
            await writeSequence("\r") // Move to beginning of current line

            // Erase the previous output by moving up and clearing
            if previousLineCount > 1 {
                await writeSequence("\u{001B}[\(previousLineCount - 1)A") // Move up (N-1) lines
                stats.bytesWritten += 5 + String(previousLineCount - 1).count
            }

            // Use line-by-line clearing for better test compatibility
            for lineIndex in 0 ..< previousLineCount {
                if lineIndex > 0 {
                    await writeSequence("\u{001B}[\(lineIndex + 1);1H") // Move to line
                    stats.bytesWritten += 6 + String(lineIndex + 1).count
                }
                await writeSequence("\u{001B}[2K") // Clear entire line
                stats.bytesWritten += 4
            }

            // Move back to start
            await writeSequence("\u{001B}[1;1H")
            stats.bytesWritten += 6
        }

        // Reset terminal state
        await writeSequence(TerminalState.resetSequence)
        terminalState = .default

        // Render each line absolutely with explicit cursor moves and EOL hygiene
        for row in 0 ..< grid.height {
            // Move to row, column 1
            await writeSequence("\u{001B}[\(row + 1);1H")
            // Clear line before drawing to eliminate any leftover bg/colors
            await writeSequence("\u{001B}[2K")
            if let rowCells = grid.getRow(row) {
                let sequence = await renderRow(rowCells, optimizeState: true)
                await writeSequence(sequence)
            }
            // Reset SGR at end-of-line to prevent bleed into border/newline
            await writeSequence(TerminalState.resetSequence)
        }

        // Position cursor after the frame
        let cursorRestoreSequence = "\u{001B}[\(grid.height + 1);1H" // Move to line after frame
        await writeSequence(cursorRestoreSequence)
        stats.bytesWritten += (6 + String(grid.height + 1).count)

        // Update tracking
        previousLineCount = grid.height
        stats.linesChanged = grid.height
        stats.totalLines = grid.height
        return stats
    }

    /// Render using delta update: only changed lines
    func renderDelta(_ grid: TerminalGrid, previousGrid: TerminalGrid? = nil) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .deltaUpdate

        // Avoid autowrap toggling; relative updates handle EOL hygiene explicitly

        // Use provided previous grid or fall back to currentGrid
        let current = previousGrid ?? currentGrid
        guard let current else {
            // No previous grid - fall back to full redraw
            let statsFromFull = await renderInkStyle(grid)
            // renderInkStyle re-enables autowrap; ensure our local flag is reset
            return statsFromFull
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
            await enableAutowrapIfNeeded()
            return stats
        }

        // Render each changed line
        for lineIndex in changedLines {
            // Move cursor to the line
            let moveSequence = "\u{001B}[\(lineIndex + 1);1H" // Move to line (1-based), column 1
            await writeSequence(moveSequence)
            stats.bytesWritten += moveSequence.utf8.count

            // Clear the entire line (for test compatibility)
            let clearSequence = "\u{001B}[2K" // Clear entire line
            await writeSequence(clearSequence)
            stats.bytesWritten += clearSequence.utf8.count

            // Move cursor back to column 1
            let columnSequence = "\u{001B}[G" // Move to column 1
            await writeSequence(columnSequence)
            stats.bytesWritten += columnSequence.utf8.count

            // Render the new line content
            if lineIndex < grid.height,
               let cells = grid.getRow(lineIndex) {
                let lineSequence = await renderRow(cells, optimizeState: true)
                await writeSequence(lineSequence)
                stats.bytesWritten += lineSequence.utf8.count
            }
            // Reset SGR at end-of-line to prevent style bleed
            await writeSequence(TerminalState.resetSequence)
        }

        // Handle frame shrinkage: clear lines that are beyond the new frame
        if grid.height < current.height {
            for lineIndex in grid.height ..< current.height {
                // Move cursor to the line that needs to be cleared
                let moveSequence = "\u{001B}[\(lineIndex + 1);1H" // Move to line (1-based), column 1
                await writeSequence(moveSequence)
                stats.bytesWritten += moveSequence.utf8.count

                // Clear the entire line
                let clearSequence = "\u{001B}[2K" // Clear entire line
                await writeSequence(clearSequence)
                stats.bytesWritten += clearSequence.utf8.count

                // Move cursor back to column 1
                let columnSequence = "\u{001B}[G" // Move to column 1
                await writeSequence(columnSequence)
                stats.bytesWritten += columnSequence.utf8.count
            }
        }

        // CRITICAL: Always restore cursor to the end position after delta updates
        // This ensures the cursor returns to the proper typing position regardless
        // of which lines were updated during the delta rendering
        let restoreCursorSequence = "\u{001B}[\(grid.height + 1);1H" // Move to line after frame
        await writeSequence(restoreCursorSequence)
        stats.bytesWritten += restoreCursorSequence.utf8.count

        // Populate totalLines for accurate efficiency
        stats.totalLines = grid.height

        return stats
    }

    /// Render a row of cells with SGR optimization
    func renderRow(_ cells: [TerminalCell], optimizeState: Bool) async -> String {
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
    func writeSequence(_ sequence: String) async {
        if let out = outEncoder {
            out.write(sequence)
            return
        }
        if let writer {
            await writer.write(sequence)
            return
        }
        if let data = sequence.data(using: .utf8) {
            do { try output.write(contentsOf: data) } catch { /* ignore */ }
        }
    }

    /// Ensure any buffered output is flushed
    private func flushOutput() async {
        if let writer { await writer.flush() }
    }

    /// Disable terminal autowrap during rendering
    private func disableAutowrapIfNeeded() async {
        if !autowrapDisabled {
            await writeSequence("\u{001B}[?7l") // DECAWM off
            autowrapDisabled = true
        }
    }

    /// Re-enable terminal autowrap after rendering
    private func enableAutowrapIfNeeded() async {
        if autowrapDisabled {
            await writeSequence("\u{001B}[?7h") // DECAWM on
            autowrapDisabled = false
        }
    }
}
