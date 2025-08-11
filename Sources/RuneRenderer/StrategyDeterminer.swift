import Foundation

/// Determines the optimal rendering strategy given the current and new grids,
/// configuration policy, and adaptive thresholds.
public struct StrategyDeterminer: Sendable {
    private let configuration: RenderConfiguration
    private var adaptiveThresholds: AdaptiveThresholds

    public init(configuration: RenderConfiguration, adaptiveThresholds: AdaptiveThresholds) {
        self.configuration = configuration
        self.adaptiveThresholds = adaptiveThresholds
    }

    public mutating func updateAdaptiveThresholds(_ thresholds: AdaptiveThresholds) {
        adaptiveThresholds = thresholds
    }

    public func determineStrategy(
        newGrid: TerminalGrid,
        currentGrid: TerminalGrid?,
        forceFullRedraw: Bool,
    ) async -> RenderingStrategy {
        if forceFullRedraw || currentGrid == nil {
            return .fullRedraw
        }

        // Respect explicit configuration mode
        switch configuration.optimizationMode {
        case .fullRedraw:
            return .fullRedraw
        case .lineDiff:
            guard currentGrid != nil else { return .fullRedraw }
            return .deltaUpdate
        case .automatic:
            break
        }

        guard let current = currentGrid else { return .fullRedraw }

        // Check dimensions
        if newGrid.width != current.width || newGrid.height != current.height {
            return .fullRedraw
        }

        // Calculate change metrics
        let changedLines = newGrid.changedLines(comparedTo: current)
        let changePercentage = Double(changedLines.count) / Double(newGrid.height)

        // Estimate bytes for different strategies
        let fullRedrawBytes = estimateFullRedrawBytes(grid: newGrid)
        let deltaBytes = estimateDeltaBytes(changedLines: changedLines, grid: newGrid)

        // Use adaptive threshold
        let threshold = adaptiveThresholds.deltaThreshold
        let bytesSaved = Double(fullRedrawBytes - deltaBytes) / Double(fullRedrawBytes)

        if changePercentage > 0.7 { return .fullRedraw }
        if bytesSaved < threshold { return .fullRedraw }

        if await detectScrollPattern(newGrid: newGrid, currentGrid: current) {
            return .scrollOptimized
        }

        return .deltaUpdate
    }

    private func estimateFullRedrawBytes(grid: TerminalGrid) -> Int {
        grid.width * grid.height * 2
    }

    private func estimateDeltaBytes(changedLines: [Int], grid: TerminalGrid) -> Int {
        let cursorMovementBytes = changedLines.count * 10
        let contentBytes = changedLines.count * grid.width * 2
        return cursorMovementBytes + contentBytes
    }

    private func detectScrollPattern(newGrid: TerminalGrid, currentGrid: TerminalGrid) async -> Bool {
        guard newGrid.width == currentGrid.width else { return false }
        guard newGrid.height == currentGrid.height else { return false }
        let height = newGrid.height
        // Try downward scroll by offset (new lines appended at bottom)
        for offset in 1 ..< height {
            var ok = true
            for row in 0 ..< (height - offset) where newGrid.getRow(row)! != currentGrid.getRow(row + offset)! {
                ok = false; break
            }
            if ok { return true }
        }
        // Try upward scroll by offset (new lines added at top)
        for offset in 1 ..< height {
            var ok = true
            for row in offset ..< height where newGrid.getRow(row)! != currentGrid.getRow(row - offset)! {
                ok = false; break
            }
            if ok { return true }
        }
        return false
    }
}
