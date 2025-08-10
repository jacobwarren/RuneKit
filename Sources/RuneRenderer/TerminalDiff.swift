import Foundation

/// Protocol for computing a minimal set of line updates between two grids
public protocol TerminalDiffer {
    func diff(from old: TerminalGrid, to new: TerminalGrid) -> [Int]
}

/// Default differ that uses TerminalGrid.changedLines
public struct SimpleLineDiffer: TerminalDiffer {
    public init() {}
    public func diff(from old: TerminalGrid, to new: TerminalGrid) -> [Int] {
        return new.changedLines(comparedTo: old)
    }
}

