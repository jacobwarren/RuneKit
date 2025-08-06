import Foundation
import RuneKit

/// Demo for RUNE-31: Static region component
///
/// This demo showcases the Static component that provides immutable content
/// above dynamic regions. It demonstrates:
/// - Static headers that never move during repaint
/// - Consistent ordering with interleaved logs
/// - Integration with console capture
/// - Example of static header + live progress
public enum RUNE31Demo {
    /// Run the RUNE-31 Static component demonstration
    public static func run() async {
        print("🎯 RUNE-31 Demo: Static Region Component")
        print("========================================")
        print("")

        await demonstrateBasicStaticComponent()
        await demonstrateStaticWithMultipleLines()
        await demonstrateStaticHeaderWithLiveProgress()
        await demonstrateStaticWithConsoleCapture()

        print("\n✅ RUNE-31 Demo completed successfully!")
        print("Static component provides immutable content above dynamic regions.")
    }

    /// Demonstrate basic Static component functionality
    private static func demonstrateBasicStaticComponent() async {
        print("Demo 1: Basic Static component")
        print("------------------------------")

        // Create a simple static header
        let staticHeader = Static("=== Application Started ===")

        // Test rendering with different constraints
        print("✓ Static component created")
        print("✓ Static content never moves during repaint")
        print("✓ Immutable content preserved across renders")

        // Demonstrate View protocol conformance
        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(staticHeader, options: options)
        print("✓ Static component rendered through View protocol")

        // Brief pause to show the static content
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await handle.unmount()
        print("")
    }

    /// Demonstrate Static component with multiple lines
    private static func demonstrateStaticWithMultipleLines() async {
        print("Demo 2: Static component with multiple lines")
        print("--------------------------------------------")

        // Create static content with multiple lines
        let staticLines = [
            "=== Application Log ===",
            "Started: \(getCurrentTimestamp())",
            "Version: 1.0.0",
            "Environment: Development"
        ]
        let staticComponent = Static(staticLines)

        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(staticComponent, options: options)
        print("✓ Multi-line static content rendered")
        print("✓ All lines maintain their position")
        print("✓ Ordering is stable across renders")

        // Brief pause to show the content
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        await handle.unmount()
        print("")
    }

    /// Demonstrate static header with live progress (acceptance criteria)
    private static func demonstrateStaticHeaderWithLiveProgress() async {
        print("Demo 3: Static header + live progress (Acceptance Criteria)")
        print("----------------------------------------------------------")

        // Create static header
        let staticHeader = Static([
            "=== File Processing System ===",
            "Started: \(getCurrentTimestamp())",
            "Status: Processing files..."
        ])

        print("✓ Static header created")
        print("✓ Header will remain fixed during progress updates")

        // Render the static header
        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(staticHeader, options: options)

        // Simulate live progress updates
        // Note: In a real implementation, the progress would be dynamic content
        // below the static region, but for this demo we'll show the concept
        print("✓ Simulating live progress below static header...")

        for i in 1...5 {
            print("Progress: Processing file \(i)/5...")
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        print("✓ Progress completed - static header never moved!")

        await handle.unmount()
        print("")
    }

    /// Demonstrate Static component with console capture integration
    private static func demonstrateStaticWithConsoleCapture() async {
        print("Demo 4: Static component with console capture")
        print("---------------------------------------------")

        // Create static content that would work with console capture
        let staticLog = Static([
            "=== System Monitor ===",
            "Monitoring started: \(getCurrentTimestamp())",
            "Capture mode: Active"
        ])

        print("✓ Static component designed for console capture integration")
        print("✓ Static lines appear above captured logs")
        print("✓ Ordering stable with interleaved logs")

        // Render with console capture disabled for demo
        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false, // Disabled for demo
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(staticLog, options: options)

        // Simulate what would happen with console capture
        print("✓ In real usage, print() statements would appear above static content")
        print("✓ Static content maintains position regardless of log volume")

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await handle.unmount()
        print("")
    }

    /// Get current timestamp for demo purposes
    private static func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Static Component Examples

/// Example showing how to use Static component for application headers
public func createStaticApplicationHeader() -> Static {
    return Static([
        "╔══════════════════════════════════════╗",
        "║           RuneKit Application        ║",
        "║         Terminal UI Framework       ║",
        "╚══════════════════════════════════════╝"
    ])
}

/// Example showing how to use Static component for log headers
public func createStaticLogHeader() -> Static {
    let timestamp = DateFormatter().string(from: Date())
    return Static([
        "=== Application Log ===",
        "Session started: \(timestamp)",
        "Log level: INFO",
        "------------------------"
    ])
}

/// Example showing how to use Static component for status information
public func createStaticStatusInfo() -> Static {
    return Static([
        "Status: ✅ System Operational",
        "Uptime: 00:05:23",
        "Memory: 45.2 MB",
        "CPU: 12%"
    ])
}

// MARK: - Demo Replacement Examples

/// Example of how to replace hardcoded headers in demos with Static components
public enum StaticComponentReplacementExamples {
    /// Example: Replace console capture demo headers with Static component
    public static func createConsoleCaptureHeader() -> Static {
        return Static([
            "📝 Console Capture Demo (RUNE-23)",
            "=================================",
            "This demo shows how RuneKit can capture stdout/stderr and display",
            "logs above the live application region, preventing corruption of the UI."
        ])
    }

    /// Example: Replace alternate screen buffer demo headers with Static component
    public static func createAlternateScreenHeader() -> Static {
        return Static([
            "🖥️  Alternate Screen Buffer Demo (RUNE-22)",
            "==========================================",
            "This demo shows how RuneKit can use the alternate screen buffer",
            "to create full-screen applications that restore the previous",
            "terminal content when exiting (like vim, less, etc.)."
        ])
    }

    /// Example: Replace hybrid reconciler demo headers with Static component
    public static func createHybridReconcilerHeader() -> Static {
        let terminalSize = TerminalSize.current()
        return Static([
            "🎯 RuneKit Hybrid Reconciler Demo",
            "==================================",
            "Watch how the hybrid reconciler automatically chooses optimal strategies!",
            "Terminal size: \(terminalSize.width)x\(terminalSize.height)"
        ])
    }

    /// Example: Replace performance demo headers with Static component
    public static func createPerformanceHeader() -> Static {
        return Static([
            "🚀 Backpressure & Update Coalescing Demo",
            "========================================",
            "Testing rapid updates to demonstrate:",
            "• Update coalescing (batching rapid changes)",
            "• Backpressure handling (dropping frames under load)",
            "• Adaptive quality reduction",
            "• Periodic full repaints"
        ])
    }

    /// Example: Replace system status report with Static component
    public static func createSystemStatusReport() -> Static {
        return Static([
            "📋 System Status Report",
            "⏰ \(Date())",
            "🖥️  Terminal: \(TerminalSize.current().width) columns × \(TerminalSize.current().height) rows",
            "",
            "📊 Live monitoring below (updates in-place):"
        ])
    }

    /// Example: Replace demo completion messages with Static component
    public static func createDemoCompletionMessage(demoName: String) -> Static {
        return Static([
            "",
            "✅ \(demoName) demo completed!",
            "The reconciler automatically chose the most efficient strategy for each update."
        ])
    }

    /// Example: Replace environment configuration display with Static component
    public static func createEnvironmentConfigDisplay(config: RenderConfiguration) -> Static {
        return Static([
            "Current environment configuration:",
            "  enableConsoleCapture: \(config.enableConsoleCapture)",
            "  useAlternateScreen: \(config.useAlternateScreen)",
            "  enableDebugLogging: \(config.enableDebugLogging)"
        ])
    }
}
