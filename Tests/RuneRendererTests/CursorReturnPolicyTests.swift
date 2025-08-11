import Foundation
import Testing
@testable import RuneRenderer

struct CursorReturnPolicyTests {
    @Test("Delta renders restore cursor to end-of-frame")
    func deltaRestoresCursor() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting)
        let g1 = TerminalGrid(width: 5, height: 3)
        await renderer.render(g1, strategy: .fullRedraw)

        var g2 = g1
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "X"))
        _ = await renderer.render(g2, strategy: .deltaUpdate, previousGrid: g1)
        pipe.fileHandleForWriting.closeFile()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(output.contains("\u{001B}[4;1H"))
    }

    @Test("Delta with no changes keeps cursor at end-of-frame")
    func deltaNoChangesStillRestores() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting)
        let g1 = TerminalGrid(width: 5, height: 3)
        await renderer.render(g1, strategy: .fullRedraw)
        _ = await renderer.render(g1, strategy: .deltaUpdate, previousGrid: g1)
        pipe.fileHandleForWriting.closeFile()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(output.contains("\u{001B}[4;1H"))
    }
}
