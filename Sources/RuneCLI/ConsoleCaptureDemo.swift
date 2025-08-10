import Foundation
import RuneRenderer
import RuneComponents
import RuneLayout

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

        // Create a simple application frame using Box component
        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Live Application"),
                     Text("Status: Running"),
                     Text("Logs appear above")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 22, height: 4)
        let lines = box.render(in: rect)
        let appFrame = TerminalRenderer.Frame(lines: lines, width: 22, height: lines.count)

        print("Rendering application frame with console capture...")
        await frameBuffer.renderFrame(appFrame)

        // Capture initialized, continue naturally

        print("Now printing some log messages - they should appear above the live region:")

        // Simulate application logs
        print("🔍 Application started")
        print("📊 Processing data...")
        print("⚠️ Warning: Low memory")
        // Simulate stderr output using a different approach for concurrency safety
        print("❌ Error: Connection failed")
        print("✅ Recovery successful")
        print("📈 Performance metrics updated")

        // Update the application frame to show new status using Box component
        let updatedBox = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Live Application"),
                     Text("Status: Updated"),
                     Text("Logs appear above")
        )
        let updatedRect = FlexLayout.Rect(x: 0, y: 0, width: 22, height: 4)
        let updatedLines = updatedBox.render(in: updatedRect)
        let updatedFrame = TerminalRenderer.Frame(lines: updatedLines, width: 22, height: updatedLines.count)

        await frameBuffer.renderFrame(updatedFrame)
        print("🔄 Application state updated")

        print("")
        print("Demo 1 complete. Notice how logs appeared above the live region!")

        // Clean up
        await frameBuffer.clear()

        // Cleanup completed naturally
    }

    /// Demo 2: Console capture disabled (default behavior)
    private static func consoleCaptureDisabledDemo() async {
        print("")
        print("Demo 2: Console capture disabled (default behavior)")
        print("--------------------------------------------------")
        print("Creating a FrameBuffer with console capture disabled...")

        let normalConfig = RenderConfiguration(enableConsoleCapture: false)
        let normalFrameBuffer = FrameBuffer(configuration: normalConfig)

        let normalBox = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Normal Mode"),
                     Text("No capture")
        )
        let normalRect = FlexLayout.Rect(x: 0, y: 0, width: 17, height: 3)
        let normalLines = normalBox.render(in: normalRect)
        let normalFrame = TerminalRenderer.Frame(lines: normalLines, width: 17, height: normalLines.count)

        await normalFrameBuffer.renderFrame(normalFrame)

        print("This print statement appears normally (not captured)")
        print("Console capture is disabled in this mode")

        // Normal mode demo completed naturally

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
