import Foundation

public protocol CursorManager {
    var row: Int { get }
    var col: Int { get }
    func moveTo(row: Int, col: Int)
    func hide(); func show()
    func clearScreen()
    func clearLine()
    func moveToColumn1()
}

public final class ANSICursorManager: CursorManager, @unchecked Sendable {
    private let out: TerminalOutputEncoder
    public private(set) var row = 0
    public private(set) var col = 0
    public init(out: TerminalOutputEncoder) { self.out = out }

    public func moveTo(row: Int, col: Int) {
        out.write("\u{001B}[\(row);\(col)H")
        self.row = row - 1
        self.col = col - 1
    }

    public func hide() { out.write("\u{001B}[?25l") }
    public func show() { out.write("\u{001B}[?25h") }
    public func clearScreen() { out.write("\u{001B}[2J\u{001B}[H"); row = 0; col = 0 }
    public func clearLine() { out.write("\u{001B}[2K") }
    public func moveToColumn1() { out.write("\u{001B}[G"); col = 0 }
}
