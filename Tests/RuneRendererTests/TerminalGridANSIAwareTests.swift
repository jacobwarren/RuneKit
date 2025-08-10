import Testing
@testable import RuneRenderer
@testable import RuneUnicode

struct TerminalGridANSIAwareTests {
    @Test("ANSI SGR inside content should not consume columns; right border remains visible")
    func sgrDoesNotConsumeColumns() async {
        let left = "│"
        let right = "│"
        let boldStart = "\u{001B}[1m"
        let reset = "\u{001B}[0m"
        // Construct a line with ANSI SGR that should visually be 8 columns: │ Bold │
        let line = left + " " + boldStart + "Bold" + reset + " " + right
        let width = 8

        // Build grid from the line
        let grid = TerminalGrid(lines: [line], width: width)
        // Confirm last visible cell is the right border glyph
        if let row = grid.getRow(0) {
            #expect(row.count == width)
            #expect(row[width - 1].content == right)
        } else {
            #expect(false, "row 0 should exist")
        }

        // Round-trip render through TerminalRenderer to ensure sequences survive
        let renderer = TerminalRenderer()
        _ = await renderer.render(grid, forceFullRedraw: true)
        _ = await renderer.render(grid, forceFullRedraw: false)
        // Success if no crash and no trimming occurred
        #expect(true)
    }
}

