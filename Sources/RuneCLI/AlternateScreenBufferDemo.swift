import Foundation
import RuneRenderer

/// Alternate screen buffer demonstration functions
extension RuneCLI {
    /// Demonstrate alternate screen buffer functionality (RUNE-22)
    static func alternateScreenBufferDemo() async {
        print("")
        print("🖥️  Alternate Screen Buffer Demo (RUNE-22)")
        print("==========================================")
        print("This demo shows how RuneKit can use the alternate screen buffer")
        print("to create full-screen applications that restore the previous")
        print("terminal content when exiting (like vim, less, etc.).")
        print("")

        // Demo 1: Basic alternate screen buffer usage
        print("Demo 1: Basic alternate screen buffer")
        print("------------------------------------")
        print("Creating a FrameBuffer with alternate screen enabled...")

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(configuration: config)

        // Check if alternate screen is supported
        let isActive = await frameBuffer.isAlternateScreenActive()
        print("Alternate screen initially active: \(isActive)")

        // Get terminal size for frame creation
        let terminalSize = TerminalSize.current()

        // Create a welcome frame
        let welcomeFrame = createAlternateScreenWelcomeFrame(terminalWidth: terminalSize.width)

        print("Rendering welcome frame in alternate screen...")
        await frameBuffer.renderFrame(welcomeFrame)

        // Welcome screen displayed, continue naturally

        // Create an application simulation frame
        let appFrame = createAlternateScreenAppFrame(terminalWidth: terminalSize.width)

        print("Switching to application view...")
        await frameBuffer.renderFrame(appFrame)

        // Application displayed, continue naturally

        // Clean up - this should restore the previous terminal content
        print("Exiting alternate screen (should restore previous content)...")
        await frameBuffer.clear()

        // Cleanup completed, continue naturally

        print("")
        print("Demo 1 complete. Previous terminal content should be restored!")

        // Demo 2: Alternate screen disabled (fallback behavior)
        print("")
        print("Demo 2: Alternate screen disabled (fallback)")
        print("-------------------------------------------")
        print("Creating a FrameBuffer with alternate screen disabled...")

        let normalConfig = RenderConfiguration(useAlternateScreen: false)
        let normalFrameBuffer = FrameBuffer(configuration: normalConfig)

        let fallbackFrame = createFallbackDemoFrame(terminalWidth: terminalSize.width)

        await normalFrameBuffer.renderFrame(fallbackFrame)

        // Fallback displayed, continue naturally

        await normalFrameBuffer.clear()

        print("")
        print("Demo 2 complete. This rendered normally without alternate screen.")

        // Demo 3: Environment variable configuration
        print("")
        print("Demo 3: Environment variable configuration")
        print("-----------------------------------------")
        print("Alternate screen can be controlled via RUNE_ALT_SCREEN environment variable:")
        print("  export RUNE_ALT_SCREEN=true   # Enable alternate screen")
        print("  export RUNE_ALT_SCREEN=false  # Disable alternate screen")
        print("  export RUNE_ALT_SCREEN=1      # Enable alternate screen")
        print("  export RUNE_ALT_SCREEN=0      # Disable alternate screen")
        print("")

        // Test environment configuration
        let envConfig = RenderConfiguration.fromEnvironment()
        print("Current environment configuration:")
        print("  useAlternateScreen: \(envConfig.useAlternateScreen)")
        print("  enableConsoleCapture: \(envConfig.enableConsoleCapture)")
        print("  enableDebugLogging: \(envConfig.enableDebugLogging)")

        print("")
        print("Alternate screen buffer demo completed!")
        print("Key benefits:")
        print("• Full-screen application support")
        print("• Previous terminal content preservation")
        print("• Automatic alternate screen enter/leave")
        print("• Previous terminal content restoration")
        print("• Environment variable configuration")
        print("• Graceful fallback when disabled")
        print("• Integration with RuneKit's rendering system")
    }
}
