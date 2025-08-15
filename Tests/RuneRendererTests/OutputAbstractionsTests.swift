import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

@Suite("Output abstractions tests", .enabled(if: !TestEnv.isCI))
struct OutputAbstractionsTests {
    @Test("FileHandleOutputEncoder writes to pipe")
    func fileHandleEncoderWrites() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let out = FileHandleOutputEncoder(handle: pipe.fileHandleForWriting)
        await out.write("hello")
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8) ?? ""
        #expect(s == "hello")
    }

    @Test("ANSICursorManager emits sequences")
    func cursorManagerSequences() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let out = FileHandleOutputEncoder(handle: pipe.fileHandleForWriting)
        let cm = ANSICursorManager(out: out)
        await cm.hide(); await cm.show(); await cm.clearScreen(); await cm.clearLine(); await cm.moveTo(row: 2, col: 3); await cm.moveToColumn1()
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
