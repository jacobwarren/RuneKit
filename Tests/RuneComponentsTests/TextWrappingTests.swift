import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneUnicode

struct TextWrappingTests {
    @Test("wrappedLines preserves ANSI and avoids bleed with emojis/ZWJ/CJK")
    func wrappedLinesPreservesANSI() {
        // Arrange
        let text = Text("Hello👨‍👩‍👧‍👦 世界 🎉 Test!", color: .red, bold: true)
        // Act
        let lines = text.wrappedLines(width: 8) // 8 display columns per line
        // Assert - non-empty and multiple lines
        #expect(lines.count >= 2)
        // Each non-empty line should have reset if it starts styled
        for line in lines where !line.isEmpty {
            let tokens = ANSITokenizer().tokenize(line)
            // If first token is SGR, last should be reset
            if case .sgr = tokens.first { #expect(tokens.last == .sgr([0])) }
        }
        // Content round-trip via StyledText plainText reconstruction check
        let joined = lines.joined()
        let rtTokens = ANSITokenizer().tokenize(joined)
        // Extract plain text from tokens
        let plain = rtTokens.compactMap { if case let .text(s) = $0 { s } else { nil } }.joined()
        #expect(plain == "Hello👨‍👩‍👧‍👦 世界 🎉 Test!")
    }
}
