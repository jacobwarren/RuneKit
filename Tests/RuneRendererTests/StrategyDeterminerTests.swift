import Testing
@testable import RuneRenderer

struct StrategyDeterminerTests {
    @Test("Full redraw when no current grid or dimensions changed")
    func fullRedrawConditions() async {
        let config = RenderConfiguration(optimizationMode: .automatic)
        let determiner = StrategyDeterminer(configuration: config, adaptiveThresholds: AdaptiveThresholds())
        let g1 = TerminalGrid(width: 10, height: 3)
        let s1 = await determiner.determineStrategy(newGrid: g1, currentGrid: nil, forceFullRedraw: false)
        #expect(s1 == .fullRedraw)

        let g2 = TerminalGrid(width: 12, height: 3)
        let s2 = await determiner.determineStrategy(newGrid: g2, currentGrid: g1, forceFullRedraw: false)
        #expect(s2 == .fullRedraw)
    }

    @Test("Delta when small change and thresholds OK")
    func deltaDecision() async {
        let config = RenderConfiguration(optimizationMode: .automatic)
        let determiner = StrategyDeterminer(configuration: config, adaptiveThresholds: AdaptiveThresholds())
        let g1 = TerminalGrid(width: 10, height: 3)
        var g2 = g1
        g2.setCell(at: 1, column: 1, to: TerminalCell(content: "X"))
        let s = await determiner.determineStrategy(newGrid: g2, currentGrid: g1, forceFullRedraw: false)
        #expect(s == .deltaUpdate || s == .scrollOptimized)
    }
}

