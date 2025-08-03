import Testing
@testable import RuneANSI

/// Tests for ANSI tokenizer functionality following TDD principles
struct ANSITokenizerTests {
    
    // MARK: - Basic Tokenization Tests
    
    @Test("Empty string returns empty array")
    func testTokenizeEmptyString() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = ""
        
        // Act
        let tokens = tokenizer.tokenize(input)
        
        // Assert
        #expect(tokens.isEmpty, "Empty string should return empty token array")
    }
    
    @Test("Plain text without ANSI codes")
    func testTokenizePlainText() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "Hello World"
        
        // Act
        let tokens = tokenizer.tokenize(input)
        
        // Assert
        #expect(tokens == [.text("Hello World")], "Plain text should be tokenized as single text token")
    }
    
    // MARK: - SGR (Styling) Tests - These will initially fail
    
    @Test("Simple SGR color code", .disabled("Will be implemented in next iteration"))
    func testTokenizeSimpleSGR() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[31mRed Text\u{001B}[0m"
        
        // Act
        let tokens = tokenizer.tokenize(input)
        
        // Assert
        let expected: [ANSIToken] = [
            .sgr([31]),
            .text("Red Text"),
            .sgr([0])
        ]
        #expect(tokens == expected, "SGR codes should be properly tokenized")
    }
    
    @Test("Multiple SGR parameters", .disabled("Will be implemented in next iteration"))
    func testTokenizeMultipleSGRParameters() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[1;31mBold Red\u{001B}[0m"
        
        // Act
        let tokens = tokenizer.tokenize(input)
        
        // Assert
        let expected: [ANSIToken] = [
            .sgr([1, 31]),
            .text("Bold Red"),
            .sgr([0])
        ]
        #expect(tokens == expected, "Multiple SGR parameters should be parsed correctly")
    }
    
    // MARK: - Cursor Movement Tests - These will initially fail
    
    @Test("Cursor up movement", .disabled("Will be implemented in next iteration"))
    func testTokenizeCursorUp() {
        // Arrange
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[3A"
        
        // Act
        let tokens = tokenizer.tokenize(input)
        
        // Assert
        #expect(tokens == [.cursor(3, "A")], "Cursor up should be tokenized correctly")
    }
    
    // MARK: - Mixed Content Tests - These will initially fail
    
    @Test("Mixed text and ANSI codes", .disabled("Will be implemented in next iteration"))
    func testTokenizeMixedContent() {
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
            .text(" World")
        ]
        #expect(tokens == expected, "Mixed content should be tokenized correctly")
    }
}
