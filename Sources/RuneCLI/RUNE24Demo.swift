import Foundation
import RuneKit

/// Demo for RUNE-24: render(_:options) API
///
/// This demo showcases the new top-level render function with various options
/// including TTY detection, CI heuristics, signal handling, and console capture.
public enum RUNE24Demo {
    /// Run the RUNE-24 API demonstration
    public static func run() async {
        print("🎯 RUNE-24 Demo: render(_:options) API")
        print("=====================================")
        print("")

        await demonstrateBasicRender()
        await demonstrateCustomOptions()
        await demonstrateEnvironmentDetection()

        print("")
        print("✅ RUNE-24 Demo completed successfully!")
        print("Key features demonstrated:")
        print("  • Top-level render(_:options) function")
        print("  • TTY detection and CI environment heuristics")
        print("  • Signal handling with exitOnCtrlC option")
        print("  • Console capture with patchConsole option")
        print("  • Alternate screen buffer control")
        print("  • FPS capping and performance tuning")
        print("  • RenderHandle for programmatic control")
    }

    /// Demonstrate basic render function usage
    private static func demonstrateBasicRender() async {
        print("Demo 1: Basic render function with default options")
        print("------------------------------------------------")

        // Create a simple view
        let welcomeView = Text("Welcome to RuneKit RUNE-24!")

        // Use default options (environment-aware)
        let handle = await render(welcomeView)

        print("✓ Render function called with default options")
        print("✓ RenderHandle created successfully")

        // Check handle properties
        let isActive = await handle.isActive
        let hasSignalHandler = await handle.hasSignalHandler()
        let hasConsoleCapture = await handle.hasConsoleCapture()

        print("  - Handle active: \(isActive)")
        print("  - Signal handler: \(hasSignalHandler)")
        print("  - Console capture: \(hasConsoleCapture)")

        // Clean up
        await handle.stop()
        print("✓ Handle stopped gracefully")
        print("")
    }

    /// Demonstrate custom options
    private static func demonstrateCustomOptions() async {
        print("Demo 2: Custom render options")
        print("-----------------------------")

        // Create custom options for a non-interactive environment
        let customOptions = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
        )

        let statusView = Text("Custom Options Demo")
        let handle = await render(statusView, options: customOptions)

        print("✓ Custom options applied:")
        print("  - exitOnCtrlC: false")
        print("  - patchConsole: false")
        print("  - useAltScreen: false")
        print("  - fpsCap: 30.0")

        // Verify options took effect
        let hasSignalHandler = await handle.hasSignalHandler()
        let hasConsoleCapture = await handle.hasConsoleCapture()

        print("✓ Options verification:")
        print("  - Signal handler disabled: \(!hasSignalHandler)")
        print("  - Console capture disabled: \(!hasConsoleCapture)")

        await handle.stop()
        print("✓ Custom options demo completed")
        print("")
    }

    /// Demonstrate environment detection
    private static func demonstrateEnvironmentDetection() async {
        print("Demo 3: Environment detection and heuristics")
        print("--------------------------------------------")

        // Test TTY detection
        let isTTY = RenderOptions.isInteractiveTerminal()
        print("✓ TTY detection: \(isTTY ? "Interactive terminal" : "Non-interactive (pipe/redirect)")")

        // Test CI detection
        let isCI = RenderOptions.isCIEnvironment()
        print("✓ CI detection: \(isCI ? "CI environment detected" : "Local development environment")")

        // Show environment-aware defaults
        let envOptions = RenderOptions.fromEnvironment()
        print("✓ Environment-aware defaults:")
        print("  - exitOnCtrlC: \(envOptions.exitOnCtrlC)")
        print("  - patchConsole: \(envOptions.patchConsole)")
        print("  - useAltScreen: \(envOptions.useAltScreen)")
        print("  - fpsCap: \(envOptions.fpsCap)")

        // Test with simulated CI environment
        let ciEnvironment = ["CI": "true", "GITHUB_ACTIONS": "true"]
        let ciOptions = RenderOptions.fromEnvironment(ciEnvironment)
        print("✓ Simulated CI environment defaults:")
        print("  - exitOnCtrlC: \(ciOptions.exitOnCtrlC) (should be false)")
        print("  - patchConsole: \(ciOptions.patchConsole) (should be false)")
        print("  - useAltScreen: \(ciOptions.useAltScreen) (should be false)")
        print("  - fpsCap: \(ciOptions.fpsCap) (should be 30.0)")

        print("✓ Environment detection demo completed")
        print("")
    }
}
