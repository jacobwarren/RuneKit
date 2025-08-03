import Foundation
import Testing
@testable import RuneUnicode

/// Tests for Unicode width calculation functionality following TDD principles
struct WidthTests {
    // MARK: - Basic ASCII Tests

    @Test("Empty string has zero width")
    func emptyStringWidth() {
        // Arrange
        let input = ""

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 0, "Empty string should have zero width")
    }

    @Test("ASCII characters have width 1")
    func aSCIIWidth() {
        // Arrange
        let input = "Hello"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 5, "ASCII string 'Hello' should have width 5")
    }

    @Test("ASCII with spaces")
    func aSCIIWithSpaces() {
        // Arrange
        let input = "Hello World"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 11, "ASCII string 'Hello World' should have width 11")
    }

    // MARK: - Emoji Tests - These will initially fail

    @Test("Simple emoji width", .disabled("Will be implemented in next iteration"))
    func simpleEmojiWidth() {
        // Arrange
        let input = "👍"

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 2, "Thumbs up emoji should have width 2")
    }

    @Test("Complex emoji sequence width", .disabled("Will be implemented in next iteration"))
    func complexEmojiWidth() {
        // Arrange
        let input = "👨‍👩‍👧‍👦" // Family emoji with ZWJ sequences

        // Act
        let width = Width.displayWidth(of: input)

        // Assert
        #expect(width == 2, "Family emoji should have width 2 despite multiple codepoints")
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

    // MARK: - Scalar-level Tests

    @Test("ASCII scalar width")
    func aSCIIScalarWidth() {
        // Arrange
        let scalar = Unicode.Scalar(65)! // 'A'

        // Act
        let width = Width.displayWidth(of: scalar)

        // Assert
        #expect(width == 1, "ASCII character should have width 1")
    }

    // MARK: - wcwidth/wcswidth Bridge Tests (RUNE-16)

    @Test("Control characters have zero width")
    func controlCharacterWidth() {
        // Arrange - Test various control characters
        let controlChars: [Unicode.Scalar] = [
            Unicode.Scalar(0)!, // NULL
            Unicode.Scalar(7)!, // BEL
            Unicode.Scalar(8)!, // BS
            Unicode.Scalar(9)!, // TAB - special case, should be 1
            Unicode.Scalar(10)!, // LF
            Unicode.Scalar(13)!, // CR
            Unicode.Scalar(27)!, // ESC
            Unicode.Scalar(127)!, // DEL
        ]

        for scalar in controlChars {
            // Act
            let width = Width.displayWidth(of: scalar)

            // Assert
            if scalar.value == 9 { // TAB
                #expect(width == 1, "TAB character should have width 1, got \(width)")
            } else {
                #expect(
                    width == 0,
                    "Control character U+\(String(scalar.value, radix: 16, uppercase: true)) should have width 0, got \(width)",
                )
            }
        }
    }

    @Test("Combining marks have zero width")
    func combiningMarkWidth() {
        // Arrange - Test combining diacritical marks
        let combiningMarks: [Unicode.Scalar] = [
            Unicode.Scalar(0x0300)!, // COMBINING GRAVE ACCENT
            Unicode.Scalar(0x0301)!, // COMBINING ACUTE ACCENT
            Unicode.Scalar(0x0302)!, // COMBINING CIRCUMFLEX ACCENT
            Unicode.Scalar(0x0308)!, // COMBINING DIAERESIS
            Unicode.Scalar(0x030A)!, // COMBINING RING ABOVE
        ]

        for scalar in combiningMarks {
            // Act
            let width = Width.displayWidth(of: scalar)

            // Assert
            #expect(
                width == 0,
                "Combining mark U+\(String(scalar.value, radix: 16, uppercase: true)) should have width 0, got \(width)",
            )
        }
    }

    @Test("String with combining marks")
    func stringWithCombiningMarks() {
        // Arrange - Test strings with combining characters
        let testCases: [(String, Int, String)] = [
            ("À", 1, "A with grave accent (precomposed)"),
            ("A\u{0300}", 1, "A + combining grave accent"),
            ("é", 1, "e with acute accent (precomposed)"),
            ("e\u{0301}", 1, "e + combining acute accent"),
            ("ñ", 1, "n with tilde (precomposed)"),
            ("n\u{0303}", 1, "n + combining tilde"),
        ]

        for (input, expectedWidth, description) in testCases {
            // Act
            let width = Width.displayWidth(of: input)

            // Assert
            #expect(
                width == expectedWidth,
                "\(description): '\(input)' should have width \(expectedWidth), got \(width)",
            )
        }
    }

    @Test("Whitespace characters")
    func whitespaceCharacterWidth() {
        // Arrange - Test various whitespace characters
        let whitespaceChars: [(Unicode.Scalar, Int, String)] = [
            (Unicode.Scalar(0x0020)!, 1, "SPACE"),
            (Unicode.Scalar(0x00A0)!, 1, "NO-BREAK SPACE"),
            (Unicode.Scalar(0x1680)!, 1, "OGHAM SPACE MARK"),
            (Unicode.Scalar(0x2000)!, 1, "EN QUAD"),
            (Unicode.Scalar(0x2001)!, 1, "EM QUAD"),
            (Unicode.Scalar(0x2002)!, 1, "EN SPACE"),
            (Unicode.Scalar(0x2003)!, 1, "EM SPACE"),
            (Unicode.Scalar(0x2004)!, 1, "THREE-PER-EM SPACE"),
            (Unicode.Scalar(0x2005)!, 1, "FOUR-PER-EM SPACE"),
            (Unicode.Scalar(0x2006)!, 1, "SIX-PER-EM SPACE"),
            (Unicode.Scalar(0x2007)!, 1, "FIGURE SPACE"),
            (Unicode.Scalar(0x2008)!, 1, "PUNCTUATION SPACE"),
            (Unicode.Scalar(0x2009)!, 1, "THIN SPACE"),
            (Unicode.Scalar(0x200A)!, 1, "HAIR SPACE"),
            (Unicode.Scalar(0x202F)!, 1, "NARROW NO-BREAK SPACE"),
            (Unicode.Scalar(0x205F)!, 1, "MEDIUM MATHEMATICAL SPACE"),
            (Unicode.Scalar(0x3000)!, 2, "IDEOGRAPHIC SPACE"), // Wide space
        ]

        for (scalar, expectedWidth, description) in whitespaceChars {
            // Act
            let width = Width.displayWidth(of: scalar)

            // Assert
            #expect(
                width == expectedWidth,
                "\(description) U+\(String(scalar.value, radix: 16, uppercase: true)) should have width \(expectedWidth), got \(width)",
            )
        }
    }

    @Test("Basic Latin characters")
    func basicLatinCharacterWidth() {
        // Arrange - Test Basic Latin printable range (U+0020-U+007E)
        // Note: U+007F (DEL) is a control character and should have width 0
        for codePoint in 0x0020 ... 0x007E {
            guard let scalar = Unicode.Scalar(codePoint) else { continue }

            // Act
            let width = Width.displayWidth(of: scalar)

            // Assert
            #expect(
                width == 1,
                "Basic Latin character U+\(String(codePoint, radix: 16, uppercase: true)) should have width 1, got \(width)",
            )
        }
    }

    // MARK: - Performance Tests

    @Test("Performance benchmark for common strings")
    func performanceBenchmark() {
        // Arrange - Create test strings of various types
        let testStrings = [
            "Hello, World!",
            "The quick brown fox jumps over the lazy dog",
            "ASCII text with numbers 1234567890 and symbols !@#$%^&*()",
            "Text with accents: café, naïve, résumé, piñata",
            "Mixed content: Hello 世界 🌍",
            String(repeating: "A", count: 1000), // Long ASCII string
            String(repeating: "À", count: 500), // Long string with accents
        ]

        // Act & Assert - Measure performance
        let startTime = Date()

        for _ in 0 ..< 1000 { // Run 1000 iterations
            for testString in testStrings {
                _ = Width.displayWidth(of: testString)
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Performance expectation: should complete in reasonable time
        // This is more of a smoke test than a strict performance requirement
        #expect(duration < 1.0, "Performance test took \(duration) seconds, expected < 1.0 seconds")

        print(
            "Performance benchmark: \(testStrings.count * 1000) width calculations in \(String(format: "%.3f", duration)) seconds",
        )
    }
}
