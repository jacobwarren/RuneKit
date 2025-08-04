import Foundation
import Testing
@testable import RuneUnicode

/// Test case for character width validation
private struct CharacterWidthTestCase {
    let character: Character
    let expectedWidth: Int
    let description: String

    init(_ character: Character, _ expectedWidth: Int, _ description: String) {
        self.character = character
        self.expectedWidth = expectedWidth
        self.description = description
    }
}

/// Tests for East Asian width calculation functionality
struct WidthEastAsianTests {
    // MARK: - East Asian Width Tests (RUNE-18)

    @Test("East Asian Width - Chinese ideographs")
    func eastAsianWidthChinese() {
        // Arrange
        let testCases = [
            CharacterWidthTestCase("表", 2, "Chinese ideograph should be wide"),
            CharacterWidthTestCase("你", 2, "Chinese ideograph should be wide"),
            CharacterWidthTestCase("好", 2, "Chinese ideograph should be wide"),
        ]

        for testCase in testCases {
            // Act
            let width = Width.displayWidth(of: testCase.character)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description): '\(testCase.character)' should have width \(testCase.expectedWidth), got \(width)",
                )
        }
    }

    @Test("East Asian Width - Japanese characters")
    func eastAsianWidthJapanese() {
        // Arrange
        let testCases = [
            CharacterWidthTestCase("こ", 2, "Hiragana should be wide"),
            CharacterWidthTestCase("ん", 2, "Hiragana should be wide"),
            CharacterWidthTestCase("カ", 2, "Katakana should be wide"),
            CharacterWidthTestCase("タ", 2, "Katakana should be wide"),
        ]

        for testCase in testCases {
            // Act
            let width = Width.displayWidth(of: testCase.character)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description): '\(testCase.character)' should have width \(testCase.expectedWidth), got \(width)",
                )
        }
    }

    @Test("East Asian Width - Fullwidth characters")
    func eastAsianWidthFullwidth() {
        // Arrange
        let testCases = [
            CharacterWidthTestCase("Ａ", 2, "Fullwidth Latin A should be wide"),
            CharacterWidthTestCase("１", 2, "Fullwidth digit should be wide"),
            CharacterWidthTestCase("，", 2, "Fullwidth comma should be wide"),
            CharacterWidthTestCase("！", 2, "Fullwidth exclamation should be wide"),
        ]

        for testCase in testCases {
            // Act
            let width = Width.displayWidth(of: testCase.character)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description): '\(testCase.character)' should have width \(testCase.expectedWidth), got \(width)",
                )
        }
    }

    @Test("East Asian Width - Halfwidth characters")
    func eastAsianWidthHalfwidth() {
        // Arrange
        let testCases = [
            CharacterWidthTestCase("ｱ", 1, "Halfwidth Katakana should be narrow"),
            CharacterWidthTestCase("ｶ", 1, "Halfwidth Katakana should be narrow"),
        ]

        for testCase in testCases {
            // Act
            let width = Width.displayWidth(of: testCase.character)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description): '\(testCase.character)' should have width \(testCase.expectedWidth), got \(width)",
                )
        }
    }

    // MARK: - CJK Character Tests - These will initially fail

    @Test("Chinese characters width", .disabled("Will be implemented in next iteration"))
    func chineseCharacterWidth() {
        // Arrange
        let input = "你好"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 4, "Chinese characters should have width 2 each")
    }

    @Test("Japanese characters width", .disabled("Will be implemented in next iteration"))
    func japaneseCharacterWidth() {
        // Arrange
        let input = "こんにちは"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 10, "Japanese hiragana should have width 2 each")
    }
}
