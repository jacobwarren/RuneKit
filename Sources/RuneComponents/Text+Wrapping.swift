import RuneANSI
import RuneLayout

public extension Text {
    /// Wrap text content by display width, preserving ANSI styling.
    /// - Parameter width: Maximum display width per line
    /// - Returns: Array of encoded ANSI strings for each wrapped line
    func wrappedLines(width: Int) -> [String] {
        guard width > 0 else { return [] }
        // Build styled text once
        let span = TextSpan(text: content, attributes: attributes)
        let styled = StyledText(spans: [span])
        let lines = styled.wrapByDisplayWidth(width: width)
        let converter = ANSISpanConverter(profile: RuntimeStateContext.terminalProfile)
        let tokenizer = ANSITokenizer()
        return lines.map { tokenizer.encode(converter.styledTextToTokens($0)) }
    }
}
