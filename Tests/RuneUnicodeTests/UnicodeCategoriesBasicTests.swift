import Foundation
import Testing
@testable import RuneUnicode

/// Basic tests for Unicode categories and utf8proc integration
struct UnicodeCategoriesBasicTests {
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
}
