import Foundation
import Testing
@testable import RuneANSI

/// Tests for invalid color handling and inverse interactions (RUNE-35)
struct InvalidColorAndInverseTests {
    @Test("Invalid 256-color SGR parameter is ignored gracefully")
    func invalid256ColorParameterIgnored() {
        // Arrange: SGR 38;5;999 is invalid (index out of range)
        let tokens: [ANSIToken] = [
            .sgr([38, 5, 999]),
            .text("X"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styled = converter.tokensToStyledText(tokens)

        // Assert: No foreground color should be applied
        #expect(styled.spans.count == 1, "Should have single span of text")
        #expect(styled.spans[0].text == "X", "Text should be preserved")
        #expect(styled.spans[0].attributes.color == nil, "Invalid 256-color should be ignored")
    }

    @Test("Invalid RGB SGR parameters are ignored gracefully")
    func invalidRGBParametersIgnored() {
        // Arrange: SGR 38;2;300;-1;256 (components out of 0...255)
        let tokens: [ANSIToken] = [
            .sgr([38, 2, 300, -1, 256]),
            .text("Y"),
            .sgr([0]),
        ]
        let converter = ANSISpanConverter()

        // Act
        let styled = converter.tokensToStyledText(tokens)

        // Assert
        #expect(styled.spans.count == 1, "Should have single span of text")
        #expect(styled.spans[0].text == "Y", "Text should be preserved")
        #expect(styled.spans[0].attributes.color == nil, "Invalid RGB color should be ignored")
    }

    @Test("Generator omits SGR for invalid color values in attributes")
    func generatorOmitsInvalidAttributeColors() {
        // Arrange: Attributes contain invalid values
        let attrs = TextAttributes(
            color: .rgb(300, -1, 256), // invalid
            backgroundColor: .color256(300), // invalid
            bold: true,
        )
        let span = TextSpan(text: "Z", attributes: attrs)
        let styled = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styled)

        // Assert: Tokens should include bold SGR but no 38;2 or 48;5 sequences
        // Flatten to ANSI string for easier searching
        let ansi = ANSITokenizer().encode(tokens)
        #expect(ansi.contains("\u{001B}[1m"), "Bold code should be present")
        #expect(!ansi.contains("\u{001B}[38;2"), "Invalid RGB should not be emitted")
        #expect(!ansi.contains("\u{001B}[48;5"), "Invalid 256 bg should not be emitted")
        #expect(ansi.contains("Z"), "Text should be present")
        #expect(ansi.contains("\u{001B}[0m"), "Reset should still be emitted since a style was applied")
    }

    @Test("Inverse with explicit fg and bg keeps both color codes")
    func inverseWithExplicitColorsKeepsCodes() {
        // Arrange
        let attrs = TextAttributes(
            color: .red,
            backgroundColor: .blue,
            inverse: true,
        )
        let span = TextSpan(text: "inv", attributes: attrs)
        let styled = StyledText(spans: [span])
        let converter = ANSISpanConverter()

        // Act
        let tokens = converter.styledTextToTokens(styled)
        let ansi = ANSITokenizer().encode(tokens)

        // Assert: Should contain inverse (7), red fg (31) and blue bg (44)
        #expect(ansi.contains("\u{001B}["), "Should contain SGR")
        #expect(ansi.contains("7"), "Should contain inverse code 7")
        #expect(ansi.contains("31"), "Should contain red fg code 31")
        #expect(ansi.contains("44"), "Should contain blue bg code 44")
        #expect(ansi.contains("inv"), "Should contain text content")
        #expect(ansi.contains("\u{001B}[0m"), "Should reset at end")
    }
}
