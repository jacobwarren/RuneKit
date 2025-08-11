import Testing
@testable import RuneANSI

struct LineComposerGoldenZWJTests {
    // Family emoji ZWJ sequence
    let fam = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}" // 👨‍👩‍👧‍👦

    @Test("Split never breaks ZWJ family at boundary")
    func splitZWJBoundary() {
        let s = "A" + fam + "B"
        let (l1, r1) = LineComposer.splitVisibleColumns(s, at: 1)
        // l1 == "A", r1 starts with fam
        let l1Text = ANSITokenizer().tokenize(l1).compactMap { if case let .text(t) = $0 { t } else { nil } }.joined()
        let r1Text = ANSITokenizer().tokenize(r1).compactMap { if case let .text(t) = $0 { t } else { nil } }.joined()
        #expect(l1Text == "A")
        #expect(r1Text.hasPrefix(fam))

        // Split at A + fam (width 1 + 2) = 3, ensure fam not split
        let (l2, r2) = LineComposer.splitVisibleColumns(s, at: 3)
        let l2Text = ANSITokenizer().tokenize(l2).compactMap { if case let .text(t) = $0 { t } else { nil } }.joined()
        let r2Text = ANSITokenizer().tokenize(r2).compactMap { if case let .text(t) = $0 { t } else { nil } }.joined()
        #expect(l2Text == "A" + fam)
        #expect(r2Text == "B")
    }

    @Test("Wrap preserves ZWJ family across lines")
    func wrapZWJ() {
        let sample = fam + "X"
        let lines = LineComposer.wrapToWidth(sample, width: 2)
        // fam width=2, so first line is fam, second is X
        let tokens = lines
            .map { ANSITokenizer().tokenize($0).compactMap { if case let .text(t) = $0 { t } else { nil } }.joined() }
        #expect(tokens.count == 2)
        #expect(tokens[0] == fam)
        #expect(tokens[1] == "X")
    }
}
