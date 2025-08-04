import Foundation
import Testing
@testable import RuneANSI

/// Tests for StyledText operations like merging, splitting, and basic manipulation
struct StyledTextOperationsTests {
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
        #expect(styledText.plainText.isEmpty, "Plain text should be empty")
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

    // MARK: - Character-based Splitting Tests

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

    // MARK: - Performance Tests

    @Test("Large text performance")
    func largeTextPerformance() {
        // Arrange
        let largeText = String(repeating: "A", count: 10_000)
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
