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

// Platform-specific wcwidth availability
#if canImport(Darwin)
private let kWcwidthAvailable = true
#else
// wcwidth may not be available on all Linux distributions
private let kWcwidthAvailable = false
#endif

public enum Width {
    /// Calculate the display width of a string in terminal columns
    /// - Parameter string: The string to measure
    /// - Returns: Number of terminal columns the string will occupy
    public static func displayWidth(of string: String) -> Int {
        // Fast path: no ANSI SGR sequences
        if !string.contains("\u{001B}[") {
            // Fast path A: if the string is pure ASCII, count bytes directly without grapheme iteration
            var allASCII = true
            for byte in string.utf8 where byte >= 0x80 { allASCII = false; break }
            if allASCII {
                var width = 0
                for byte in string.utf8 {
                    if byte >= 0x20 && byte <= 0x7E {
                        width &+= 1
                    } else if byte == 0x09 {
                        width &+= 1 // TAB
                    }
                    // other controls contribute 0
                }
                return width
            }
            var totalWidth = 0
            for cluster in string {
                totalWidth += displayWidth(of: cluster)
            }
            return totalWidth
        }
        // Strip ANSI SGR sequences (ESC '[' ... 'm') before measuring
        let stripped = Self.stripANSISGR(from: string)
        var totalWidth = 0
        for cluster in stripped {
            totalWidth += displayWidth(of: cluster)
        }
        return totalWidth
    }

    /// Calculate the display width of an extended grapheme cluster
    /// - Parameter cluster: The extended grapheme cluster to measure
    /// - Returns: Number of terminal columns the cluster will occupy
    public static func displayWidth(of cluster: Character) -> Int {
        let scalars = Array(cluster.unicodeScalars)

        // Check if this is an emoji sequence first
        if let emojiWidth = EmojiWidth.emojiWidth(of: scalars) {
            return emojiWidth
        }

        // Single scalar case - use enhanced width calculation
        if scalars.count == 1 {
            return displayWidthEnhanced(of: scalars[0])
        }

        // Multi-scalar case - check for combining characters
        // If we have combining characters, the base character determines width
        var baseWidth = 0
        var hasCombining = false

        for scalar in scalars {
            if UnicodeCategories.isCombining(scalar) {
                hasCombining = true
                // Combining characters don't add to width
                continue
            }
            // Non-combining character
            baseWidth += displayWidthEnhanced(of: scalar)
        }

        // If we had combining characters, return the base width
        if hasCombining {
            return baseWidth
        }

        // Fallback: sum all scalar widths
        var totalWidth = 0
        for scalar in scalars {
            totalWidth += displayWidthEnhanced(of: scalar)
        }

        return totalWidth
    }

    // Helper lives inside Width to keep access control simple
    private static func stripANSISGR(from string: String) -> String {
        var result = String.UnicodeScalarView()
        var iter = string.unicodeScalars.makeIterator()
        while let scalar = iter.next() {
            if scalar.value == 0x1B { // ESC
                if let bracket = iter.next(), bracket.value == 0x5B { // '['
                    while let parameterScalar = iter.next() {
                        if parameterScalar.value == 0x6D { break }
                    }
                    continue
                } else {
                    result.append(scalar)
                    continue
                }
            } else {
                result.append(scalar)
            }
        }
        return String(result)
    }

    /// Calculate the display width of a single Unicode scalar (legacy method)
    /// - Parameter scalar: The Unicode scalar to measure
    /// - Returns: Number of terminal columns (0, 1, or 2)
    public static func displayWidth(of scalar: Unicode.Scalar) -> Int {
        displayWidthEnhanced(of: scalar)
    }

    /// Enhanced display width calculation with East Asian Width support
    /// - Parameter scalar: The Unicode scalar to measure
    /// - Returns: Number of terminal columns (0, 1, or 2)
    private static func displayWidthEnhanced(of scalar: Unicode.Scalar) -> Int {
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

        // Check East Asian Width property first for accurate CJK/fullwidth handling
        let eastAsianWidth = EastAsianWidth.terminalWidth(of: scalar)
        if eastAsianWidth == 2 {
            return 2
        }

        // Use wcwidth for baseline width calculation if available
        if kWcwidthAvailable {
            #if canImport(Darwin)
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
            #endif
        }

        // Fallback implementation when wcwidth is not available (e.g., Linux)
        return fallbackWidthCalculation(codePoint)
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
        // Check zero-width combining marks first
        if let width = checkCombiningMarks(codePoint) {
            return width
        }

        // Check other character ranges
        return checkOtherRanges(codePoint)
    }

    /// Check combining marks that have zero width
    private static func checkCombiningMarks(_ codePoint: UInt32) -> Int? {
        if (codePoint >= 0x0300 && codePoint <= 0x036F) || // Combining Diacritical Marks
            (codePoint >= 0x1AB0 && codePoint <= 0x1AFF) || // Combining Diacritical Marks Extended
            (codePoint >= 0x1DC0 && codePoint <= 0x1DFF) || // Combining Diacritical Marks Supplement
            (codePoint >= 0xFE20 && codePoint <= 0xFE2F) { // Combining Half Marks
            return 0
        }
        return nil
    }

    /// Check other character ranges for width
    private static func checkOtherRanges(_ codePoint: UInt32) -> Int {
        // CJK Symbols and Punctuation (U+3000-U+303F)
        if codePoint >= 0x3000, codePoint <= 0x303F {
            return codePoint == 0x3000 ? 2 : 1 // U+3000 IDEOGRAPHIC SPACE is wide
        }

        // Latin-1 Supplement (U+00A0-U+00FF)
        if codePoint >= 0x00A0, codePoint <= 0x00FF {
            return 1
        }

        // General Punctuation (U+2000-U+206F)
        if codePoint >= 0x2000, codePoint <= 0x206F {
            return checkGeneralPunctuation(codePoint)
        }

        // DEL character
        if codePoint == 0x7F {
            return 0
        }

        // Default fallback
        return 1
    }

    /// Check General Punctuation range for zero-width characters
    private static func checkGeneralPunctuation(_ codePoint: UInt32) -> Int {
        if (codePoint >= 0x200B && codePoint <= 0x200F) || // Zero-width spaces
            (codePoint >= 0x202A && codePoint <= 0x202E) || // Bidirectional format characters
            (codePoint >= 0x2060 && codePoint <= 0x2064) { // Invisible characters
            return 0
        }
        return 1
    }

    /// Fallback width calculation when wcwidth is not available
    /// - Parameter codePoint: The Unicode code point
    /// - Returns: The display width (0, 1, or 2)
    private static func fallbackWidthCalculation(_ codePoint: UInt32) -> Int {
        // Check basic ASCII and control characters first
        if let width = checkBasicCharacters(codePoint) {
            return width
        }

        // Check combining marks (zero width)
        if checkCombiningMarks(codePoint) != nil {
            return 0
        }

        // Check wide characters (CJK, etc.)
        if let width = checkWideCharacters(codePoint) {
            return width
        }

        // Check other character ranges
        return checkOtherCharacterRanges(codePoint)
    }

    /// Check basic ASCII and control characters
    private static func checkBasicCharacters(_ codePoint: UInt32) -> Int? {
        // Basic ASCII printable characters
        if codePoint >= 0x20, codePoint <= 0x7E {
            return 1
        }

        // Control characters
        if codePoint < 0x20 || codePoint == 0x7F || (codePoint >= 0x80 && codePoint < 0xA0) {
            return codePoint == 0x09 ? 1 : 0 // TAB has width 1, others are 0
        }

        return nil
    }

    /// Check wide characters (CJK scripts)
    private static func checkWideCharacters(_ codePoint: UInt32) -> Int? {
        // CJK Unified Ideographs
        if codePoint >= 0x4E00, codePoint <= 0x9FFF {
            return 2
        }

        // CJK Symbols and Punctuation
        if codePoint >= 0x3000, codePoint <= 0x303F {
            return codePoint == 0x3000 ? 2 : 1 // IDEOGRAPHIC SPACE is wide
        }

        // Hangul, Hiragana, Katakana
        if (codePoint >= 0xAC00 && codePoint <= 0xD7AF) || // Hangul Syllables
            (codePoint >= 0x3040 && codePoint <= 0x309F) || // Hiragana
            (codePoint >= 0x30A0 && codePoint <= 0x30FF) { // Katakana
            return 2
        }

        return nil
    }

    /// Check other character ranges
    private static func checkOtherCharacterRanges(_ codePoint: UInt32) -> Int {
        // Latin-1 Supplement
        if codePoint >= 0x00A0, codePoint <= 0x00FF {
            return 1
        }

        // General Punctuation
        if codePoint >= 0x2000, codePoint <= 0x206F {
            return checkGeneralPunctuation(codePoint)
        }

        // Default: assume width 1
        return 1
    }
}
