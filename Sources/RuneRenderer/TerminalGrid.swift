import Foundation

/// A 2D grid of terminal cells with efficient diff and rendering capabilities
public struct TerminalGrid: Sendable, Equatable {
    /// The grid of cells (row-major order)
    private var cells: [[TerminalCell]]

    /// Grid dimensions
    public let width: Int
    public let height: Int

    /// Line hashes for quick dirty detection
    private var lineHashes: [Int]

    /// Create a new terminal grid
    /// - Parameters:
    ///   - width: Grid width in columns
    ///   - height: Grid height in rows
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height

        // Initialize with empty cells
        self.cells = Array(repeating: Array(repeating: .empty, count: width), count: height)
        self.lineHashes = Array(repeating: 0, count: height)

        // Calculate initial hashes
        updateLineHashes()
    }

    /// Create a grid from string lines (for compatibility)
    /// - Parameters:
    ///   - lines: Array of strings representing each row
    ///   - width: Grid width (will pad or truncate lines as needed)
    public init(lines: [String], width: Int) {
        self.width = width
        self.height = lines.count

        self.cells = lines.map { line in
            var row: [TerminalCell] = []
            var columnIndex = 0

            // Convert string to cells, handling wide characters properly
            // Use String.SubSequence to iterate over grapheme clusters (visual characters)
            for char in line {
                let charString = String(char)
                let cell = TerminalCell(content: charString)

                // Add the cell if it fits
                if columnIndex + cell.width <= width {
                    row.append(cell)
                    columnIndex += cell.width
                } else {
                    // Character doesn't fit, stop processing this line
                    break
                }
            }

            // Pad with empty cells if needed
            while row.count < width {
                row.append(.empty)
            }

            // Truncate if too long (shouldn't happen with the new logic, but safety check)
            if row.count > width {
                row = Array(row.prefix(width))
            }

            return row
        }

        self.lineHashes = Array(repeating: 0, count: height)
        updateLineHashes()
    }

    /// Get a cell at the specified position
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - column: Column index (0-based)
    /// - Returns: The cell, or nil if out of bounds
    public func cell(at row: Int, column: Int) -> TerminalCell? {
        guard row >= 0 && row < height && column >= 0 && column < width else {
            return nil
        }
        return cells[row][column]
    }

    /// Set a cell at the specified position
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - column: Column index (0-based)
    ///   - cell: The new cell value
    public mutating func setCell(at row: Int, column: Int, to cell: TerminalCell) {
        guard row >= 0 && row < height && column >= 0 && column < width else {
            return
        }

        cells[row][column] = cell
        updateLineHash(for: row)
    }

    /// Set an entire row of cells
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - cells: Array of cells (will be padded or truncated to fit)
    public mutating func setRow(_ row: Int, to newCells: [TerminalCell]) {
        guard row >= 0 && row < height else { return }

        var adjustedCells = newCells

        // Pad with empty cells if needed
        while adjustedCells.count < width {
            adjustedCells.append(.empty)
        }

        // Truncate if too long
        if adjustedCells.count > width {
            adjustedCells = Array(adjustedCells.prefix(width))
        }

        cells[row] = adjustedCells
        updateLineHash(for: row)
    }

    /// Get an entire row of cells
    /// - Parameter row: Row index (0-based)
    /// - Returns: Array of cells, or nil if out of bounds
    public func getRow(_ row: Int) -> [TerminalCell]? {
        guard row >= 0 && row < height else { return nil }
        return cells[row]
    }

    /// Update a region of the grid
    /// - Parameters:
    ///   - startRow: Starting row (inclusive)
    ///   - endRow: Ending row (exclusive)
    ///   - startColumn: Starting column (inclusive)
    ///   - endColumn: Ending column (exclusive)
    ///   - cell: Cell to fill the region with
    public mutating func fillRegion(
        startRow: Int,
        endRow: Int,
        startColumn: Int,
        endColumn: Int,
        with cell: TerminalCell
    ) {
        let clampedStartRow = max(0, startRow)
        let clampedEndRow = min(height, endRow)
        let clampedStartColumn = max(0, startColumn)
        let clampedEndColumn = min(width, endColumn)

        for row in clampedStartRow..<clampedEndRow {
            for column in clampedStartColumn..<clampedEndColumn {
                cells[row][column] = cell
            }
            updateLineHash(for: row)
        }
    }

    /// Clear the entire grid
    public mutating func clear() {
        for row in 0..<height {
            for column in 0..<width {
                cells[row][column] = .empty
            }
            updateLineHash(for: row)
        }
    }

    /// Get lines that have changed compared to another grid
    /// - Parameter other: The other grid to compare against
    /// - Returns: Array of row indices that differ
    public func changedLines(comparedTo other: TerminalGrid) -> [Int] {
        var changedRows: [Int] = []

        // Handle dimension changes more intelligently
        if width != other.width || height != other.height {
            // Compare lines that exist in both grids
            let commonHeight = min(height, other.height)
            let commonWidth = min(width, other.width)

            for row in 0..<commonHeight {
                // For dimension changes, we need to compare cell by cell
                // since line hashes might not be comparable
                var lineChanged = false

                for col in 0..<commonWidth where cells[row][col] != other.cells[row][col] {
                    lineChanged = true
                    break
                }

                // Also check if the line lengths differ
                if width != other.width {
                    lineChanged = true
                }

                if lineChanged {
                    changedRows.append(row)
                }
            }

            // Add any new lines (if height increased)
            if height > other.height {
                for row in other.height..<height {
                    changedRows.append(row)
                }
            }

            // Add any removed lines (if height decreased)
            if height < other.height {
                for row in height..<other.height {
                    changedRows.append(row)
                }
            }

            return changedRows
        }

        // Same dimensions - use fast hash comparison
        for row in 0..<height where lineHashes[row] != other.lineHashes[row] {
            changedRows.append(row)
        }

        return changedRows
    }

    /// Get dirty rectangles (regions that have changed)
    /// - Parameter other: The other grid to compare against
    /// - Returns: Array of rectangles representing changed regions
    public func dirtyRectangles(comparedTo other: TerminalGrid) -> [DirtyRectangle] {
        let changedRows = changedLines(comparedTo: other)

        if changedRows.isEmpty {
            return []
        }

        // For now, return each changed line as a full-width rectangle
        // TODO: Implement more sophisticated rectangle merging
        return changedRows.map { row in
            DirtyRectangle(
                startRow: row,
                endRow: row + 1,
                startColumn: 0,
                endColumn: width
            )
        }
    }

    /// Convert grid to string representation (for debugging)
    public func toString() -> String {
        return cells.map { row in
            row.map { $0.content }.joined()
        }.joined(separator: "\n")
    }

    /// Get grid as array of strings (for Frame conversion)
    public func getLines() -> [String] {
        return cells.map { row in
            row.map { $0.content }.joined()
        }
    }

    // MARK: - Private Methods

    /// Update line hashes for all rows
    private mutating func updateLineHashes() {
        for row in 0..<height {
            updateLineHash(for: row)
        }
    }

    /// Update hash for a specific row
    private mutating func updateLineHash(for row: Int) {
        guard row >= 0 && row < height else { return }

        var hasher = Hasher()
        for cell in cells[row] {
            hasher.combine(cell)
        }
        lineHashes[row] = hasher.finalize()
    }
}

/// Represents a rectangular region that needs updating
public struct DirtyRectangle: Sendable, Equatable {
    public let startRow: Int
    public let endRow: Int      // Exclusive
    public let startColumn: Int
    public let endColumn: Int   // Exclusive

    public init(startRow: Int, endRow: Int, startColumn: Int, endColumn: Int) {
        self.startRow = startRow
        self.endRow = endRow
        self.startColumn = startColumn
        self.endColumn = endColumn
    }

    /// Check if this rectangle is empty
    public var isEmpty: Bool {
        return startRow >= endRow || startColumn >= endColumn
    }

    /// Get the area of this rectangle
    public var area: Int {
        return max(0, endRow - startRow) * max(0, endColumn - startColumn)
    }
}
