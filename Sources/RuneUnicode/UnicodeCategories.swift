/// Unicode Categories API using utf8proc for accurate categorization
///
/// This module provides Swift-friendly access to Unicode character categories,
/// combining mark detection, and emoji scalar identification using the utf8proc
/// C library for maximum accuracy and performance.
///
/// ## Features
/// - **Unicode category detection** for any scalar using the latest Unicode standard
/// - **Combining mark identification** for proper text rendering and processing
/// - **Emoji scalar detection** using Extended_Pictographic property
/// - **Unicode normalization** (NFC, NFD, NFKC, NFKD) for text processing
/// - **High performance** with utf8proc C library backend
/// - **Cross-platform** support (macOS, Linux) via system package managers
///
/// ## Unicode Version
/// This implementation uses utf8proc which supports Unicode version determined at runtime.
/// Call `UnicodeCategories.unicodeVersion()` to get the exact version being used.
///
/// ## Usage Examples
/// ```swift
/// // Category detection
/// let category = UnicodeCategories.category(of: Unicode.Scalar("A")!)
/// // Returns: .uppercaseLetter
///
/// // Combining mark detection
/// let isCombining = UnicodeCategories.isCombining(Unicode.Scalar(0x0301)!)
/// // Returns: true (combining acute accent)
///
/// // Emoji detection
/// let isEmoji = UnicodeCategories.isEmojiScalar(Unicode.Scalar("👍")!)
/// // Returns: true
///
/// // Text normalization
/// let normalized = UnicodeNormalization.normalize("é", form: .nfd)
/// // Returns: "e\u{0301}" (decomposed form)
/// ```
///
/// ## Performance
/// All functions are optimized for performance and can handle high-frequency calls.
/// The underlying utf8proc library is written in C and provides excellent performance
/// characteristics suitable for real-time text processing.

import Cutf8proc

/// Unicode General Categories as defined by the Unicode Standard
/// Maps to utf8proc category constants for consistency
public enum UnicodeCategory {
    // Letters
    case uppercaseLetter // Lu
    case lowercaseLetter // Ll
    case titlecaseLetter // Lt
    case modifierLetter // Lm
    case otherLetter // Lo

    // Marks
    case nonspacingMark // Mn
    case spacingMark // Mc
    case enclosingMark // Me

    // Numbers
    case decimalNumber // Nd
    case letterNumber // Nl
    case otherNumber // No

    // Punctuation
    case connectorPunctuation // Pc
    case dashPunctuation // Pd
    case openPunctuation // Ps
    case closePunctuation // Pe
    case initialPunctuation // Pi
    case finalPunctuation // Pf
    case otherPunctuation // Po

    // Symbols
    case mathSymbol // Sm
    case currencySymbol // Sc
    case modifierSymbol // Sk
    case otherSymbol // So

    // Separators
    case spaceSeparator // Zs
    case lineSeparator // Zl
    case paragraphSeparator // Zp

    // Other
    case control // Cc
    case format // Cf
    case surrogate // Cs
    case privateUse // Co
    case unassigned // Cn
}

/// Main API for Unicode character categorization
///
/// This enum provides static methods for Unicode character analysis using utf8proc.
/// All methods are thread-safe and optimized for performance.
public enum UnicodeCategories {
    /// Get the Unicode version supported by the underlying utf8proc library
    /// - Returns: Unicode version string in MAJOR.MINOR.PATCH format
    public static func unicodeVersion() -> String {
        guard let versionCString = utf8proc_unicode_version() else {
            return "Unknown"
        }
        return String(cString: versionCString)
    }

    /// Convert utf8proc category to Swift UnicodeCategory enum
    /// - Parameter utf8procCategory: The utf8proc category constant
    /// - Returns: Corresponding Swift UnicodeCategory
    private static func convertCategory(_ utf8procCategory: utf8proc_category_t) -> UnicodeCategory {
        switch utf8procCategory {
        case UTF8PROC_CATEGORY_LU: .uppercaseLetter
        case UTF8PROC_CATEGORY_LL: .lowercaseLetter
        case UTF8PROC_CATEGORY_LT: .titlecaseLetter
        case UTF8PROC_CATEGORY_LM: .modifierLetter
        case UTF8PROC_CATEGORY_LO: .otherLetter
        case UTF8PROC_CATEGORY_MN: .nonspacingMark
        case UTF8PROC_CATEGORY_MC: .spacingMark
        case UTF8PROC_CATEGORY_ME: .enclosingMark
        case UTF8PROC_CATEGORY_ND: .decimalNumber
        case UTF8PROC_CATEGORY_NL: .letterNumber
        case UTF8PROC_CATEGORY_NO: .otherNumber
        case UTF8PROC_CATEGORY_PC: .connectorPunctuation
        case UTF8PROC_CATEGORY_PD: .dashPunctuation
        case UTF8PROC_CATEGORY_PS: .openPunctuation
        case UTF8PROC_CATEGORY_PE: .closePunctuation
        case UTF8PROC_CATEGORY_PI: .initialPunctuation
        case UTF8PROC_CATEGORY_PF: .finalPunctuation
        case UTF8PROC_CATEGORY_PO: .otherPunctuation
        case UTF8PROC_CATEGORY_SM: .mathSymbol
        case UTF8PROC_CATEGORY_SC: .currencySymbol
        case UTF8PROC_CATEGORY_SK: .modifierSymbol
        case UTF8PROC_CATEGORY_SO: .otherSymbol
        case UTF8PROC_CATEGORY_ZS: .spaceSeparator
        case UTF8PROC_CATEGORY_ZL: .lineSeparator
        case UTF8PROC_CATEGORY_ZP: .paragraphSeparator
        case UTF8PROC_CATEGORY_CC: .control
        case UTF8PROC_CATEGORY_CF: .format
        case UTF8PROC_CATEGORY_CS: .surrogate
        case UTF8PROC_CATEGORY_CO: .privateUse
        case UTF8PROC_CATEGORY_CN: .unassigned
        default: .unassigned
        }
    }

    /// Get the Unicode category for a given scalar
    ///
    /// This method uses utf8proc to determine the precise Unicode General Category
    /// for any Unicode scalar value. The categorization follows the Unicode Standard
    /// and is updated with each utf8proc release.
    ///
    /// - Parameter scalar: The Unicode scalar to categorize
    /// - Returns: The Unicode category as defined by the Unicode Standard
    /// - Complexity: O(1) - constant time lookup
    ///
    /// Example:
    /// ```swift
    /// let category = UnicodeCategories.category(of: Unicode.Scalar("A")!)
    /// // Returns: .uppercaseLetter
    /// ```
    public static func category(of scalar: Unicode.Scalar) -> UnicodeCategory {
        let codePoint = Int32(scalar.value)
        let utf8procCategory = utf8proc_category(codePoint)
        return convertCategory(utf8procCategory)
    }

    /// Check if a Unicode scalar is a combining mark
    ///
    /// Combining marks are characters that combine with preceding base characters
    /// to form a single grapheme cluster. This includes nonspacing marks (Mn),
    /// spacing combining marks (Mc), and enclosing marks (Me).
    ///
    /// This is essential for proper text rendering, cursor movement, and text
    /// selection in terminal applications.
    ///
    /// - Parameter scalar: The Unicode scalar to check
    /// - Returns: True if the scalar is a combining mark (categories Mn, Mc, or Me)
    /// - Complexity: O(1) - constant time lookup
    ///
    /// Example:
    /// ```swift
    /// let isCombining = UnicodeCategories.isCombining(Unicode.Scalar(0x0301)!)
    /// // Returns: true (combining acute accent)
    /// ```
    public static func isCombining(_ scalar: Unicode.Scalar) -> Bool {
        let codePoint = Int32(scalar.value)
        let utf8procCategory = utf8proc_category(codePoint)

        // Combining marks are in categories Mn, Mc, and Me
        return utf8procCategory == UTF8PROC_CATEGORY_MN ||
            utf8procCategory == UTF8PROC_CATEGORY_MC ||
            utf8procCategory == UTF8PROC_CATEGORY_ME
    }

    /// Check if a Unicode scalar is an emoji
    ///
    /// This method uses the Extended_Pictographic property from the Unicode Standard
    /// to accurately identify emoji scalars. This is more reliable than range-based
    /// checks as it follows the official Unicode emoji specification.
    ///
    /// Note: This identifies individual emoji scalars, not complete emoji sequences.
    /// Complex emoji (like family emoji) may consist of multiple scalars joined
    /// by Zero Width Joiners (ZWJ).
    ///
    /// - Parameter scalar: The Unicode scalar to check
    /// - Returns: True if the scalar has emoji properties
    /// - Complexity: O(1) - constant time lookup
    ///
    /// Example:
    /// ```swift
    /// let isEmoji = UnicodeCategories.isEmojiScalar(Unicode.Scalar("👍")!)
    /// // Returns: true
    /// ```
    public static func isEmojiScalar(_ scalar: Unicode.Scalar) -> Bool {
        let codePoint = Int32(scalar.value)
        guard let property = utf8proc_get_property(codePoint) else {
            return false
        }

        // Check if the character has Extended_Pictographic property
        // This is the most accurate way to detect emoji scalars
        let boundclass = property.pointee.boundclass
        return boundclass == UTF8PROC_BOUNDCLASS_EXTENDED_PICTOGRAPHIC.rawValue ||
            boundclass == UTF8PROC_BOUNDCLASS_E_BASE.rawValue ||
            boundclass == UTF8PROC_BOUNDCLASS_E_MODIFIER.rawValue
    }
}

/// Unicode Normalization Forms as defined by Unicode Standard Annex #15
///
/// These normalization forms ensure consistent representation of Unicode text
/// and are essential for text comparison, searching, and processing.
public enum UnicodeNormalizationForm {
    /// Canonical Decomposition, followed by Canonical Composition (NFC)
    ///
    /// This is the most common normalization form. It decomposes characters
    /// into their canonical forms and then recomposes them. Most text should
    /// be in NFC form for optimal compatibility.
    case nfc

    /// Canonical Decomposition (NFD)
    ///
    /// Decomposes characters into their canonical constituent parts.
    /// Useful for analysis and processing of individual character components.
    case nfd

    /// Compatibility Decomposition, followed by Canonical Composition (NFKC)
    ///
    /// Like NFC but also decomposes compatibility characters (like ligatures)
    /// into their canonical equivalents. Use with caution as it may change
    /// the visual appearance of text.
    case nfkc

    /// Compatibility Decomposition (NFKD)
    ///
    /// Decomposes both canonical and compatibility characters.
    /// Most aggressive normalization form.
    case nfkd
}

/// Unicode text normalization using utf8proc
///
/// This enum provides static methods for Unicode text normalization according
/// to Unicode Standard Annex #15. Normalization is essential for text processing,
/// comparison, and ensuring consistent representation across different systems.
public enum UnicodeNormalization {
    /// Normalize a Unicode string using the specified normalization form
    ///
    /// This method applies Unicode normalization to ensure consistent text
    /// representation. The normalization process may change the byte sequence
    /// of the string while preserving its semantic meaning.
    ///
    /// - Parameters:
    ///   - string: The string to normalize
    ///   - form: The normalization form to apply
    /// - Returns: The normalized string, or the original string if normalization fails
    /// - Complexity: O(n) where n is the length of the input string
    ///
    /// Example:
    /// ```swift
    /// let decomposed = "e\u{0301}" // e + combining acute
    /// let normalized = UnicodeNormalization.normalize(decomposed, form: .nfc)
    /// // Returns: "é" (precomposed)
    /// ```
    public static func normalize(_ string: String, form: UnicodeNormalizationForm) -> String {
        // Convert normalization form to utf8proc options
        let options: utf8proc_option_t = switch form {
        case .nfc:
            UTF8PROC_COMPOSE
        case .nfd:
            UTF8PROC_DECOMPOSE
        case .nfkc:
            utf8proc_option_t(UTF8PROC_COMPOSE.rawValue | UTF8PROC_COMPAT.rawValue)
        case .nfkd:
            utf8proc_option_t(UTF8PROC_DECOMPOSE.rawValue | UTF8PROC_COMPAT.rawValue)
        }

        // Convert Swift string to UTF-8 bytes
        let inputData = string.utf8CString

        // Call utf8proc_map to normalize the string
        var outputPtr: UnsafeMutablePointer<utf8proc_uint8_t>?
        let result = inputData.withUnsafeBufferPointer { buffer in
            utf8proc_map(buffer.baseAddress, buffer.count - 1, &outputPtr, options)
        }

        // Check for errors
        guard result >= 0, let output = outputPtr else {
            // Return original string if normalization fails
            return string
        }

        // Convert result back to Swift string
        defer { free(output) }
        let normalizedString = String(cString: output)
        return normalizedString
    }

    /// Check if a string is already in the specified normalization form
    /// - Parameters:
    ///   - string: The string to check
    ///   - form: The normalization form to check against
    /// - Returns: True if the string is already normalized
    public static func isNormalized(_ string: String, form: UnicodeNormalizationForm) -> Bool {
        let normalized = normalize(string, form: form)
        return string == normalized
    }
}
