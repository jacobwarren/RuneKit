import Testing
import Foundation
@testable import RuneANSI

/// Tests that run the styled text examples to demonstrate functionality
struct StyledTextExampleTests {
    
    @Test("Run basic conversion example")
    func testBasicConversionExample() {
        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()
        
        // Parse ANSI-formatted text
        let input = "\u{001B}[1;31mError:\u{001B}[0m \u{001B}[33mWarning message\u{001B}[0m"
        let tokens = tokenizer.tokenize(input)
        
        // Convert to styled text spans
        let styledText = converter.tokensToStyledText(tokens)
        
        print("=== Basic Conversion Example ===")
        print("Input (raw): \(input.debugDescription)")
        print("Spans:")
        for (index, span) in styledText.spans.enumerated() {
            let attrs = span.attributes
            var attrDesc = ""
            if attrs.bold { attrDesc += "bold " }
            if let color = attrs.color { attrDesc += "\(color) " }
            print("  \(index): '\(span.text)' (\(attrDesc.isEmpty ? "plain" : attrDesc.trimmingCharacters(in: .whitespaces)))")
        }

        // Convert back to ANSI
        let outputTokens = converter.styledTextToTokens(styledText)
        let output = tokenizer.encode(outputTokens)
        print("Round-trip (raw): \(output.debugDescription)")
        print("Identical: \(input == output)")
        
        // Verify the example works correctly
        #expect(styledText.spans.count == 3, "Should have 3 spans")

        // Check semantic equivalence - the plain text should be identical
        let roundTripTokens = tokenizer.tokenize(output)
        let outputSpans = converter.tokensToStyledText(roundTripTokens)

        #expect(styledText.plainText == outputSpans.plainText, "Plain text should be identical")

        // The output may have fewer spans due to optimization, but the content should be the same
        #expect(styledText.spans[0].text == "Error:", "First span should be 'Error:'")
        #expect(styledText.spans[0].attributes.bold == true, "First span should be bold")
        #expect(styledText.spans[0].attributes.color == .red, "First span should be red")

        #expect(styledText.spans[2].text == "Warning message", "Third span should be 'Warning message'")
        #expect(styledText.spans[2].attributes.color == .yellow, "Third span should be yellow")
    }
    
    @Test("Run merging spans example")
    func testMergingSpansExample() {
        // Create styled text with adjacent spans that have the same attributes
        let redBold = TextAttributes(color: .red, bold: true)
        let spans = [
            TextSpan(text: "Hello ", attributes: redBold),
            TextSpan(text: "beautiful ", attributes: redBold),
            TextSpan(text: "world", attributes: redBold)
        ]
        let styledText = StyledText(spans: spans)
        
        print("\n=== Merging Spans Example ===")
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
        
        // Verify the example works correctly
        #expect(styledText.spans.count == 3, "Should start with 3 spans")
        #expect(merged.spans.count == 1, "Should merge to 1 span")
        #expect(merged.spans[0].text == "Hello beautiful world", "Text should be concatenated")
    }
    
    @Test("Run splitting text example")
    func testSplittingTextExample() {
        // Create styled text with multiple spans
        let styledText = StyledText(spans: [
            TextSpan(text: "Hello ", attributes: TextAttributes(color: .red)),
            TextSpan(text: "beautiful ", attributes: TextAttributes(bold: true)),
            TextSpan(text: "world!", attributes: TextAttributes(color: .blue))
        ])
        
        print("\n=== Splitting Text Example ===")
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
        
        // Verify the example works correctly
        #expect(left.plainText == "Hello beau", "Left part should be 'Hello beau'")
        #expect(right.plainText == "tiful world!", "Right part should be 'tiful world!'")
        #expect(left.spans.count == 2, "Left should have 2 spans")
        #expect(right.spans.count == 2, "Right should have 2 spans")
    }
    
    @Test("Run complex colors example")
    func testComplexColorsExample() {
        let converter = ANSISpanConverter()
        
        // Create spans with different color formats
        let spans = [
            TextSpan(text: "Basic red ", attributes: TextAttributes(color: .red)),
            TextSpan(text: "256-color ", attributes: TextAttributes(color: .color256(196))),
            TextSpan(text: "RGB orange", attributes: TextAttributes(color: .rgb(255, 165, 0)))
        ]
        let styledText = StyledText(spans: spans)
        
        // Convert to ANSI tokens
        let tokens = converter.styledTextToTokens(styledText)
        let tokenizer = ANSITokenizer()
        let ansiString = tokenizer.encode(tokens)
        
        print("\n=== Complex Colors Example ===")
        print("Complex colors ANSI (raw): \(ansiString.debugDescription)")
        
        // Round-trip to verify preservation
        let parsedTokens = tokenizer.tokenize(ansiString)
        let roundTrip = converter.tokensToStyledText(parsedTokens)
        
        print("Round-trip verification:")
        for (index, span) in roundTrip.spans.enumerated() {
            print("  Span \(index): '\(span.text)' - Color: \(span.attributes.color ?? .white)")
        }
        
        // Verify the example works correctly
        #expect(roundTrip.spans.count == 3, "Should have 3 spans after round-trip")
        #expect(roundTrip.spans[0].attributes.color == .red, "First span should be red")
        #expect(roundTrip.spans[1].attributes.color == .color256(196), "Second span should be 256-color")
        #expect(roundTrip.spans[2].attributes.color == .rgb(255, 165, 0), "Third span should be RGB")
    }
    
    @Test("Run all attributes example")
    func testAllAttributesExample() {
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
            dim: true
        )
        
        let span = TextSpan(text: "All attributes", attributes: allAttributes)
        let styledText = StyledText(spans: [span])
        
        // Convert to ANSI and back
        let tokens = converter.styledTextToTokens(styledText)
        let tokenizer = ANSITokenizer()
        let ansiString = tokenizer.encode(tokens)
        
        print("\n=== All Attributes Example ===")
        print("All attributes ANSI (raw): \(ansiString.debugDescription)")
        
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
        
        // Verify all attributes are preserved
        #expect(resultAttrs.color == allAttributes.color, "Color should be preserved")
        #expect(resultAttrs.backgroundColor == allAttributes.backgroundColor, "Background should be preserved")
        #expect(resultAttrs.bold == allAttributes.bold, "Bold should be preserved")
        #expect(resultAttrs.italic == allAttributes.italic, "Italic should be preserved")
        #expect(resultAttrs.underline == allAttributes.underline, "Underline should be preserved")
        #expect(resultAttrs.inverse == allAttributes.inverse, "Inverse should be preserved")
        #expect(resultAttrs.strikethrough == allAttributes.strikethrough, "Strikethrough should be preserved")
        #expect(resultAttrs.dim == allAttributes.dim, "Dim should be preserved")
    }
}
