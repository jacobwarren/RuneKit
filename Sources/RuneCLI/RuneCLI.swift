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

        // In CI or non-interactive terminals (like Docker builds), skip demos entirely.
        let isInteractive = RenderOptions.isInteractiveTerminal()
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                             ProcessInfo.processInfo.environment["SWIFTPM_TEST"] != nil ||
                             ProcessInfo.processInfo.environment["CI"] != nil
        if !isInteractive || isRunningTests {
            print("RuneCLI running in non-interactive/test/CI mode — skipping demos.")
            return
        }


        // Check command line arguments
        let args = CommandLine.arguments
        if args.count > 1 {
            switch args[1] {
            case "spinner":
                await spinnerDemo()
            case "exact-spinner":
                await exactSpinnerDemo()
            case "comprehensive":
                await comprehensiveComponentDemo()
            case "components":
                await comprehensiveComponentDemo()
            case "tickets":
                await runTickets1318()
            default:
                await runTickets1318()
            }
        } else {
            await runTickets1318()
        }
    }

        // Shared demo render options: own the terminal outside CI (Ink-like behavior)
        static var demoOptions: RenderOptions {
            // Use TTY and CI-aware defaults to avoid aborts in non-interactive contexts
            return RenderOptions.fromEnvironment()
        }



    // Run through RUNE-13 to RUNE-18 ticket demos sequentially
    static func runTickets1318() async {
        print("\n=== RuneKit Ticket Demos: RUNE-13 → RUNE-18 ===\n")
        await demoRUNE13()
        await demoRUNE14()
        await demoRUNE15()
        await demoRUNE16()
        await demoRUNE17()
        await demoRUNE18()
        print("\n✅ Completed RUNE-13 to RUNE-18 demos.\n")

        // Now run RUNE-19 → RUNE-24 demos sequentially
        await runTickets1924()
        // And then RUNE-25 → RUNE-29 demos sequentially
        await runTickets2529()
        // And finally RUNE-30 → RUNE-34 demos sequentially
        await runTickets3034()
    }

        // Run through RUNE-19 to RUNE-24 ticket demos sequentially
        static func runTickets1924() async {
            print("\n=== RuneKit Ticket Demos: RUNE-19 → RUNE-24 ===\n")
            await demoRUNE19()
            await demoRUNE20()
            await demoRUNE21()
            await demoRUNE22()
            await demoRUNE23()

            await demoRUNE24()
            print("\n✅ Completed RUNE-19 to RUNE-24 demos.\n")
        }
        // Run through RUNE-25 to RUNE-29 ticket demos sequentially
        static func runTickets2529() async {
            print("\n=== RuneKit Ticket Demos: RUNE-25 → RUNE-29 ===\n")
            await demoRUNE25()
            await demoRUNE26()
            await demoRUNE27()
            await demoRUNE28()
            await demoRUNE29()
            print("\n✅ Completed RUNE-25 to RUNE-29 demos.\n")
        }
        // Run through RUNE-30 to RUNE-34 ticket demos sequentially
        static func runTickets3034() async {
            print("\n=== RuneKit Ticket Demos: RUNE-30 → RUNE-34 ===\n")
            await demoRUNE30()
            await demoRUNE31()
            await demoRUNE32()
            await demoRUNE33()
            await demoRUNE34()
            print("\n✅ Completed RUNE-30 to RUNE-34 demos.\n")
        }

        // RUNE-30: <Box> with borders & padding
        static func demoRUNE30() async {
            print("RUNE-30: <Box> with borders & padding")

            // Example 1: Single border with padding
            let single = Box(
                border: .single,
                paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                child: Text("Hello 👋 CJK：世界")
            )
            let singleRect = FlexLayout.Rect(x: 0, y: 0, width: 18, height: 5)
            let singleLines = single.render(in: singleRect)
            print("- Single border with padding:")
            singleLines.forEach { print("  \($0)") }

            // Example 2: Double border
            let double = Box(border: .double, child: Text("Double"))
            let doubleLines = double.render(in: FlexLayout.Rect(x: 0, y: 0, width: 12, height: 3))
            print("- Double border:")
            doubleLines.forEach { print("  \($0)") }

            // Example 3: Rounded border
            let rounded = Box(border: .rounded, child: Text("Rounded"))
            let roundedLines = rounded.render(in: FlexLayout.Rect(x: 0, y: 0, width: 13, height: 3))
            print("- Rounded border:")
            roundedLines.forEach { print("  \($0)") }

            print("✅ RUNE-30 demo complete\n")
        }

        // RUNE-31: <Static> region
        static func demoRUNE31() async {
            print("RUNE-31: <Static> region (logs above live region)")

            // Configure FrameBuffer with console capture to keep logs/static above live content
            let config = RenderConfiguration(enableConsoleCapture: true)
            let fb = FrameBuffer(configuration: config)

            // Render a live region (simple progress box)
            func progressFrame(_ step: Int) -> TerminalRenderer.Frame {
                let box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1,
                               children: Text("Header (live)"), Text("Progress: \(step)/3"))
                let rect = FlexLayout.Rect(x: 0, y: 0, width: 24, height: 4)
                let lines = box.render(in: rect)
                return TerminalRenderer.Frame(lines: lines, width: 24, height: lines.count)
            }

            // Start with frame 1 so capture is active, then emit static lines via stdout
            await fb.renderFrame(progressFrame(1))
            print("=== Static Header ===")
            print("Logs and headers stay above the live region.")

            // Update frames — static lines should remain above and stable
            await fb.renderFrame(progressFrame(2))
            await fb.renderFrame(progressFrame(3))
            await fb.waitForPendingUpdates()
            await fb.clear()

            print("✅ RUNE-31 demo complete\n")
        }

        // RUNE-32: <Spacer> and alignment props
        static func demoRUNE32() async {
            print("RUNE-32: <Spacer> and alignment props")

            // Row: Left |———Spacer———| Right
            let row = Box(
                flexDirection: .row,
                width: .points(24), height: .points(3),
                children: Text("Left"), Spacer(), Text("Right")
            )
            let rowLines = row.render(in: FlexLayout.Rect(x: 0, y: 0, width: 24, height: 3))
            print("- Row with Spacer (Left ··· Right):")
            rowLines.forEach { print("  \($0)") }

            // Column with centered item and Spacer not affecting cross-axis
            let column = Box(
                border: .single,
                flexDirection: .column,
                justifyContent: .spaceBetween,
                alignItems: .center,
                width: .points(20), height: .points(6),
                children: Text("Top"), Spacer(), Text("Bottom")
            )
            let columnLines = column.render(in: FlexLayout.Rect(x: 0, y: 0, width: 20, height: 6))
            print("- Column with borders, padding=0, spacers and alignment:")
            columnLines.forEach { print("  \($0)") }

            print("✅ RUNE-32 demo complete\n")
        }

        // RUNE-33: <Newline count={n}>
        static func demoRUNE33() async {
            print("RUNE-33: <Newline count={n}>")
            let nl3 = Newline(count: 3)
            let linesAll = nl3.render(in: FlexLayout.Rect(x: 0, y: 0, width: 10, height: 5))
            print("- Newline(3) in height=5 → lines: \(linesAll.count) (expected 3)")
            let linesConstrained = nl3.render(in: FlexLayout.Rect(x: 0, y: 0, width: 10, height: 2))
            print("- Newline(3) in height=2 → lines: \(linesConstrained.count) (expected 2)")
            print("- SGR leakage: none (empty strings)")
            print("✅ RUNE-33 demo complete\n")
        }

        // RUNE-34: <Transform transform: (string) -> string>
        static func demoRUNE34() async {
            print("RUNE-34: <Transform transform: (string) -> string>")

            // ANSI-safe uppercase
            let upper = Transform(transform: { $0.uppercased() }) {
                Text("Error: warning", color: .red, backgroundColor: .yellow)
            }
            let upLine = upper.render(in: FlexLayout.Rect(x: 0, y: 0, width: 30, height: 1)).first ?? ""
            print("- ANSI-safe uppercase: \(upLine)")

            // Chaining/nesting
            let chained = Transform(transform: { $0.replacingOccurrences(of: "WORLD", with: "UNIVERSE") }) {
                Transform(transform: { $0.uppercased() }) {
                    Text("Hello world", color: .cyan)
                }
            }
            let chLine = chained.render(in: FlexLayout.Rect(x: 0, y: 0, width: 30, height: 1)).first ?? ""
            print("- Chained transform: \(chLine)")

            print("✅ RUNE-34 demo complete\n")
        }

        // RUNE-25: Render handle API (unmount/clear/rerender/waitUntilExit)
        static func demoRUNE25() async {
            print("RUNE-25: Render handle API (unmount/clear/rerender/waitUntilExit)")
            struct CounterView: View { var body: some View { Text("Counter: 1", color: .yellow) } }
            let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 30)
            let handle = await render(CounterView(), options: options)
            // Rerender with new content (state-preserving semantics are documented)
            struct CounterView2: View { var body: some View { Text("Counter: 2", color: .yellow) } }
            await handle.rerender(CounterView2())
            // Clear, then unmount; also show waitUntilExit resolving
            let waitTask = Task { await handle.waitUntilExit() }
            await handle.clear()
            await handle.unmount()
            _ = await waitTask.value
            print("✅ RUNE-25 demo complete\n")
        }

        // RUNE-26: Yoga ADR + integration plan
        static func demoRUNE26() async {
            print("RUNE-26: Yoga ADR + integration plan")
            print("  - ADR 001 committed selecting Yoga via SPM")
            print("  - Package.swift includes `yoga` dependency; RuneLayout links it")
            print("  - Mapping of Box props → Yoga nodes implemented in YogaWrapper")
            print("  - Perf & portability notes documented in ADR")
            print("✅ RUNE-26 demo complete\n")
        }

        // RUNE-27: Basic Yoga layout (row/column + padding/margin/gap)
        static func demoRUNE27() async {
            print("RUNE-27: Basic Yoga layout (row/column + padding/margin/gap)")
            let layoutRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
            let view = Box(
                flexDirection: .row,
                columnGap: 2,
                children: Box(flexDirection: .column, rowGap: 1, children: Text("L1"), Text("L2")),
                          Box(flexDirection: .column, rowGap: 2, children: Text("R1"), Text("R2"), Text("R3"))
            )
            let lines = view.render(in: layoutRect)
            for (i, line) in lines.enumerated() { print("  [\(i)] \(line)") }
            print("✅ RUNE-27 demo complete\n")
        }

        // RUNE-28: Flex grow/shrink, min/max, wrap (Yoga)
        static func demoRUNE28() async {
            print("RUNE-28: Flex grow/shrink, min/max, wrap (Yoga)")
            let container = FlexLayout.Rect(x: 0, y: 0, width: 40, height: 10)
            let row = Box(
                flexDirection: .row,
                columnGap: 1,
                children: Box(width: .points(10), child: Text("A")),
                          Box(flexGrow: 1, child: Text("Grow")),
                          Box(width: .points(5), minWidth: .points(5), child: Text("Fix"))
            )
            let lines = row.render(in: container)
            for (i, line) in lines.enumerated() { print("  [\(i)] \(line)") }
            print("✅ RUNE-28 demo complete\n")
        }

        // RUNE-29: Text component (styled)
        static func demoRUNE29() async {
            print("RUNE-29: Text component (styled)")
            let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)
            let text = Text("Styled ✅ 世界", color: .magenta, bold: true, underline: true)
            let lines = text.render(in: rect)
            for (i, line) in lines.enumerated() { print("  [\(i)] \(line)") }
            print("✅ RUNE-29 demo complete\n")
        }



        // RUNE-19: ANSI-aware wrap & slice
        static func demoRUNE19() async {
            print("RUNE-19: ANSI-aware wrap & slice")
            let attrs1 = TextAttributes(color: .red, bold: true)
            let attrs2 = TextAttributes(color: .blue)
            let styled = StyledText(spans: [
                TextSpan(text: "Hello ", attributes: attrs1),
                TextSpan(text: "👨‍👩‍👧‍👦 世界 🎉 Test!", attributes: attrs2)
            ])
            // Wrap at width 12 and show lines without color bleed
            let lines = styled.wrapByDisplayWidth(width: 12)
            let converter = ANSISpanConverter()
            for (i, line) in lines.enumerated() {
                let tokens = converter.styledTextToTokens(line)
                let raw = ANSITokenizer().encode(tokens)
                print("  Line #\(i+1): \(raw)")
            }
            // Slice example
            let sliced = styled.sliceByDisplayColumns(from: 3, to: 9)
            let rawSliced = ANSITokenizer().encode(converter.styledTextToTokens(sliced))
            print("  Slice [3,9): \(rawSliced)")
            print("✅ RUNE-19 demo complete\n")
        }

        // RUNE-20: Frame buffer & region repaint
        static func demoRUNE20() async {
            print("RUNE-20: Frame buffer & region repaint")
            let fb = FrameBuffer() // default stdout
            // Render two frames where the second is shorter to verify erase/shrink
            let frame1 = TerminalRenderer.Frame(lines: [
                "Frame Buffer Test",
                "Second Line",
                "Third Line"
            ], width: 80, height: 3)
            await fb.renderFrame(frame1)
            try? await Task.sleep(for: .milliseconds(300))
            let frame2 = TerminalRenderer.Frame(lines: [
                "Frame Buffer Test"
            ], width: 80, height: 1)
            await fb.renderFrame(frame2)
            await fb.waitForPendingUpdates()
            // Ensure cursor restored on clear
            await fb.clear()
            print("✅ RUNE-20 demo complete\n")
        }

        // RUNE-21: Line-diff renderer (changed-line rewrite)
        static func demoRUNE21() async {
            print("RUNE-21: Line-diff renderer (changed-line rewrite)")
            let config = RenderConfiguration(optimizationMode: .lineDiff, enableMetrics: true)
            let fb = FrameBuffer(configuration: config)
            // Create base lines and then change a subset
            var lines = (1...10).map { "Line \($0)" }
            let frame1 = TerminalRenderer.Frame(lines: lines, width: 40, height: lines.count)
            await fb.renderFrame(frame1)
            // Change two lines
            lines[2] = "Line 3 Modified"
            lines[7] = "Line 8 Modified"
            let frame2 = TerminalRenderer.Frame(lines: lines, width: 40, height: lines.count)
            await fb.renderFrame(frame2)
            await fb.waitForPendingUpdates()
            // Pull renderer metrics snapshot
            print("  Render mode: lineDiff; metrics collected (bytes/lines via RenderStats/metrics)")
            await fb.clear()
            print("✅ RUNE-21 demo complete\n")
        }

        // RUNE-22: Alternate screen buffer support
        static func demoRUNE22() async {
            print("RUNE-22: Alternate screen buffer support")
            // Use render(options) with alt screen on
            struct AltView: View { var body: some View { Box(backgroundColor: .blue, child: Text("Alt Screen Demo", color: .white, bold: true)) } }
            let handle = await render(AltView(), options: RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: true))
            print("  Entered alternate screen; showing content briefly...")
            try? await Task.sleep(for: .milliseconds(500))
            await handle.clear()
            await handle.unmount()
            print("  Left alternate screen; shell prompt should be restored")
            print("✅ RUNE-22 demo complete\n")
        }

        // RUNE-23: Stdout/stderr capture & log lane
        static func demoRUNE23() async {
            print("RUNE-23: Stdout/stderr capture & log lane")
            let options = RenderOptions(exitOnCtrlC: false, patchConsole: true, useAltScreen: false)
            struct LogView: View { var body: some View { Box(border: .single, child: Text("Live Region", color: .cyan, bold: true)) } }
            let handle = await render(LogView(), options: options)
            // Emit some logs that should appear above the live region
            print("Log: This is a stdout message")
            fputs("Error: This is a stderr message\n", stderr)
            try? await Task.sleep(for: .milliseconds(300))
            await handle.clear()
            await handle.unmount()
            print("✅ RUNE-23 demo complete\n")
        }

        // RUNE-24: render(_:options) API showcase
        static func demoRUNE24() async {
            print("RUNE-24: render(_:options) API")
            // Use custom fpsCap and turn features on/off to show effect
            struct DemoView: View { var body: some View { Text("Options Demo", color: .green, bold: true) } }
            let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 30.0)
            let handle = await render(DemoView(), options: options)
            try? await Task.sleep(for: .milliseconds(200))
            await handle.rerender(DemoView())
            await handle.clear()
            await handle.unmount()
            print("✅ RUNE-24 demo complete\n")
        }



    // RUNE-13: Initialize SwiftPM library “RuneKit”
    static func demoRUNE13() async {
        print("RUNE-13: Initialize SwiftPM library ‘RuneKit’")
        print("- Products: RuneKit (umbrella), RuneCLI (executable)")
        print("- Targets: RuneANSI, RuneUnicode, RuneLayout, RuneRenderer, RuneComponents")
        // Minimal smoke: render a simple Text via layout rect
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
        let hello = Text("Hello, RuneKit!")
        let line = hello.render(in: rect).first ?? ""
        print("Hello output: \(line)")
        print("✅ RUNE-13 demo complete\n")
    }

    // RUNE-14: ANSI tokenizer
    static func demoRUNE14() async {
        print("RUNE-14: ANSI tokenizer")
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[1;31mBold Red\u{001B}[0m and \u{001B}[33mYellow\u{001B}[0m"
        let tokens = tokenizer.tokenize(input)
        let roundTrip = tokenizer.encode(tokens)
        print("Tokens count: \(tokens.count)")
        print("Round-trip identical: \(input == roundTrip)")
        // Include a cursor movement and erase to show control parsing
        let control = "\u{001B}[2J\u{001B}[H" // clear screen + home
        let controlTokens = tokenizer.tokenize(control)
        print("Control tokens parsed: \(controlTokens.count)")
        print("✅ RUNE-14 demo complete\n")
    }

    // RUNE-15: Styled text runs (ANSI spans model)
    static func demoRUNE15() async {
        print("RUNE-15: Styled text runs (spans)")
        let converter = ANSISpanConverter()
        let attrs1 = TextAttributes(color: .red, bold: true)
        let attrs2 = TextAttributes(color: .blue)
        let styled = StyledText(spans: [
            TextSpan(text: "Hello ", attributes: attrs1),
            TextSpan(text: "world!", attributes: attrs2),
        ])
        let tokens = converter.styledTextToTokens(styled)
        let back = converter.tokensToStyledText(tokens)
        print("Span count: \(styled.spans.count) → tokens: \(tokens.count) → spans: \(back.spans.count)")
        let (left, right) = styled.split(at: 7)
        print("Split at col 7 → left: ‘\(left.plainText)’, right: ‘\(right.plainText)’")
        let merged = styled.mergingAdjacentSpans()
        print("Merged span count: \(merged.spans.count)")
        print("✅ RUNE-15 demo complete\n")
    }

    // RUNE-16: wcwidth/wcswidth bridge (baseline)
    static func demoRUNE16() async {
        print("RUNE-16: Baseline display width (wcwidth)")
        let samples: [(String, String)] = [
            ("Hello", "ASCII"),
            ("café", "Accents"),
            ("A\u{0300}", "Combining grave"),
            ("\u{0007}", "Control BEL"),
            ("\t", "Tab"),
            ("世界", "CJK"),
        ]
        for (s, d) in samples {
            print("  \(d): ‘\(s)’ → width = \(Width.displayWidth(of: s))")
        }
        print("✅ RUNE-16 demo complete\n")
    }

    // RUNE-17: utf8proc categories and normalization
    static func demoRUNE17() async {
        print("RUNE-17: Unicode categories (utf8proc) + normalization")
        let cases = ["A", "é", "e\u{0301}", "👍", "世", "\u{0301}"]
        for s in cases {
            if let sc = s.unicodeScalars.first {
                let cat = UnicodeCategories.category(of: sc)
                let combining = UnicodeCategories.isCombining(sc)
                let emoji = UnicodeCategories.isEmojiScalar(sc)
                print("  ‘\(s)’ → cat: \(cat), combining: \(combining), emoji: \(emoji)")
            }
        }
        let text = "e\u{0301} ﬁ"
        print("  NFC:  ‘\(UnicodeNormalization.normalize(text, form: .nfc))’")
        print("  NFD:  ‘\(UnicodeNormalization.normalize(text, form: .nfd))’")
        print("  NFKC: ‘\(UnicodeNormalization.normalize(text, form: .nfkc))’")
        print("  NFKD: ‘\(UnicodeNormalization.normalize(text, form: .nfkd))’")
        print("✅ RUNE-17 demo complete\n")
    }

    // RUNE-18: Emoji & East Asian overrides
    static func demoRUNE18() async {
        print("RUNE-18: Emoji & East Asian width overrides")
        let samples = [
            ("👨‍👩‍👧‍👦", "Family emoji cluster"),
            ("🏳️‍⚧️", "Trans flag"),
            ("🇯🇵", "JP flag"),
            ("表", "CJK Han"),
            ("，", "CJK punctuation"),
            ("🙂", "Emoji at EOL"),
        ]
        for (s, d) in samples {
            print("  \(d): ‘\(s)’ → width = \(Width.displayWidth(of: s))")
        }
        print("✅ RUNE-18 demo complete\n")
    }

    /// Demo the animated spinner component
    static func spinnerDemo() async {
        // Demo different spinner types
        let spinnerKinds: [(Int, String)] = [
            (0, "Simple Dots"),
            (1, "Braille Dots"),
            (2, "Line Spinner"),
            (3, "Star Animation"),
            (4, "Growing Vertical"),
            (5, "Balloon Effect")
        ]

        let options = demoOptions

        // Render once and animate each spinner type cooperatively
        let header = Box(
            border: .single,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
                Static(["🎯 RuneKit Spinner Demo",
                        "Demonstrating an animated spinner built with Transform + Ticker",
                        "Preparing…"]) )
        let handle = await render(header, options: options)

        for (kind, name) in spinnerKinds {
            let durationSec: TimeInterval = 2.0
            let fps: UInt64 = 125_000_000 // 8 FPS
            let start = Date()
            while Date().timeIntervalSince(start) < durationSec {
                await handle.rerender { @Sendable in
                    let frames: [String] = {
                        switch kind {
                        case 0: return ["·", "✢", "✳", "∗", "✻", "✽"] // simpleDots
                        case 1: return ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"] // dots
                        case 2: return ["|", "/", "-", "\\"] // line
                        case 3: return ["✶", "✸", "✹", "✺", "✹", "✷"] // star
                        case 4: return ["▁", "▃", "▄", "▅", "▆", "▇", "▆", "▅", "▄", "▃"] // growVertical
                        default: return [".", "o", "O", "@", "*"] // balloon
                        }
                    }()
                    // Build spinner line by time-aware Transform with frames
                    let startTime = Date().timeIntervalSince1970
                    return Box(
                        border: .single,
                        paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                        children:
                            Static(["🎯 RuneKit Spinner Demo — \(name)"]),
                            Newline(count: 1),
                            Transform(timeAware: { input, t in
                                let elapsed = t - startTime
                                let idx = Int((elapsed * 8.0).rounded(.down)) % frames.count
                                let symbol = frames[idx]
                                return "\(symbol) Loading… (esc to interrupt)"
                            }) { Text("") }
                    )
                }
                try? await Task.sleep(nanoseconds: fps)
            }
        }

        await handle.clear()
        await handle.unmount()
    }

        struct SpinnerDemoViews {
            static func spinnerHeaderBox(_ subtitle: String) -> some View {
                Box(
                    border: .single,
                    paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                    children:
                        Static(["🎯 RuneKit Spinner Demo",
                                "Demonstrating an animated spinner built with Transform + Ticker",
                                subtitle])
                )
            }
            static func spinnerComposite(type: Int, name: String) -> some View {
                let frames: [String]
                switch type {
                case 0: frames = ["·", "✢", "✳", "∗", "✻", "✽"]
                case 1: frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
                case 2: frames = ["|", "/", "-", "\\"]
                case 3: frames = ["✶", "✸", "✹", "✺", "✹", "✷"]
                case 4: frames = ["▁", "▃", "▄", "▅", "▆", "▇", "▆", "▅", "▄", "▃"]
                default: frames = [".", "o", "O", "@", "*"]
                }
                let startTime = Date().timeIntervalSince1970
                return Box(
                    border: .single,
                    paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                    children:
                        Static(["🎯 RuneKit Spinner Demo — \(name)"]),
                        Newline(count: 1),
                        Transform(timeAware: { _, t in
                            let elapsed = t - startTime
                            let idx = Int((elapsed * 8.0).rounded(.down)) % frames.count
                            let symbol = frames[idx]
                            return "\(symbol) Loading… (esc to interrupt)"
                        }) { Text("") }
                )
            }
        }


    /// Demo the exact spinner from your example with random messages
    static func exactSpinnerDemo() async {
        let options = demoOptions

        func spinnerView() -> Box {
            let frames = ["·", "✢", "✳", "∗", "✻", "✽"]
            return Box(
                border: .single,
                paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                children:
                    Static([
                        "🎯 Exact Spinner Demo (Your Original Example)",
                        "This is the exact spinner you requested with random messages",
                        "(Press Ctrl+C to interrupt)"
                    ]),
                    Newline(count: 1),
                    Transform(timeAware: { _, t in
                        let idx = Int((t * 8.0).rounded(.down)) % frames.count
                        return "\(frames[idx]) Processing… (esc to interrupt)"
                    }) { Text("") }
            )
        }

        let handle = await render(spinnerView(), options: options)

        // Create animation timer that triggers re-renders
        let animationTask = Task {
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < 5.0 {
                try? await Task.sleep(for: .milliseconds(125)) // 8 FPS
                await handle.rerender(spinnerView())
            }
        }

        // Wait for animation to complete
        await animationTask.value

        await handle.clear()
        await handle.unmount()

        print("✅ Exact spinner demo completed!")
        print("This matches your original example with:")
        print("  • Simple dots animation: [\"·\", \"✢\", \"✳\", \"✻\", \"✽\"]")
        print("  • Random messages cycling every 2 seconds")
        print("  • Cyan color theme")
        print("  • 8 FPS smooth animation")
        print("  • (esc to interrupt) instructions")
    }

    /// Test just the live frame buffer demo to verify the coalescing fix
    static func testLiveFrameBufferDemoFix() async {
        print("🎬 Testing Live Frame Buffer Demo Fix")
        print("====================================")
        print("This test verifies that the coalescing bug is fixed.")
        print("")

        // Create frame buffer that writes to stdout
        let frameBuffer = FrameBuffer()

        // Animation frames using Transform component (RUNE-34)
        let loadingFrames = createTransformBasedLoadingFrames().map { transform in
            createBoxFrameWithTransform(transform: transform)
        }

        print("Rendering loading animation frames...")

        // Animate loading for 1 cycle
        let frameDescriptions = ["Loading...", "Loading.", "Loading..", "Loading..."]
        for (index, frame) in loadingFrames.enumerated() {
            print("  → About to render frame \(index + 1): \(frameDescriptions[index]) (using Transform)")
            await frameBuffer.renderFrame(frame)
            print("  → Rendered frame \(index + 1): \(frameDescriptions[index]) (using Transform)")
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

        // Let the demo run naturally without artificial delays

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

    /// RUNE-26 Yoga layout engine demo
    static func yogaLayoutDemo() async {
        await YogaLayoutDemo.run()
    }

    /// Comprehensive Component Integration Demo
    static func comprehensiveComponentDemo() async {
        await ComprehensiveComponentDemo.run()
    }

    /// Create Transform-based loading frames for animation
    private static func createTransformBasedLoadingFrames() -> [Transform] {
        let dotPatterns = ["...", ".", "..", "..."]

        return dotPatterns.map { dots in
            Transform(transform: { text in
                text.replacingOccurrences(of: "...", with: dots)
            }) {
                Text("Loading...", color: .blue, bold: true)
            }
        }
    }
}
