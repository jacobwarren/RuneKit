import Foundation
import Testing
@testable import RuneUnicode

/// Tests for Unicode category enum functionality
struct UnicodeCategoriesEnumTests {
    // MARK: - Unicode Category Enum Tests

    @Test("Number category detection")
    func numberCategoryDetection() {
        // Arrange
        let digit0 = Unicode.Scalar(48)! // '0'
        let romanOne = Unicode.Scalar(0x2160)! // Ⅰ (Roman numeral one)

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: digit0) == .decimalNumber,
            "Digit '0' should be categorized as decimal number",
        )
        #expect(
            UnicodeCategories.category(of: romanOne) == .letterNumber,
            "Roman numeral Ⅰ should be categorized as letter number",
        )
    }

    @Test("Punctuation category detection")
    func punctuationCategoryDetection() {
        // Arrange
        let period = Unicode.Scalar(46)! // '.'
        let openParen = Unicode.Scalar(40)! // '('
        let closeParen = Unicode.Scalar(41)! // ')'

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: period) == .otherPunctuation,
            "Period '.' should be categorized as other punctuation",
        )
        #expect(
            UnicodeCategories.category(of: openParen) == .openPunctuation,
            "Open parenthesis '(' should be categorized as open punctuation",
        )
        #expect(
            UnicodeCategories.category(of: closeParen) == .closePunctuation,
            "Close parenthesis ')' should be categorized as close punctuation",
        )
    }

    @Test("Symbol category detection")
    func symbolCategoryDetection() {
        // Arrange
        let plusSign = Unicode.Scalar(43)! // '+'
        let dollarSign = Unicode.Scalar(36)! // '$'

        // Act & Assert
        #expect(
            UnicodeCategories.category(of: plusSign) == .mathSymbol,
            "Plus sign '+' should be categorized as math symbol",
        )
        #expect(
            UnicodeCategories.category(of: dollarSign) == .currencySymbol,
            "Dollar sign '$' should be categorized as currency symbol",
        )
    }
}
