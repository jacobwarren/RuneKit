import Foundation
import RuneKit

/// RuneCLI - Example executable demonstrating RuneKit functionality
///
/// This CLI serves as both a demo of RuneKit capabilities and a test
/// that the package builds and runs correctly across platforms.

@main
struct RuneCLI {
    /// Test emoji width calculations
    static func testEmojiWidths() {
        print("🔍 Testing Emoji Width Calculations")
        print("===================================")

        let testEmojis = [
            "✅",  // Check mark (U+2705)
            "📦",  // Package (U+1F4E6)
            "👍",  // Thumbs up
            "🎯",  // Direct hit
        ]

        for emoji in testEmojis {
            let width = Width.displayWidth(of: emoji)
            let scalars = Array(emoji.unicodeScalars)
            let scalarInfo = scalars.map { "U+\(String($0.value, radix: 16, uppercase: true))" }.joined(separator: " ")

            print("Emoji: '\(emoji)' → width: \(width) (scalars: \(scalarInfo))")
        }

        // Test the specific problematic content
        let completeText = "Complete! ✅"
        let shrunkText = "Shrunk! 📦"

        print("\nFull strings:")
        print("'\(completeText)' → width: \(Width.displayWidth(of: completeText))")
        print("'\(shrunkText)' → width: \(Width.displayWidth(of: shrunkText))")
        print("")
    }

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

        // Test emoji widths
        testEmojiWidths()

        // Demonstrate basic functionality
        await demonstrateBasicFunctionality()

        // Demonstrate styled text spans
        demonstrateStyledTextSpans()

        // Demonstrate frame buffer (RUNE-20)
        await demonstrateFrameBuffer()

        // Interactive frame buffer demo
        print("")
        print("Would you like to see a live frame buffer demo? (y/n)")
        if let input = readLine(), input.lowercased() == "y" {
            await liveFrameBufferDemo()
        }

        // Interactive frame buffer demo
        print("")
        print("Would you like to see a live frame buffer demo? (y/n)")
        if let input = readLine(), input.lowercased() == "y" {
            await liveFrameBufferDemo()
        }

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

    /// Demonstrate frame buffer functionality with in-place repaint
    static func demonstrateFrameBuffer() async {
        print("")
        print("=== Frame Buffer Demo (RUNE-20) ===")
        print("")
        print("This demo shows region-based frame rendering with:")
        print("• In-place repaint without flicker")
        print("• Cursor management during rendering")
        print("• Proper cleanup on frame height changes")
        print("")

        // Create a frame buffer
        let frameBuffer = FrameBuffer()

        print("Rendering animated frames...")
        print("(Note: In a real terminal, this would show smooth updates)")
        print("")

        // Demo 1: Basic frame rendering with dynamic width calculation
        let frameContents = ["Loading...", "Loading.", "Loading..", "Loading...", "Complete! ✅"]
        let frames = frameContents.map { content in
            createBoxFrame(content: content)
        }

        print("Demo 1: Basic animation frames")
        for (index, frame) in frames.enumerated() {
            print("Frame \(index + 1):")
            for line in frame.lines {
                print("  \(line)")
            }
            print("")

            // In a real demo, we would render to terminal:
            // await frameBuffer.renderFrame(frame)
            // try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        // Demo 2: Frame height shrinkage
        print("Demo 2: Frame height changes")
        let tallFrame = createMultiLineBoxFrame(contents: ["Line 1", "Line 2", "Line 3", "Line 4"])
        let shortFrame = createBoxFrame(content: "Shrunk! 📦")

        print("Tall frame (6 lines):")
        for line in tallFrame.lines {
            print("  \(line)")
        }
        print("")

        print("Short frame (3 lines) - extra lines would be cleared:")
        for line in shortFrame.lines {
            print("  \(line)")
        }
        print("")

        // Demo 3: Error handling
        print("Demo 3: Error handling and cleanup")
        print("• Cursor is hidden during rendering")
        print("• Cursor is restored on completion")
        print("• Cursor is restored even on errors")
        print("• Cleanup occurs on process termination")
        print("")

        print("Frame buffer demo completed! 🎬")
        print("In a real terminal application, these frames would render")
        print("smoothly in-place without flicker or cursor artifacts.")
    }

    /// Create a box frame with dynamic width based on content
    /// - Parameter content: The text content to display in the box
    /// - Returns: A properly sized frame with borders
    static func createBoxFrame(content: String) -> TerminalRenderer.Frame {
        let padding = 2  // 1 space on each side
        let borderWidth = 2  // 1 character for each border
        let contentWidth = Width.displayWidth(of: content)  // Use display width, not character count
        let totalWidth = contentWidth + padding + borderWidth

        let horizontalBorder = String(repeating: "─", count: totalWidth - 2)
        let topBorder = "┌\(horizontalBorder)┐"
        let bottomBorder = "└\(horizontalBorder)┘"
        let middleLine = "│ \(content) │"

        return TerminalRenderer.Frame(
            lines: [topBorder, middleLine, bottomBorder],
            width: totalWidth,
            height: 3
        )
    }

    /// Create a multi-line box frame with dynamic width
    /// - Parameter contents: Array of content lines
    /// - Returns: A properly sized frame with borders
    static func createMultiLineBoxFrame(contents: [String]) -> TerminalRenderer.Frame {
        let padding = 2  // 1 space on each side
        let borderWidth = 2  // 1 character for each border
        let maxContentWidth = contents.map { Width.displayWidth(of: $0) }.max() ?? 0  // Use display width
        let totalWidth = maxContentWidth + padding + borderWidth

        let horizontalBorder = String(repeating: "─", count: totalWidth - 2)
        let topBorder = "┌\(horizontalBorder)┐"
        let bottomBorder = "└\(horizontalBorder)┘"

        var lines = [topBorder]
        for content in contents {
            // Pad based on display width, not character count
            let contentDisplayWidth = Width.displayWidth(of: content)
            let paddingNeeded = maxContentWidth - contentDisplayWidth
            let paddedContent = content + String(repeating: " ", count: paddingNeeded)
            lines.append("│ \(paddedContent) │")
        }
        lines.append(bottomBorder)

        return TerminalRenderer.Frame(
            lines: lines,
            width: totalWidth,
            height: lines.count
        )
    }

    /// Live demonstration of frame buffer with actual terminal rendering
    static func liveFrameBufferDemo() async {
        print("")
        print("🎬 Starting live frame buffer demo...")
        print("Watch the frames replace each other in-place!")
        print("")

        // Give user time to read
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Create frame buffer that writes to stdout
        let frameBuffer = FrameBuffer()

        // Animation frames with consistent width
        let loadingContents = ["Loading...", "Loading.", "Loading..", "Loading..."]
        let loadingFrames = loadingContents.map { content in
            createBoxFrame(content: content)
        }

        // Animate loading for a few cycles
        for _ in 0..<3 {
            for frame in loadingFrames {
                await frameBuffer.renderFrame(frame)
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            }
        }

        // Final completion frame
        let completeFrame = createBoxFrame(content: "Complete! ✅")
        await frameBuffer.renderFrame(completeFrame)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Demo frame height shrinkage
        print("")
        print("")
        print("Now demonstrating frame height shrinkage...")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Tall frame
        let tallFrame = createMultiLineBoxFrame(contents: ["Line 1", "Line 2", "Line 3", "Line 4"])
        await frameBuffer.renderFrame(tallFrame)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Shrink to short frame (extra lines should be cleared)
        let shortFrame = createBoxFrame(content: "Shrunk! 📦")
        await frameBuffer.renderFrame(shortFrame)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Clear the frame buffer
        await frameBuffer.clear()

        print("")
        print("")
        print("✨ Live demo completed!")
        print("Notice how:")
        print("• Frames replaced each other in the same location")
        print("• No flicker or cursor artifacts during animation")
        print("• Extra lines were properly cleared when frame shrank")
        print("• Cursor was hidden during rendering and restored at the end")
    }
}
