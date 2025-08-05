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

/// Test case for scalar width validation
private struct ScalarWidthTestCase {
    let scalar: Unicode.Scalar
    let expectedWidth: Int
    let description: String

    init(_ scalar: Unicode.Scalar, _ expectedWidth: Int, _ description: String) {
        self.scalar = scalar
        self.expectedWidth = expectedWidth
        self.description = description
    }
}

/// Tests for wcwidth/wcswidth bridge functionality (RUNE-16)
struct WidthWcwidthTests {
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
        let testCases = [
            StringWidthTestCase("À", 1, "A with grave accent (precomposed)"),
            StringWidthTestCase("A\u{0300}", 1, "A + combining grave accent"),
            StringWidthTestCase("é", 1, "e with acute accent (precomposed)"),
            StringWidthTestCase("e\u{0301}", 1, "e + combining acute accent"),
            StringWidthTestCase("ñ", 1, "n with tilde (precomposed)"),
            StringWidthTestCase("n\u{0303}", 1, "n + combining tilde"),
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

    @Test("Whitespace characters")
    func whitespaceCharacterWidth() {
        // Arrange - Test various whitespace characters
        let whitespaceChars = [
            ScalarWidthTestCase(Unicode.Scalar(0x0020)!, 1, "SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x00A0)!, 1, "NO-BREAK SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x1680)!, 1, "OGHAM SPACE MARK"),
            ScalarWidthTestCase(Unicode.Scalar(0x2000)!, 1, "EN QUAD"),
            ScalarWidthTestCase(Unicode.Scalar(0x2001)!, 1, "EM QUAD"),
            ScalarWidthTestCase(Unicode.Scalar(0x2002)!, 1, "EN SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2003)!, 1, "EM SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2004)!, 1, "THREE-PER-EM SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2005)!, 1, "FOUR-PER-EM SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2006)!, 1, "SIX-PER-EM SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2007)!, 1, "FIGURE SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2008)!, 1, "PUNCTUATION SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x2009)!, 1, "THIN SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x200A)!, 1, "HAIR SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x202F)!, 1, "NARROW NO-BREAK SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x205F)!, 1, "MEDIUM MATHEMATICAL SPACE"),
            ScalarWidthTestCase(Unicode.Scalar(0x3000)!, 2, "IDEOGRAPHIC SPACE"), // Wide space
        ]

        for testCase in whitespaceChars {
            // Act
            let width = Width.displayWidth(of: testCase.scalar)

            // Assert
            #expect(
                width == testCase.expectedWidth,
                "\(testCase.description) U+\(String(testCase.scalar.value, radix: 16, uppercase: true)) should have width \(testCase.expectedWidth), got \(width)",
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
}
