import Foundation
import RuneComponents
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

        for i in 1 ... 100 {
            let frame = createSystemMonitorFrame(
                terminalWidth: 80,
                cpuUsage: i % 100, // Constantly changing
                ramUsage: (i * 2) % 100,
                diskUsage: (i * 3) % 100,
                netUsage: (i * 4) % 100,
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
                print(
                    "Frame \(i): Queue depth: \(metrics.currentQueueDepth), Dropped: \(metrics.droppedFrames), Quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))",
                )
            }
        }

        // Wait for queue to settle
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Show final metrics through proper frame buffer to avoid overlay
        let finalMetrics = await frameBuffer.getPerformanceMetrics()
        let metricsFrame = createFinalResultsFrame(terminalWidth: 80, metrics: finalMetrics)
        await frameBuffer.renderFrame(metricsFrame)

        // Let users read the results naturally without artificial timeout

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

        // System settled, continue to next demo
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

        print("Starting live rendering...")
        // Start immediately without artificial delay

        let frameBuffer = FrameBuffer()

        // Animation frames using Transform component (RUNE-34)
        let loadingFrames = createTransformBasedLoadingFrames().map { transform in
            createBoxFrameWithTransform(transform: transform)
        }

        // Animate loading for 2 cycles (reduced for demo)
        let frameDescriptions = ["Loading...", "Loading.", "Loading..", "Loading..."]
        for cycle in 0 ..< 2 {
            for (index, frame) in loadingFrames.enumerated() {
                await frameBuffer.renderFrame(frame)
                print("  → Rendered frame \(cycle * 4 + index + 1): \(frameDescriptions[index]) (using Transform)")
                let frameSleepTime: UInt64 = ProcessInfo.processInfo
                    .environment["CI"] != nil ? 50_000_000 : 800_000_000 // 0.05s in CI, 0.8s locally
                try? await Task.sleep(nanoseconds: frameSleepTime)
            }
        }

        // Final completion frame
        let completeFrame = createBoxFrame(content: "Complete! ✅")
        await frameBuffer.renderFrame(completeFrame)
        print("  → Rendered final frame: Complete! ✅")

        // Final result displayed, continue naturally

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

        // Results displayed, continue to next demo
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
