/// ANSI color representation for terminal styling
///
/// This module provides comprehensive color support for ANSI escape sequences,
/// including basic colors, 256-color palette, and full RGB colors.

/// Represents a color in ANSI escape sequences
///
/// This enum covers all standard ANSI color representations including
/// basic 16 colors, 256-color palette, and full RGB colors.
public enum ANSIColor: Equatable, Hashable, Sendable {
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
