import Foundation

extension TerminalRenderer {
    /// Render using scroll-optimized updates when grid is an N-line shift
    func renderScrollOptimized(_ grid: TerminalGrid, previousGrid: TerminalGrid?) async -> RenderStats {
        var stats = RenderStats()
        stats.strategy = .scrollOptimized
        guard let current = previousGrid else { return await renderInkStyle(grid) }
        // Determine direction: try match of current shifted
        let height = grid.height
        // Detect largest offset for down/up shift
        func detectDownShift() -> Int {
            var best = 0
            if height > 1 {
                for offset in 1 ..< height {
                    var ok = true
                    for row in 0 ..< (height - offset) where grid.getRow(row)! != current.getRow(row + offset)! {
                        ok = false; break
                    }
                    if ok { best = offset; break }
                }
            }
            return best
        }
        func detectUpShift() -> Int {
            var best = 0
            if height > 1 {
                for offset in 1 ..< height {
                    var ok = true
                    for row in offset ..< height where grid.getRow(row)! != current.getRow(row - offset)! {
                        ok = false; break
                    }
                    if ok { best = offset; break }
                }
            }
            return best
        }
        let nDown = detectDownShift()
        if nDown > 0 {
            // Scroll up by n: ESC[nS] moves the viewport up; new lines to render at bottom
            let seq = "\u{001B}[\(nDown)S"
            await writeSequence(seq); stats.bytesWritten += seq.utf8.count
            for j in 0 ..< nDown {
                let rowIndex = height - nDown + j
                let move = "\u{001B}[\(rowIndex + 1);1H"
                await writeSequence(move); stats.bytesWritten += move.utf8.count
                if let row = grid.getRow(rowIndex) {
                    let line = await renderRow(row, optimizeState: true)
                    await writeSequence(line); stats.bytesWritten += line.utf8.count
                }
            }
            let restore = "\u{001B}[\(height + 1);1H"
            await writeSequence(restore); stats.bytesWritten += restore.utf8.count
            stats.totalLines = height
            return stats
        }
        let nUp = detectUpShift()
        if nUp > 0 {
            // Scroll down by n: ESC[nT]; new lines to render at top
            let seq = "\u{001B}[\(nUp)T"
            await writeSequence(seq); stats.bytesWritten += seq.utf8.count
            for j in 0 ..< nUp {
                let move = "\u{001B}[\(j + 1);1H"
                await writeSequence(move); stats.bytesWritten += move.utf8.count
                if let row = grid.getRow(j) {
                    let line = await renderRow(row, optimizeState: true)
                    await writeSequence(line); stats.bytesWritten += line.utf8.count
                }
            }
            let restore = "\u{001B}[\(height + 1);1H"
            await writeSequence(restore); stats.bytesWritten += restore.utf8.count
            stats.totalLines = height
            return stats
        }
        // Fallback
        return await renderDelta(grid, previousGrid: previousGrid)
    }
}
