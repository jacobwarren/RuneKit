import Foundation
import Testing
@testable import RuneANSI

/// Tests for ANSI token to styled text conversion and round-trip functionality
struct ANSIConversionTests {
    // MARK: - ANSI Tokens to Spans Conversion Tests

    @Test("Convert plain text tokens to spans")
    func tokensToSpansPlainText() {
        // Arrange
        let tokens: [ANSIToken] = [.text("Hello World")]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 1, "Should have one span")
        #expect(styledText.spans[0].text == "Hello World", "Text should be preserved")
        #expect(styledText.spans[0].attributes.isDefault, "Should have default attributes")
    }

    @Test("Convert simple SGR tokens to spans")
    func tokensToSpansSimpleSGR() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([31]), // Red color
            .text("Red Text"),
            .sgr([0]), // Reset
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 1, "Should have one span")
        #expect(styledText.spans[0].text == "Red Text", "Text should be preserved")
        #expect(styledText.spans[0].attributes.color == .red, "Should have red color")
    }

    @Test("Convert multiple SGR tokens to spans")
    func tokensToSpansMultipleSGR() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([1]), // Bold
            .text("Bold "),
            .sgr([31]), // Add red color
            .text("Bold Red"),
            .sgr([0]), // Reset
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 2, "Should have two spans")
        #expect(styledText.spans[0].text == "Bold ", "First span text")
        #expect(styledText.spans[0].attributes.bold == true, "First span should be bold")
        #expect(styledText.spans[0].attributes.color == nil, "First span should have no color")

        #expect(styledText.spans[1].text == "Bold Red", "Second span text")
        #expect(styledText.spans[1].attributes.bold == true, "Second span should be bold")
        #expect(styledText.spans[1].attributes.color == .red, "Second span should be red")
    }

    @Test("Convert mixed tokens with non-SGR sequences")
    func tokensToSpansMixed() {
        // Arrange
        let tokens: [ANSIToken] = [
            .text("Before "),
            .cursor(3, "A"), // Non-SGR token (should be ignored for styling)
            .sgr([31]),
            .text("Red"),
            .sgr([0]),
            .text(" After"),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 3, "Should have three spans")
        #expect(styledText.spans[0].text == "Before ", "First span")
        #expect(styledText.spans[1].text == "Red", "Second span")
        #expect(styledText.spans[1].attributes.color == .red, "Second span should be red")
        #expect(styledText.spans[2].text == " After", "Third span")
    }

    @Test("Convert 256-color tokens to spans")
    func tokensToSpans256Color() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([38, 5, 196]), // 256-color red foreground
            .text("256 Red"),
            .sgr([48, 5, 21]), // 256-color blue background
            .text(" with Blue BG"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 2, "Should have two spans")
        #expect(styledText.spans[0].attributes.color == .color256(196), "First span should have 256-color red")
        #expect(styledText.spans[1].attributes.color == .color256(196), "Second span should inherit color")
        #expect(
            styledText.spans[1].attributes.backgroundColor == .color256(21),
            "Second span should have blue background",
        )
    }

    @Test("Convert RGB color tokens to spans")
    func tokensToSpansRGBColor() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([38, 2, 255, 128, 0]), // RGB orange foreground
            .text("RGB Orange"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 1, "Should have one span")
        #expect(styledText.spans[0].attributes.color == .rgb(255, 128, 0), "Should have RGB orange color")
    }

    @Test("Convert empty token array")
    func tokensToSpansEmpty() {
        // Arrange
        let tokens: [ANSIToken] = []
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.isEmpty, "Should have no spans")
        #expect(styledText.plainText.isEmpty, "Plain text should be empty")
    }

    @Test("Convert tokens with only SGR (no text)")
    func tokensToSpansOnlySGR() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([1]),
            .sgr([31]),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.isEmpty, "Should have no spans when no text")
    }

    // MARK: - Spans to ANSI Tokens Conversion Tests

    @Test("Convert plain text spans to tokens")
    func spansToTokensPlainText() {
        // Arrange
        let span = TextSpan(text: "Hello World", attributes: TextAttributes())
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.count == 1, "Should have one token")
        #expect(tokens[0] == .text("Hello World"), "Should be plain text token")
    }

    @Test("Convert styled spans to tokens")
    func spansToTokensStyled() {
        // Arrange
        let attributes = TextAttributes(color: .red, bold: true)
        let span = TextSpan(text: "Bold Red", attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.count == 3, "Should have SGR, text, and reset tokens")

        // Check SGR token contains both bold and red
        if case let .sgr(params) = tokens[0] {
            #expect(params.contains(1), "Should contain bold parameter")
            #expect(params.contains(31), "Should contain red parameter")
        } else {
            #expect(Bool(false), "First token should be SGR")
        }

        #expect(tokens[1] == .text("Bold Red"), "Second token should be text")
        #expect(tokens[2] == .sgr([0]), "Third token should be reset")
    }

    @Test("Convert multiple spans to tokens")
    func spansToTokensMultiple() {
        // Arrange
        let span1 = TextSpan(text: "Plain ", attributes: TextAttributes())
        let span2 = TextSpan(text: "Bold", attributes: TextAttributes(bold: true))
        let span3 = TextSpan(text: " Red", attributes: TextAttributes(color: .red))
        let styledText = StyledText(spans: [span1, span2, span3])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.count == 6, "Should have 6 tokens: text, SGR, text, SGR, text, reset")
        #expect(tokens[0] == .text("Plain "), "First token should be plain text")
        #expect(tokens[1] == .sgr([1]), "Second token should be bold SGR")
        #expect(tokens[2] == .text("Bold"), "Third token should be bold text")
        #expect(tokens[3] == .sgr([31]), "Fourth token should be red SGR")
        #expect(tokens[4] == .text(" Red"), "Fifth token should be red text")
        #expect(tokens[5] == .sgr([0]), "Sixth token should be reset")
    }

    @Test("Convert 256-color spans to tokens")
    func spansToTokens256Color() {
        // Arrange
        let attributes = TextAttributes(color: .color256(196))
        let span = TextSpan(text: "256 Red", attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.count == 3, "Should have SGR, text, and reset tokens")
        #expect(tokens[0] == .sgr([38, 5, 196]), "Should have 256-color SGR")
        #expect(tokens[1] == .text("256 Red"), "Should have text")
        #expect(tokens[2] == .sgr([0]), "Should have reset")
    }

    @Test("Convert RGB color spans to tokens")
    func spansToTokensRGBColor() {
        // Arrange
        let attributes = TextAttributes(color: .rgb(255, 128, 0))
        let span = TextSpan(text: "RGB Orange", attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.count == 3, "Should have SGR, text, and reset tokens")
        #expect(tokens[0] == .sgr([38, 2, 255, 128, 0]), "Should have RGB SGR")
        #expect(tokens[1] == .text("RGB Orange"), "Should have text")
        #expect(tokens[2] == .sgr([0]), "Should have reset")
    }

    @Test("Convert empty styled text to tokens")
    func spansToTokensEmpty() {
        // Arrange
        let styledText = StyledText(spans: [])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(tokens.isEmpty, "Should have no tokens")
    }

    // MARK: - Edge Case Tests

    @Test("Handle malformed SGR parameters gracefully")
    func malformedSGRParameters() {
        // Arrange
        let tokens: [ANSIToken] = [
            .sgr([38, 5]), // Incomplete 256-color sequence
            .text("Text"),
            .sgr([38, 2, 255]), // Incomplete RGB sequence
            .text("More"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styledText.spans.count == 2, "Should handle malformed sequences gracefully")
        #expect(styledText.plainText == "TextMore", "Text should be preserved")
    }
}
