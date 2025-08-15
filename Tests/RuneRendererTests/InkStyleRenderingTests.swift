import Foundation
import Testing
@testable import RuneRenderer

@Suite("Ink-style renderer behavior on main screen buffer")
struct InkStyleRenderingTests {
    /// Build a small grid with known lines
    private func makeGrid(_ lines: [String]) -> TerminalGrid {
        let width = max(20, lines.map { $0.count }.max() ?? 0)
        return TerminalGrid(lines: lines, width: width)
    }

    @Test("First render writes lines and positions cursor below frame (no full screen clear in ink style)")
    func firstRenderPositionsCursor() async {
        // Arrange
        let mem = MemoryEncoder()
        let cfg = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false, enablePluggableIO: true)
        let cursor = SafeCursorManager(out: mem)
        let renderer = TerminalRenderer(output: .standardOutput, encoder: mem, cursor: cursor, configuration: cfg)
        let grid = makeGrid(["A", "B"])

        // Act
        _ = await renderer.render(grid, strategy: .fullRedraw)

        // Assert basic properties
        let out = await mem.snapshot()
        #expect(out.contains("\u{001B}[1;1H") && out.contains("\u{001B}[2;1H"), "Should move to each row start")
        #expect(out.contains("A") && out.contains("B"), "Should write line contents")
        #expect(out.contains("\u{001B}[3;1H"), "Should move cursor to the line after frame")
    }

    @Test("Second render clears previous region line-by-line before writing new content")
    func secondRenderClearsPreviousRegion() async {
        let mem = MemoryEncoder()
        let cfg = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false, enablePluggableIO: true)
        let cursor = SafeCursorManager(out: mem)
        let renderer = TerminalRenderer(output: .standardOutput, encoder: mem, cursor: cursor, configuration: cfg)
        _ = await renderer.render(makeGrid(["AAAA"]) , strategy: .fullRedraw)
        await mem.reset()
        _ = await renderer.render(makeGrid(["BBBB"]) , strategy: .fullRedraw)
        let out = await mem.snapshot()
        // Should include ESC[2K sequences for clearing lines
        #expect(out.contains("\u{001B}[2K"), "Should clear lines with ESC[2K on subsequent renders")
        #expect(out.contains("BBBB"), "Should render new content")
    }
}

/// Minimal encoder to capture renderer output safely across actors
actor MemoryEncoder: TerminalOutputEncoder {
    private var _buffer: String = ""
    func write(_ text: String) async { _buffer += text }
    func snapshot() async -> String { _buffer }
    func reset() async { _buffer = "" }
    func flush() async { /* no-op for memory encoder */ }
}

/// CursorManager wrapper that is Sendable for tests
struct SafeCursorManager: CursorManager, Sendable {
    let out: MemoryEncoder
    var row: Int { 0 }
    var col: Int { 0 }
    func moveTo(row: Int, col: Int) async { await out.write("\u{001B}[\(row);\(col)H") }
    func hide() async { await out.write("\u{001B}[?25l") }
    func show() async { await out.write("\u{001B}[?25h") }
    func clearScreen() async { await out.write("\u{001B}[2J\u{001B}[H") }
    func clearLine() async { await out.write("\u{001B}[2K") }
    func moveToColumn1() async { await out.write("\u{001B}[G") }
}

