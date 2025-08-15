import Foundation

public protocol CursorManager {
    var row: Int { get }
    var col: Int { get }
    func moveTo(row: Int, col: Int) async
    func hide() async; func show() async
    func clearScreen() async
    func clearLine() async
    func moveToColumn1() async
}

public final class ANSICursorManager: CursorManager, @unchecked Sendable {
    private let out: TerminalOutputEncoder
    public private(set) var row = 0
    public private(set) var col = 0
    public init(out: TerminalOutputEncoder) { self.out = out }

    public func moveTo(row: Int, col: Int) async {
        await out.write("\u{001B}[\(row);\(col)H")
        self.row = row - 1
        self.col = col - 1
    }

    public func hide() async { await out.write("\u{001B}[?25l") }
    public func show() async { await out.write("\u{001B}[?25h") }
    public func clearScreen() async { await out.write("\u{001B}[2J\u{001B}[H"); row = 0; col = 0 }
    public func clearLine() async { await out.write("\u{001B}[2K") }
    public func moveToColumn1() async { await out.write("\u{001B}[G"); col = 0 }
}
