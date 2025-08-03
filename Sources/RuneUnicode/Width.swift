/// Utilities for calculating display width of Unicode strings
///
/// This module handles the complex task of determining how many terminal
/// columns a string will occupy when displayed. This is non-trivial due to:
/// - Emoji that can be 1 or 2 columns wide
/// - CJK characters that are 2 columns wide
/// - Zero-width joiners and combining characters
/// - Control characters that have no width

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

public enum Width {
    /// Calculate the display width of a string in terminal columns
    /// - Parameter string: The string to measure
    /// - Returns: Number of terminal columns the string will occupy
    public static func displayWidth(of string: String) -> Int {
        var totalWidth = 0

        for scalar in string.unicodeScalars {
            totalWidth += displayWidth(of: scalar)
        }

        return totalWidth
    }

    /// Calculate the display width of a single Unicode scalar
    /// - Parameter scalar: The Unicode scalar to measure
    /// - Returns: Number of terminal columns (0, 1, or 2)
    public static func displayWidth(of scalar: Unicode.Scalar) -> Int {
        let codePoint = scalar.value

        // Handle special cases first before calling wcwidth

        // Control characters (C0 and C1 control sets)
        if (codePoint < 0x20) || (codePoint >= 0x7F && codePoint < 0xA0) {
            // Special case: TAB should have width 1 for terminal display
            if codePoint == 0x09 { // TAB
                return 1
            }
            return 0 // Other control characters have zero width
        }

        // Use wcwidth for baseline width calculation
        let result = wcwidth(wchar_t(codePoint))

        // wcwidth returns:
        // -1 for non-printable characters
        //  0 for zero-width characters
        //  1 for normal width characters
        //  2 for wide characters (CJK, etc.)
        switch result {
        case -1:
            // wcwidth returned -1, but we need to handle some cases manually
            return handleUnrecognizedCharacter(codePoint)
        case 0:
            return 0 // Zero-width characters (combining marks, etc.)
        case 1:
            return 1 // Normal width
        case 2:
            return 2 // Wide characters
        default:
            // Fallback for unexpected values
            return max(0, Int(result))
        }
    }

    /// Check if a Unicode scalar is a zero-width character
    /// - Parameter scalar: The Unicode scalar to check
    /// - Returns: True if the character has zero display width
    public static func isZeroWidth(_ scalar: Unicode.Scalar) -> Bool {
        displayWidth(of: scalar) == 0
    }

    /// Check if a Unicode scalar is wide (2 columns)
    /// - Parameter scalar: The Unicode scalar to check
    /// - Returns: True if the character occupies 2 terminal columns
    public static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        displayWidth(of: scalar) == 2
    }

    /// Handle characters that wcwidth doesn't recognize (returns -1)
    /// - Parameter codePoint: The Unicode code point
    /// - Returns: The display width (0, 1, or 2)
    private static func handleUnrecognizedCharacter(_ codePoint: UInt32) -> Int {
        // Combining Diacritical Marks (U+0300-U+036F)
        if codePoint >= 0x0300, codePoint <= 0x036F {
            return 0
        }

        // Combining Diacritical Marks Extended (U+1AB0-U+1AFF)
        if codePoint >= 0x1AB0, codePoint <= 0x1AFF {
            return 0
        }

        // Combining Diacritical Marks Supplement (U+1DC0-U+1DFF)
        if codePoint >= 0x1DC0, codePoint <= 0x1DFF {
            return 0
        }

        // Combining Half Marks (U+FE20-U+FE2F)
        if codePoint >= 0xFE20, codePoint <= 0xFE2F {
            return 0
        }

        // CJK Symbols and Punctuation (U+3000-U+303F)
        if codePoint >= 0x3000, codePoint <= 0x303F {
            // U+3000 IDEOGRAPHIC SPACE is wide
            if codePoint == 0x3000 {
                return 2
            }
            return 1
        }

        // Latin-1 Supplement (U+00A0-U+00FF)
        if codePoint >= 0x00A0, codePoint <= 0x00FF {
            return 1
        }

        // General Punctuation (U+2000-U+206F)
        if codePoint >= 0x2000, codePoint <= 0x206F {
            // Zero-width spaces and format characters
            if codePoint >= 0x200B, codePoint <= 0x200F {
                return 0 // Zero-width spaces
            }
            if codePoint >= 0x202A, codePoint <= 0x202E {
                return 0 // Bidirectional format characters
            }
            if codePoint >= 0x2060, codePoint <= 0x2064 {
                return 0 // Invisible characters
            }
            return 1
        }

        // For other unrecognized characters, check if they're in the Basic Latin range
        // that should be control characters
        if codePoint == 0x7F {
            return 0 // DEL character
        }

        // Default fallback for other unrecognized characters
        return 1
    }
}
