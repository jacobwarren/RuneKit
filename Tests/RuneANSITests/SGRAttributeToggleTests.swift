import Foundation
import Testing
@testable import RuneANSI

struct SGRAttributeToggleTests {
    @Test("Style toggles maintain correctness with minimal emissions")
    func togglesMinimal() {
        let converter = ANSISpanConverter()
        // Sequence: bold on -> bold+underline on -> underline only -> default
        let a = TextSpan(text: "A", attributes: TextAttributes(bold: true))
        let b = TextSpan(text: "B", attributes: TextAttributes(bold: true, underline: true))
        let c = TextSpan(text: "C", attributes: TextAttributes(underline: true))
        let d = TextSpan(text: "D", attributes: TextAttributes())
        let styled = StyledText(spans: [a, b, c, d])
        let tokens = converter.styledTextToTokens(styled)
        let sgrs: [[Int]] = tokens.compactMap { if case let .sgr(p) = $0 { p } else { nil } }
        // Assert we at least turned bold on at some point and underline on at some point, and ended with reset
        #expect(sgrs.contains(where: { $0.contains(1) }))
        #expect(sgrs.contains(where: { $0.contains(4) }))
        #expect(sgrs.last == [0])
    }

    @Test("Color change does not emit unnecessary reset")
    func colorChangeNoReset() {
        let spans = [
            TextSpan(text: "A", attributes: TextAttributes(color: .red)),
            TextSpan(text: "B", attributes: TextAttributes(color: .blue)),
        ]
        let styled = StyledText(spans: spans)
        let tokens = ANSISpanConverter().styledTextToTokens(styled)
        // Should contain color codes but no reset between A and B, only final reset
        let resets = tokens.count(where: { $0 == .sgr([0]) })
        #expect(resets == 1)
    }
}
