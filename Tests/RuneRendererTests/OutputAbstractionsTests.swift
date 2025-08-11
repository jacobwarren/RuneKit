import Foundation
import Testing
@testable import RuneRenderer

struct OutputAbstractionsTests {
    @Test("FileHandleOutputEncoder writes to pipe")
    func fileHandleEncoderWrites() {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let out = FileHandleOutputEncoder(handle: pipe.fileHandleForWriting)
        out.write("hello")
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8) ?? ""
        #expect(s == "hello")
    }

    @Test("ANSICursorManager emits sequences")
    func cursorManagerSequences() {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let out = FileHandleOutputEncoder(handle: pipe.fileHandleForWriting)
        let cm = ANSICursorManager(out: out)
        cm.hide(); cm.show(); cm.clearScreen(); cm.clearLine(); cm.moveTo(row: 2, col: 3); cm.moveToColumn1()
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8) ?? ""
        #expect(s.contains("\u{001B}[?25l"))
        #expect(s.contains("\u{001B}[?25h"))
        #expect(s.contains("\u{001B}[2J\u{001B}[H"))
        #expect(s.contains("\u{001B}[2K"))
        #expect(s.contains("\u{001B}[2;3H"))
        #expect(s.contains("\u{001B}[G"))
    }
}
