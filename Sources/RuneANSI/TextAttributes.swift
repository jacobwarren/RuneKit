/// Text styling attributes for ANSI-aware text representation
///
/// This module provides the TextAttributes structure that represents
/// all styling attributes that can be controlled via ANSI SGR codes.

/// Text styling attributes that can be applied to text spans
///
/// This structure represents all the styling attributes that can be
/// controlled via ANSI SGR (Select Graphic Rendition) codes.
public struct TextAttributes: Equatable, Hashable {
    /// Foreground text color
    public var color: ANSIColor?

    /// Background text color
    public var backgroundColor: ANSIColor?

    /// Bold/bright text
    public var bold: Bool

    /// Italic text
    public var italic: Bool

    /// Underlined text
    public var underline: Bool

    /// Inverse/reverse video (swap foreground and background)
    public var inverse: Bool

    /// Strikethrough text
    public var strikethrough: Bool

    /// Dim/faint text
    public var dim: Bool

    /// Initialize text attributes with default values
    ///
    /// - Parameters:
    ///   - color: Foreground color (default: nil)
    ///   - backgroundColor: Background color (default: nil)
    ///   - bold: Bold styling (default: false)
    ///   - italic: Italic styling (default: false)
    ///   - underline: Underline styling (default: false)
    ///   - inverse: Inverse styling (default: false)
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
        dim: Bool = false,
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

    /// Check if these attributes represent default (unstyled) text
    ///
    /// - Returns: true if all attributes are in their default state
    public var isDefault: Bool {
        color == nil &&
            backgroundColor == nil &&
            !bold &&
            !italic &&
            !underline &&
            !inverse &&
            !strikethrough &&
            !dim
    }
}
