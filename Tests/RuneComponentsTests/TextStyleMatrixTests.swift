import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneLayout

struct TextStyleMatrixTests {
    @Test("Common style combinations produce ANSI and reset")
    func commonCombinations() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
        let cases: [(String, Text)] = [
            ("red bold", Text("Test", color: .red, bold: true)),
            ("inverse + bg", Text("Test", backgroundColor: .blue, inverse: true)),
            ("256 fg", Text("Test", color: .color256(196))),
            ("rgb fg", Text("Test", color: .rgb(255, 165, 0))),
            ("underline dim", Text("Test", underline: true, dim: true)),
            ("strike italic", Text("Test", italic: true, strikethrough: true)),
        ]

        for (name, text) in cases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(name): should render one line")
            let line = lines[0]
            #expect(line.contains("\u{001B}["), "\(name): should contain SGR")
            #expect(line.contains("Test"), "\(name): should contain text")
            #expect(line.contains("\u{001B}[0m"), "\(name): should reset")
        }
    }
}
