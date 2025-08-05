import Foundation
import Testing
@testable import RuneANSI
@testable import RuneUnicode

/// Tests for TextSpan functionality and basic operations
struct TextSpanTests {
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

    // MARK: - Character-based Splitting Tests

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
        #expect(left.text.isEmpty, "Left part should be empty")
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
        #expect(right.text.isEmpty, "Right part should be empty")
        #expect(right.attributes == attributes, "Right part should preserve attributes")
    }

    @Test("Split at invalid indices")
    func splitAtInvalidIndices() {
        // Arrange
        let span = TextSpan(text: "Hello", attributes: TextAttributes(bold: true))

        // Act & Assert - Split beyond end
        let (left1, right1) = span.split(at: 100)
        #expect(left1.text == "Hello", "Left should be full text when splitting beyond end")
        #expect(right1.text.isEmpty, "Right should be empty when splitting beyond end")

        // Act & Assert - Split at negative index
        let (left2, right2) = span.split(at: -5)
        #expect(left2.text.isEmpty, "Left should be empty when splitting at negative index")
        #expect(right2.text == "Hello", "Right should be full text when splitting at negative index")
    }

    // MARK: - Display Width Splitting Tests

    @Test("Split span by display width with emoji")
    func splitSpanByDisplayWidthEmoji() {
        // Arrange
        let attributes = TextAttributes(color: .green)
        let span = TextSpan(text: "Hi👍Ok", attributes: attributes) // Hi(2) + 👍(2) + Ok(2) = 6 total

        // Act - Split at width 4 (should include Hi + 👍)
        let (left, right) = span.splitByDisplayWidth(at: 4)

        // Assert
        #expect(left.text == "Hi👍", "Left should include emoji")
        #expect(right.text == "Ok", "Right should be remaining text")
        #expect(left.attributes == attributes, "Attributes should be preserved")
    }

    @Test("Split span by display width with CJK")
    func splitSpanByDisplayWidthCJK() {
        // Arrange
        let attributes = TextAttributes(color: .blue)
        let span = TextSpan(text: "A世界B", attributes: attributes) // A(1) + 世(2) + 界(2) + B(1) = 6 total

        // Act - Split at width 3 (should include A + 世)
        let (left, right) = span.splitByDisplayWidth(at: 3)

        // Assert
        #expect(left.text == "A世", "Left should include first CJK character")
        #expect(right.text == "界B", "Right should include remaining characters")
    }

    @Test("Split span with last column guard")
    func splitSpanWithLastColumnGuard() {
        // Arrange
        let attributes = TextAttributes(color: .yellow)
        let span = TextSpan(text: "AB世", attributes: attributes) // A(1) + B(1) + 世(2) = 4 total

        // Act - Split at width 3 with guard (should prevent 世 at last column)
        let (left, right) = span.splitByDisplayWidth(at: 3, lastColumnGuard: true)

        // Assert
        #expect(left.text == "AB", "Left should stop before wide character")
        #expect(right.text == "世", "Right should contain wide character")
    }

    // MARK: - Unicode Edge Cases

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

    @Test("Zero-width characters handling")
    func zeroWidthCharactersHandling() {
        // Arrange - Text with combining marks (zero-width)
        let attributes = TextAttributes(color: .cyan)
        let text = "e\u{0301}a\u{0300}o\u{0302}" // e with acute, a with grave, o with circumflex
        let span = TextSpan(text: text, attributes: attributes)

        // Act
        let totalWidth = Width.displayWidth(of: text)
        let (left, _) = span.splitByDisplayWidth(at: 2)

        // Assert
        #expect(totalWidth == 3, "Should count base characters only, not combining marks")
        #expect(left.text.count >= 2, "Should include base characters with their combining marks")
    }
}
