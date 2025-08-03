/// East Asian Width property implementation according to UAX #11
///
/// This module implements the Unicode East Asian Width property as defined in
/// Unicode Standard Annex #11 (UAX #11). This property is essential for
/// determining the display width of characters in East Asian typography
/// and terminal applications.
///
/// ## East Asian Width Categories
/// - **Fullwidth (F)**: Characters that are typically rendered as wide in East Asian contexts
/// - **Halfwidth (H)**: Characters that are typically rendered as narrow in East Asian contexts
/// - **Wide (W)**: Characters that are wide in East Asian contexts and narrow elsewhere
/// - **Narrow (Na)**: Characters that are narrow in East Asian contexts and narrow elsewhere
/// - **Ambiguous (A)**: Characters that can be either wide or narrow depending on context
/// - **Neutral (N)**: Characters that do not occur in East Asian text
///
/// ## Terminal Display Rules
/// For terminal applications, the width mapping is:
/// - Fullwidth (F) → 2 columns
/// - Wide (W) → 2 columns
/// - Halfwidth (H) → 1 column
/// - Narrow (Na) → 1 column
/// - Neutral (N) → 1 column
/// - Ambiguous (A) → 1 column (in most terminal contexts)

import Foundation

/// East Asian Width categories as defined by UAX #11
public enum EastAsianWidthCategory: String, CaseIterable {
    case fullwidth = "F"
    case halfwidth = "H"
    case wide = "W"
    case narrow = "Na"
    case ambiguous = "A"
    case neutral = "N"

    /// Get the terminal display width for this category
    /// - Returns: Number of terminal columns (1 or 2)
    public var terminalWidth: Int {
        switch self {
        case .fullwidth, .wide:
            2
        case .halfwidth, .narrow, .ambiguous, .neutral:
            1
        }
    }
}

/// East Asian Width property lookup and utilities
public enum EastAsianWidth {
    /// Get the East Asian Width category for a Unicode scalar
    /// - Parameter scalar: The Unicode scalar to categorize
    /// - Returns: The East Asian Width category
    public static func category(of scalar: Unicode.Scalar) -> EastAsianWidthCategory {
        let codePoint = scalar.value

        // Check fullwidth and wide ranges first (most common for width 2)
        if isFullwidthOrWide(codePoint) {
            return isFullwidth(codePoint) ? .fullwidth : .wide
        }

        // Check halfwidth range
        if isHalfwidth(codePoint) {
            return .halfwidth
        }

        // Check ambiguous ranges
        if isAmbiguous(codePoint) {
            return .ambiguous
        }

        // Default to narrow for most characters
        return .narrow
    }

    /// Get the terminal display width based on East Asian Width property
    /// - Parameter scalar: The Unicode scalar to measure
    /// - Returns: Number of terminal columns (1 or 2)
    public static func terminalWidth(of scalar: Unicode.Scalar) -> Int {
        category(of: scalar).terminalWidth
    }

    // MARK: - Private Range Checks

    /// Check if a code point is in Fullwidth category
    private static func isFullwidth(_ codePoint: UInt32) -> Bool {
        // Fullwidth ASCII variants (U+FF01-U+FF5E)
        if codePoint >= 0xFF01, codePoint <= 0xFF5E {
            return true
        }

        // Fullwidth symbol variants (U+FFE0-U+FFE6)
        if codePoint >= 0xFFE0, codePoint <= 0xFFE6 {
            return true
        }

        return false
    }

    /// Check if a code point is in Wide category
    private static func isWide(_ codePoint: UInt32) -> Bool {
        // CJK Unified Ideographs (U+4E00-U+9FFF)
        if codePoint >= 0x4E00, codePoint <= 0x9FFF {
            return true
        }

        // CJK Unified Ideographs Extension A (U+3400-U+4DBF)
        if codePoint >= 0x3400, codePoint <= 0x4DBF {
            return true
        }

        // Hangul Syllables (U+AC00-U+D7AF)
        if codePoint >= 0xAC00, codePoint <= 0xD7AF {
            return true
        }

        // Hiragana (U+3040-U+309F)
        if codePoint >= 0x3040, codePoint <= 0x309F {
            return true
        }

        // Katakana (U+30A0-U+30FF)
        if codePoint >= 0x30A0, codePoint <= 0x30FF {
            return true
        }

        // CJK Symbols and Punctuation (U+3000-U+303F)
        if codePoint >= 0x3000, codePoint <= 0x303F {
            return true
        }

        // Enclosed CJK Letters and Months (U+3200-U+32FF)
        if codePoint >= 0x3200, codePoint <= 0x32FF {
            return true
        }

        // CJK Compatibility (U+3300-U+33FF)
        if codePoint >= 0x3300, codePoint <= 0x33FF {
            return true
        }

        // CJK Unified Ideographs Extension B (U+20000-U+2A6DF)
        if codePoint >= 0x20000, codePoint <= 0x2A6DF {
            return true
        }

        // CJK Unified Ideographs Extension C (U+2A700-U+2B73F)
        if codePoint >= 0x2A700, codePoint <= 0x2B73F {
            return true
        }

        // CJK Unified Ideographs Extension D (U+2B740-U+2B81F)
        if codePoint >= 0x2B740, codePoint <= 0x2B81F {
            return true
        }

        // CJK Unified Ideographs Extension E (U+2B820-U+2CEAF)
        if codePoint >= 0x2B820, codePoint <= 0x2CEAF {
            return true
        }

        // CJK Unified Ideographs Extension F (U+2CEB0-U+2EBEF)
        if codePoint >= 0x2CEB0, codePoint <= 0x2EBEF {
            return true
        }

        return false
    }

    /// Check if a code point is Fullwidth or Wide
    private static func isFullwidthOrWide(_ codePoint: UInt32) -> Bool {
        isFullwidth(codePoint) || isWide(codePoint)
    }

    /// Check if a code point is in Halfwidth category
    private static func isHalfwidth(_ codePoint: UInt32) -> Bool {
        // Halfwidth Katakana variants (U+FF65-U+FF9F)
        if codePoint >= 0xFF65, codePoint <= 0xFF9F {
            return true
        }

        // Halfwidth Hangul variants (U+FFA0-U+FFDC)
        if codePoint >= 0xFFA0, codePoint <= 0xFFDC {
            return true
        }

        return false
    }

    /// Check if a code point is in Ambiguous category
    private static func isAmbiguous(_ codePoint: UInt32) -> Bool {
        // Greek and Coptic (selected characters)
        if codePoint >= 0x0391, codePoint <= 0x03A9 {
            return true // Greek capital letters
        }
        if codePoint >= 0x03B1, codePoint <= 0x03C9 {
            return true // Greek small letters
        }

        // Cyrillic (selected characters)
        if codePoint >= 0x0401, codePoint <= 0x044F {
            return true
        }

        // Box Drawing (U+2500-U+257F)
        if codePoint >= 0x2500, codePoint <= 0x257F {
            return true
        }

        // Block Elements (U+2580-U+259F)
        if codePoint >= 0x2580, codePoint <= 0x259F {
            return true
        }

        return false
    }
}
