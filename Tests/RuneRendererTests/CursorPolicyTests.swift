import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

struct CursorPolicyTests {
    @Test("Renderer respects hideCursorDuringRender=false")
    func rendererRespectsCursorPolicyFalse() async {
        let cap = PipeCapture()
        let output = cap.start()
        // Configuration with policy disabled
        let config = RenderConfiguration(hideCursorDuringRender: false)
        // Use pluggable IO for determinism if enabled is required
        let renderer = TerminalRenderer(output: output, encoder: nil, cursor: nil, configuration: config)

        // Minimal grid
        let grid = TerminalGrid(width: 3, height: 1)
        _ = await renderer.render(grid, forceFullRedraw: true)
        let out = await cap.finishAndReadString()
        // Should not hide or show cursor sequences
        #expect(!out.contains("\u{001B}[?25l"), "Should not hide cursor when policy is false")
        #expect(!out.contains("\u{001B}[?25h"), "Should not show cursor when policy is false")
    }

    @Test("Renderer respects hideCursorDuringRender=true (default)")
    func rendererRespectsCursorPolicyTrue() async {
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        let grid = TerminalGrid(width: 3, height: 1)
        _ = await renderer.render(grid, forceFullRedraw: true)
        let out = await cap.finishAndReadString()
        // Should hide and later show cursor
        #expect(out.contains("\u{001B}[?25l"), "Should hide cursor by default policy")
        #expect(out.contains("\u{001B}[?25h"), "Should show cursor after render")
    }
}
