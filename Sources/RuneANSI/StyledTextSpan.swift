/// Styled text spans model for ANSI-aware text representation
///
/// This module provides a structured way to represent text with styling attributes,
/// enabling efficient manipulation of styled text without re-parsing ANSI sequences.
/// It supports conversion to/from ANSI tokens while preserving all styling information.

/// Represents a color in ANSI escape sequences
///
/// This enum covers all standard ANSI color representations including
/// basic 16 colors, 256-color palette, and full RGB colors.
public enum ANSIColor: Equatable, Hashable {
    /// Basic ANSI colors (30-37 for foreground, 40-47 for background)
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case brightBlack
    case brightRed
    case brightGreen
    case brightYellow
    case brightBlue
    case brightMagenta
    case brightCyan
    case brightWhite
    
    /// 256-color palette (0-255)
    /// - Parameter index: Color index in the 256-color palette
    case color256(Int)
    
    /// RGB color with full 24-bit color support
    /// - Parameters:
    ///   - red: Red component (0-255)
    ///   - green: Green component (0-255)
    ///   - blue: Blue component (0-255)
    case rgb(Int, Int, Int)
}

/// Text styling attributes that can be applied to text spans
///
/// This structure represents all the styling attributes that can be
/// controlled via ANSI SGR (Select Graphic Rendition) codes.
public struct TextAttributes: Equatable, Hashable {
    /// Foreground text color
    public var color: ANSIColor?
    
    /// Background color
    public var backgroundColor: ANSIColor?
    
    /// Bold/bright text (SGR 1)
    public var bold: Bool
    
    /// Italic text (SGR 3)
    public var italic: Bool
    
    /// Underlined text (SGR 4)
    public var underline: Bool
    
    /// Inverse/reverse video (SGR 7)
    public var inverse: Bool
    
    /// Strikethrough text (SGR 9)
    public var strikethrough: Bool
    
    /// Dim/faint text (SGR 2)
    public var dim: Bool
    
    /// Initialize text attributes with optional styling
    ///
    /// - Parameters:
    ///   - color: Foreground color (default: nil)
    ///   - backgroundColor: Background color (default: nil)
    ///   - bold: Bold styling (default: false)
    ///   - italic: Italic styling (default: false)
    ///   - underline: Underline styling (default: false)
    ///   - inverse: Inverse video styling (default: false)
    ///   - strikethrough: Strikethrough styling (default: false)
    ///   - dim: Dim styling (default: false)
    public init(
        color: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        inverse: Bool = false,
        strikethrough: Bool = false,
        dim: Bool = false
    ) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.inverse = inverse
        self.strikethrough = strikethrough
        self.dim = dim
    }
    
    /// Check if attributes represent default (no styling)
    public var isDefault: Bool {
        return color == nil &&
               backgroundColor == nil &&
               !bold &&
               !italic &&
               !underline &&
               !inverse &&
               !strikethrough &&
               !dim
    }
}

/// A span of text with consistent styling attributes
///
/// Text spans represent contiguous runs of text that share the same
/// styling attributes. This allows for efficient representation and
/// manipulation of styled text.
public struct TextSpan: Equatable, Hashable {
    /// The text content of this span
    public let text: String
    
    /// The styling attributes applied to this span
    public let attributes: TextAttributes
    
    /// Initialize a text span
    ///
    /// - Parameters:
    ///   - text: The text content
    ///   - attributes: The styling attributes to apply
    public init(text: String, attributes: TextAttributes) {
        self.text = text
        self.attributes = attributes
    }
    
    /// Create a plain text span with no styling
    ///
    /// - Parameter text: The text content
    /// - Returns: A text span with default attributes
    public static func plain(_ text: String) -> TextSpan {
        return TextSpan(text: text, attributes: TextAttributes())
    }
    
    /// Check if this span has any styling applied
    public var isPlain: Bool {
        return attributes.isDefault
    }
    
    /// The length of the text content
    public var length: Int {
        return text.count
    }
    
    /// Check if this span is empty
    public var isEmpty: Bool {
        return text.isEmpty
    }

    /// Split this span at the specified character index
    ///
    /// This method splits the text span into two parts at the given character
    /// index, preserving the attributes in both resulting spans.
    ///
    /// - Parameter index: The character index at which to split (0-based)
    /// - Returns: A tuple containing the left and right parts
    public func split(at index: Int) -> (left: TextSpan, right: TextSpan) {
        let clampedIndex = max(0, min(index, text.count))

        let leftText = String(text.prefix(clampedIndex))
        let rightText = String(text.dropFirst(clampedIndex))

        let leftSpan = TextSpan(text: leftText, attributes: attributes)
        let rightSpan = TextSpan(text: rightText, attributes: attributes)

        return (left: leftSpan, right: rightSpan)
    }
}

/// A collection of styled text spans representing formatted text
///
/// StyledText provides a high-level interface for working with text
/// that contains multiple styling runs. It can be converted to/from
/// ANSI token sequences while preserving all formatting information.
public struct StyledText: Equatable {
    /// The text spans that make up this styled text
    public let spans: [TextSpan]
    
    /// Initialize styled text with an array of spans
    ///
    /// - Parameter spans: The text spans to include
    public init(spans: [TextSpan]) {
        self.spans = spans
    }
    
    /// Create styled text from plain text with no formatting
    ///
    /// - Parameter text: The plain text content
    /// - Returns: StyledText with a single plain span
    public static func plain(_ text: String) -> StyledText {
        return StyledText(spans: [TextSpan.plain(text)])
    }
    
    /// Extract the plain text content without any formatting
    public var plainText: String {
        return spans.map { $0.text }.joined()
    }
    
    /// Check if this styled text is empty
    public var isEmpty: Bool {
        return spans.isEmpty || spans.allSatisfy { $0.isEmpty }
    }
    
    /// The total length of all text content
    public var length: Int {
        return spans.reduce(0) { $0 + $1.length }
    }
    
    /// Check if this styled text contains only plain text (no formatting)
    public var isPlain: Bool {
        return spans.allSatisfy { $0.isPlain }
    }

    /// Merge adjacent spans with identical attributes
    ///
    /// This method combines consecutive spans that have the same attributes
    /// into single spans, reducing the total number of spans while preserving
    /// all text content and formatting.
    ///
    /// - Returns: A new StyledText with merged spans
    public func mergingAdjacentSpans() -> StyledText {
        guard !spans.isEmpty else { return self }

        var mergedSpans: [TextSpan] = []
        var currentSpan = spans[0]

        for i in 1..<spans.count {
            let nextSpan = spans[i]

            // If attributes match, merge the text
            if currentSpan.attributes == nextSpan.attributes {
                currentSpan = TextSpan(
                    text: currentSpan.text + nextSpan.text,
                    attributes: currentSpan.attributes
                )
            } else {
                // Attributes don't match, save current span and start new one
                mergedSpans.append(currentSpan)
                currentSpan = nextSpan
            }
        }

        // Don't forget the last span
        mergedSpans.append(currentSpan)

        return StyledText(spans: mergedSpans)
    }

    /// Split styled text at the specified column position
    ///
    /// This method splits the styled text into two parts at the given column
    /// position, preserving all formatting and handling spans that cross the
    /// split boundary.
    ///
    /// - Parameter column: The column position at which to split (0-based)
    /// - Returns: A tuple containing the left and right parts
    public func split(at column: Int) -> (left: StyledText, right: StyledText) {
        guard column > 0 else {
            return (left: StyledText(spans: []), right: self)
        }

        guard column < length else {
            return (left: self, right: StyledText(spans: []))
        }

        var leftSpans: [TextSpan] = []
        var rightSpans: [TextSpan] = []
        var currentColumn = 0

        for span in spans {
            let spanEnd = currentColumn + span.length

            if spanEnd <= column {
                // Entire span goes to the left
                leftSpans.append(span)
            } else if currentColumn >= column {
                // Entire span goes to the right
                rightSpans.append(span)
            } else {
                // Span crosses the split boundary
                let splitIndex = column - currentColumn
                let (leftPart, rightPart) = span.split(at: splitIndex)

                if !leftPart.isEmpty {
                    leftSpans.append(leftPart)
                }
                if !rightPart.isEmpty {
                    rightSpans.append(rightPart)
                }
            }

            currentColumn = spanEnd
        }

        return (
            left: StyledText(spans: leftSpans),
            right: StyledText(spans: rightSpans)
        )
    }
}

/// Converter between ANSI tokens and styled text spans
///
/// This converter handles the complex task of converting between the low-level
/// ANSI token representation and the higher-level styled text span model.
/// It maintains state during conversion to properly handle SGR sequences.
public struct ANSISpanConverter {

    public init() {}

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
            case .text(let text):
                pendingText += text

            case .sgr(let parameters):
                // If we have pending text, create a span with current attributes
                if !pendingText.isEmpty {
                    spans.append(TextSpan(text: pendingText, attributes: currentAttributes))
                    pendingText = ""
                }

                // Update attributes based on SGR parameters
                currentAttributes = applySGRParameters(parameters, to: currentAttributes)

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

        var tokens: [ANSIToken] = []
        var needsReset = false

        for span in styledText.spans {
            // Generate SGR token for this span's attributes if they're not default
            if !span.attributes.isDefault {
                let sgrParameters = attributesToSGRParameters(span.attributes)
                if !sgrParameters.isEmpty {
                    tokens.append(.sgr(sgrParameters))
                    needsReset = true
                }
            }

            // Add the text content
            if !span.text.isEmpty {
                tokens.append(.text(span.text))
            }
        }

        // Add reset if we applied any styling
        if needsReset {
            tokens.append(.sgr([0]))
        }

        return tokens
    }

    /// Apply SGR parameters to text attributes
    ///
    /// This method interprets SGR parameter codes and updates the text attributes
    /// accordingly. It handles all standard SGR codes including colors and styles.
    ///
    /// - Parameters:
    ///   - parameters: SGR parameter codes
    ///   - attributes: Current text attributes to modify
    /// - Returns: Updated text attributes
    private func applySGRParameters(_ parameters: [Int], to attributes: TextAttributes) -> TextAttributes {
        var newAttributes = attributes
        var i = 0

        while i < parameters.count {
            let param = parameters[i]

            switch param {
            case 0:
                // Reset all attributes
                newAttributes = TextAttributes()

            case 1:
                // Bold
                newAttributes.bold = true

            case 2:
                // Dim
                newAttributes.dim = true

            case 3:
                // Italic
                newAttributes.italic = true

            case 4:
                // Underline
                newAttributes.underline = true

            case 7:
                // Inverse
                newAttributes.inverse = true

            case 9:
                // Strikethrough
                newAttributes.strikethrough = true

            case 22:
                // Normal intensity (turn off bold and dim)
                newAttributes.bold = false
                newAttributes.dim = false

            case 23:
                // Not italic
                newAttributes.italic = false

            case 24:
                // Not underlined
                newAttributes.underline = false

            case 27:
                // Not inverse
                newAttributes.inverse = false

            case 29:
                // Not strikethrough
                newAttributes.strikethrough = false

            case 30...37:
                // Basic foreground colors
                newAttributes.color = basicColor(from: param - 30)

            case 38:
                // Extended foreground color
                if let color = parseExtendedColor(parameters, startingAt: i) {
                    newAttributes.color = color.color
                    i = color.nextIndex - 1 // -1 because loop will increment
                }

            case 39:
                // Default foreground color
                newAttributes.color = nil

            case 40...47:
                // Basic background colors
                newAttributes.backgroundColor = basicColor(from: param - 40)

            case 48:
                // Extended background color
                if let color = parseExtendedColor(parameters, startingAt: i) {
                    newAttributes.backgroundColor = color.color
                    i = color.nextIndex - 1 // -1 because loop will increment
                }

            case 49:
                // Default background color
                newAttributes.backgroundColor = nil

            case 90...97:
                // Bright foreground colors
                newAttributes.color = brightColor(from: param - 90)

            case 100...107:
                // Bright background colors
                newAttributes.backgroundColor = brightColor(from: param - 100)

            default:
                // Unknown parameter, ignore
                break
            }

            i += 1
        }

        return newAttributes
    }

    /// Convert text attributes to SGR parameters
    ///
    /// This method generates the appropriate SGR parameter codes for the given
    /// text attributes, handling all supported styling options.
    ///
    /// - Parameter attributes: The text attributes to convert
    /// - Returns: Array of SGR parameter codes
    private func attributesToSGRParameters(_ attributes: TextAttributes) -> [Int] {
        var parameters: [Int] = []

        // Add style parameters
        if attributes.bold {
            parameters.append(1)
        }
        if attributes.dim {
            parameters.append(2)
        }
        if attributes.italic {
            parameters.append(3)
        }
        if attributes.underline {
            parameters.append(4)
        }
        if attributes.inverse {
            parameters.append(7)
        }
        if attributes.strikethrough {
            parameters.append(9)
        }

        // Add foreground color
        if let color = attributes.color {
            parameters.append(contentsOf: colorToSGRParameters(color, isBackground: false))
        }

        // Add background color
        if let backgroundColor = attributes.backgroundColor {
            parameters.append(contentsOf: colorToSGRParameters(backgroundColor, isBackground: true))
        }

        return parameters
    }

    /// Convert color to SGR parameters
    ///
    /// - Parameters:
    ///   - color: The color to convert
    ///   - isBackground: Whether this is a background color
    /// - Returns: Array of SGR parameters for the color
    private func colorToSGRParameters(_ color: ANSIColor, isBackground: Bool) -> [Int] {
        let baseOffset = isBackground ? 40 : 30
        let brightOffset = isBackground ? 100 : 90

        switch color {
        case .black:
            return [baseOffset + 0]
        case .red:
            return [baseOffset + 1]
        case .green:
            return [baseOffset + 2]
        case .yellow:
            return [baseOffset + 3]
        case .blue:
            return [baseOffset + 4]
        case .magenta:
            return [baseOffset + 5]
        case .cyan:
            return [baseOffset + 6]
        case .white:
            return [baseOffset + 7]
        case .brightBlack:
            return [brightOffset + 0]
        case .brightRed:
            return [brightOffset + 1]
        case .brightGreen:
            return [brightOffset + 2]
        case .brightYellow:
            return [brightOffset + 3]
        case .brightBlue:
            return [brightOffset + 4]
        case .brightMagenta:
            return [brightOffset + 5]
        case .brightCyan:
            return [brightOffset + 6]
        case .brightWhite:
            return [brightOffset + 7]
        case .color256(let index):
            return [isBackground ? 48 : 38, 5, index]
        case .rgb(let red, let green, let blue):
            return [isBackground ? 48 : 38, 2, red, green, blue]
        }
    }

    /// Parse extended color sequences (256-color or RGB)
    ///
    /// - Parameters:
    ///   - parameters: Full SGR parameter array
    ///   - startIndex: Index of the 38 or 48 parameter
    /// - Returns: Parsed color and next index, or nil if invalid
    private func parseExtendedColor(_ parameters: [Int], startingAt startIndex: Int) -> (color: ANSIColor, nextIndex: Int)? {
        guard startIndex + 1 < parameters.count else { return nil }

        let colorType = parameters[startIndex + 1]

        switch colorType {
        case 5:
            // 256-color palette
            guard startIndex + 2 < parameters.count else { return nil }
            let colorIndex = parameters[startIndex + 2]
            guard colorIndex >= 0 && colorIndex <= 255 else { return nil }
            return (.color256(colorIndex), startIndex + 3)

        case 2:
            // RGB color
            guard startIndex + 4 < parameters.count else { return nil }
            let red = parameters[startIndex + 2]
            let green = parameters[startIndex + 3]
            let blue = parameters[startIndex + 4]
            guard red >= 0 && red <= 255 &&
                  green >= 0 && green <= 255 &&
                  blue >= 0 && blue <= 255 else { return nil }
            return (.rgb(red, green, blue), startIndex + 5)

        default:
            return nil
        }
    }

    /// Convert basic color index to ANSIColor
    ///
    /// - Parameter index: Color index (0-7)
    /// - Returns: Corresponding ANSIColor
    private func basicColor(from index: Int) -> ANSIColor {
        switch index {
        case 0: return .black
        case 1: return .red
        case 2: return .green
        case 3: return .yellow
        case 4: return .blue
        case 5: return .magenta
        case 6: return .cyan
        case 7: return .white
        default: return .white
        }
    }

    /// Convert bright color index to ANSIColor
    ///
    /// - Parameter index: Color index (0-7)
    /// - Returns: Corresponding bright ANSIColor
    private func brightColor(from index: Int) -> ANSIColor {
        switch index {
        case 0: return .brightBlack
        case 1: return .brightRed
        case 2: return .brightGreen
        case 3: return .brightYellow
        case 4: return .brightBlue
        case 5: return .brightMagenta
        case 6: return .brightCyan
        case 7: return .brightWhite
        default: return .brightWhite
        }
    }
}
