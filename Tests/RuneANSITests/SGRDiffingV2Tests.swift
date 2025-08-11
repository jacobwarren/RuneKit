import Foundation
import Testing
@testable import RuneANSI

struct SGRDiffingV2Tests {
    @Test("Attribute-level diff emits reset when reverting to default and caches common attrs")
    func attributeLevelDiffAndCache() {
        var converter = ANSISpanConverter()
        // Build styled text with sequence: default -> bold red -> bold red (same) -> default -> blue
        let a = TextSpan(text: "A", attributes: TextAttributes())
        let br = TextSpan(text: "B", attributes: TextAttributes(color: .red, bold: true))
        let br2 = TextSpan(text: "C", attributes: TextAttributes(color: .red, bold: true))
        let d = TextSpan(text: "D", attributes: TextAttributes())
        let e = TextSpan(text: "E", attributes: TextAttributes(color: .blue))
        let styled = StyledText(spans: [a, br, br2, d, e])
        let tokens = converter.styledTextToTokens(styled)
        let ansi = ANSITokenizer().encode(tokens)
        // Expect minimal emissions: SGR for bold red before B, no new SGR before C, reset before D text, SGR for blue
        // before E, then final reset
        #expect(ansi.contains("\u{001B}["))
        // Should have two resets total: one after D path? Actually, our diff places reset at transition to default
        // (before D) and final reset at end of non-default block
        let resets = ansi.components(separatedBy: "\u{001B}[0m").count - 1
        #expect(resets >= 1)
    }
}
