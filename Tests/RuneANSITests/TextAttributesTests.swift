import Foundation
import Testing
@testable import RuneANSI

/// Tests for TextAttributes and basic styling functionality
struct TextAttributesTests {
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
        let _ = ANSIColor.blue

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

    // MARK: - Complex Attribute Combinations

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
}
