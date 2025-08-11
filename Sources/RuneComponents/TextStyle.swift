import RuneANSI

/// Effects for Text styling
public struct TextEffect: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let bold = TextEffect(rawValue: 1 << 0)
    public static let italic = TextEffect(rawValue: 1 << 1)
    public static let underline = TextEffect(rawValue: 1 << 2)
    public static let inverse = TextEffect(rawValue: 1 << 3)
    public static let strikethrough = TextEffect(rawValue: 1 << 4)
    public static let dim = TextEffect(rawValue: 1 << 5)
}

/// Composable style abstraction for Text
public struct TextStyle: Equatable, Hashable, Sendable {
    public var foreground: ANSIColor?
    public var background: ANSIColor?
    public var effects: TextEffect

    public init(foreground: ANSIColor? = nil, background: ANSIColor? = nil, effects: TextEffect = []) {
        self.foreground = foreground
        self.background = background
        self.effects = effects
    }

    /// Overlay another style; "last wins" semantics
    public func overlay(_ other: TextStyle) -> TextStyle {
        TextStyle(
            foreground: other.foreground ?? foreground,
            background: other.background ?? background,
            effects: effects.union(other.effects),
        )
    }

    /// Convert to TextAttributes
    public var attributes: TextAttributes {
        TextAttributes(
            color: foreground,
            backgroundColor: background,
            bold: effects.contains(.bold),
            italic: effects.contains(.italic),
            underline: effects.contains(.underline),
            inverse: effects.contains(.inverse),
            strikethrough: effects.contains(.strikethrough),
            dim: effects.contains(.dim),
        )
    }
}

/// Simple theme with base and accent styles
public struct Theme: Equatable, Hashable {
    public var base: TextStyle
    public var accent: TextStyle
    public init(base: TextStyle, accent: TextStyle) {
        self.base = base
        self.accent = accent
    }
}
