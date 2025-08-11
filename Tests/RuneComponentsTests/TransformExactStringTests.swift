import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneLayout

struct TransformExactStringTests {
    @Test("Transform uppercasing keeps styles and transforms content only")
    func transformUppercaseKeepsStyles() {
        // Arrange
        let t = Transform(transform: { $0.uppercased() }) {
            Text("hello", color: .red, bold: true)
        }
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Act
        let lines = t.render(in: rect)
        #expect(lines.count == 1)
        let s = lines[0]

        // Assert ANSI string preserves styles; allow either param order 1;31 or 31;1
        let esc = "\u{001B}["
        let expectedA = "\(esc)1;31mHELLO\(esc)0m"
        let expectedB = "\(esc)31;1mHELLO\(esc)0m"
        #expect(s == expectedA || s == expectedB)
    }
}
