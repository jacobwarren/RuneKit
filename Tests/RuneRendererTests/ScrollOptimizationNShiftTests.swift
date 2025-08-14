import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

struct ScrollOptimizationNShiftTests {
    @Test("Detect two-line downward scroll and emit ESC[2S and write 2 lines")
    func scrollDownTwo() async {
        let cap = PipeCapture()
        let renderer = TerminalRenderer(output: cap.start())
        var g1 = TerminalGrid(width: 5, height: 4)
        g1.setCell(at: 0, column: 0, to: TerminalCell(content: "A"))
        g1.setCell(at: 1, column: 0, to: TerminalCell(content: "B"))
        g1.setCell(at: 2, column: 0, to: TerminalCell(content: "C"))
        g1.setCell(at: 3, column: 0, to: TerminalCell(content: "D"))
        var g2 = TerminalGrid(width: 5, height: 4)
        g2.setCell(at: 0, column: 0, to: TerminalCell(content: "C"))
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "D"))
        g2.setCell(at: 2, column: 0, to: TerminalCell(content: "E"))
        g2.setCell(at: 3, column: 0, to: TerminalCell(content: "F"))

        _ = await renderer.render(g1, strategy: RenderingStrategy.fullRedraw)
        _ = await renderer.render(g2, strategy: RenderingStrategy.scrollOptimized, previousGrid: g1)
        let output = await cap.finishAndReadString()
        #expect(output.contains("\u{001B}[2S"))
        // Should render two new lines 'E' at row 3 and 'F' at row 4
        #expect(output.contains("\u{001B}[3;1H"))
        #expect(output.contains("\u{001B}[4;1H"))
    }

    @Test("Detect two-line upward scroll and emit ESC[2T and write 2 lines at top")
    func scrollUpTwo() async {
        let cap = PipeCapture()
        let renderer = TerminalRenderer(output: cap.start())
        var g1 = TerminalGrid(width: 5, height: 4)
        g1.setCell(at: 0, column: 0, to: TerminalCell(content: "A"))
        g1.setCell(at: 1, column: 0, to: TerminalCell(content: "B"))
        g1.setCell(at: 2, column: 0, to: TerminalCell(content: "C"))
        g1.setCell(at: 3, column: 0, to: TerminalCell(content: "D"))
        var g2 = TerminalGrid(width: 5, height: 4)
        g2.setCell(at: 0, column: 0, to: TerminalCell(content: "Y"))
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "Z"))
        g2.setCell(at: 2, column: 0, to: TerminalCell(content: "A"))
        g2.setCell(at: 3, column: 0, to: TerminalCell(content: "B"))

        _ = await renderer.render(g1, strategy: RenderingStrategy.fullRedraw)
        _ = await renderer.render(g2, strategy: RenderingStrategy.scrollOptimized, previousGrid: g1)
        let output = await cap.finishAndReadString()
        #expect(output.contains("\u{001B}[2T"))
        // Should write two top lines at rows 1 and 2
        #expect(output.contains("\u{001B}[1;1H"))
        #expect(output.contains("\u{001B}[2;1H"))
    }
}
