import Testing
@testable import RuneANSI
@testable import RuneComponents

struct TextColorBleedTests {
    @Test("No color bleed across lines")
    func noColorBleedAcrossLines() {
        // Render three lines: plain, styled, plain
        let styled = StyledText(spans: [TextSpan(text: "colored", attributes: TextAttributes(color: .red, bold: true))])
        let tokens = ANSISpanConverter().styledTextToTokens(styled)
        let ansi = ANSITokenizer().encode(tokens)

        let lines = ["plain-1", ansi, "plain-2"]
        let joined = lines.joined(separator: "\n")
        // Ensure that after the styled line, we include a reset sequence before the next line
        // This is indirectly checked by running SGRStateMachine across retokenized stream and ending in default state
        let retokens = ANSITokenizer().tokenize(joined)
        var machine = SGRStateMachine()
        for token in retokens {
            switch token {
            case let .sgr(params): _ = machine.apply(params)
            default: break
            }
        }
        #expect(machine.attributes.isDefault)
    }
}
