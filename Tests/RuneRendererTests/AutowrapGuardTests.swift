import Foundation
import Testing
@testable import RuneRenderer

struct AutowrapGuardTests {
    @Test("Grid omits wide cluster at EOL (CJK fullwidth)")
    func gridOmitsWideAtEOL_CJK() {
        // "表" is width 2; preceding ASCII is width 1
        let line = "A表"
        let grid = TerminalGrid(lines: [line], width: 2)
        guard let row = grid.getRow(0) else { return #expect(Bool(false), "row 0 should exist") }
        #expect(row.count == 2)
        // Last cell should not be the wide char; should be empty padding
        #expect(row[1].content != "表")
        #expect(row[1].content == " ")
    }

    @Test("Grid omits wide cluster at EOL (emoji)")
    func gridOmitsWideAtEOL_Emoji() {
        let line = "x👍" // x(1) + 👍(2) => total 3; width=2 should drop 👍
        let grid = TerminalGrid(lines: [line], width: 2)
        guard let row = grid.getRow(0) else { return #expect(Bool(false), "row 0 should exist") }
        #expect(row.count == 2)
        #expect(row[0].content == "x")
        #expect(row[1].content == " ")
    }

    @Test("Grid omits wide cluster at EOL (fullwidth punctuation)")
    func gridOmitsWideAtEOL_FullwidthPunct() {
        let line = "x，" // x(1) + ，(2)
        let grid = TerminalGrid(lines: [line], width: 2)
        guard let row = grid.getRow(0) else { return #expect(Bool(false), "row 0 should exist") }
        #expect(row.count == 2)
        #expect(row[0].content == "x")
        #expect(row[1].content == " ")
    }

    @Test("DECAWM toggles off/on around full redraw when enabled")
    func decawmTogglesFullRedraw() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let cfg = RenderConfiguration(disableAutowrapDuringRender: true)
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting, encoder: nil, cursor: nil, configuration: cfg)
        let grid = TerminalGrid(width: 4, height: 2)
        _ = await renderer.render(grid, strategy: .fullRedraw)
        pipe.fileHandleForWriting.closeFile()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(out.contains("\u{001B}[?7l"), "Should disable autowrap at start of render")
        #expect(out.contains("\u{001B}[?7h"), "Should re-enable autowrap at end of render")
    }

    @Test("DECAWM toggles off/on around delta update when enabled")
    func decawmTogglesDelta() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let cfg = RenderConfiguration(disableAutowrapDuringRender: true)
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting, encoder: nil, cursor: nil, configuration: cfg)
        var g1 = TerminalGrid(width: 3, height: 2)
        var g2 = g1
        g2.setCell(at: 0, column: 0, to: TerminalCell(content: "X"))
        _ = await renderer.render(g1, strategy: .fullRedraw)
        _ = await renderer.render(g2, strategy: .deltaUpdate, previousGrid: g1)
        pipe.fileHandleForWriting.closeFile()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Expect at least one disable/enable pair across the renders
        #expect(out.contains("\u{001B}[?7l"))
        #expect(out.contains("\u{001B}[?7h"))
    }
}

