/// Emoji width calculation for complex emoji sequences
///
/// This module handles the complex task of determining display width for emoji,
/// including multi-scalar sequences like ZWJ sequences, flag emojis, keycap sequences,
/// and other complex emoji that should be treated as single display units.
///
/// ## Emoji Categories for Width Calculation
/// - **Simple emoji**: Single scalar emoji (👍, 😀, etc.) → width 2
/// - **ZWJ sequences**: Multiple emoji joined with ZWJ (👨‍👩‍👧‍👦) → width 2
/// - **Flag emoji**: Regional indicator pairs (🇯🇵) → width 2
/// - **Keycap sequences**: Digit/symbol + variation selector + keycap (1️⃣) → width 2
/// - **Modifier sequences**: Base emoji + skin tone modifier (👋🏽) → width 2
/// - **Tag sequences**: Base emoji + tag characters (🏴󠁧󠁢󠁳󠁣󠁴󠁿) → width 2
///
/// ## Implementation Strategy
/// The key insight is that complex emoji sequences should be treated as single
/// grapheme clusters with width 2, regardless of how many Unicode scalars they contain.

import Foundation

/// Emoji width calculation utilities
public enum EmojiWidth {
    /// Calculate the display width of an emoji sequence
    /// - Parameter scalars: Array of Unicode scalars forming the emoji
    /// - Returns: Display width (0, 1, or 2) or nil if not an emoji sequence
    public static func emojiWidth(of scalars: [Unicode.Scalar]) -> Int? {
        guard !scalars.isEmpty else { return nil }

        // Single scalar emoji
        if scalars.count == 1 {
            return singleEmojiWidth(scalars[0])
        }

        // Multi-scalar emoji sequences
        return multiScalarEmojiWidth(scalars)
    }

    /// Check if a sequence of scalars forms a valid emoji
    /// - Parameter scalars: Array of Unicode scalars to check
    /// - Returns: True if this is a valid emoji sequence
    public static func isEmojiSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        emojiWidth(of: scalars) != nil
    }

    // MARK: - Single Scalar Emoji

    /// Calculate width for single scalar emoji
    /// - Parameter scalar: The Unicode scalar to check
    /// - Returns: Width (2) if it's an emoji, nil otherwise
    private static func singleEmojiWidth(_ scalar: Unicode.Scalar) -> Int? {
        let codePoint = scalar.value

        // Basic emoji ranges that should have width 2
        if isBasicEmoji(codePoint) {
            return 2
        }

        // Check if it's an emoji using Unicode properties
        if UnicodeCategories.isEmojiScalar(scalar) {
            return 2
        }

        return nil
    }

    /// Check if a code point is in basic emoji ranges
    /// - Parameter codePoint: The Unicode code point to check
    /// - Returns: True if it's a basic emoji
    private static func isBasicEmoji(_ codePoint: UInt32) -> Bool {
        // Emoticons (U+1F600-U+1F64F)
        if codePoint >= 0x1F600, codePoint <= 0x1F64F {
            return true
        }

        // Miscellaneous Symbols and Pictographs (U+1F300-U+1F5FF)
        if codePoint >= 0x1F300, codePoint <= 0x1F5FF {
            return true
        }

        // Transport and Map Symbols (U+1F680-U+1F6FF)
        if codePoint >= 0x1F680, codePoint <= 0x1F6FF {
            return true
        }

        // Supplemental Symbols and Pictographs (U+1F900-U+1F9FF)
        if codePoint >= 0x1F900, codePoint <= 0x1F9FF {
            return true
        }

        // Symbols and Pictographs Extended-A (U+1FA70-U+1FAFF)
        if codePoint >= 0x1FA70, codePoint <= 0x1FAFF {
            return true
        }

        return false
    }

    // MARK: - Multi-Scalar Emoji Sequences

    /// Calculate width for multi-scalar emoji sequences
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: Width (2) if it's a valid emoji sequence, nil otherwise
    private static func multiScalarEmojiWidth(_ scalars: [Unicode.Scalar]) -> Int? {
        // ZWJ sequences (Zero Width Joiner)
        if isZWJSequence(scalars) {
            return 2
        }

        // Flag emoji (Regional Indicator pairs)
        if isFlagEmoji(scalars) {
            return 2
        }

        // Keycap sequences
        if isKeycapSequence(scalars) {
            return 2
        }

        // Modifier sequences (skin tone, etc.)
        if isModifierSequence(scalars) {
            return 2
        }

        // Tag sequences
        if isTagSequence(scalars) {
            return 2
        }

        return nil
    }

    /// Check if scalars form a ZWJ (Zero Width Joiner) sequence
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: True if this is a valid ZWJ sequence
    private static func isZWJSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        // Must have at least 3 scalars: emoji + ZWJ + emoji
        guard scalars.count >= 3 else { return false }

        // Check for ZWJ characters (U+200D)
        let hasZWJ = scalars.contains { $0.value == 0x200D }
        guard hasZWJ else { return false }

        // Check that non-ZWJ scalars are emoji or emoji-related
        for scalar in scalars {
            let codePoint = scalar.value

            // Skip ZWJ and variation selectors
            if codePoint == 0x200D || (codePoint >= 0xFE00 && codePoint <= 0xFE0F) {
                continue
            }

            // Must be emoji or emoji-related
            if !isBasicEmoji(codePoint), !UnicodeCategories.isEmojiScalar(scalar) {
                return false
            }
        }

        return true
    }

    /// Check if scalars form a flag emoji (Regional Indicator pair)
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: True if this is a valid flag emoji
    private static func isFlagEmoji(_ scalars: [Unicode.Scalar]) -> Bool {
        // Flag emoji are exactly 2 Regional Indicator symbols
        guard scalars.count == 2 else { return false }

        // Both must be Regional Indicator symbols (U+1F1E6-U+1F1FF)
        for scalar in scalars {
            let codePoint = scalar.value
            if !(codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF) {
                return false
            }
        }

        return true
    }

    /// Check if scalars form a keycap sequence
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: True if this is a valid keycap sequence
    private static func isKeycapSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        // Keycap sequences: base + variation selector + combining enclosing keycap
        guard scalars.count == 3 else { return false }

        let codePoints = scalars.map(\.value)

        // Pattern: digit/symbol + U+FE0F + U+20E3
        if codePoints[1] == 0xFE0F, codePoints[2] == 0x20E3 {
            let base = codePoints[0]
            // Valid bases: 0-9, *, #
            if (base >= 0x30 && base <= 0x39) || base == 0x2A || base == 0x23 {
                return true
            }
        }

        return false
    }

    /// Check if scalars form a modifier sequence (e.g., skin tone)
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: True if this is a valid modifier sequence
    private static func isModifierSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        guard scalars.count == 2 else { return false }

        let base = scalars[0].value
        let modifier = scalars[1].value

        // Base must be emoji
        if !isBasicEmoji(base), !UnicodeCategories.isEmojiScalar(scalars[0]) {
            return false
        }

        // Modifier must be skin tone modifier (U+1F3FB-U+1F3FF)
        if modifier >= 0x1F3FB, modifier <= 0x1F3FF {
            return true
        }

        return false
    }

    /// Check if scalars form a tag sequence
    /// - Parameter scalars: Array of Unicode scalars
    /// - Returns: True if this is a valid tag sequence
    private static func isTagSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        guard scalars.count >= 3 else { return false }

        // Must start with emoji
        let base = scalars[0].value
        if !isBasicEmoji(base), !UnicodeCategories.isEmojiScalar(scalars[0]) {
            return false
        }

        // Must end with tag terminator (U+E007F)
        if scalars.last?.value != 0xE007F {
            return false
        }

        // Middle characters must be tag characters (U+E0020-U+E007E)
        for i in 1 ..< (scalars.count - 1) {
            let codePoint = scalars[i].value
            if !(codePoint >= 0xE0020 && codePoint <= 0xE007E) {
                return false
            }
        }

        return true
    }
}
