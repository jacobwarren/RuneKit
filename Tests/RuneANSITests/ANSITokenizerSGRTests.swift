import Testing
@testable import RuneANSI

/// Tests for ANSI tokenizer SGR (styling) functionality
struct ANSITokenizerSGRTests {
    // MARK: - SGR (Styling) Tests

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
}
