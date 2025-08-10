import Testing
@testable import RuneANSI

struct LineComposerTests {
    @Test("Split preserves SGR and grapheme boundaries")
    func splitPreserves() {
        let s = "\u{001B}[1;31mA\u{001B}[0mB\u{2705}C"
        let (l, r) = LineComposer.splitVisibleColumns(s, at: 3)
        // Visible widths: A(1) B(1) ✅(2) -> split after 3 should cut right before C
        // We do not split inside the emoji: since it would overflow, it moves to the right side
        // So l is plain "AB" and r starts with the emoji, ending with 'C'
        let lText = ANSITokenizer().tokenize(l).compactMap { if case .text(let t) = $0 { return t } else { return nil } }.joined()
        let rText = ANSITokenizer().tokenize(r).compactMap { if case .text(let t) = $0 { return t } else { return nil } }.joined()
        #expect(lText == "AB")
        #expect(rText.hasPrefix("\u{2705}"))
        #expect(rText.hasSuffix("C"))
    }

    @Test("Wrap produces lines that rejoin to original ignoring resets")
    func wrapRoundTrip() {
        let s = "\u{001B}[33mHello, colorful world!\u{001B}[0m"
        let lines = LineComposer.wrapToWidth(s, width: 5)
        // Encode back without extra info
        let joined = lines.joined()
        // Allow for extra resets; verify text content ordering via tokens
        let toks = ANSITokenizer().tokenize(joined).compactMap { if case .text(let t) = $0 { return t } else { return nil } }.joined()
        let orig = ANSITokenizer().tokenize(s).compactMap { if case .text(let t) = $0 { return t } else { return nil } }.joined()
        #expect(toks == orig)
    }
}


    @Test("Truncate appends reset and prevents style bleed")
    func truncatePreventsBleed() {
        let s = "\u{001B}[31mRed\u{001B}[0mBlue"
        // Truncate to width 2 ("Re") and ensure a reset at the end
        let t = LineComposer.truncateVisibleColumns(s, to: 2)
        // Tokenize truncated: expect text "Re" with an SGR reset at the end
        let toks = ANSITokenizer().tokenize(t)
        // There should be at least a reset token as last SGR
        #expect(toks.last == .sgr([0]))
        // Subsequent text should render unstyled when concatenated
        let joined = t + "X"
        // Verify the trailing 'X' is not colored
        let rendered = ANSITokenizer().tokenize(joined)
        // Collect SGR tokens after the reset; there should be none before the 'X'
        let postResetSGRCount = rendered.drop { $0 != .sgr([0]) }.filter { if case .sgr = $0 { return true } else { return false } }.count
        #expect(postResetSGRCount == 1)
    }

