import Foundation
import Testing
@testable import RuneANSI

/// Tests for styled text spans functionality following TDD principles
struct StyledTextSpanTests {
    // MARK: - Text Attributes Tests

    @Test("Default text attributes should have no styling")
    func defaultTextAttributes() {
        // Arrange & Act
        let attributes = TextAttributes()

        // Assert
        #expect(attributes.color == nil, "Default color should be nil")
        #expect(attributes.backgroundColor == nil, "Default background color should be nil")
        #expect(attributes.bold == false, "Default bold should be false")
        #expect(attributes.italic == false, "Default italic should be false")
        #expect(attributes.underline == false, "Default underline should be false")
        #expect(attributes.inverse == false, "Default inverse should be false")
        #expect(attributes.strikethrough == false, "Default strikethrough should be false")
        #expect(attributes.dim == false, "Default dim should be false")
    }

    @Test("Text attributes with bold styling")
    func textAttributesBold() {
        // Arrange & Act
        let attributes = TextAttributes(bold: true)

        // Assert
        #expect(attributes.bold == true, "Bold should be true")
        #expect(attributes.italic == false, "Other attributes should remain default")
    }

    @Test("Text attributes with color")
    func textAttributesWithColor() {
        // Arrange & Act
        let attributes = TextAttributes(color: .red)

        // Assert
        #expect(attributes.color == .red, "Color should be red")
        #expect(attributes.bold == false, "Other attributes should remain default")
    }

    @Test("Text attributes equality")
    func textAttributesEquality() {
        // Arrange
        let attrs1 = TextAttributes(color: .red, bold: true)
        let attrs2 = TextAttributes(color: .red, bold: true)
        let attrs3 = TextAttributes(color: .blue, bold: true)

        // Act & Assert
        #expect(attrs1 == attrs2, "Identical attributes should be equal")
        #expect(attrs1 != attrs3, "Different attributes should not be equal")
    }

    // MARK: - Color Tests

    @Test("Basic ANSI colors")
    func basicANSIColors() {
        // Arrange & Act
        let red = ANSIColor.red
        let green = ANSIColor.green
        let blue = ANSIColor.blue

        // Assert
        #expect(red != green, "Different colors should not be equal")
        #expect(red == ANSIColor.red, "Same colors should be equal")
    }

    @Test("256-color palette")
    func testColor256() {
        // Arrange & Act
        let color196 = ANSIColor.color256(196) // Bright red
        let color21 = ANSIColor.color256(21) // Bright blue

        // Assert
        #expect(color196 != color21, "Different 256 colors should not be equal")
        #expect(color196 == ANSIColor.color256(196), "Same 256 colors should be equal")
    }

    @Test("RGB colors")
    func rGBColors() {
        // Arrange & Act
        let red = ANSIColor.rgb(255, 0, 0)
        let green = ANSIColor.rgb(0, 255, 0)
        let sameRed = ANSIColor.rgb(255, 0, 0)

        // Assert
        #expect(red != green, "Different RGB colors should not be equal")
        #expect(red == sameRed, "Same RGB colors should be equal")
    }

    // MARK: - Text Span Tests

    @Test("Text span with plain text")
    func textSpanPlain() {
        // Arrange & Act
        let span = TextSpan(text: "Hello World", attributes: TextAttributes())

        // Assert
        #expect(span.text == "Hello World", "Text should be preserved")
        #expect(span.attributes == TextAttributes(), "Attributes should be default")
    }

    @Test("Text span with styled attributes")
    func textSpanStyled() {
        // Arrange
        let attributes = TextAttributes(color: .red, bold: true)

        // Act
        let span = TextSpan(text: "Bold Red", attributes: attributes)

        // Assert
        #expect(span.text == "Bold Red", "Text should be preserved")
        #expect(span.attributes.color == .red, "Color should be red")
        #expect(span.attributes.bold == true, "Bold should be true")
    }

    @Test("Text span equality")
    func textSpanEquality() {
        // Arrange
        let attrs = TextAttributes(color: .blue)
        let span1 = TextSpan(text: "Hello", attributes: attrs)
        let span2 = TextSpan(text: "Hello", attributes: attrs)
        let span3 = TextSpan(text: "World", attributes: attrs)

        // Act & Assert
        #expect(span1 == span2, "Identical spans should be equal")
        #expect(span1 != span3, "Different spans should not be equal")
    }

    // MARK: - Styled Text Tests

    @Test("Styled text with single span")
    func styledTextSingleSpan() {
        // Arrange
        let span = TextSpan(text: "Hello", attributes: TextAttributes())

        // Act
        let styledText = StyledText(spans: [span])

        // Assert
        #expect(styledText.spans.count == 1, "Should have one span")
        #expect(styledText.spans[0] == span, "Span should be preserved")
    }

    @Test("Styled text with multiple spans")
    func styledTextMultipleSpans() {
        // Arrange
        let span1 = TextSpan(text: "Hello ", attributes: TextAttributes())
        let span2 = TextSpan(text: "World", attributes: TextAttributes(bold: true))

        // Act
        let styledText = StyledText(spans: [span1, span2])

        // Assert
        #expect(styledText.spans.count == 2, "Should have two spans")
        #expect(styledText.spans[0] == span1, "First span should be preserved")
        #expect(styledText.spans[1] == span2, "Second span should be preserved")
    }

    @Test("Styled text plain text extraction")
    func styledTextPlainText() {
        // Arrange
        let span1 = TextSpan(text: "Hello ", attributes: TextAttributes())
        let span2 = TextSpan(text: "World", attributes: TextAttributes(bold: true))
        let styledText = StyledText(spans: [span1, span2])

        // Act
        let plainText = styledText.plainText

        // Assert
        #expect(plainText == "Hello World", "Plain text should concatenate all span text")
    }

    @Test("Empty styled text")
    func emptyStyledText() {
        // Arrange & Act
        let styledText = StyledText(spans: [])

        // Assert
        #expect(styledText.spans.isEmpty, "Should have no spans")
        #expect(styledText.plainText == "", "Plain text should be empty")
    }

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
        #expect(styledText.plainText == "", "Plain text should be empty")
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
            #expect(false, "First token should be SGR")
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

    // MARK: - Round-trip Conversion Tests

    @Test("Round-trip conversion preserves plain text")
    func roundTripPlainText() {
        // Arrange
        let originalTokens: [ANSIToken] = [.text("Hello World")]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(originalTokens)
        let convertedTokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(convertedTokens == originalTokens, "Plain text should round-trip perfectly")
    }

    @Test("Round-trip conversion preserves simple styling")
    func roundTripSimpleStyling() {
        // Arrange
        let originalTokens: [ANSIToken] = [
            .sgr([31]),
            .text("Red Text"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(originalTokens)
        let convertedTokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(convertedTokens == originalTokens, "Simple styling should round-trip perfectly")
    }

    @Test("Round-trip conversion preserves complex styling")
    func roundTripComplexStyling() {
        // Arrange
        let originalTokens: [ANSIToken] = [
            .sgr([1, 31]), // Bold red
            .text("Bold Red "),
            .sgr([4]), // Add underline
            .text("Bold Red Underline"),
            .sgr([0]), // Reset
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(originalTokens)
        let convertedTokens = converter.styledTextToTokens(styledText)

        // Assert - Check that the styling is preserved (order may differ)
        #expect(convertedTokens.count == originalTokens.count, "Should have same number of tokens")

        // Verify the styled text has correct spans
        #expect(styledText.spans.count == 2, "Should have two spans")
        #expect(styledText.spans[0].attributes.bold == true, "First span should be bold")
        #expect(styledText.spans[0].attributes.color == .red, "First span should be red")
        #expect(styledText.spans[1].attributes.bold == true, "Second span should be bold")
        #expect(styledText.spans[1].attributes.color == .red, "Second span should be red")
        #expect(styledText.spans[1].attributes.underline == true, "Second span should be underlined")
    }

    @Test("Round-trip conversion preserves 256-color")
    func roundTrip256Color() {
        // Arrange
        let originalTokens: [ANSIToken] = [
            .sgr([38, 5, 196]),
            .text("256 Color"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(originalTokens)
        let convertedTokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(convertedTokens == originalTokens, "256-color should round-trip perfectly")
    }

    @Test("Round-trip conversion preserves RGB color")
    func roundTripRGBColor() {
        // Arrange
        let originalTokens: [ANSIToken] = [
            .sgr([38, 2, 255, 128, 0]),
            .text("RGB Color"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styledText = converter.tokensToStyledText(originalTokens)
        let convertedTokens = converter.styledTextToTokens(styledText)

        // Assert
        #expect(convertedTokens == originalTokens, "RGB color should round-trip perfectly")
    }

    // MARK: - Span Utilities Tests

    @Test("Merge adjacent compatible spans")
    func mergeAdjacentSpans() {
        // Arrange
        let attributes = TextAttributes(color: .red, bold: true)
        let span1 = TextSpan(text: "Hello ", attributes: attributes)
        let span2 = TextSpan(text: "World", attributes: attributes)
        let styledText = StyledText(spans: [span1, span2])

        // Act
        let merged = styledText.mergingAdjacentSpans()

        // Assert
        #expect(merged.spans.count == 1, "Should merge into one span")
        #expect(merged.spans[0].text == "Hello World", "Text should be concatenated")
        #expect(merged.spans[0].attributes == attributes, "Attributes should be preserved")
    }

    @Test("Don't merge spans with different attributes")
    func dontMergeDifferentAttributes() {
        // Arrange
        let attrs1 = TextAttributes(color: .red)
        let attrs2 = TextAttributes(color: .blue)
        let span1 = TextSpan(text: "Red ", attributes: attrs1)
        let span2 = TextSpan(text: "Blue", attributes: attrs2)
        let styledText = StyledText(spans: [span1, span2])

        // Act
        let merged = styledText.mergingAdjacentSpans()

        // Assert
        #expect(merged.spans.count == 2, "Should not merge different attributes")
        #expect(merged.spans[0] == span1, "First span should be unchanged")
        #expect(merged.spans[1] == span2, "Second span should be unchanged")
    }

    @Test("Merge multiple adjacent compatible spans")
    func mergeMultipleAdjacentSpans() {
        // Arrange
        let attributes = TextAttributes(bold: true)
        let span1 = TextSpan(text: "Hello ", attributes: attributes)
        let span2 = TextSpan(text: "beautiful ", attributes: attributes)
        let span3 = TextSpan(text: "world", attributes: attributes)
        let styledText = StyledText(spans: [span1, span2, span3])

        // Act
        let merged = styledText.mergingAdjacentSpans()

        // Assert
        #expect(merged.spans.count == 1, "Should merge all compatible spans")
        #expect(merged.spans[0].text == "Hello beautiful world", "All text should be concatenated")
        #expect(merged.spans[0].attributes == attributes, "Attributes should be preserved")
    }

    @Test("Split span at character boundary")
    func splitSpanAtBoundary() {
        // Arrange
        let attributes = TextAttributes(color: .red, bold: true)
        let span = TextSpan(text: "Hello World", attributes: attributes)

        // Act
        let (left, right) = span.split(at: 5)

        // Assert
        #expect(left.text == "Hello", "Left part should be 'Hello'")
        #expect(left.attributes == attributes, "Left part should preserve attributes")
        #expect(right.text == " World", "Right part should be ' World'")
        #expect(right.attributes == attributes, "Right part should preserve attributes")
    }

    @Test("Split span at beginning")
    func splitSpanAtBeginning() {
        // Arrange
        let attributes = TextAttributes(italic: true)
        let span = TextSpan(text: "Hello", attributes: attributes)

        // Act
        let (left, right) = span.split(at: 0)

        // Assert
        #expect(left.text == "", "Left part should be empty")
        #expect(left.attributes == attributes, "Left part should preserve attributes")
        #expect(right.text == "Hello", "Right part should be full text")
        #expect(right.attributes == attributes, "Right part should preserve attributes")
    }

    @Test("Split span at end")
    func splitSpanAtEnd() {
        // Arrange
        let attributes = TextAttributes(underline: true)
        let span = TextSpan(text: "Hello", attributes: attributes)

        // Act
        let (left, right) = span.split(at: 5)

        // Assert
        #expect(left.text == "Hello", "Left part should be full text")
        #expect(left.attributes == attributes, "Left part should preserve attributes")
        #expect(right.text == "", "Right part should be empty")
        #expect(right.attributes == attributes, "Right part should preserve attributes")
    }

    @Test("Split styled text at column boundary")
    func splitStyledTextAtColumn() {
        // Arrange
        let span1 = TextSpan(text: "Hello ", attributes: TextAttributes(color: .red))
        let span2 = TextSpan(text: "World", attributes: TextAttributes(bold: true))
        let styledText = StyledText(spans: [span1, span2])

        // Act - Split at column 8 (middle of "World")
        let (left, right) = styledText.split(at: 8)

        // Assert
        #expect(left.spans.count == 2, "Left should have two spans")
        #expect(left.spans[0].text == "Hello ", "First span should be complete")
        #expect(left.spans[1].text == "Wo", "Second span should be partial")

        #expect(right.spans.count == 1, "Right should have one span")
        #expect(right.spans[0].text == "rld", "Right span should have remaining text")
        #expect(right.spans[0].attributes.bold == true, "Right span should preserve attributes")
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

    @Test("Handle empty spans in merge")
    func mergeWithEmptySpans() {
        // Arrange
        let attributes = TextAttributes(bold: true)
        let span1 = TextSpan(text: "Hello", attributes: attributes)
        let span2 = TextSpan(text: "", attributes: attributes) // Empty span
        let span3 = TextSpan(text: "World", attributes: attributes)
        let styledText = StyledText(spans: [span1, span2, span3])

        // Act
        let merged = styledText.mergingAdjacentSpans()

        // Assert
        #expect(merged.spans.count == 1, "Should merge all spans including empty ones")
        #expect(merged.spans[0].text == "HelloWorld", "Text should be concatenated correctly")
    }

    @Test("Split at invalid indices")
    func splitAtInvalidIndices() {
        // Arrange
        let span = TextSpan(text: "Hello", attributes: TextAttributes(bold: true))

        // Act & Assert - Split beyond end
        let (left1, right1) = span.split(at: 100)
        #expect(left1.text == "Hello", "Left should be full text when splitting beyond end")
        #expect(right1.text == "", "Right should be empty when splitting beyond end")

        // Act & Assert - Split at negative index
        let (left2, right2) = span.split(at: -5)
        #expect(left2.text == "", "Left should be empty when splitting at negative index")
        #expect(right2.text == "Hello", "Right should be full text when splitting at negative index")
    }

    @Test("Complex attribute combinations")
    func complexAttributeCombinations() {
        // Arrange
        let attributes = TextAttributes(
            color: .rgb(255, 128, 64),
            backgroundColor: .color256(21),
            bold: true,
            italic: true,
            underline: true,
            inverse: true,
            strikethrough: true,
            dim: true,
        )
        let span = TextSpan(text: "Complex", attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)
        let roundTrip = converter.tokensToStyledText(tokens)

        // Assert
        #expect(roundTrip.spans.count == 1, "Should preserve complex attributes")
        let resultAttrs = roundTrip.spans[0].attributes
        #expect(resultAttrs.color == attributes.color, "Color should be preserved")
        #expect(resultAttrs.backgroundColor == attributes.backgroundColor, "Background color should be preserved")
        #expect(resultAttrs.bold == attributes.bold, "Bold should be preserved")
        #expect(resultAttrs.italic == attributes.italic, "Italic should be preserved")
        #expect(resultAttrs.underline == attributes.underline, "Underline should be preserved")
        #expect(resultAttrs.inverse == attributes.inverse, "Inverse should be preserved")
        #expect(resultAttrs.strikethrough == attributes.strikethrough, "Strikethrough should be preserved")
        #expect(resultAttrs.dim == attributes.dim, "Dim should be preserved")
    }

    @Test("Unicode text handling")
    func unicodeTextHandling() {
        // Arrange
        let unicodeText = "Hello 🌍 世界 🎉"
        let attributes = TextAttributes(color: .blue)
        let span = TextSpan(text: unicodeText, attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styledText)
        let roundTrip = converter.tokensToStyledText(tokens)

        // Assert
        #expect(roundTrip.plainText == unicodeText, "Unicode text should be preserved")
        #expect(roundTrip.spans[0].attributes.color == .blue, "Attributes should be preserved")
    }

    @Test("Large text performance")
    func largeTextPerformance() {
        // Arrange
        let largeText = String(repeating: "A", count: 10000)
        let attributes = TextAttributes(color: .red)
        let span = TextSpan(text: largeText, attributes: attributes)
        let styledText = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let startTime = Date()
        let tokens = converter.styledTextToTokens(styledText)
        let roundTrip = converter.tokensToStyledText(tokens)
        let endTime = Date()

        // Assert
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 0.1, "Large text conversion should be fast (< 100ms)")
        #expect(roundTrip.plainText == largeText, "Large text should be preserved")
    }
}
