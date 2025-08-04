import Foundation
import Testing
@testable import RuneUnicode

/// Test case for string width validation
private struct StringWidthTestCase {
    let string: String
    let expectedWidth: Int
    let description: String

    init(_ string: String, _ expectedWidth: Int, _ description: String) {
        self.string = string
        self.expectedWidth = expectedWidth
        self.description = description
    }
}

/// Golden test suite for RUNE-18 acceptance criteria
struct WidthGoldenTests {
    // MARK: - Golden Test Suite for RUNE-18 Acceptance Criteria

    @Test("Golden test: Family emoji ZWJ sequence")
    func goldenTestFamilyEmoji() {
        // Arrange - 👨‍👩‍👧‍👦 (Family: Man, Woman, Girl, Boy)
        let familyEmoji = "👨‍👩‍👧‍👦"

        // Act
        let width = Width.displayWidth(of: familyEmoji)

        // Assert
        #expect(width == 2, "Family emoji ZWJ sequence should have width 2")

        // Test as grapheme cluster
        let cluster = familyEmoji.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Family emoji as grapheme cluster should have width 2")
    }

    @Test("Golden test: Transgender flag emoji")
    func goldenTestTransgenderFlag() {
        // Arrange - 🏳️‍⚧️ (Transgender Flag)
        let transgenderFlag = "🏳️‍⚧️"

        // Act
        let width = Width.displayWidth(of: transgenderFlag)

        // Assert
        #expect(width == 2, "Transgender flag emoji should have width 2")

        // Test as grapheme cluster
        let cluster = transgenderFlag.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Transgender flag as grapheme cluster should have width 2")
    }

    @Test("Golden test: Japanese flag emoji")
    func goldenTestJapaneseFlag() {
        // Arrange - 🇯🇵 (Flag: Japan)
        let japanFlag = "🇯🇵"

        // Act
        let width = Width.displayWidth(of: japanFlag)

        // Assert
        #expect(width == 2, "Japanese flag emoji should have width 2")

        // Test as grapheme cluster
        let cluster = japanFlag.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Japanese flag as grapheme cluster should have width 2")
    }

    @Test("Golden test: Chinese ideograph")
    func goldenTestChineseIdeograph() {
        // Arrange - 表 (Chinese character meaning "table" or "surface")
        let chineseChar = "表"

        // Act
        let width = Width.displayWidth(of: chineseChar)

        // Assert
        #expect(width == 2, "Chinese ideograph should have width 2")

        // Test as grapheme cluster
        let cluster = chineseChar.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Chinese ideograph as grapheme cluster should have width 2")
    }

    @Test("Golden test: Fullwidth comma")
    func goldenTestFullwidthComma() {
        // Arrange - ， (Fullwidth comma)
        let fullwidthComma = "，"

        // Act
        let width = Width.displayWidth(of: fullwidthComma)

        // Assert
        #expect(width == 2, "Fullwidth comma should have width 2")

        // Test as grapheme cluster
        let cluster = fullwidthComma.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Fullwidth comma as grapheme cluster should have width 2")
    }

    @Test("Golden test: Slightly smiling face emoji")
    func goldenTestSmilingFace() {
        // Arrange - 🙂 (Slightly Smiling Face)
        let smilingFace = "🙂"

        // Act
        let width = Width.displayWidth(of: smilingFace)

        // Assert
        #expect(width == 2, "Slightly smiling face emoji should have width 2")

        // Test as grapheme cluster
        let cluster = smilingFace.first!
        let clusterWidth = Width.displayWidth(of: cluster)
        #expect(clusterWidth == 2, "Slightly smiling face as grapheme cluster should have width 2")
    }

    @Test("Golden test: End-of-line scenarios")
    func goldenTestEndOfLineScenarios() {
        // Test all golden characters at end of line scenarios
        let testCases = [
            StringWidthTestCase("Hello 👨‍👩‍👧‍👦", 8, "Family emoji at EOL: 'Hello ' (6) + emoji (2)"),
            StringWidthTestCase("Test 🏳️‍⚧️", 7, "Transgender flag at EOL: 'Test ' (5) + flag (2)"),
            StringWidthTestCase("Flag 🇯🇵", 7, "Japanese flag at EOL: 'Flag ' (5) + flag (2)"),
            StringWidthTestCase("Char 表", 7, "Chinese ideograph at EOL: 'Char ' (5) + ideograph (2)"),
            StringWidthTestCase("Punct，", 7, "Fullwidth comma at EOL: 'Punct' (5) + comma (2)"),
            StringWidthTestCase("Face 🙂", 7, "Smiling face at EOL: 'Face ' (5) + emoji (2)"),
        ]

        for testCase in testCases {
            // Act
            let width = Width.displayWidth(of: testCase.string)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description): '\(testCase.string)' should have width \(testCase.expectedWidth), got \(width)",
                )
        }
    }

    // MARK: - Legacy Emoji Tests - These will initially fail

    @Test("Simple emoji width", .disabled("Will be implemented in next iteration"))
    func simpleEmojiWidth() {
        // Arrange
        let input = "👍"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 2, "Simple emoji should have width 2")
    }

    @Test("Complex emoji width", .disabled("Will be implemented in next iteration"))
    func complexEmojiWidth() {
        // Arrange
        let input = "👨‍👩‍👧‍👦" // Family emoji with ZWJ sequences

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 2, "Complex emoji should have width 2")
    }

    @Test("Flag emoji width", .disabled("Will be implemented in next iteration"))
    func flagEmojiWidth() {
        // Arrange
        let input = "🇯🇵" // Japanese flag

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 2, "Flag emoji should have width 2")
    }

    // MARK: - Mixed Content Tests - These will initially fail

    @Test("Mixed ASCII and emoji", .disabled("Will be implemented in next iteration"))
    func mixedASCIIAndEmoji() {
        // Arrange
        let input = "Hello 👍 World"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 13, "Mixed content: 'Hello ' (6) + '👍' (2) + ' World' (6) = 14")
    }
}
