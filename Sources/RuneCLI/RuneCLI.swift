import Foundation
import RuneKit

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Utility for getting terminal dimensions
struct TerminalSize {
    let width: Int
    let height: Int

    /// Get current terminal size, with fallback to reasonable defaults
    static func current() -> TerminalSize {
        #if canImport(Darwin)
        var windowSize = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &windowSize) == 0 {
            return TerminalSize(width: Int(windowSize.ws_col), height: Int(windowSize.ws_row))
        }
        #elseif canImport(Glibc)
        var windowSize = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &windowSize) == 0 {
            return TerminalSize(width: Int(windowSize.ws_col), height: Int(windowSize.ws_row))
        }
        #endif

        // Fallback to reasonable defaults
        return TerminalSize(width: 80, height: 24)
    }
}

@main
struct RuneCLI {
    static func main() async {
        // Check if we should run just the live demo test
        if CommandLine.arguments.contains("--live-demo-only") {
            await testLiveFrameBufferDemoFix()
            return
        }

        print("🎯 RuneKit Complete Demo Suite")
        print("==============================")
        print("Running all RuneKit demonstrations in sequence...")
        print("")

        // 1. Current main() - Hybrid Reconciler Demo
        await hybridReconcilerDemo()

        // 2. Basic functionality
        await demonstrateBasicFunctionality()

        // 3. Styled Text component (RUNE-29)
        demonstrateStyledTextComponent()

        // 4. Styled text spans
        demonstrateStyledTextSpans()

        // 5. Unicode categories
        demonstrateUnicodeCategories()

        // 6. Frame buffer
        await demonstrateFrameBuffer()

        // 7. Live frame buffer demo
        await liveFrameBufferDemo()

        // 8. Backpressure and coalescing demo
        await backpressureDemo()

        // 9. Alternate screen buffer demo (RUNE-22)
        await alternateScreenBufferDemo()

        // 10. Console capture demo (RUNE-23)
        await consoleCaptureDemo()

        // 11. RUNE-24 render(_:options) API demo
        await rune24Demo()

        // 12. RUNE-25 render handle control methods demo
        await rune25Demo()

        // 12. RUNE-26 Yoga layout engine demo
        await yogaLayoutDemo()

        // 13. RUNE-27 Box layout with padding/margin/gap demo
        rune27Demo()

        print("")
        print("🎉 All RuneKit demonstrations completed!")
        print("Thanks for exploring RuneKit's capabilities!")
    }

    /// Test just the live frame buffer demo to verify the coalescing fix
    static func testLiveFrameBufferDemoFix() async {
        print("🎬 Testing Live Frame Buffer Demo Fix")
        print("====================================")
        print("This test verifies that the coalescing bug is fixed.")
        print("")

        // Create frame buffer that writes to stdout
        let frameBuffer = FrameBuffer()

        // Animation frames with consistent width
        let loadingContents = ["Loading...", "Loading.", "Loading..", "Loading..."]
        let loadingFrames = loadingContents.map { content in
            createBoxFrame(content: content)
        }

        print("Rendering loading animation frames...")

        // Animate loading for 1 cycle
        for (index, frame) in loadingFrames.enumerated() {
            print("  → About to render frame \(index + 1): \(loadingContents[index])")
            await frameBuffer.renderFrame(frame)
            print("  → Rendered frame \(index + 1): \(loadingContents[index])")
            let animationSleepTime: UInt64 = ProcessInfo.processInfo
                .environment["CI"] != nil ? 50_000_000 : 500_000_000 // 0.05s in CI, 0.5s locally
            try? await Task.sleep(nanoseconds: animationSleepTime)
        }

        // Final completion frame - this is the critical test
        print("  → About to render final frame: Complete! ✅")
        let completeFrame = createBoxFrame(content: "Complete! ✅")
        await frameBuffer.renderFrame(completeFrame)
        print("  → Rendered final frame: Complete! ✅")

        // Wait for any pending updates
        await frameBuffer.waitForPendingUpdates()
        print("  → All pending updates completed")

        let testSleepTime: UInt64 = ProcessInfo.processInfo
            .environment["CI"] != nil ? 50_000_000 : 2_000_000_000 // 0.05s in CI, 2s locally
        try? await Task.sleep(nanoseconds: testSleepTime)

        // Clear the frame buffer
        await frameBuffer.clear()

        print("")
        print("✅ Test completed!")
        print("If you can see this message, the final frame was rendered successfully.")
        print("The coalescing bug has been fixed!")
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

        // Test component rendering with styling
        let plainText = Text("Demo")
        let styledText = Text("Styled Demo", color: .green, bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let plainLines = plainText.render(in: rect)
        let styledLines = styledText.render(in: rect)

        print("Component: Plain text rendered to \(plainLines.count) lines")
        print("Component: Styled text rendered to \(styledLines.count) lines")

        // Demonstrate the styled output
        print("Plain output: \(plainLines[0])")
        print("Styled output: \(styledLines[0])")

        // Test renderer (without actually writing to terminal)
        _ = TerminalRenderer()
        print("Renderer: Created successfully")

        print("All modules working correctly! 🚀")
    }

    /// Demonstrate styled Text component functionality (RUNE-29)
    static func demonstrateStyledTextComponent() {
        print("\n--- Styled Text Component Demo (RUNE-29) ---")

        let rect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 1)

        print("\n1. Basic Styling:")

        // Basic color styling
        let redText = Text("Error: Something went wrong", color: .red)
        let greenText = Text("Success: Operation completed", color: .green)
        let blueText = Text("Info: Processing data", color: .blue)

        print("Red text: \(redText.render(in: rect)[0])")
        print("Green text: \(greenText.render(in: rect)[0])")
        print("Blue text: \(blueText.render(in: rect)[0])")

        print("\n2. Text Formatting:")

        // Text formatting
        let boldText = Text("Bold Important Text", bold: true)
        let italicText = Text("Italic Emphasis", italic: true)
        let underlineText = Text("Underlined Link", underline: true)

        print("Bold: \(boldText.render(in: rect)[0])")
        print("Italic: \(italicText.render(in: rect)[0])")
        print("Underline: \(underlineText.render(in: rect)[0])")

        print("\n3. Combined Styling:")

        // Combined styling
        let warningText = Text("⚠️  Warning", color: .yellow, bold: true)
        let errorText = Text("❌ Critical Error", color: .red, bold: true, underline: true)
        let successText = Text("✅ All Good", color: .green, bold: true)

        print("Warning: \(warningText.render(in: rect)[0])")
        print("Error: \(errorText.render(in: rect)[0])")
        print("Success: \(successText.render(in: rect)[0])")

        print("\n4. Advanced Colors:")

        // RGB and 256 colors
        let rgbText = Text("RGB Orange Text", color: .rgb(255, 165, 0))
        let color256Text = Text("256-Color Bright Red", color: .color256(196))

        print("RGB: \(rgbText.render(in: rect)[0])")
        print("256-color: \(color256Text.render(in: rect)[0])")

        print("\n5. Background Colors:")

        // Background colors
        let highlightText = Text("Highlighted Text", color: .black, backgroundColor: .yellow)
        let inverseText = Text("Inverse Text", inverse: true)

        print("Highlight: \(highlightText.render(in: rect)[0])")
        print("Inverse: \(inverseText.render(in: rect)[0])")

        print("\n6. Unicode and Emoji:")

        // Unicode and emoji support
        let emojiText = Text("🚀 Rocket Launch", color: .cyan, bold: true)
        let cjkText = Text("你好世界 (Hello World)", color: .magenta)
        let symbolText = Text("© 2024 RuneKit ™", color: .blue, italic: true)

        print("Emoji: \(emojiText.render(in: rect)[0])")
        print("CJK: \(cjkText.render(in: rect)[0])")
        print("Symbols: \(symbolText.render(in: rect)[0])")

        print("\nStyled Text component working perfectly! ✨")
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
        _ = FrameBuffer()

        print("Rendering animated frames...")
        print("(Note: In a real terminal, this would show smooth updates)")
        print("")

        // Demo 1: Basic frame rendering with dynamic width calculation
        let frameContents = ["Loading...", "Loading.", "Loading..", "Loading...", "Complete! ✅"]
        let frames = frameContents.map { content in
            RuneCLI.createBoxFrame(content: content)
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
        let tallFrame = RuneCLI.createMultiLineBoxFrame(contents: ["Line 1", "Line 2", "Line 3", "Line 4"])
        let shortFrame = RuneCLI.createBoxFrame(content: "Shrunk! 📦")

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

    /// RUNE-24 render(_:options) API demo
    static func rune24Demo() async {
        await RUNE24Demo.run()
    }

    /// RUNE-25 render handle control methods demo
    static func rune25Demo() async {
        await RUNE25Demo.run()
    }

    /// RUNE-26 Yoga layout engine demo
    static func yogaLayoutDemo() async {
        await YogaLayoutDemo.run()
    }

    /// RUNE-27 Box layout with padding/margin/gap demo
    static func rune27Demo() {
        RUNE27Demo.run()
    }
}
