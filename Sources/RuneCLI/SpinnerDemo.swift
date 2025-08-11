import Foundation
import RuneComponents
import RuneKit

/// Spinner / Loader demos implemented using RuneKit HooksRuntime APIs
extension RuneCLI {
    /// Full spinner demo: animated glyph + message + elapsed seconds + hint text
    static func hooksSpinnerDemo() async {
        // Force alt screen off for this demo for easier visibility
        var options = RenderOptions.fromEnvironment()
        options = RenderOptions(
            stdout: options.stdout,
            stdin: options.stdin,
            stderr: options.stderr,
            exitOnCtrlC: options.exitOnCtrlC,
            patchConsole: options.patchConsole,
            useAltScreen: false, // override
            enableRawMode: options.enableRawMode,
            enableBracketedPaste: options.enableBracketedPaste,
            fpsCap: options.fpsCap,
            terminalProfile: options.terminalProfile
        )
        // Important: build inside rerender closure so hooks register and requestRerender is bound
        let handle = await render(Text(""), options: options)
        await handle.rerender { spinnerView() }
        // Let it spin for a short period for demo purposes
        try? await Task.sleep(for: .seconds(3))
        await handle.clear()
        await handle.unmount()
        print("✓ Hooks spinner demo complete")
    }

    /// Minimal spinner demo: just the glyph animating
    static func hooksSimpleSpinnerDemo() async {
        let base = RenderOptions.fromEnvironment()
        let options = RenderOptions(
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
        let handle = await render(Text(""), options: options)
        await handle.rerender { simpleSpinnerView() }
        try? await Task.sleep(for: .seconds(2))
        await handle.clear()
        await handle.unmount()
        print("✓ Hooks simple spinner demo complete")
    }

    // MARK: - View Builders

    private static func spinnerView() -> Box {
        // Use ASCII-safe frames to avoid font/rendering issues
        let frames: [String] = ["|", "/", "-", "\\", "-", "/"]

        // Stable refs across rerenders
        let startTime = HooksRuntime.useRef(Date())
        let message = HooksRuntime.useRef(Self.messages.randomElement() ?? "Working")

        // Drive rerenders approximately every 120ms (8–9 FPS)
        HooksRuntime.useEffect("spinnerTimer", depsToken: "once") {
            let task = Task {
                while !Task.isCancelled {
                    HooksRuntime.requestRerender()
                    try? await Task.sleep(for: .milliseconds(120))
                }
            }
            return { task.cancel() }
        }

        // Compute frame and elapsed time from startTime
        let elapsed = Date().timeIntervalSince(startTime.current)
        let frame = Int((elapsed * 1000.0) / 120.0) % max(1, frames.count)
        let elapsedSeconds = Int(elapsed.rounded(.down))

        // Combine content into one visible, cyan line for reliability across terminals
        let line = "\(frames[frame]) \(message.current)… (\(elapsedSeconds)s · esc to interrupt)"
        let text = Text(line, color: .cyan, bold: true)
        return Box(child: text)
    }

    private static func simpleSpinnerView() -> Box {
        #if os(macOS)
        let chars: [String] = ["·", "✢", "✳", "∗", "✻", "✽"]
        #else
        let chars: [String] = ["·", "✢", "*", "∗", "✻", "✽"]
        #endif
        let frames = chars + chars.reversed()
        let startTime = HooksRuntime.useRef(Date())

        HooksRuntime.useEffect("spinnerTimer", depsToken: "once") {
            let task = Task {
                while !Task.isCancelled {
                    HooksRuntime.requestRerender()
                    try? await Task.sleep(for: .milliseconds(120))
                }
            }
            return { task.cancel() }
        }

        let elapsed = Date().timeIntervalSince(startTime.current)
        let frame = Int((elapsed * 1000.0) / 120.0) % max(1, frames.count)
        let spinnerGlyph = Text(frames[frame], color: .cyan, bold: true)
        return Box(width: .points(2), height: .points(1), child: spinnerGlyph)
    }

    // MARK: - Data

    private static let messages: [String] = [
        "Accomplishing","Actioning","Actualizing","Baking","Brewing","Calculating","Cerebrating","Churning",
        "Clauding","Coalescing","Cogitating","Computing","Conjuring","Considering","Cooking","Crafting",
        "Creating","Crunching","Deliberating","Determining","Doing","Effecting","Finagling","Forging",
        "Forming","Generating","Hatching","Herding","Honking","Hustling","Ideating","Inferring","Manifesting",
        "Marinating","Moseying","Mulling","Mustering","Musing","Noodling","Percolating","Pondering","Processing",
        "Puttering","Reticulating","Ruminating","Schlepping","Shucking","Simmering","Smooshing","Spinning",
        "Stewing","Synthesizing","Thinking","Transmuting","Vibing","Working",
    ]
}

