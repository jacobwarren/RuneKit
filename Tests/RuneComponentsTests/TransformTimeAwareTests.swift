import Foundation
import Testing
@testable import RuneComponents
@testable import RuneLayout

@Suite("Transform time-aware initializer tests")
struct TransformTimeAwareTests {
    @Test("Time-aware Transform with constant transform behaves like normal Transform and preserves ANSI")
    func timeAwareConstantBehavior() {
        // Arrange
        let child = Text("\u{001B}[1;34mhello\u{001B}[0m") // bold blue hello
        let transform = Transform(timeAware: { input, _ in
            input.uppercased()
        }) { child }
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Act
        let lines = transform.render(in: rect)

        // Assert
        #expect(lines.count == 1)
        let out = lines[0]
        #expect(out.contains("\u{001B}["), "Should preserve ANSI codes")
        #expect(out.contains("HELLO"), "Should apply uppercase transform")
        #expect(out.contains("\u{001B}[0m"), "Should preserve reset code")
    }

    @Test("Time-aware Transform produces different output over time", .disabled("Timing-sensitive test that can hang"))
    func timeAwareChangesOverTime() async {
        // Arrange: encode the integer seconds field into output to detect change
        let child = Text("tick")
        let transform = Transform(timeAware: { _, t in
            "T:\(Int(t * 1000))" // ms resolution to make change likely
        }) { child }
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Act
        let first = transform.render(in: rect)[0]
        try? await Task.sleep(for: .milliseconds(50))
        let second = transform.render(in: rect)[0]

        // Assert: in CI timing can be tight, but 50ms should flip ms value
        #expect(first != second, "Two renders separated by time should differ")
    }
}
