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
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
        }
        #elseif canImport(Glibc)
        var w = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 {
            return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
        }
        #endif

        // Fallback to reasonable defaults
        return TerminalSize(width: 80, height: 24)
    }
}

@main
struct RuneCLI {
    static func main() async {
        print("🎯 RuneKit Complete Demo Suite")
        print("==============================")
        print("Running all RuneKit demonstrations in sequence...")
        print("")

        // 1. Current main() - Hybrid Reconciler Demo
        await hybridReconcilerDemo()

        // 2. Basic functionality
        await demonstrateBasicFunctionality()

        // 3. Styled text spans
        demonstrateStyledTextSpans()

        // 4. Unicode categories
        demonstrateUnicodeCategories()

        // 5. Frame buffer
        await demonstrateFrameBuffer()

        // 6. Live frame buffer demo
        await liveFrameBufferDemo()

        // 7. Backpressure and coalescing demo
        await backpressureDemo()

        print("")
        print("🎉 All RuneKit demonstrations completed!")
        print("Thanks for exploring RuneKit's capabilities!")
    }

    /// The original hybrid reconciler demo (was main())
    static func hybridReconcilerDemo() async {
        // Get terminal size for dynamic layout
        let terminalSize = TerminalSize.current()

        print("🎯 RuneKit Hybrid Reconciler Demo")
        print("==================================")
        print("Watch how the hybrid reconciler automatically chooses optimal strategies!")
        print("Terminal size: \(terminalSize.width)x\(terminalSize.height)")
        print("")

        // Add some content before the frame to test positioning
        print("📋 System Status Report")
        print("⏰ \(Date())")
        print("🖥️  Terminal: \(terminalSize.width) columns × \(terminalSize.height) rows")
        print("")
        print("📊 Live monitoring below (updates in-place):")
        print("")

        let frameBuffer = FrameBuffer()

        // Create frames that adapt to terminal width
        let frame1 = createSystemMonitorFrame(
            terminalWidth: terminalSize.width,
            cpuUsage: 40,
            ramUsage: 20,
            diskUsage: 30,
            netUsage: 15
        )

        let frame2 = createSystemMonitorFrame(
            terminalWidth: terminalSize.width,
            cpuUsage: 99,  // Dramatic change to make it obvious
            ramUsage: 20,
            diskUsage: 30,
            netUsage: 15
        )

        // Render initial frame using hybrid reconciler
        await frameBuffer.renderFrame(frame1)
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds to see initial frame

        // Update frame - hybrid reconciler will automatically choose optimal strategy
        await frameBuffer.renderFrame(frame2)
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds to see frame update

        // Create a third frame with more changes
        let frame3 = createSystemMonitorFrame(
            terminalWidth: terminalSize.width,
            cpuUsage: 85,  // Changed again
            ramUsage: 40,  // RAM also changed
            diskUsage: 30,
            netUsage: 25   // Network also changed
        )

        await frameBuffer.renderFrame(frame3)
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds to see frame update

        // Create a frame with massive changes (should trigger full redraw)
        let frame4 = createSystemMonitorFrame(
            terminalWidth: terminalSize.width,
            cpuUsage: 60,
            ramUsage: 30,
            diskUsage: 40,
            netUsage: 10,
            style: .double  // Different border style
        )

        await frameBuffer.renderFrame(frame4)
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds to see frame update

        await frameBuffer.clear()

        // Add some content after the frame to test positioning
        print("")
        print("✅ Demo complete!")
        print("The hybrid reconciler automatically chose optimal strategies:")
        print("• First render: Full redraw (no previous frame)")
        print("• Second render: Delta update (1 line changed)")
        print("• Third render: Delta update (2 lines changed)")
        print("• Fourth render: Full redraw (dimensions changed + many lines changed)")
        print("")

        // Show performance metrics
        let metrics = await frameBuffer.getPerformanceMetrics()
        print("📊 Performance Metrics:")
        print("• Average efficiency: \(String(format: "%.1f%%", metrics.averageEfficiency * 100))")
        print("• Total renders: \(metrics.totalRenders)")
        print("• Frames since full redraw: \(metrics.framesSinceFullRedraw)")
        print("• Current delta threshold: \(String(format: "%.1f%%", metrics.adaptiveThresholds.deltaThreshold * 100))")
        print("• Dropped frames: \(metrics.droppedFrames)")
        print("• Current queue depth: \(metrics.currentQueueDepth)")
        print("• Adaptive quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))")
        print("")
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
        _ = FrameBuffer()

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

    /// Border style for system monitor frame
    enum BorderStyle {
        case single
        case double

        var topLeft: String {
            switch self {
            case .single: return "┌"
            case .double: return "╔"
            }
        }

        var topRight: String {
            switch self {
            case .single: return "┐"
            case .double: return "╗"
            }
        }

        var bottomLeft: String {
            switch self {
            case .single: return "└"
            case .double: return "╚"
            }
        }

        var bottomRight: String {
            switch self {
            case .single: return "┘"
            case .double: return "╝"
            }
        }

        var horizontal: String {
            switch self {
            case .single: return "─"
            case .double: return "═"
            }
        }

        var vertical: String {
            switch self {
            case .single: return "│"
            case .double: return "║"
            }
        }

        var crossTop: String {
            switch self {
            case .single: return "┬"
            case .double: return "╦"
            }
        }

        var crossMiddle: String {
            switch self {
            case .single: return "├"
            case .double: return "╠"
            }
        }

        var crossRight: String {
            switch self {
            case .single: return "┤"
            case .double: return "╣"
            }
        }
    }

    /// Create a system monitor frame that adapts to terminal width
    static func createSystemMonitorFrame(
        terminalWidth: Int,
        cpuUsage: Int,
        ramUsage: Int,
        diskUsage: Int,
        netUsage: Int,
        style: BorderStyle = .single
    ) -> TerminalRenderer.Frame {
        // Calculate optimal frame width (leave some margin)
        let maxFrameWidth = min(terminalWidth - 4, 50)  // Leave 4 chars margin, max 50 wide
        let minFrameWidth = 25  // Minimum width for readability
        let frameWidth = max(minFrameWidth, maxFrameWidth)

        // Calculate content width (subtract borders)
        let contentWidth = frameWidth - 2

        // Create progress bars that fit the available space
        // Format: "DISK: [████████████████████████████████] 100%"
        // Need space for: label(5) + ": [" (3) + "] " (2) + "100%" (4) = 14 chars minimum
        let barWidth = max(6, contentWidth - 16)  // Leave space for label, brackets, and percentage

        func createProgressBar(_ percentage: Int, width: Int) -> String {
            let filled = (percentage * width) / 100
            let empty = width - filled
            return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        }

        // Build the frame
        let horizontalBorder = String(repeating: style.horizontal, count: frameWidth - 2)
        let topBorder = style.topLeft + horizontalBorder + style.topRight
        let bottomBorder = style.bottomLeft + horizontalBorder + style.bottomRight

        // Title line
        let title = "System Monitor"
        let titlePadding = (contentWidth - title.count) / 2
        let titleLine = style.vertical + String(repeating: " ", count: titlePadding) + title +
            String(repeating: " ", count: contentWidth - titlePadding - title.count) + style.vertical

        // Separator line
        let separatorBorder = String(repeating: style.horizontal, count: frameWidth - 2)
        let separatorLine = style.crossMiddle + separatorBorder + style.crossRight

        // Metric lines
        func createMetricLine(_ label: String, _ percentage: Int) -> String {
            let bar = createProgressBar(percentage, width: barWidth)
            let percentText = String(format: "%3d%%", percentage)
            let line = "\(label): [\(bar)] \(percentText)"
            let lineWidth = Width.displayWidth(of: line)
            let padding = max(0, contentWidth - lineWidth - 2)  // -2 for the spaces around content
            return style.vertical + " " + line + String(repeating: " ", count: padding) + " " + style.vertical
        }

        let cpuLine = createMetricLine("CPU ", cpuUsage)
        let ramLine = createMetricLine("RAM ", ramUsage)
        let diskLine = createMetricLine("DISK", diskUsage)
        let netLine = createMetricLine("NET ", netUsage)

        let lines = [
            topBorder,
            titleLine,
            separatorLine,
            cpuLine,
            ramLine,
            diskLine,
            netLine,
            bottomBorder
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: frameWidth,
            height: lines.count
        )
    }

    /// Create a final results frame that displays below the system monitor
    static func createFinalResultsFrame(
        terminalWidth: Int,
        metrics: HybridPerformanceMetrics
    ) -> TerminalRenderer.Frame {
        let style = BorderStyle.single
        let frameWidth = min(terminalWidth - 4, 60)  // Leave margin and max width
        let contentWidth = frameWidth - 2  // Account for borders

        let horizontalBorder = String(repeating: style.horizontal, count: frameWidth - 2)
        let topBorder = style.topLeft + horizontalBorder + style.topRight
        let bottomBorder = style.bottomLeft + horizontalBorder + style.bottomRight

        // Title line
        let title = "📊 Final Backpressure Test Results"
        let titlePadding = max(0, (contentWidth - title.count) / 2)
        let titleLine = style.vertical + String(repeating: " ", count: titlePadding) + title +
            String(repeating: " ", count: max(0, contentWidth - titlePadding - title.count)) + style.vertical

        // Separator line - use crossMiddle and crossRight instead of leftTee/rightTee
        let separatorLine = style.crossMiddle + String(repeating: style.horizontal, count: frameWidth - 2) + style.crossRight

        // Metric lines
        let totalRendersText = "• Total renders processed: \(metrics.totalRenders)"
        let droppedFramesText = "• Frames dropped due to backpressure: \(metrics.droppedFrames)"
        let queueDepthText = "• Final queue depth: \(metrics.currentQueueDepth)"
        let adaptiveQualityText = "• Final adaptive quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))"
        let efficiencyText = "• Average efficiency: \(String(format: "%.1f%%", metrics.averageEfficiency * 100))"

        func createTextLine(_ text: String) -> String {
            let padding = max(0, contentWidth - text.count)
            return style.vertical + text + String(repeating: " ", count: padding) + style.vertical
        }

        let lines = [
            "",  // Empty line for spacing
            topBorder,
            titleLine,
            separatorLine,
            createTextLine(totalRendersText),
            createTextLine(droppedFramesText),
            createTextLine(queueDepthText),
            createTextLine(adaptiveQualityText),
            createTextLine(efficiencyText),
            bottomBorder
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: frameWidth,
            height: lines.count
        )
    }

    /// Demonstrate backpressure handling and update coalescing
    static func backpressureDemo() async {
        print("")
        print("🚀 Backpressure & Update Coalescing Demo")
        print("========================================")
        print("Testing rapid updates to demonstrate:")
        print("• Update coalescing (batching rapid changes)")
        print("• Backpressure handling (dropping frames under load)")
        print("• Adaptive quality reduction")
        print("• Periodic full repaints")
        print("")

        let frameBuffer = FrameBuffer()
        let terminalSize = TerminalSize.current()

        print("Sending rapid updates (100 frames in quick succession)...")
        print("Watch how the system handles the load:")
        print("")

        // Send 100 rapid updates to stress test the system
        for i in 0..<100 {
            let frame = createSystemMonitorFrame(
                terminalWidth: terminalSize.width,
                cpuUsage: Int.random(in: 10...100),
                ramUsage: Int.random(in: 10...80),
                diskUsage: Int.random(in: 10...60),
                netUsage: Int.random(in: 5...50)
            )

            // Fire updates rapidly without waiting
            await frameBuffer.renderFrame(frame)

            // Show progress every 20 frames
            if i % 20 == 0 {
                let metrics = await frameBuffer.getPerformanceMetrics()
                print("Frame \(i): Queue depth: \(metrics.currentQueueDepth), Dropped: \(metrics.droppedFrames), Quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))")
            }
        }

        // Wait for queue to settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Show final metrics through proper frame buffer to avoid overlay
        let finalMetrics = await frameBuffer.getPerformanceMetrics()

        // Create final results frame that won't overlay the system monitor
        let finalResultsFrame = createFinalResultsFrame(
            terminalWidth: terminalSize.width,
            metrics: finalMetrics
        )

        // Submit through frame buffer to ensure proper positioning
        await frameBuffer.renderFrame(finalResultsFrame)

        await frameBuffer.clear()
        print("")
        print("✅ Backpressure demo completed!")
        print("The system successfully handled rapid updates by:")
        print("• Coalescing multiple updates into single renders")
        print("• Dropping frames when queue depth exceeded limits")
        print("• Reducing quality temporarily under load")
        print("• Maintaining terminal responsiveness")
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
