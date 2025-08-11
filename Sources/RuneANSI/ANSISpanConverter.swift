/// Converter between ANSI tokens and styled text spans
///
/// This module provides conversion functionality between low-level ANSI tokens
/// and high-level styled text representations, handling SGR state management.

/// Converter between ANSI tokens and styled text spans
///
/// This converter handles the complex task of converting between the low-level
/// ANSI token representation and the higher-level styled text span model.
/// It maintains state during conversion to properly handle SGR sequences.
public struct ANSISpanConverter {
    private let sgrProcessor = SGRParameterProcessor()
    private let sgrGenerator = SGRParameterGenerator()
    private let profile: TerminalProfile

    public init(profile: TerminalProfile = .trueColor) {
        self.profile = profile
    }

    public init() {
        profile = .trueColor
    }

    /// Convert ANSI tokens to styled text
    ///
    /// This method processes ANSI tokens and builds styled text spans by
    /// tracking SGR state changes and grouping text with consistent attributes.
    ///
    /// - Parameter tokens: Array of ANSI tokens to convert
    /// - Returns: StyledText with appropriate spans
    public func tokensToStyledText(_ tokens: [ANSIToken]) -> StyledText {
        var spans: [TextSpan] = []
        var currentAttributes = TextAttributes()
        var pendingText = ""

        for token in tokens {
            switch token {
            case let .text(text):
                pendingText += text

            case let .sgr(parameters):
                // If we have pending text, create a span with current attributes
                if !pendingText.isEmpty {
                    spans.append(TextSpan(text: pendingText, attributes: currentAttributes))
                    pendingText = ""
                }

                // Update attributes based on SGR parameters
                currentAttributes = sgrProcessor.applySGRParameters(parameters, to: currentAttributes)

            default:
                // Non-SGR tokens don't affect styling, but if we have pending text,
                // we should create a span to preserve the text order
                if !pendingText.isEmpty {
                    spans.append(TextSpan(text: pendingText, attributes: currentAttributes))
                    pendingText = ""
                }
            }
        }

        // Handle any remaining pending text
        if !pendingText.isEmpty {
            spans.append(TextSpan(text: pendingText, attributes: currentAttributes))
        }

        return StyledText(spans: spans)
    }

    /// Convert styled text to ANSI tokens
    ///
    /// This method converts styled text spans back to ANSI tokens, generating
    /// appropriate SGR sequences for each span's attributes.
    ///
    /// - Parameter styledText: The styled text to convert
    /// - Returns: Array of ANSI tokens representing the styled text
    public func styledTextToTokens(_ styledText: StyledText) -> [ANSIToken] {
        guard !styledText.spans.isEmpty else { return [] }

        // Minimal diffing with attribute-level generator + small cache
        var tokens: [ANSIToken] = []
        var previousAttributes = TextAttributes()
        var diffGen = SGRDiffGenerator()
        diffGen.profile = profile

        for span in styledText.spans {
            let attrs = span.attributes
            if attrs != previousAttributes {
                let diff = diffGen.diff(from: previousAttributes, to: attrs)
                if !diff.isEmpty { tokens.append(.sgr(diff)) }
                previousAttributes = attrs
            }
            if !span.text.isEmpty { tokens.append(.text(span.text)) }
        }

        if !previousAttributes.isDefault {
            tokens.append(.sgr([0]))
        }

        return tokens
    }
}
