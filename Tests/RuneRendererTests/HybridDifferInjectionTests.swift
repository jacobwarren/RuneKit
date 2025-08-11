import Foundation
import Testing
@testable import RuneRenderer

private struct FakeDiffer: TerminalDiffer {
    let lines: [Int]
    func diff(from _: TerminalGrid, to _: TerminalGrid) -> [Int] { lines }
}

struct HybridDifferInjectionTests {
    @Test("HybridReconciler uses injected differ for delta path")
    func usesInjectedDiffer() async {
        let pipe = Pipe(); defer { pipe.fileHandleForReading.closeFile() }
        let renderer = TerminalRenderer(output: pipe.fileHandleForWriting)
        let reconciler = HybridReconciler(
            renderer: renderer,
            configuration: RenderConfiguration(),
            differ: FakeDiffer(lines: [1]),
        )

        let g1 = TerminalGrid(width: 5, height: 3)
        await reconciler.render(g1)

        var g2 = g1
        g2.setCell(at: 1, column: 0, to: TerminalCell(content: "X"))
        await reconciler.render(g2)
        pipe.fileHandleForWriting.closeFile()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Expect at least one cursor move to line 2 (1-based) because differ returned [1]
        #expect(output.contains("\u{001B}[2;1H"))
    }
}
