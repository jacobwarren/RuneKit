import Foundation
import Testing
import TestSupport
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneKit
@testable import RuneLayout

/// Snapshot tests for Text style matrices (RUNE-35 acceptance)
struct TextStyleSnapshotTests {

    init() {
        // Clean up shared state before each test to prevent interference between tests
        StateRegistry.shared.clearAll()
        StateObjectStore.shared.clearAll()
    }
    private func render(_ text: Text) -> [String] {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
        return text.render(in: rect)
    }

    @Test("Snapshot: 16-color + effects")
    func snapshotBasic16AndEffects() {
        let cases: [(String, Text)] = [
            ("basic_red_bold", Text("Test", color: .red, bold: true)),
            ("basic_blue_inverse_bg_yellow", Text("Test", color: .blue, backgroundColor: .yellow, inverse: true)),
            ("basic_green_underline_dim", Text("Test", color: .green, underline: true, dim: true)),
        ]
        for (name, text) in cases {
            let lines = render(text)
            Snapshot.assertLinesSnapshot(lines, named: name)
        }
    }

    @Test("Snapshot: 256 and truecolor")
    func snapshot256AndTruecolor() {
        let cases: [(String, Text)] = [
            ("palette_196_bold", Text("Test", color: .color256(196), bold: true)),
            ("rgb_255_128_0_italic", Text("Test", color: .rgb(255, 128, 0), italic: true)),
            ("bg_palette_21_inverse", Text("Test", backgroundColor: .color256(21), inverse: true)),
        ]
        for (name, text) in cases {
            let lines = render(text)
            Snapshot.assertLinesSnapshot(lines, named: name)
        }
    }
}
