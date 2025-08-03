import Foundation
import Testing
@testable import RuneUnicode

/// Tests for Unicode categories and utf8proc integration following TDD principles
/// These tests will initially fail until utf8proc is integrated
struct UnicodeCategoriesTests {
    // MARK: - Basic Category Detection Tests

    @Test("ASCII letter category detection")
    func asciiLetterCategory() {
        // Arrange
        let uppercaseA = Unicode.Scalar(65)! // 'A'
        let lowercaseA = Unicode.Scalar(97)! // 'a'

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: uppercaseA) == .uppercaseLetter,
            "Uppercase 'A' should be categorized as uppercase letter",
        )
        #expect(
            UnicodeCategories.category(of: lowercaseA) == .lowercaseLetter,
            "Lowercase 'a' should be categorized as lowercase letter",
        )
    }

    @Test("Combining mark detection")
    func combiningMarkDetection() {
        // Arrange - Combining Diacritical Marks
        let combiningAcute = Unicode.Scalar(0x0301)! // COMBINING ACUTE ACCENT
        let combiningGrave = Unicode.Scalar(0x0300)! // COMBINING GRAVE ACCENT
        let regularA = Unicode.Scalar(65)! // 'A' - not combining

        // Act & Assert
        #expect(
            UnicodeCategories.isCombining(combiningAcute),
            "U+0301 COMBINING ACUTE ACCENT should be detected as combining mark",
        )
        #expect(
            UnicodeCategories.isCombining(combiningGrave),
            "U+0300 COMBINING GRAVE ACCENT should be detected as combining mark",
        )
        #expect(
            !UnicodeCategories.isCombining(regularA),
            "Regular letter 'A' should not be detected as combining mark",
        )
    }

    @Test("Emoji scalar detection")
    func emojiScalarDetection() {
        // Arrange
        let thumbsUp = Unicode.Scalar(0x1F44D)! // 👍
        let redHeart = Unicode.Scalar(0x2764)! // ❤
        let regularA = Unicode.Scalar(65)! // 'A' - not emoji
        let digit = Unicode.Scalar(48)! // '0' - not emoji

        // Act & Assert
        #expect(
            UnicodeCategories.isEmojiScalar(thumbsUp),
            "U+1F44D THUMBS UP SIGN should be detected as emoji scalar",
        )
        #expect(
            UnicodeCategories.isEmojiScalar(redHeart),
            "U+2764 HEAVY BLACK HEART should be detected as emoji scalar",
        )
        #expect(
            !UnicodeCategories.isEmojiScalar(regularA),
            "Regular letter 'A' should not be detected as emoji scalar",
        )
        #expect(
            !UnicodeCategories.isEmojiScalar(digit),
            "Digit '0' should not be detected as emoji scalar",
        )
    }

    // MARK: - Unicode Category Enum Tests

    @Test("Number category detection")
    func numberCategoryDetection() {
        // Arrange
        let digit0 = Unicode.Scalar(48)! // '0'
        let romanOne = Unicode.Scalar(0x2160)! // Ⅰ (Roman numeral one)

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: digit0) == .decimalNumber,
            "Digit '0' should be categorized as decimal number",
        )
        #expect(
            UnicodeCategories.category(of: romanOne) == .letterNumber,
            "Roman numeral Ⅰ should be categorized as letter number",
        )
    }

    @Test("Punctuation category detection")
    func punctuationCategoryDetection() {
        // Arrange
        let period = Unicode.Scalar(46)! // '.'
        let openParen = Unicode.Scalar(40)! // '('
        let closeParen = Unicode.Scalar(41)! // ')'

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: period) == .otherPunctuation,
            "Period '.' should be categorized as other punctuation",
        )
        #expect(
            UnicodeCategories.category(of: openParen) == .openPunctuation,
            "Open parenthesis '(' should be categorized as open punctuation",
        )
        #expect(
            UnicodeCategories.category(of: closeParen) == .closePunctuation,
            "Close parenthesis ')' should be categorized as close punctuation",
        )
    }

    @Test("Symbol category detection")
    func symbolCategoryDetection() {
        // Arrange
        let plusSign = Unicode.Scalar(43)! // '+'
        let dollarSign = Unicode.Scalar(36)! // '$'

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: plusSign) == .mathSymbol,
            "Plus sign '+' should be categorized as math symbol",
        )
        #expect(
            UnicodeCategories.category(of: dollarSign) == .currencySymbol,
            "Dollar sign '$' should be categorized as currency symbol",
        )
    }

    // MARK: - Edge Cases and Complex Characters

    @Test("Control character detection")
    func controlCharacterDetection() {
        // Arrange
        let tab = Unicode.Scalar(9)! // TAB
        let newline = Unicode.Scalar(10)! // LF
        let del = Unicode.Scalar(127)! // DEL

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: tab) == .control,
            "TAB should be categorized as control character",
        )
        #expect(
            UnicodeCategories.category(of: newline) == .control,
            "Newline should be categorized as control character",
        )
        #expect(
            UnicodeCategories.category(of: del) == .control,
            "DEL should be categorized as control character",
        )
    }

    @Test("CJK character detection")
    func cjkCharacterDetection() {
        // Arrange
        let chineseChar = Unicode.Scalar(0x4E00)! // 一 (Chinese)
        let japaneseHiragana = Unicode.Scalar(0x3042)! // あ (Hiragana)
        let koreanHangul = Unicode.Scalar(0xAC00)! // 가 (Hangul)

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: chineseChar) == .otherLetter,
            "Chinese character should be categorized as other letter",
        )
        #expect(
            UnicodeCategories.category(of: japaneseHiragana) == .otherLetter,
            "Japanese Hiragana should be categorized as other letter",
        )
        #expect(
            UnicodeCategories.category(of: koreanHangul) == .otherLetter,
            "Korean Hangul should be categorized as other letter",
        )
    }

    // MARK: - Performance Tests

    @Test("Category detection performance")
    func categoryDetectionPerformance() {
        // Arrange - Create test scalars of various types
        let testScalars: [Unicode.Scalar] = [
            Unicode.Scalar(65)!, // 'A'
            Unicode.Scalar(97)!, // 'a'
            Unicode.Scalar(48)!, // '0'
            Unicode.Scalar(0x1F44D)!, // 👍
            Unicode.Scalar(0x0301)!, // COMBINING ACUTE ACCENT
            Unicode.Scalar(0x4E00)!, // 一 (Chinese)
        ]

        // Act & Assert - Measure performance
        let startTime = Date()

        for _ in 0 ..< 10000 { // Run 10,000 iterations
            for scalar in testScalars {
                _ = UnicodeCategories.category(of: scalar)
                _ = UnicodeCategories.isCombining(scalar)
                _ = UnicodeCategories.isEmojiScalar(scalar)
            }
        }

        let elapsedTime = Date().timeIntervalSince(startTime)

        // Should complete in reasonable time (less than 1 second for 60,000 operations)
        #expect(
            elapsedTime < 1.0,
            "Category detection should be fast: \(elapsedTime)s for 60,000 operations",
        )
    }

    // MARK: - Normalization Tests

    @Test("Unicode normalization NFC")
    func unicodeNormalizationNFC() {
        // Arrange - Decomposed form: e + combining acute accent
        let decomposed = "e\u{0301}" // e + ́
        let expectedComposed = "é" // precomposed é

        // Act
        let normalized = UnicodeNormalization.normalize(decomposed, form: .nfc)

        // Assert
        #expect(
            normalized == expectedComposed,
            "NFC normalization should compose decomposed characters",
        )
    }

    @Test("Unicode normalization NFD")
    func unicodeNormalizationNFD() {
        // Arrange - Precomposed form
        let composed = "é" // precomposed é
        let expectedDecomposed = "e\u{0301}" // e + ́

        // Act
        let normalized = UnicodeNormalization.normalize(composed, form: .nfd)

        // Assert
        #expect(
            normalized == expectedDecomposed,
            "NFD normalization should decompose precomposed characters",
        )
    }

    @Test("Unicode normalization NFKC")
    func unicodeNormalizationNFKC() {
        // Arrange - Compatibility characters
        let compatibility = "ﬁ" // U+FB01 LATIN SMALL LIGATURE FI
        let expectedCanonical = "fi" // f + i

        // Act
        let normalized = UnicodeNormalization.normalize(compatibility, form: .nfkc)

        // Assert
        #expect(
            normalized == expectedCanonical,
            "NFKC normalization should decompose compatibility characters",
        )
    }

    @Test("Unicode normalization NFKD")
    func unicodeNormalizationNFKD() {
        // Arrange - Compatibility characters
        let input = "ﬁ" // U+FB01 LATIN SMALL LIGATURE FI

        // Act
        let normalized = UnicodeNormalization.normalize(input, form: .nfkd)

        // Assert
        // Should decompose the ligature into separate characters
        #expect(
            normalized.contains("f") && normalized.contains("i"),
            "NFKD normalization should decompose compatibility characters",
        )
        #expect(
            normalized == "fi",
            "NFKD should decompose ligature ﬁ to 'fi'",
        )
    }

    // MARK: - Version and Metadata Tests

    @Test("Unicode version information")
    func unicodeVersionInformation() {
        // Act
        let version = UnicodeCategories.unicodeVersion()

        // Assert
        #expect(!version.isEmpty, "Unicode version should not be empty")
        #expect(version != "Unknown", "Unicode version should be available")

        // Version should be in MAJOR.MINOR.PATCH format
        let components = version.split(separator: ".")
        #expect(components.count >= 2, "Version should have at least major.minor components")

        // Should be a reasonable Unicode version (>= 10.0)
        if let major = Int(components[0]) {
            #expect(major >= 10, "Unicode version should be 10.0 or higher")
        }
    }
}
