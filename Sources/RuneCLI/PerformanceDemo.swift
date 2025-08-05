import Foundation
import RuneRenderer

/// Performance demonstration functions
extension RuneCLI {
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

        // Create frames with rapid changes
        print("Sending 100 rapid frame updates...")

        for i in 1...100 {
            let frame = createSystemMonitorFrame(
                terminalWidth: 80,
                cpuUsage: i % 100,  // Constantly changing
                ramUsage: (i * 2) % 100,
                diskUsage: (i * 3) % 100,
                netUsage: (i * 4) % 100
            )

            // Fire and forget - don't await to create backpressure
            Task {
                await frameBuffer.renderFrame(frame)
            }

            // Small delay to prevent complete overwhelming
            if i % 5 == 0 {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms every 5 frames
            }

            // Show progress every 10 frames
            if i % 10 == 0 {
                let metrics = await frameBuffer.getPerformanceMetrics()
                print("Frame \(i): Queue depth: \(metrics.currentQueueDepth), Dropped: \(metrics.droppedFrames), Quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))")
            }
        }

        // Wait for queue to settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Show final metrics through proper frame buffer to avoid overlay
        let finalMetrics = await frameBuffer.getPerformanceMetrics()
        let metricsFrame = createFinalResultsFrame(terminalWidth: 80, metrics: finalMetrics)
        await frameBuffer.renderFrame(metricsFrame)

        let readSleepTime: UInt64 = ProcessInfo.processInfo.environment["CI"] != nil ? 100_000_000 : 3_000_000_000 // 0.1s in CI, 3s locally
        try? await Task.sleep(nanoseconds: readSleepTime)

        await frameBuffer.clear()

        print("")
        print("✅ Backpressure demo completed!")
        print("Key features demonstrated:")
        print("• Update coalescing under rapid changes")
        print("• Backpressure handling with frame dropping")
        print("• Adaptive quality reduction under load")
        print("• Performance metrics tracking")
        print("• Reducing quality temporarily under load")
        print("• Maintaining terminal responsiveness")

        // Give time for system to settle before next demo
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }

    /// Live demonstration of frame buffer with actual terminal rendering
    static func liveFrameBufferDemo() async {
        print("")
        print("🎬 Live Frame Buffer Demo")
        print("========================")
        print("This demo renders actual frames to the terminal to show:")
        print("• In-place frame updates without flicker")
        print("• Cursor management (hidden during rendering)")
        print("• Proper cleanup and restoration")
        print("")

        print("Starting live rendering in 3 seconds...")
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        let frameBuffer = FrameBuffer()

        // Animation frames with consistent width
        let loadingContents = ["Loading...", "Loading.", "Loading..", "Loading..."]
        let loadingFrames = loadingContents.map { content in
            createBoxFrame(content: content)
        }

        // Animate loading for 2 cycles (reduced for demo)
        for cycle in 0..<2 {
            for (index, frame) in loadingFrames.enumerated() {
                await frameBuffer.renderFrame(frame)
                print("  → Rendered frame \(cycle * 4 + index + 1): \(loadingContents[index])")
                let frameSleepTime: UInt64 = ProcessInfo.processInfo.environment["CI"] != nil ? 50_000_000 : 800_000_000 // 0.05s in CI, 0.8s locally
                try? await Task.sleep(nanoseconds: frameSleepTime)
            }
        }

        // Final completion frame
        let completeFrame = createBoxFrame(content: "Complete! ✅")
        await frameBuffer.renderFrame(completeFrame)
        print("  → Rendered final frame: Complete! ✅")

        // Wait to show final result (reduced in CI)
        let finalSleepTime: UInt64 = ProcessInfo.processInfo.environment["CI"] != nil ? 50_000_000 : 2_000_000_000 // 0.05s in CI, 2s locally
        try? await Task.sleep(nanoseconds: finalSleepTime)

        // Clean up
        await frameBuffer.clear()

        print("")
        print("✅ Live demo completed!")
        print("")

        // Show performance metrics
        let metrics = await frameBuffer.getPerformanceMetrics()
        print("📊 Performance Summary:")
        print("• Total renders: \(metrics.totalRenders)")
        print("• Average efficiency: \(String(format: "%.1f%%", metrics.averageEfficiency * 100))")
        print("• Frames since full redraw: \(metrics.framesSinceFullRedraw)")
        print("• Dropped frames: \(metrics.droppedFrames)")
        print("• Current queue depth: \(metrics.currentQueueDepth)")
        print("")

        print("Key features demonstrated:")
        print("• Smooth in-place frame updates")
        print("• No cursor flicker or artifacts")
        print("• Proper frame cleanup")
        print("• Cursor is hidden during rendering and restored afterward")
        print("• ANSI escape sequences handle all positioning and clearing")

        // Give time for user to read results before next demo
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
    }
}
