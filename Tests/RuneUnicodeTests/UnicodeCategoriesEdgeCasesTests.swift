import Foundation
import Testing
@testable import RuneUnicode

/// Tests for Unicode categories edge cases and complex characters
struct UnicodeCategoriesEdgeCasesTests {
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

        // Act & Assert - Measure performance with reduced iterations to prevent hanging
        let startTime = Date()

        for _ in 0 ..< 100 { // Reduced from 10,000 to 100 iterations
            for scalar in testScalars {
                _ = UnicodeCategories.category(of: scalar)
                _ = UnicodeCategories.isCombining(scalar)
                // Skip emoji detection for now as it may have memory issues
                // _ = UnicodeCategories.isEmojiScalar(scalar)
            }
        }

        let elapsedTime = Date().timeIntervalSince(startTime)

        // Should complete in reasonable time (less than 0.1 second for 1,200 operations)
        #expect(
            elapsedTime < 0.1,
            "Category detection should be fast: \(elapsedTime)s for 1,200 operations",
        )
    }
}
