import RuneLayout
import RuneANSI
import RuneUnicode

/// A styled text component that supports ANSI styling
///
/// Text component renders styled text using the spans → tokens → renderer pipeline.
/// It supports all standard ANSI styling attributes including colors, bold, italic,
/// underline, strikethrough, inverse, and dim.
public struct Text: Component {
    public let content: String
    public let attributes: TextAttributes

    /// Initialize a plain text component (backward compatibility)
    ///
    /// - Parameter content: The text content to display
    public init(_ content: String) {
        self.content = content
        self.attributes = TextAttributes()
    }

    /// Initialize a text component with content and optional styling
    ///
    /// - Parameters:
    ///   - content: The text content to display
    ///   - color: Foreground color (default: nil)
    ///   - backgroundColor: Background color (default: nil)
    ///   - bold: Bold styling (default: false)
    ///   - italic: Italic styling (default: false)
    ///   - underline: Underline styling (default: false)
    ///   - strikethrough: Strikethrough styling (default: false)
    ///   - inverse: Inverse styling (default: false)
    ///   - dim: Dim styling (default: false)
    public init(
        _ content: String,
        color: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        inverse: Bool = false,
        dim: Bool = false
    ) {
        self.content = content
        self.attributes = TextAttributes(
            color: color,
            backgroundColor: backgroundColor,
            bold: bold,
            italic: italic,
            underline: underline,
            inverse: inverse,
            strikethrough: strikethrough,
            dim: dim
        )
    }

    /// Initialize a text component with content and text attributes
    ///
    /// - Parameters:
    ///   - content: The text content to display
    ///   - attributes: The styling attributes to apply
    public init(_ content: String, attributes: TextAttributes) {
        self.content = content
        self.attributes = attributes
    }

    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Handle empty content
        if content.isEmpty {
            var lines: [String] = []
            for _ in 0..<rect.height {
                lines.append("")
            }
            return lines
        }

        // Create styled text span
        let span = TextSpan(text: content, attributes: attributes)
        _ = StyledText(spans: [span])

        // Convert to ANSI tokens if styling is applied
        if attributes.isDefault {
            // No styling - use plain text with width constraint
            // Use display width to prevent emoji clipping
            let truncated = truncateToDisplayWidth(content, maxWidth: rect.width)
            var lines = [truncated]

            // Fill remaining height with empty lines
            while lines.count < rect.height {
                lines.append("")
            }

            return lines
        } else {
            // Apply width constraint to the content first, then apply styling
            // Use display width to prevent emoji clipping
            let truncatedContent = truncateToDisplayWidth(content, maxWidth: rect.width)
            let truncatedSpan = TextSpan(text: truncatedContent, attributes: attributes)
            let truncatedStyledText = StyledText(spans: [truncatedSpan])

            // Convert to ANSI tokens and encode
            let converter = ANSISpanConverter()
            let tokens = converter.styledTextToTokens(truncatedStyledText)
            let tokenizer = ANSITokenizer()
            let ansiString = tokenizer.encode(tokens)

            var lines = [ansiString]

            // Fill remaining height with empty lines
            while lines.count < rect.height {
                lines.append("")
            }

            return lines
        }
    }

    /// Truncate a string to fit within a specific display width
    /// - Parameters:
    ///   - text: The text to truncate
    ///   - maxWidth: The maximum display width allowed
    /// - Returns: The truncated text that fits within maxWidth display columns
    private func truncateToDisplayWidth(_ text: String, maxWidth: Int) -> String {
        guard maxWidth > 0 else { return "" }

        var result = ""
        var currentWidth = 0

        for char in text {
            let charWidth = Width.displayWidth(of: String(char))
            if currentWidth + charWidth <= maxWidth {
                result.append(char)
                currentWidth += charWidth
            } else {
                break
            }
        }

        return result
    }
}
