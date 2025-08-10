import Foundation
import Testing
@testable import RuneRenderer

struct CursorPolicyTests {
    @Test("Renderer respects hideCursorDuringRender=false")
    func rendererRespectsCursorPolicyFalse() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let output = pipe.fileHandleForWriting
        // Configuration with policy disabled
        let config = RenderConfiguration(hideCursorDuringRender: false)
        // Use pluggable IO for determinism if enabled is required
        let renderer = TerminalRenderer(output: output, encoder: nil, cursor: nil, configuration: config)

        // Minimal grid
        let grid = TerminalGrid(width: 3, height: 1)
        _ = await renderer.render(grid, forceFullRedraw: true)
        output.closeFile()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Should not hide or show cursor sequences
        #expect(!out.contains("\u{001B}[?25l"), "Should not hide cursor when policy is false")
        #expect(!out.contains("\u{001B}[?25h"), "Should not show cursor when policy is false")
    }

    @Test("Renderer respects hideCursorDuringRender=true (default)")
    func rendererRespectsCursorPolicyTrue() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let output = pipe.fileHandleForWriting
        let renderer = TerminalRenderer(output: output)

        let grid = TerminalGrid(width: 3, height: 1)
        _ = await renderer.render(grid, forceFullRedraw: true)
        output.closeFile()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Should hide and later show cursor
        #expect(out.contains("\u{001B}[?25l"), "Should hide cursor by default policy")
        #expect(out.contains("\u{001B}[?25h"), "Should show cursor after render")
    }
}

