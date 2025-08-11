import Foundation
import Testing
@testable import RuneANSI

struct SGRDiffingTests {
    @Test("Generator avoids redundant SGR when attributes unchanged")
    func avoidsRedundantSGR() {
        // Arrange: two spans with identical attributes
        let attrs = TextAttributes(color: .yellow, bold: true)
        let spans = [
            TextSpan(text: "A", attributes: attrs),
            TextSpan(text: "B", attributes: attrs),
        ]
        let styled = StyledText(spans: spans)
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styled)
        let ansi = ANSITokenizer().encode(tokens)

        // Assert: Ideally only one SGR open before A, none before B, then reset once.
        let opens = ansi.components(separatedBy: "\u{001B}[").count(where: { $0.contains("m") })
        #expect(opens <= 2, "Should not emit SGR redundantly for identical consecutive spans")
    }
}
