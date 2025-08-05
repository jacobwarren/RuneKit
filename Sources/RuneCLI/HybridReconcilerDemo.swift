import Foundation
import RuneRenderer

/// Hybrid reconciler demonstration functions
extension RuneCLI {
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
        print("✅ Hybrid reconciler demo completed!")
        print("The reconciler automatically chose the most efficient strategy for each update.")
        print("")
    }
}
