import Foundation
import RuneANSI
import RuneComponents
import RuneKit
import RuneLayout
import RuneRenderer

private enum DemoEnv {
    static var options: RenderOptions {
        // Force demos to use main screen buffer (no alternate screen)
        let base = RenderOptions.fromEnvironment()
        return RenderOptions(
            stdout: base.stdout,
            stdin: base.stdin,
            stderr: base.stderr,
            exitOnCtrlC: base.exitOnCtrlC,
            patchConsole: base.patchConsole,
            useAltScreen: false,
            enableRawMode: base.enableRawMode,
            enableBracketedPaste: base.enableBracketedPaste,
            fpsCap: base.fpsCap,
            terminalProfile: base.terminalProfile
        )
    }
}

/// Comprehensive demonstration of ALL RuneKit components working together
/// This demo showcases proper nesting, integration, and real-world usage patterns
public enum ComprehensiveComponentDemo {
    public static func run() async {
        // Build intro view inside the component tree (no interleaved prints)
        let intro = Box(
            border: .rounded,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static([
                "🚀 Comprehensive RuneKit Component Integration Demo",
                "This demo showcases ALL components working together in realistic scenarios:",
                "• Text with full styling capabilities",
                "• Box with borders, padding, and layout",
                "• Static for immutable headers and logs",
                "• Newline for consistent spacing",
                "• Spacer for flexible layouts",
                "• Transform for dynamic content modification",
            ]),
        )

        let options = DemoEnv.options
        let handle = await render(intro, options: options)

        // Stage 1 → 5: rerender between demos within the same session
        try? await Task.sleep(for: .seconds(1))
        await handle.rerender(simpleIntegrationView())
        try? await Task.sleep(for: .seconds(1))
        await handle.rerender(textStylingView())
        try? await Task.sleep(for: .seconds(1))
        await handle.rerender(boxLayoutsView())
        try? await Task.sleep(for: .seconds(1))
        await handle.rerender(transformCapabilitiesView())
        try? await Task.sleep(for: .seconds(1))
        await handle.rerender(completeApplicationView())
        try? await Task.sleep(for: .seconds(2))

        // Stage 6: animated spinner (cooperative rerender for ~3s)
        let spinnerDuration: TimeInterval = 3.0
        let spinnerInterval: UInt64 = 125_000_000 // 8 FPS
        let spinnerStart = Date()
        while Date().timeIntervalSince(spinnerStart) < spinnerDuration {
            await handle.rerender(spinnerCompositeView())
            try? await Task.sleep(nanoseconds: spinnerInterval)
        }

        // Stage 7: all components in one rounded box
        await handle.rerender(allComponentsInRoundedBoxView())
        try? await Task.sleep(for: .seconds(2))

        // Cleanup
        await handle.clear()
        await handle.unmount()

        print("✅ Comprehensive Component Integration Demo completed!")
        print("All RuneKit components working together seamlessly! 🎉")
    }

    /// Demo 6: Animated spinner using Transform + Ticker (no Spinner component)
    private static func demonstrateSpinnerAndDynamicTransform() async {
        print("🎬 Demo 6: Animated Transform-driven spinner")
        print("============================================")

        let options = DemoEnv.options

        // Build spinner view inside rerender closure to satisfy @Sendable
        let start = Date().timeIntervalSince1970
        let handle = await render(
            Box(
                border: .single,
                paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                children:
                Static([
                    "🎬 Demo 6: Animated spinner built with Transform + Ticker",
                    "====================================================",
                ]),
                Newline(count: 1),
                Transform(timeAware: { _, t in
                    let frames = ["·", "✢", "✳", "∗", "✻", "✽"]
                    let idx = Int(((t - start) * 8.0).rounded(.down)) % frames.count
                    return "\(frames[idx]) Processing… (esc to interrupt)"
                }) { Text("") },
            ),
            options: options,
        )

        // Animate for ~3 seconds using a cooperative loop
        let end = start + 3.0
        while Date().timeIntervalSince1970 < end {
            await handle.rerender { @Sendable in
                Box(
                    border: .single,
                    paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
                    children:
                    Static([
                        "🎬 Demo 6: Animated spinner built with Transform + Ticker",
                        "====================================================",
                    ]),
                    Newline(count: 1),
                    Transform(timeAware: { _, t in
                        let frames = ["·", "✢", "✳", "∗", "✻", "✽"]
                        let idx = Int(((t - start) * 8.0).rounded(.down)) % frames.count
                        return "\(frames[idx]) Processing… (esc to interrupt)"
                    }) { Text("") },
                )
            }
            try? await Task.sleep(for: .milliseconds(125))
        }

        await handle.clear()
        await handle.unmount()

        print("✓ Animated spinner demonstrated (Transform + rerender loop)")
        print("")
    }

    /// Demo 1: Simple Component Integration
    private static func demonstrateSimpleIntegration() async {
        // Create a simple layout using all basic components, with heading as Static
        let simpleLayout = Box(
            border: .single,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            children:
            Static(["🔧 Demo 1: Simple Component Integration"]),
            Newline(count: 1),
            Text("🎯 Welcome to RuneKit!", color: .cyan, bold: true),
        )

        let options = DemoEnv.options

        let handle = await render(simpleLayout, options: options)
        try? await Task.sleep(for: .seconds(1))
        await handle.clear()
        await handle.unmount()
    }

    /// Demo 2: Text Styling Showcase
    private static func demonstrateTextStyling() async {
        let textShowcase = Box(
            border: .double,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            children:
            Static(["🎨 Demo 2: Text Styling Showcase"]),
            Newline(count: 1),
            Text("Text Styling Examples", color: .white, bold: true),
        )

        let options = DemoEnv.options
        let handle = await render(textShowcase, options: options)
        try? await Task.sleep(for: .seconds(1))
        await handle.clear()
        await handle.unmount()
    }

    /// Demo 3: Box Layout Patterns
    private static func demonstrateBoxLayouts() async {
        let layoutDemo = Box(
            border: .rounded,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            children:
            Static(["📦 Demo 3: Box Layout Patterns"]),
            Newline(count: 1),
            Text("📦 Box Layout Demo", color: .green, bold: true),
        )

        let options = DemoEnv.options

        let handle = await render(layoutDemo, options: options)
        try? await Task.sleep(for: .seconds(1))
        await handle.clear()
        await handle.unmount()
    }

    /// Demo 4: Transform Capabilities
    private static func demonstrateTransformCapabilities() async {
        let transformDemo = Box(
            border: .single,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            children:
            Static(["🔄 Demo 4: Transform Capabilities"]),
            Newline(count: 1),
            Transform(
                transform: { $0.uppercased() },
                child: Text("Transform Demo: Making Text Uppercase", color: .magenta, bold: true),
            ),
        )

        let options = DemoEnv.options

        let handle = await render(transformDemo, options: options)
        try? await Task.sleep(for: .seconds(1))
        await handle.clear()
        await handle.unmount()
    }

    /// Demo 5: Complete Application Example
    private static func demonstrateCompleteApplication() async {
        let application = Box(
            border: .double,
            paddingTop: 1,
            paddingRight: 3,
            paddingBottom: 1,
            paddingLeft: 3,
            children:
            Static(["🚀 Demo 5: Complete Application Example"]),
            Newline(count: 1),
            Transform(transform: { "🎯 " + $0.uppercased() + " 🎯" }) {
                Text("RuneKit Complete Demo", color: .cyan, bold: true)
            },
        )

        let options = DemoEnv.options

        let handle = await render(application, options: options)
        try? await Task.sleep(for: .seconds(2))
        await handle.clear()
        await handle.unmount()
    }

    // Demo 7: All core components inside a single rounded box (legacy function no longer used)
    private static func demonstrateAllComponentsInRoundedBox() async {
        // Keep a minimal version for compatibility; single-session flow uses view builder below
        let composite = allComponentsInRoundedBoxView()
        let options = DemoEnv.options
        let handle = await render(composite, options: options)
        try? await Task.sleep(for: .seconds(2))
        await handle.clear()
        await handle.unmount()
    }
}

extension ComprehensiveComponentDemo {
    // MARK: - View Builders for Single-Session Flow

    private static func simpleIntegrationView() -> Box {
        Box(
            border: .single,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static(["🔧 Demo 1: Simple Component Integration"]),
            Newline(count: 1),
            Text("🎯 Welcome to RuneKit!", color: .cyan, bold: true),
        )
    }

    private static func textStylingView() -> Box {
        Box(
            border: .double,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static(["🎨 Demo 2: Text Styling Showcase"]),
            Newline(count: 1),
            Text("Text Styling Examples", color: .white, bold: true),
        )
    }

    private static func boxLayoutsView() -> Box {
        Box(
            border: .rounded,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static(["📦 Demo 3: Box Layout Patterns"]),
            Newline(count: 1),
            Text("📦 Box Layout Demo", color: .green, bold: true),
        )
    }

    private static func transformCapabilitiesView() -> Box {
        Box(
            border: .single,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static(["🔄 Demo 4: Transform Capabilities"]),
            Newline(count: 1),
            Transform(
                transform: { $0.uppercased() },
                child: Text("Transform Demo: Making Text Uppercase", color: .magenta, bold: true),
            ),
        )
    }

    private static func completeApplicationView() -> Box {
        Box(
            border: .double,
            paddingTop: 1, paddingRight: 3, paddingBottom: 1, paddingLeft: 3,
            children:
            Static(["🚀 Demo 5: Complete Application Example"]),
            Newline(count: 1),
            Transform(transform: { "🎯 " + $0.uppercased() + " 🎯" }) {
                Text("RuneKit Complete Demo", color: .cyan, bold: true)
            },
        )
    }

    private static func spinnerCompositeView() -> Box {
        Box(
            border: .single,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            Static([
                "🎬 Demo 6: Animated spinner built with Transform + Ticker",
                "====================================================",
            ]),
            Newline(count: 1),
            Transform(timeAware: { _, t in
                let frames = ["·", "✢", "✳", "∗", "✻", "✽"]
                let idx = Int((t * 8.0).rounded(.down)) % frames.count
                return "\(frames[idx]) Processing… (esc to interrupt)"
            }) { Text("") },
        )
    }

    private static func allComponentsInRoundedBoxView() -> Box {
        let header = Static([
            "🧩 Demo 7: All Core Components in One Rounded Box",
            "=================================================",
            "RuneKit Components",
            "All Together Now ➕",
        ])
        let innerTransformed = Transform(transform: { input in
            "✨ " + input.uppercased() + " ✨"
        }) {
            Text("inside transform", color: .magenta, bold: true)
        }
        return Box(
            border: .rounded,
            backgroundColor: .black,
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            children:
            header,
            Newline(count: 1),
            Text("This is a Text component", color: .cyan),
            Spacer(),
            innerTransformed,
            Newline(count: 1),
        )
    }
}
