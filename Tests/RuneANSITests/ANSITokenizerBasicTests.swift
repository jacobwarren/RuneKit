import Testing
@testable import RuneANSI

/// Basic tests for ANSI tokenizer functionality
struct ANSITokenizerBasicTests {
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
}
