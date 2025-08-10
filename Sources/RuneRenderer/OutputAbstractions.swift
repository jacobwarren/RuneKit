import Foundation

public protocol OutputEncoder {
    func write(_ string: String)
}

public final class FileHandleOutputEncoder: OutputEncoder {
    private let handle: FileHandle
    public init(handle: FileHandle) { self.handle = handle }
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
}

public protocol CursorManager {
    var row: Int { get }
    var col: Int { get }
    func moveTo(row: Int, col: Int)
    func hide(); func show()
    func clearScreen()
    func clearLine()
    func moveToColumn1()
}

public final class ANSICursorManager: CursorManager {
    private let out: OutputEncoder
    public private(set) var row: Int = 0
    public private(set) var col: Int = 0
    public init(out: OutputEncoder) { self.out = out }

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

