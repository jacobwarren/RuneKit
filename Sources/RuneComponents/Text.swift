import RuneANSI
import RuneLayout
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
        attributes = TextAttributes()
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
        dim: Bool = false,
    ) {
        self.content = content
        attributes = TextAttributes(
            color: color,
            backgroundColor: backgroundColor,
            bold: bold,
            italic: italic,
            underline: underline,
            inverse: inverse,
            strikethrough: strikethrough,
            dim: dim,
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

    /// Initialize with TextStyle abstraction
    public init(_ content: String, style: TextStyle) {
        self.content = content
        attributes = style.attributes
    }

    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Handle empty content
        if content.isEmpty {
            var lines: [String] = []
            for _ in 0 ..< rect.height {
                lines.append("")
            }
            return lines
        }

        // Build styled text and wrap to width, preserving ANSI
        let styled = StyledText(spans: [TextSpan(text: content, attributes: attributes)])
        let wrappedStyled = styled.wrapByDisplayWidth(width: rect.width)
        let converter = ANSISpanConverter(profile: RuntimeStateContext.terminalProfile)
        let tokenizer = ANSITokenizer()
        let encodedLines = wrappedStyled.map { tokenizer.encode(converter.styledTextToTokens($0)) }

        // Render semantics: single line of content within width; remaining lines empty
        var lines: [String] = []
        lines.append(encodedLines.first ?? "")
        while lines.count < rect.height {
            lines.append("")
        }
        return lines
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

// MARK: - Chainable modifiers for developer ergonomics (RUNE-36)

public extension Text {
    /// Returns a copy with bold enabled/disabled
    func bold(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.bold = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with italic enabled/disabled
    func italic(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.italic = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with underline enabled/disabled
    func underline(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.underline = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with strikethrough enabled/disabled
    func strikethrough(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.strikethrough = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with inverse enabled/disabled
    func inverse(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.inverse = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with dim enabled/disabled
    func dim(_ enabled: Bool = true) -> Text {
        var attrs = attributes
        attrs.dim = enabled
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with foreground color set
    func color(_ color: ANSIColor?) -> Text {
        var attrs = attributes
        attrs.color = color
        return Text(content, attributes: attrs)
    }

    /// Returns a copy with background color set
    func bg(_ color: ANSIColor?) -> Text {
        var attrs = attributes
        attrs.backgroundColor = color
        return Text(content, attributes: attrs)
    }

    // MARK: - Ergonomics: hex + conditional modifiers

    func color(hex: String?) -> Text {
        guard let hex, let ansiColor = ANSIColor.fromHex(hex) else { return self }
        return self.color(ansiColor)
    }

    func bg(hex: String?) -> Text {
        guard let hex, let ansiColor = ANSIColor.fromHex(hex) else { return self }
        return self.bg(ansiColor)
    }

    func color(_ color: ANSIColor?, when condition: Bool) -> Text {
        condition ? self.color(color) : self
    }

    func bg(_ color: ANSIColor?, when condition: Bool) -> Text {
        condition ? bg(color) : self
    }
}
