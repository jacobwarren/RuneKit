import Foundation
import RuneRenderer

/// Console capture demonstration functions
extension RuneCLI {
    /// Demonstrate console capture functionality (RUNE-23)
    static func consoleCaptureDemo() async {
        print("")
        print("📝 Console Capture Demo (RUNE-23)")
        print("=================================")
        print("This demo shows how RuneKit can capture stdout/stderr and display")
        print("logs above the live application region, preventing corruption of the UI.")
        print("")

        await consoleCaptureBasicDemo()
        await consoleCaptureDisabledDemo()
        await consoleCaptureEnvironmentDemo()
    }

    /// Demo 1: Basic console capture functionality
    private static func consoleCaptureBasicDemo() async {
        print("Demo 1: Basic console capture")
        print("-----------------------------")
        print("Creating a FrameBuffer with console capture enabled...")

        let config = RenderConfiguration(enableDebugLogging: false, enableConsoleCapture: true)
        let frameBuffer = FrameBuffer(configuration: config)

        // Create a simple application frame
        let appFrame = TerminalRenderer.Frame(
            lines: [
                "┌─ Live Application ─┐",
                "│ Status: Running    │",
                "│ Logs appear above  │",
                "└────────────────────┘"
            ],
            width: 22,
            height: 4
        )

        print("Rendering application frame with console capture...")
        await frameBuffer.renderFrame(appFrame)

        // Wait a moment for capture to initialize
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

        print("Now printing some log messages - they should appear above the live region:")

        // Simulate application logs
        print("🔍 Application started")
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        print("📊 Processing data...")
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        print("⚠️ Warning: Low memory")
        fputs("❌ Error: Connection failed\n", stderr)
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        print("✅ Recovery successful")
        print("📈 Performance metrics updated")

        // Update the application frame to show new status
        let updatedFrame = TerminalRenderer.Frame(
            lines: [
                "┌─ Live Application ─┐",
                "│ Status: Updated    │",
                "│ Logs appear above  │",
                "└────────────────────┘"
            ],
            width: 22,
            height: 4
        )

        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        await frameBuffer.renderFrame(updatedFrame)

        print("🔄 Application state updated")

        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        print("")
        print("Demo 1 complete. Notice how logs appeared above the live region!")

        // Clean up
        await frameBuffer.clear()

        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }

    /// Demo 2: Console capture disabled (default behavior)
    private static func consoleCaptureDisabledDemo() async {
        print("")
        print("Demo 2: Console capture disabled (default behavior)")
        print("--------------------------------------------------")
        print("Creating a FrameBuffer with console capture disabled...")

        let normalConfig = RenderConfiguration(enableConsoleCapture: false)
        let normalFrameBuffer = FrameBuffer(configuration: normalConfig)

        let normalFrame = TerminalRenderer.Frame(
            lines: [
                "┌─ Normal Mode ─┐",
                "│ No capture   │",
                "└──────────────┘"
            ],
            width: 17,
            height: 3
        )

        await normalFrameBuffer.renderFrame(normalFrame)

        print("This print statement appears normally (not captured)")
        print("Console capture is disabled in this mode")

        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        await normalFrameBuffer.clear()
    }

    /// Demo 3: Environment variable configuration
    private static func consoleCaptureEnvironmentDemo() async {
        print("")
        print("Demo 3: Environment variable configuration")
        print("-----------------------------------------")
        print("Console capture can be controlled via RUNE_CONSOLE_CAPTURE environment variable:")
        print("  export RUNE_CONSOLE_CAPTURE=true   # Enable capture")
        print("  export RUNE_CONSOLE_CAPTURE=false  # Disable capture")
        print("  export RUNE_CONSOLE_CAPTURE=1      # Enable capture")
        print("  export RUNE_CONSOLE_CAPTURE=0      # Disable capture")
        print("")

        // Test environment configuration
        let envConfig = RenderConfiguration.fromEnvironment()
        print("Current environment configuration:")
        print("  enableConsoleCapture: \(envConfig.enableConsoleCapture)")
        print("  useAlternateScreen: \(envConfig.useAlternateScreen)")
        print("  enableDebugLogging: \(envConfig.enableDebugLogging)")

        print("")
        print("Console capture demo completed!")
        print("Key benefits:")
        print("  ✅ Prevents random prints from corrupting the UI")
        print("  ✅ Preserves logs in chronological order")
        print("  ✅ Displays logs above the live region")
        print("  ✅ Distinguishes stdout from stderr")
        print("  ✅ Can be toggled via configuration")
    }
}
