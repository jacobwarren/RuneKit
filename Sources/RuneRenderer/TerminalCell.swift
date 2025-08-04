import Foundation
import RuneUnicode

/// Represents a single cell in the terminal grid with full attribute support
public struct TerminalCell: Sendable, Equatable, Hashable {
    /// The grapheme cluster content of this cell
    public let content: String

    /// Foreground color (24-bit RGB or ANSI color index)
    public let foreground: TerminalColor?

    /// Background color (24-bit RGB or ANSI color index)
    public let background: TerminalColor?

    /// Text attributes (bold, italic, underline, etc.)
    public let attributes: TerminalAttributes

    /// Width of this cell (1 for normal, 2 for wide characters, 0 for combining)
    public let width: Int

    /// Create a new terminal cell
    /// - Parameters:
    ///   - content: The grapheme cluster content
    ///   - foreground: Foreground color
    ///   - background: Background color
    ///   - attributes: Text attributes
    public init(
        content: String = " ",
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        attributes: TerminalAttributes = .none
    ) {
        self.content = content
        self.foreground = foreground
        self.background = background
        self.attributes = attributes

        // Calculate width using Unicode width rules
        if content.isEmpty {
            self.width = 0
        } else {
            // Use RuneUnicode for proper grapheme cluster width calculation
            self.width = max(1, Width.displayWidth(of: content))
        }
    }

    /// Create an empty cell
    public static let empty = TerminalCell()

    /// Check if this cell is effectively empty (space with no attributes)
    public var isEmpty: Bool {
        return content.trimmingCharacters(in: .whitespaces).isEmpty &&
            foreground == nil &&
            background == nil &&
            attributes == .none
    }

    /// Generate the ANSI escape sequence to render this cell
    /// - Parameter previousState: The previous terminal state for optimization
    /// - Returns: ANSI sequence and new terminal state
    public func renderSequence(from previousState: TerminalState) -> (sequence: String, newState: TerminalState) {
        var sequence = ""
        var newState = previousState

        // Handle foreground color changes
        if foreground != previousState.foreground {
            if let fg = foreground {
                sequence += fg.foregroundSequence
            } else {
                sequence += TerminalColor.resetForeground
            }
            newState.foreground = foreground
        }

        // Handle background color changes
        if background != previousState.background {
            if let bg = background {
                sequence += bg.backgroundSequence
            } else {
                sequence += TerminalColor.resetBackground
            }
            newState.background = background
        }

        // Handle attribute changes
        let attributeSequence = attributes.transitionSequence(from: previousState.attributes)
        if !attributeSequence.isEmpty {
            sequence += attributeSequence
            newState.attributes = attributes
        }

        // Add the content
        sequence += content

        return (sequence, newState)
    }
}

/// Represents terminal colors (ANSI or RGB)
public enum TerminalColor: Sendable, Equatable, Hashable {
    case ansi(UInt8)           // 0-255 ANSI colors
    case rgb(UInt8, UInt8, UInt8)  // 24-bit RGB

    /// ANSI escape sequence for foreground color
    public var foregroundSequence: String {
        switch self {
        case .ansi(let code):
            if code < 8 {
                return "\u{001B}[\(30 + code)m"
            } else if code < 16 {
                return "\u{001B}[\(90 + code - 8)m"
            } else {
                return "\u{001B}[38;5;\(code)m"
            }
        case let .rgb(red, green, blue):
            return "\u{001B}[38;2;\(red);\(green);\(blue)m"
        }
    }

    /// ANSI escape sequence for background color
    public var backgroundSequence: String {
        switch self {
        case .ansi(let code):
            if code < 8 {
                return "\u{001B}[\(40 + code)m"
            } else if code < 16 {
                return "\u{001B}[\(100 + code - 8)m"
            } else {
                return "\u{001B}[48;5;\(code)m"
            }
        case let .rgb(red, green, blue):
            return "\u{001B}[48;2;\(red);\(green);\(blue)m"
        }
    }

    /// Reset foreground color
    public static let resetForeground = "\u{001B}[39m"

    /// Reset background color
    public static let resetBackground = "\u{001B}[49m"

    // Common colors
    public static let black = TerminalColor.ansi(0)
    public static let red = TerminalColor.ansi(1)
    public static let green = TerminalColor.ansi(2)
    public static let yellow = TerminalColor.ansi(3)
    public static let blue = TerminalColor.ansi(4)
    public static let magenta = TerminalColor.ansi(5)
    public static let cyan = TerminalColor.ansi(6)
    public static let white = TerminalColor.ansi(7)
}

/// Terminal text attributes
public struct TerminalAttributes: OptionSet, Sendable, Equatable, Hashable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let none = TerminalAttributes([])
    public static let bold = TerminalAttributes(rawValue: 1 << 0)
    public static let dim = TerminalAttributes(rawValue: 1 << 1)
    public static let italic = TerminalAttributes(rawValue: 1 << 2)
    public static let underline = TerminalAttributes(rawValue: 1 << 3)
    public static let blink = TerminalAttributes(rawValue: 1 << 4)
    public static let reverse = TerminalAttributes(rawValue: 1 << 5)
    public static let strikethrough = TerminalAttributes(rawValue: 1 << 6)

    /// Generate ANSI sequence to transition from one attribute set to another
    public func transitionSequence(from previous: TerminalAttributes) -> String {
        if self == previous {
            return ""
        }

        var sequence = ""

        // If we need to remove any attributes, reset all and reapply
        let removed = previous.subtracting(self)
        if !removed.isEmpty {
            sequence += "\u{001B}[0m"  // Reset all
            // Now apply all current attributes
            sequence += self.enableSequence
        } else {
            // Only add new attributes
            let added = self.subtracting(previous)
            sequence += added.enableSequence
        }

        return sequence
    }

    /// ANSI sequence to enable these attributes
    private var enableSequence: String {
        var codes: [String] = []

        if contains(.bold) { codes.append("1") }
        if contains(.dim) { codes.append("2") }
        if contains(.italic) { codes.append("3") }
        if contains(.underline) { codes.append("4") }
        if contains(.blink) { codes.append("5") }
        if contains(.reverse) { codes.append("7") }
        if contains(.strikethrough) { codes.append("9") }

        return codes.isEmpty ? "" : "\u{001B}[\(codes.joined(separator: ";"))m"
    }
}

/// Tracks the current terminal state for SGR optimization
public struct TerminalState: Sendable, Equatable {
    public var foreground: TerminalColor?
    public var background: TerminalColor?
    public var attributes: TerminalAttributes

    public init(
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        attributes: TerminalAttributes = .none
    ) {
        self.foreground = foreground
        self.background = background
        self.attributes = attributes
    }

    /// Reset to default state
    public static let `default` = TerminalState()

    /// Reset sequence to return to default state
    public static let resetSequence = "\u{001B}[0m"
}
