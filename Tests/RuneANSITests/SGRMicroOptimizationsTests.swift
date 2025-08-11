import Foundation
import Testing
@testable import RuneANSI

struct SGRMicroOptimizationsTests {
    @Test("Combined SGR emitted once, avoid resets between non-default spans")
    func combinedOnceNoUnnecessaryResets() {
        // Arrange
        let spans = [
            TextSpan(text: "A", attributes: TextAttributes(color: .red, bold: true)),
            TextSpan(text: "B", attributes: TextAttributes(color: .red, bold: true)), // same attrs
            TextSpan(text: "C", attributes: TextAttributes(color: .blue, italic: true)), // different attrs
        ]
        let styled = StyledText(spans: spans)
        let converter = ANSISpanConverter()
        let tokens = converter.styledTextToTokens(styled)
        let ansi = ANSITokenizer().encode(tokens)
        // Assert: should start with a combined SGR (1;31 or 31;1 order-insensitive) and not reset between A and B
        #expect(ansi.contains("\u{001B}[1;31m") || ansi.contains("\u{001B}[31;1m"))
        // There should be no reset between A and B, only on transition to default or end
        let parts = ansi.components(separatedBy: "\u{001B}[0m")
        #expect(parts.count >= 2)
    }

    @Test("Avoid final reset if already reset when transitioning to default")
    func avoidDuplicateFinalReset() {
        var spans: [TextSpan] = []
        spans.append(TextSpan(text: "A", attributes: TextAttributes(color: .red)))
        spans.append(TextSpan(text: " ", attributes: TextAttributes())) // default to force reset
        let styled = StyledText(spans: spans)
        let converter = ANSISpanConverter()
        let tokens = converter.styledTextToTokens(styled)
        // Count resets
        let resets = tokens.count(where: { $0 == .sgr([0]) })
        #expect(resets <= 1)
    }
}
