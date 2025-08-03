import Testing
@testable import RuneANSI

/// Tests for ANSI tokenizer functionality following TDD principles
struct ANSITokenizerTests {
    // MARK: - Basic Tokenization Tests

    @Test("Empty string returns empty array")
    func tokenizeEmptyString() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = ""

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens.isEmpty, "Empty string should return empty token array")
    }

    @Test("Plain text without ANSI codes")
    func tokenizePlainText() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Hello World"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.text("Hello World")], "Plain text should be tokenized as single text token")
    }

    // MARK: - SGR (Styling) Tests - These will initially fail

    @Test("Simple SGR color code")
    func tokenizeSimpleSGR() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[31mRed Text\u{001B}[0m"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .sgr([31]),
            .text("Red Text"),
            .sgr([0]),
        ]
        #expect(tokens == expected, "SGR codes should be properly tokenized")
    }

    @Test("Multiple SGR parameters")
    func tokenizeMultipleSGRParameters() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[1;31mBold Red\u{001B}[0m"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .sgr([1, 31]),
            .text("Bold Red"),
            .sgr([0]),
        ]
        #expect(tokens == expected, "Multiple SGR parameters should be parsed correctly")
    }

    // MARK: - Cursor Movement Tests - These will initially fail

    @Test("Cursor up movement")
    func tokenizeCursorUp() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[3A"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.cursor(3, "A")], "Cursor up should be tokenized correctly")
    }

    // MARK: - Mixed Content Tests - These will initially fail

    @Test("Mixed text and ANSI codes")
    func tokenizeMixedContent() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Hello \u{001B}[31mRed\u{001B}[0m World"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .text("Hello "),
            .sgr([31]),
            .text("Red"),
            .sgr([0]),
            .text(" World"),
        ]
        #expect(tokens == expected, "Mixed content should be tokenized correctly")
    }

    // MARK: - OSC (Operating System Command) Tests

    @Test("OSC title setting with BEL terminator")
    func tokenizeOSCTitleBEL() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}]0;Terminal Title\u{0007}"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.osc("0", "Terminal Title")], "OSC title with BEL should be tokenized correctly")
    }

    @Test("OSC title setting with ESC\\ terminator")
    func tokenizeOSCTitleESC() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}]0;Terminal Title\u{001B}\\"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.osc("0", "Terminal Title")], "OSC title with ESC\\ should be tokenized correctly")
    }

    @Test("OSC with text before and after")
    func tokenizeOSCMixed() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Before \u{001B}]0;Title\u{0007} After"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .text("Before "),
            .osc("0", "Title"),
            .text(" After"),
        ]
        #expect(tokens == expected, "OSC mixed with text should be tokenized correctly")
    }

    // MARK: - Erase Sequence Tests

    @Test("Erase display from cursor to end")
    func tokenizeEraseDisplayToEnd() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[0J"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.erase(0, "J")], "Erase display to end should be tokenized correctly")
    }

    @Test("Erase entire display")
    func tokenizeEraseEntireDisplay() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[2J"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.erase(2, "J")], "Erase entire display should be tokenized correctly")
    }

    @Test("Erase line from cursor to end")
    func tokenizeEraseLineToEnd() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[K"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.erase(0, "K")], "Erase line to end should be tokenized correctly")
    }

    @Test("Erase entire line")
    func tokenizeEraseEntireLine() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[2K"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        #expect(tokens == [.erase(2, "K")], "Erase entire line should be tokenized correctly")
    }

    // MARK: - Round-trip Encoding Tests

    @Test("Round-trip SGR sequences")
    func roundTripSGR() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[31mRed\u{001B}[1;32mBold Green\u{001B}[0m"

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "SGR sequences should round-trip perfectly")
    }

    @Test("Round-trip cursor movement")
    func roundTripCursor() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[3A\u{001B}[5C"

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "Cursor movement should round-trip perfectly")
    }

    @Test("Round-trip erase sequences")
    func roundTripErase() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[2J\u{001B}[K"

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "Erase sequences should round-trip perfectly")
    }

    @Test("Round-trip OSC sequences")
    func roundTripOSC() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}]0;Terminal Title\u{0007}"

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "OSC sequences should round-trip perfectly")
    }

    @Test("Round-trip mixed content")
    func roundTripMixed() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Hello \u{001B}[31mRed\u{001B}[0m World \u{001B}[3A"

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "Mixed content should round-trip perfectly")
    }

    // MARK: - Comprehensive Snapshot Tests

    @Test("Complex nested styling")
    func tokenizeNestedStyling() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[1mBold \u{001B}[31mBold Red \u{001B}[4mBold Red Underline\u{001B}[0m Normal"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .sgr([1]),
            .text("Bold "),
            .sgr([31]),
            .text("Bold Red "),
            .sgr([4]),
            .text("Bold Red Underline"),
            .sgr([0]),
            .text(" Normal"),
        ]
        #expect(tokens == expected, "Nested styling should be tokenized correctly")
    }

    @Test("256-color and RGB color codes")
    func tokenizeExtendedColors() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[38;5;196mRed256\u{001B}[38;2;255;0;0mRGB Red\u{001B}[0m"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .sgr([38, 5, 196]),
            .text("Red256"),
            .sgr([38, 2, 255, 0, 0]),
            .text("RGB Red"),
            .sgr([0]),
        ]
        #expect(tokens == expected, "Extended color codes should be tokenized correctly")
    }

    @Test("Complex cursor movement sequence")
    func tokenizeComplexCursorMovement() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[H\u{001B}[2J\u{001B}[10;20HText\u{001B}[3A\u{001B}[5C"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .cursor(1, "H"),
            .erase(2, "J"),
            .cursor(10, "H"), // Note: This is simplified - real H command takes row;col
            .text("Text"),
            .cursor(3, "A"),
            .cursor(5, "C"),
        ]
        #expect(tokens.count == 6, "Complex cursor sequence should produce 6 tokens")
        #expect(tokens[0] == .cursor(1, "H"), "First token should be cursor home")
        #expect(tokens[1] == .erase(2, "J"), "Second token should be clear screen")
    }

    @Test("Multiple OSC sequences")
    func tokenizeMultipleOSC() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}]0;Window Title\u{0007}\u{001B}]1;Icon Name\u{0007}Text\u{001B}]2;Window Title Only\u{0007}"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .osc("0", "Window Title"),
            .osc("1", "Icon Name"),
            .text("Text"),
            .osc("2", "Window Title Only"),
        ]
        #expect(tokens == expected, "Multiple OSC sequences should be tokenized correctly")
    }

    @Test("Real-world terminal output snapshot")
    func tokenizeRealWorldOutput() {
        // Arrange
        let tokenizer = ANSITokenizer()
        // Simulates output from a typical CLI tool with colors and formatting
        let input = """
        \u{001B}[32m✓\u{001B}[0m \u{001B}[1mSuccess:\u{001B}[0m Operation completed
        \u{001B}[31m✗\u{001B}[0m \u{001B}[1mError:\u{001B}[0m \u{001B}[31mSomething went wrong\u{001B}[0m
        \u{001B}[33m⚠\u{001B}[0m \u{001B}[1mWarning:\u{001B}[0m \u{001B}[33mCheck this\u{001B}[0m
        """

        // Act
        let tokens = tokenizer.tokenize(input)
        let encoded = tokenizer.encode(tokens)

        // Assert
        #expect(encoded == input, "Real-world output should round-trip perfectly")
        #expect(tokens.count > 10, "Real-world output should produce multiple tokens")

        // Verify specific patterns
        let hasGreenCheckmark = tokens.contains { token in
            if case let .sgr(params) = token, params == [32] { return true }
            return false
        }
        #expect(hasGreenCheckmark, "Should contain green color code for checkmark")
    }

    // MARK: - Invalid/Partial Sequence Tests

    @Test("Incomplete escape sequence at end of string")
    func tokenizeIncompleteEscape() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Hello \u{001B}["

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        let expected: [ANSIToken] = [
            .text("Hello "),
            .text("\u{001B}"),
            .text("["),
        ]
        #expect(tokens == expected, "Incomplete escape should be treated as text")
    }

    @Test("Invalid CSI sequence with non-numeric parameters")
    func tokenizeInvalidCSI() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[abcm"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        // The sequence \u{001B}[a is a valid CSI sequence (though 'a' is not a recognized command)
        // so it gets parsed as a control sequence, and "bcm" becomes text
        let expected: [ANSIToken] = [
            .control("\u{001B}[a"),
            .text("bcm"),
        ]
        #expect(tokens == expected, "Invalid CSI should be parsed as control + text")
    }

    @Test("Escape sequence without final character")
    func tokenizeEscapeWithoutFinal() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Text \u{001B}[31 More text"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        // Should recover and continue parsing after the malformed sequence
        #expect(tokens.count >= 2, "Should recover from malformed sequence")
        #expect(tokens[0] == .text("Text "), "Text before malformed sequence should be preserved")
    }

    @Test("OSC sequence without terminator")
    func tokenizeOSCWithoutTerminator() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Before \u{001B}]0;Title without terminator"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        // Should treat the incomplete OSC as text after the escape
        #expect(tokens.count >= 1, "Should handle OSC without terminator")
        #expect(tokens[0] == .text("Before "), "Text before OSC should be preserved")
    }

    @Test("Mixed valid and invalid sequences")
    func tokenizeMixedValidInvalid() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[31mValid\u{001B}[invalidMore\u{001B}[0mValid again"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        // Should parse valid sequences and handle invalid ones gracefully
        #expect(tokens.count >= 3, "Should handle mix of valid and invalid sequences")
        #expect(tokens[0] == .sgr([31]), "First valid SGR should be parsed")
        #expect(tokens[1] == .text("Valid"), "Text should be preserved")

        // The invalid sequence should be handled somehow (either as control or text)
        let hasValidReset = tokens.contains { token in
            if case let .sgr(params) = token, params == [0] { return true }
            return false
        }
        #expect(hasValidReset, "Valid reset sequence should still be parsed")
    }

    @Test("Empty parameters in CSI sequence")
    func tokenizeEmptyCSIParameters() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[;;m"

        // Act
        let tokens = tokenizer.tokenize(input)

        // Assert
        // Should handle empty parameters gracefully
        #expect(tokens.count == 1, "Empty parameters should produce one token")
        if case let .sgr(params) = tokens[0] {
            // Empty parameters should be treated as 0 or filtered out
            #expect(params.isEmpty || params == [0], "Empty parameters should be handled gracefully")
        } else {
            #expect(false, "Should still be recognized as SGR sequence")
        }
    }
}
