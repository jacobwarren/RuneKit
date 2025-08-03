/// Example usage of styled text spans functionality
///
/// This file demonstrates how to use the styled text spans API for
/// processing ANSI-formatted text in terminal applications.

import Foundation

/// Example demonstrating styled text spans usage
public enum StyledTextExample {
    /// Demonstrates basic conversion between ANSI tokens and styled text spans
    public static func basicConversion() {
        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()

        // Parse ANSI-formatted text
        let input = "\u{001B}[1;31mError:\u{001B}[0m \u{001B}[33mWarning message\u{001B}[0m"
        let tokens = tokenizer.tokenize(input)

        // Convert to styled text spans
        let styledText = converter.tokensToStyledText(tokens)

        print("Original: \(input)")
        print("Spans:")
        for (index, span) in styledText.spans.enumerated() {
            print("  \(index): '\(span.text)' - \(span.attributes)")
        }

        // Convert back to ANSI
        let outputTokens = converter.styledTextToTokens(styledText)
        let output = tokenizer.encode(outputTokens)
        print("Round-trip: \(output)")
        print("Identical: \(input == output)")
    }

    /// Demonstrates merging adjacent spans with identical attributes
    public static func mergingSpans() {
        let converter = ANSISpanConverter()

        // Create styled text with adjacent spans that have the same attributes
        let redBold = TextAttributes(color: .red, bold: true)
        let spans = [
            TextSpan(text: "Hello ", attributes: redBold),
            TextSpan(text: "beautiful ", attributes: redBold),
            TextSpan(text: "world", attributes: redBold),
        ]
        let styledText = StyledText(spans: spans)

        print("Before merging: \(styledText.spans.count) spans")
        for span in styledText.spans {
            print("  '\(span.text)'")
        }

        // Merge adjacent spans
        let merged = styledText.mergingAdjacentSpans()

        print("After merging: \(merged.spans.count) spans")
        for span in merged.spans {
            print("  '\(span.text)'")
        }
    }

    /// Demonstrates splitting styled text at column boundaries
    public static func splittingText() {
        let converter = ANSISpanConverter()

        // Create styled text with multiple spans
        let styledText = StyledText(spans: [
            TextSpan(text: "Hello ", attributes: TextAttributes(color: .red)),
            TextSpan(text: "beautiful ", attributes: TextAttributes(bold: true)),
            TextSpan(text: "world!", attributes: TextAttributes(color: .blue)),
        ])

        print("Original text: '\(styledText.plainText)'")
        print("Length: \(styledText.length)")

        // Split at column 10
        let (left, right) = styledText.split(at: 10)

        print("Split at column 10:")
        print("  Left: '\(left.plainText)' (\(left.spans.count) spans)")
        print("  Right: '\(right.plainText)' (\(right.spans.count) spans)")

        // Demonstrate that attributes are preserved
        for (index, span) in left.spans.enumerated() {
            print("    Left span \(index): '\(span.text)' - \(span.attributes)")
        }
        for (index, span) in right.spans.enumerated() {
            print("    Right span \(index): '\(span.text)' - \(span.attributes)")
        }
    }

    /// Demonstrates working with complex color formats
    public static func complexColors() {
        let converter = ANSISpanConverter()

        // Create spans with different color formats
        let spans = [
            TextSpan(text: "Basic red ", attributes: TextAttributes(color: .red)),
            TextSpan(text: "256-color ", attributes: TextAttributes(color: .color256(196))),
            TextSpan(text: "RGB orange", attributes: TextAttributes(color: .rgb(255, 165, 0))),
        ]
        let styledText = StyledText(spans: spans)

        // Convert to ANSI tokens
        let tokens = converter.styledTextToTokens(styledText)
        let tokenizer = ANSITokenizer()
        let ansiString = tokenizer.encode(tokens)

        print("Complex colors ANSI: \(ansiString)")

        // Round-trip to verify preservation
        let parsedTokens = tokenizer.tokenize(ansiString)
        let roundTrip = converter.tokensToStyledText(parsedTokens)

        print("Round-trip verification:")
        for (index, span) in roundTrip.spans.enumerated() {
            print("  Span \(index): '\(span.text)' - Color: \(span.attributes.color ?? .white)")
        }
    }

    /// Demonstrates handling of all text attributes
    public static func allAttributes() {
        let converter = ANSISpanConverter()

        // Create a span with all possible attributes
        let allAttributes = TextAttributes(
            color: .cyan,
            backgroundColor: .black,
            bold: true,
            italic: true,
            underline: true,
            inverse: true,
            strikethrough: true,
            dim: true,
        )

        let span = TextSpan(text: "All attributes", attributes: allAttributes)
        let styledText = StyledText(spans: [span])

        // Convert to ANSI and back
        let tokens = converter.styledTextToTokens(styledText)
        let tokenizer = ANSITokenizer()
        let ansiString = tokenizer.encode(tokens)

        print("All attributes ANSI: \(ansiString)")

        // Verify round-trip
        let parsedTokens = tokenizer.tokenize(ansiString)
        let roundTrip = converter.tokensToStyledText(parsedTokens)
        let resultAttrs = roundTrip.spans[0].attributes

        print("Attribute preservation:")
        print("  Color: \(resultAttrs.color == allAttributes.color)")
        print("  Background: \(resultAttrs.backgroundColor == allAttributes.backgroundColor)")
        print("  Bold: \(resultAttrs.bold == allAttributes.bold)")
        print("  Italic: \(resultAttrs.italic == allAttributes.italic)")
        print("  Underline: \(resultAttrs.underline == allAttributes.underline)")
        print("  Inverse: \(resultAttrs.inverse == allAttributes.inverse)")
        print("  Strikethrough: \(resultAttrs.strikethrough == allAttributes.strikethrough)")
        print("  Dim: \(resultAttrs.dim == allAttributes.dim)")
    }

    /// Run all examples
    public static func runAllExamples() {
        print("=== Basic Conversion ===")
        basicConversion()

        print("\n=== Merging Spans ===")
        mergingSpans()

        print("\n=== Splitting Text ===")
        splittingText()

        print("\n=== Complex Colors ===")
        complexColors()

        print("\n=== All Attributes ===")
        allAttributes()
    }
}
