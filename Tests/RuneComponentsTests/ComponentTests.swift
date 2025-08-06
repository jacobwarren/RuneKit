import Testing
@testable import RuneComponents
@testable import RuneLayout
@testable import RuneANSI

/// Tests for component functionality following TDD principles
struct ComponentTests {
    // MARK: - Text Component Tests

    @Test("Text component with simple content")
    func textComponentSimple() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "First line should contain the text")
        #expect(lines[1].isEmpty, "Remaining lines should be empty")
        #expect(lines[2].isEmpty, "Remaining lines should be empty")
    }

    @Test("Text component with content longer than width")
    func textComponentTruncation() {
        // Arrange
        let text = Text("Hello World This Is Long")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "Should truncate content to fit width")
    }

    @Test("Text component with zero dimensions")
    func textComponentZeroDimensions() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 0)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero dimensions")
    }

    @Test("Text component with zero width")
    func textComponentZeroWidth() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 3)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero width")
    }

    @Test("Text component with zero height")
    func textComponentZeroHeight() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 0)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero height")
    }

    // MARK: - Box Component Tests

    @Test("Empty box component")
    func emptyBoxComponent() {
        // Arrange
        let box = Box()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        // swiftlint:disable:next prefer_key_path
        #expect(lines.allSatisfy { $0.isEmpty }, "All lines should be empty")
    }

    @Test("Box with text child")
    func boxWithTextChild() {
        // Arrange
        let text = Text("Hello")
        let box = Box(child: text)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 2)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "Should render child content")
        #expect(lines[1].isEmpty, "Remaining lines should be empty")
    }

    @Test("Box with border style none")
    func boxBorderStyleNone() {
        // Arrange
        let box = Box(border: .none)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        // swiftlint:disable:next prefer_key_path
        #expect(
            lines.allSatisfy { $0.isEmpty },
            "All lines should be empty for no border",
        )
    }

    @Test("Box with zero dimensions")
    func boxZeroDimensions() {
        // Arrange
        let box = Box()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 0)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero dimensions")
    }

    // MARK: - Styled Text Component Tests (RUNE-29)

    @Test("Text component with color styling")
    func textComponentWithColor() {
        // Arrange
        let text = Text("Hello", color: .red)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[31m"), "Should contain red color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with background color")
    func textComponentWithBackgroundColor() {
        // Arrange
        let text = Text("Hello", backgroundColor: .blue)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[44m"), "Should contain blue background code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with bold styling")
    func textComponentWithBold() {
        // Arrange
        let text = Text("Hello", bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[1m"), "Should contain bold code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with italic styling")
    func textComponentWithItalic() {
        // Arrange
        let text = Text("Hello", italic: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[3m"), "Should contain italic code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with underline styling")
    func textComponentWithUnderline() {
        // Arrange
        let text = Text("Hello", underline: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[4m"), "Should contain underline code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with strikethrough styling")
    func textComponentWithStrikethrough() {
        // Arrange
        let text = Text("Hello", strikethrough: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[9m"), "Should contain strikethrough code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with inverse styling")
    func textComponentWithInverse() {
        // Arrange
        let text = Text("Hello", inverse: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[7m"), "Should contain inverse code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with dim styling")
    func textComponentWithDim() {
        // Arrange
        let text = Text("Hello", dim: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[2m"), "Should contain dim code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with multiple styles")
    func textComponentWithMultipleStyles() {
        // Arrange
        let text = Text("Hello", color: .red, bold: true, underline: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}["), "Should contain ANSI escape sequence")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
        // Should contain all style codes (order may vary)
        let line = lines[0]
        #expect(line.contains("31") || line.contains("1;31") || line.contains("31;1"), "Should contain red color")
        #expect(line.contains("1"), "Should contain bold")
        #expect(line.contains("4"), "Should contain underline")
    }

    @Test("Text component with width constraint and styling")
    func textComponentWithWidthConstraintAndStyling() {
        // Arrange
        let text = Text("Hello World", color: .green, bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("Hello"), "Should contain truncated text")
        #expect(!lines[0].contains("World"), "Should not contain text beyond width")
        #expect(lines[0].contains("\u{001B}["), "Should contain ANSI codes")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with emoji and styling")
    func textComponentWithEmojiAndStyling() {
        // Arrange
        let text = Text("Hello 👋", color: .yellow)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("Hello 👋"), "Should contain emoji text")
        #expect(lines[0].contains("\u{001B}[33m"), "Should contain yellow color code")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with CJK characters and styling")
    func textComponentWithCJKAndStyling() {
        // Arrange
        let text = Text("你好世界", color: .cyan)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("你好世界"), "Should contain CJK text")
        #expect(lines[0].contains("\u{001B}[36m"), "Should contain cyan color code")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with no styling should not add ANSI codes")
    func textComponentWithNoStyling() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "Hello", "Should contain only plain text")
        #expect(!lines[0].contains("\u{001B}["), "Should not contain ANSI codes")
    }

    @Test("Text component with empty content and styling")
    func textComponentWithEmptyContentAndStyling() {
        // Arrange
        let text = Text("", color: .red, bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].isEmpty, "Should be empty line for empty content")
    }

    @Test("Text component with RGB color")
    func textComponentWithRGBColor() {
        // Arrange
        let text = Text("Hello", color: .rgb(255, 128, 0))
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[38;2;255;128;0m"), "Should contain RGB color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with 256 color")
    func textComponentWith256Color() {
        // Arrange
        let text = Text("Hello", color: .color256(196))
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[38;5;196m"), "Should contain 256 color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    // MARK: - Snapshot Tests for Style Combinations (RUNE-29)

    @Test("Text component style combination snapshots")
    func textComponentStyleCombinationSnapshots() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Test various style combinations and verify their ANSI output
        let testCases: [(String, Text, String)] = [
            ("Plain text", Text("Hello World"), "Hello World"),
            ("Red text", Text("Hello World", color: .red), "\u{001B}[31mHello World\u{001B}[0m"),
            ("Bold text", Text("Hello World", bold: true), "\u{001B}[1mHello World\u{001B}[0m"),
            ("Red bold", Text("Hello World", color: .red, bold: true), "\u{001B}[1;31mHello World\u{001B}[0m"),
            ("Blue background", Text("Hello World", backgroundColor: .blue), "\u{001B}[44mHello World\u{001B}[0m"),
            ("All styles", Text("Hello", color: .yellow, backgroundColor: .magenta, bold: true, italic: true, underline: true), "\u{001B}[1;3;4;33;45mHello\u{001B}[0m"),
        ]

        for (description, text, expectedPattern) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")

            if expectedPattern.contains("\u{001B}[") {
                // For styled text, check that it contains ANSI codes and the content
                #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
                #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
                #expect(lines[0].contains("Hello"), "\(description): Should contain text content")
            } else {
                // For plain text, should match exactly
                #expect(lines[0] == expectedPattern, "\(description): Should match expected output")
            }
        }
    }

    @Test("Text component with emoji style combinations")
    func textComponentEmojiStyleCombinations() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text)] = [
            ("Emoji with color", Text("Hello 👋", color: .green)),
            ("Emoji with bold", Text("🎉 Party!", bold: true)),
            ("Emoji with multiple styles", Text("🚀 Launch", color: .cyan, bold: true, underline: true)),
            ("Complex emoji", Text("👨‍👩‍👧‍👦 Family", color: .yellow)),
            ("Flag emoji", Text("🇺🇸 USA", color: .white, backgroundColor: .blue)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
            // Verify emoji is preserved in output
            #expect(lines[0].unicodeScalars.contains { $0.properties.isEmoji }, "\(description): Should contain emoji")
        }
    }

    @Test("Text component with CJK style combinations")
    func textComponentCJKStyleCombinations() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text)] = [
            ("Chinese with color", Text("你好世界", color: .red)),
            ("Japanese with bold", Text("こんにちは", bold: true)),
            ("Korean with styles", Text("안녕하세요", color: .blue, italic: true)),
            ("Mixed CJK", Text("你好 こんにちは 안녕", color: .magenta, underline: true)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
            // Verify CJK characters are preserved
            let containsCJK = lines[0].unicodeScalars.contains { scalar in
                let value = scalar.value
                return (0x4E00...0x9FFF).contains(value) || // CJK Unified Ideographs
                       (0x3040...0x309F).contains(value) || // Hiragana
                       (0x30A0...0x30FF).contains(value) || // Katakana
                       (0xAC00...0xD7AF).contains(value)    // Hangul
            }
            #expect(containsCJK, "\(description): Should contain CJK characters")
        }
    }

    @Test("Text component with special characters and styling")
    func textComponentSpecialCharactersAndStyling() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        let testCases: [(String, Text)] = [
            ("Accented chars", Text("café naïve", color: .green)),
            ("Symbols", Text("© ® ™ ± ∞", bold: true)),
            ("Math symbols", Text("α β γ δ ε", color: .blue, italic: true)),
            ("Currency", Text("$ € £ ¥ ₹", color: .yellow, backgroundColor: .black)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
        }
    }

    @Test("Text component RGB and 256 color snapshots")
    func textComponentAdvancedColorSnapshots() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text, String)] = [
            ("RGB orange", Text("Orange", color: .rgb(255, 165, 0)), "38;2;255;165;0"),
            ("RGB purple", Text("Purple", color: .rgb(128, 0, 128)), "38;2;128;0;128"),
            ("256 color bright red", Text("Bright", color: .color256(196)), "38;5;196"),
            ("256 color dark blue", Text("Dark", color: .color256(18)), "38;5;18"),
        ]

        for (description, text, expectedColorCode) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains(expectedColorCode), "\(description): Should contain expected color code")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
        }
    }

    // MARK: - Color Bleed Prevention Tests (RUNE-29)

    @Test("Text component prevents color bleed at line boundaries")
    func textComponentPreventsColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Test that styled text always ends with reset code
        let styledText = Text("Hello", color: .red, bold: true)
        let lines = styledText.render(in: rect)

        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines[0].hasSuffix("\u{001B}[0m"), "First line should end with reset code")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(lines[2].isEmpty, "Third line should be empty")

        // Verify that empty lines don't contain any ANSI codes
        #expect(!lines[1].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
        #expect(!lines[2].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
    }

    @Test("Text component with multiple lines prevents color bleed")
    func textComponentMultiLinePreventsColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 2)

        // Test with content that gets truncated
        let styledText = Text("Hello World", color: .blue, underline: true)
        let lines = styledText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0].contains("Hello"), "Should contain truncated content")
        #expect(lines[0].hasSuffix("\u{001B}[0m"), "Styled line should end with reset")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(!lines[1].contains("\u{001B}["), "Empty line should not contain ANSI codes")
    }

    @Test("Text component reset code placement")
    func textComponentResetCodePlacement() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        let testCases: [(String, Text)] = [
            ("Single style", Text("Test", color: .red)),
            ("Multiple styles", Text("Test", color: .green, bold: true, italic: true)),
            ("Background color", Text("Test", backgroundColor: .yellow)),
            ("All styles", Text("Test", color: .white, backgroundColor: .black, bold: true, italic: true, underline: true, strikethrough: true, inverse: true, dim: true)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")

            let line = lines[0]
            #expect(line.hasSuffix("\u{001B}[0m"), "\(description): Should end with reset code")

            // Verify reset is at the very end (no trailing characters)
            let resetIndex = line.lastIndex(of: "m")
            #expect(resetIndex == line.index(before: line.endIndex), "\(description): Reset should be at the very end")
        }
    }

    @Test("Text component with empty content has no color bleed")
    func textComponentEmptyContentNoColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 2)

        // Even with styling, empty content should not produce ANSI codes
        let emptyStyledText = Text("", color: .red, bold: true)
        let lines = emptyStyledText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0].isEmpty, "First line should be empty")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(!lines[0].contains("\u{001B}["), "Empty content should not contain ANSI codes")
        #expect(!lines[1].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
    }

    @Test("Text component plain text has no ANSI codes")
    func textComponentPlainTextNoANSI() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 2)

        // Plain text should never contain ANSI codes
        let plainText = Text("Hello World")
        let lines = plainText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0] == "Hello World", "Should contain plain text")
        #expect(lines[1].isEmpty, "Second line should be empty")

        // Verify no ANSI codes anywhere
        for (index, line) in lines.enumerated() {
            #expect(!line.contains("\u{001B}["), "Line \(index) should not contain ANSI codes")
        }
    }
}
