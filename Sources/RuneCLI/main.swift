import Foundation
import RuneKit

/// RuneCLI - Example executable demonstrating RuneKit functionality
///
/// This CLI serves as both a demo of RuneKit capabilities and a test
/// that the package builds and runs correctly across platforms.

@main
struct RuneCLI {
    static func main() async {
        print("Hello, RuneKit! 🎉")
        print("")
        print("RuneKit is a Swift library for terminal UIs inspired by Ink.")
        print("This CLI demonstrates that the package builds and runs successfully.")
        print("")
        print("Available modules:")
        print("  • RuneANSI - ANSI escape code parsing")
        print("  • RuneUnicode - Unicode width calculations")
        print("  • RuneLayout - Flexbox layout engine")
        print("  • RuneRenderer - Terminal frame rendering")
        print("  • RuneComponents - UI components")
        print("")
        print("Build completed successfully! ✅")

        // Demonstrate basic functionality
        await demonstrateBasicFunctionality()

        // Demonstrate styled text spans
        demonstrateStyledTextSpans()

        // Demonstrate Unicode categories
        demonstrateUnicodeCategories()
    }

    /// Demonstrate basic RuneKit functionality
    static func demonstrateBasicFunctionality() async {
        print("\n--- Basic Functionality Demo ---")

        // Test ANSI tokenizer
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize("Hello World")
        print("ANSI Tokenizer: \(tokens.count) tokens from 'Hello World'")

        // Test width calculation with wcwidth bridge
        let testCases = [
            ("Hello", "ASCII text"),
            ("café", "Text with accents"),
            ("A\u{0300}", "A + combining grave"),
            ("\u{0007}", "Control character (BEL)"),
            ("\t", "Tab character"),
            ("世界", "CJK characters"),
        ]

        print("Unicode Width calculations (wcwidth bridge):")
        for (text, description) in testCases {
            let width = Width.displayWidth(of: text)
            print("  '\(text)' (\(description)): width = \(width)")
        }

        // Test layout calculation
        let children = [FlexLayout.Size(width: 5, height: 1)]
        let containerSize = FlexLayout.Size(width: 10, height: 3)
        let rects = FlexLayout.calculateLayout(children: children, containerSize: containerSize)
        print("Layout: Calculated \(rects.count) rectangles")

        // Test component rendering
        let text = Text("Demo")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)
        let lines = text.render(in: rect)
        print("Component: Text rendered to \(lines.count) lines")

        // Test renderer (without actually writing to terminal)
        _ = TerminalRenderer()
        print("Renderer: Created successfully")

        print("All modules working correctly! 🚀")
    }

    /// Demonstrate styled text spans functionality
    static func demonstrateStyledTextSpans() {
        print("\n--- Styled Text Spans Demo ---")

        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()

        // Example 1: Basic conversion
        print("\n1. Basic ANSI to Spans Conversion:")
        let input = "\u{001B}[1;31mError:\u{001B}[0m \u{001B}[33mWarning message\u{001B}[0m"
        let tokens = tokenizer.tokenize(input)
        let styledText = converter.tokensToStyledText(tokens)

        print("   Input: \(input)")
        print("   Parsed into \(styledText.spans.count) spans:")
        for (index, span) in styledText.spans.enumerated() {
            let attrs = span.attributes
            var attrDesc = ""
            if attrs.bold { attrDesc += "bold " }
            if let color = attrs.color { attrDesc += "\(color) " }
            print(
                "     \(index): '\(span.text)' (\(attrDesc.isEmpty ? "plain" : attrDesc.trimmingCharacters(in: .whitespaces)))",
            )
        }

        // Example 2: Merging spans
        print("\n2. Merging Adjacent Spans:")
        let redBold = TextAttributes(color: .red, bold: true)
        let spans = [
            TextSpan(text: "Hello ", attributes: redBold),
            TextSpan(text: "beautiful ", attributes: redBold),
            TextSpan(text: "world", attributes: redBold),
        ]
        let multiSpanText = StyledText(spans: spans)
        let merged = multiSpanText.mergingAdjacentSpans()

        print("   Before: \(multiSpanText.spans.count) spans")
        print("   After:  \(merged.spans.count) spans")
        print("   Result: '\(merged.plainText)'")

        // Example 3: Splitting text
        print("\n3. Splitting Text at Column Boundaries:")
        let mixedText = StyledText(spans: [
            TextSpan(text: "Hello ", attributes: TextAttributes(color: .red)),
            TextSpan(text: "beautiful ", attributes: TextAttributes(bold: true)),
            TextSpan(text: "world!", attributes: TextAttributes(color: .blue)),
        ])

        let (left, right) = mixedText.split(at: 10)
        print("   Original: '\(mixedText.plainText)' (\(mixedText.length) chars)")
        print("   Split at column 10:")
        print("     Left:  '\(left.plainText)' (\(left.spans.count) spans)")
        print("     Right: '\(right.plainText)' (\(right.spans.count) spans)")

        // Example 4: Round-trip verification
        print("\n4. Round-trip Conversion:")
        let originalTokens = tokenizer.tokenize("\u{001B}[38;2;255;165;0mRGB Orange\u{001B}[0m")
        let roundTripSpans = converter.tokensToStyledText(originalTokens)
        let backToTokens = converter.styledTextToTokens(roundTripSpans)
        let finalString = tokenizer.encode(backToTokens)

        print("   Original ANSI: \(tokenizer.encode(originalTokens))")
        print("   Round-trip:    \(finalString)")
        print("   Identical:     \(tokenizer.encode(originalTokens) == finalString)")

        print("\nStyled text spans working correctly! ✨")
    }

    /// Demonstrate Unicode categories and utf8proc integration
    static func demonstrateUnicodeCategories() {
        print("\n--- Unicode Categories Demo (utf8proc) ---")

        // Show Unicode version
        let version = UnicodeCategories.unicodeVersion()
        print("Unicode version: \(version)")
        print("")

        // Test various character categories
        let testCases: [(String, String)] = [
            ("A", "Uppercase letter"),
            ("a", "Lowercase letter"),
            ("5", "Decimal number"),
            ("Ⅴ", "Roman numeral"),
            (".", "Punctuation"),
            ("+", "Math symbol"),
            ("$", "Currency symbol"),
            ("👍", "Emoji"),
            ("❤", "Heart emoji"),
            ("世", "CJK character"),
            ("é", "Precomposed accent"),
            ("e\u{0301}", "Decomposed accent"),
            ("\u{0301}", "Combining mark"),
            ("\t", "Control character"),
        ]

        print("Character category analysis:")
        for (char, description) in testCases {
            if let scalar = char.unicodeScalars.first {
                let category = UnicodeCategories.category(of: scalar)
                let isCombining = UnicodeCategories.isCombining(scalar)
                let isEmoji = UnicodeCategories.isEmojiScalar(scalar)

                print("  '\(char)' (\(description))")
                print("    Category: \(category)")
                print("    Combining: \(isCombining)")
                print("    Emoji: \(isEmoji)")
                print("")
            }
        }

        // Demonstrate normalization
        print("Unicode normalization examples:")
        let normalizationCases = [
            ("é", "Precomposed"),
            ("e\u{0301}", "Decomposed"),
            ("ﬁ", "Ligature"),
        ]

        for (text, description) in normalizationCases {
            print("  \(description): '\(text)'")
            print("    NFC:  '\(UnicodeNormalization.normalize(text, form: .nfc))'")
            print("    NFD:  '\(UnicodeNormalization.normalize(text, form: .nfd))'")
            print("    NFKC: '\(UnicodeNormalization.normalize(text, form: .nfkc))'")
            print("    NFKD: '\(UnicodeNormalization.normalize(text, form: .nfkd))'")
            print("")
        }

        print("Unicode categories working correctly! 🎯")
    }
}
