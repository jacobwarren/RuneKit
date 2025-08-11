import Foundation
import Testing
@testable import RuneRenderer

struct ScrollOptimizationTests {
    @Test("Detect one-line downward scroll and emit scroll sequence")
    func scrollDownOne() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting)
        var g1 = TerminalGrid(width: 5, height: 3)
        g1.setCell(at: 0, column: 0, to: TerminalCell(content: "A"))
        g1.setCell(at: 1, column: 0, to: TerminalCell(content: "B"))
        g1.setCell(at: 2, column: 0, to: TerminalCell(content: "C"))
        var g2 = TerminalGrid(width: 5, height: 3)
        g2.setCell(at: 0, column: 0, to: TerminalCell(content: "B"))
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "C"))
        g2.setCell(at: 2, column: 0, to: TerminalCell(content: "D"))

        // Use renderer's strategy method with explicit scrollOptimized to ensure code path
        _ = await renderer.render(g1, strategy: .fullRedraw)
        _ = await renderer.render(g2, strategy: .scrollOptimized, previousGrid: g1)
        pipe.fileHandleForWriting.closeFile()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(output.contains("\u{001B}[1S")) // scroll up by one
        #expect(output.contains("\u{001B}[3;1H")) // moved to last line to draw
    }
}
