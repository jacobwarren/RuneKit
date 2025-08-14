import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

struct CursorReturnPolicyTests {
    @Test("Delta renders restore cursor to end-of-frame")
    func deltaRestoresCursor() async {
        let cap = PipeCapture()
        let renderer = TerminalRenderer(output: cap.start())
        let g1 = TerminalGrid(width: 5, height: 3)
        await renderer.render(g1, strategy: RenderingStrategy.fullRedraw)

        var g2 = g1
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "X"))
        _ = await renderer.render(g2, strategy: RenderingStrategy.deltaUpdate, previousGrid: g1)
        let output = await cap.finishAndReadString()
        #expect(output.contains("\u{001B}[4;1H"))
    }

    @Test("Delta with no changes keeps cursor at end-of-frame")
    func deltaNoChangesStillRestores() async {
        let cap = PipeCapture()
        let renderer = TerminalRenderer(output: cap.start())
        let g1 = TerminalGrid(width: 5, height: 3)
        await renderer.render(g1, strategy: RenderingStrategy.fullRedraw)
        _ = await renderer.render(g1, strategy: RenderingStrategy.deltaUpdate, previousGrid: g1)
        let output = await cap.finishAndReadString()
        #expect(output.contains("\u{001B}[4;1H"))
    }
}
