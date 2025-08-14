import Foundation
import Testing
@testable import RuneKit

// MARK: - Concurrency and Integration Tests

@Suite("Concurrency and integration tests", .disabled("Timing-sensitive tests that can hang"))
struct ConcurrencyAndIntegrationTests {
    @Test("Concurrency safety: multiple simultaneous operations")
    func concurrencySafetyMultipleSimultaneousOperations() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Act - perform multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Multiple rerender operations
            for i in 0 ..< 5 {
                group.addTask {
                    let view = MockView(content: "Concurrent content \(i)")
                    await handle.rerender(view)
                }
            }

            // Multiple clear operations
            for _ in 0 ..< 3 {
                group.addTask {
                    await handle.clear()
                }
            }

            // Check status operations
            for _ in 0 ..< 3 {
                group.addTask {
                    _ = await handle.isActive
                }
            }
        }

        // Assert - should not crash and handle should remain active
        let isActive = await handle.isActive
        #expect(isActive, "Handle should remain active after concurrent operations")

        // Cleanup
        output.closeFile()
    }

    @Test("Concurrency safety: unmount during other operations")
    func concurrencySafetyUnmountDuringOtherOperations() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Act - perform operations concurrently with unmount
        await withTaskGroup(of: Void.self) { group in
            // Start some rerender operations
            for i in 0 ..< 3 {
                group.addTask {
                    let view = MockView(content: "Content before unmount \(i)")
                    await handle.rerender(view)
                }
            }

            // Unmount in the middle
            group.addTask {
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
                await handle.unmount()
            }

            // Try more operations after unmount starts
            for i in 0 ..< 2 {
                group.addTask {
                    try? await Task.sleep(nanoseconds: 2_000_000) // 2ms delay
                    let view = MockView(content: "Content after unmount \(i)")
                    await handle.rerender(view)
                }
            }
        }

        // Assert - handle should be unmounted
        let isActive = await handle.isActive
        #expect(!isActive, "Handle should be inactive after unmount")

        // Cleanup
        output.closeFile()
    }

    @Test("Concurrency safety: multiple waitUntilExit calls")
    func concurrencySafetyMultipleWaitUntilExitCalls() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Act - start multiple waitUntilExit calls
        let waitTasks = (0 ..< 5).map { _ in
            Task {
                await handle.waitUntilExit()
                return true
            }
        }

        // Give the wait tasks a moment to start
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // Unmount should cause all waitUntilExit calls to resolve
        await handle.unmount()

        // Wait for all tasks to complete
        let results = await withTaskGroup(of: Bool.self) { group in
            for task in waitTasks {
                group.addTask {
                    await task.value
                }
            }

            var allResolved = true
            for await result in group {
                allResolved = allResolved && result
            }
            return allResolved
        }

        // Assert - all waitUntilExit calls should resolve
        #expect(results, "All waitUntilExit calls should resolve when unmount is called")

        // Cleanup
        output.closeFile()
    }

    @Test("Integration test: Signal handler properly calls unmount")
    func integrationTestSignalHandlerProperlyCallsUnmount() async {
        // This test verifies that signal handlers properly integrate with unmount()
        // and resolve waitUntilExit() calls

        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: true, patchConsole: false)

        // Create signal handler manually for testing
        let signalHandler = SignalHandler()
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: signalHandler, options: options)

        // Set up signal handler with unmount callback
        await signalHandler.install {
            await handle.unmount()
            // Note: In real usage this would call exit(0), but we skip that for testing
        }

        // Start waiting for exit
        let waitTask = Task {
            await handle.waitUntilExit()
            return true
        }

        // Give the task a moment to start waiting
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // Simulate signal reception by calling the teardown callback directly
        await signalHandler.performGracefulTeardown()

        // Verify that waitUntilExit resolved
        let exitResult = await waitTask.value
        #expect(exitResult, "waitUntilExit should resolve when signal handler calls unmount")

        // Verify handle is unmounted
        let isActive = await handle.isActive
        #expect(!isActive, "Handle should be inactive after signal-triggered unmount")

        // Cleanup
        await signalHandler.cleanup()
        output.closeFile()
    }

    @Test("Integration test: Complete render handle lifecycle")
    func integrationTestCompleteRenderHandleLifecycle() async {
        // This test verifies the complete lifecycle of a render handle
        // from creation through various operations to final unmounting

        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Verify initial state
        let initiallyActive = await handle.isActive
        #expect(initiallyActive, "Handle should be active initially")

        // Test rerender operations
        let view1 = MockView(content: "First render")
        await handle.rerender(view1)

        let view2 = MockView(content: "Second render")
        await handle.rerender(view2)

        // Test clear operation
        await handle.clear()

        // Verify still active after operations
        let stillActive = await handle.isActive
        #expect(stillActive, "Handle should remain active after operations")

        // Test waitUntilExit in background
        let exitTask = Task {
            await handle.waitUntilExit()
            return true
        }

        // Give the task a moment to start waiting
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // Test unmount - this should resolve waitUntilExit
        await handle.unmount()

        // Verify unmounted state
        let finallyActive = await handle.isActive
        #expect(!finallyActive, "Handle should be inactive after unmount")

        // Verify waitUntilExit resolved
        let exitResult = await exitTask.value
        #expect(exitResult, "waitUntilExit should resolve when unmount is called")

        // Test that operations after unmount are safe
        await handle.clear() // Should not crash
        await handle.rerender(MockView(content: "After unmount")) // Should not crash
        await handle.unmount() // Should be idempotent

        // Cleanup
        output.closeFile()
    }

    @Test("Integration test: View to Component conversion")
    func integrationTestViewToComponentConversion() {
        // Test that our View protocol properly integrates with Component system

        // Arrange
        let textView = Text("Hello, RuneKit!")
        let boxView = Box(border: .single)

        // Act - Test that Views can be used as Components
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)
        let textLines = textView.render(in: rect)
        let boxLines = boxView.render(in: rect)

        // Assert
        #expect(textLines.count == 3, "Text view should render correct number of lines")
        #expect(textLines[0] == "Hello, RuneKit!", "Text view should render content correctly")
        #expect(boxLines.count == 3, "Box view should render correct number of lines")

        // Test that Views conform to both View and Component protocols
        #expect(textView is Component, "Text should conform to Component protocol")
        #expect(boxView is Component, "Box should conform to Component protocol")
    }

    @Test("Integration test: Terminal size detection")
    func integrationTestTerminalSizeDetection() {
        // Test that terminal size detection works and returns reasonable values

        // Act
        let terminalSize = getTerminalSize()

        // Assert
        #expect(terminalSize.width > 0, "Terminal width should be positive")
        #expect(terminalSize.height > 0, "Terminal height should be positive")
        #expect(terminalSize.width >= 80, "Terminal width should be at least 80 (fallback)")
        #expect(terminalSize.height >= 24, "Terminal height should be at least 24 (fallback)")
    }
}

// MARK: - Mock Views for Testing

struct MockView: View {
    let content: String

    var body: some View {
        Text(content)
    }
}

struct MockStatefulView: View {
    let id: String
    let counter: Int

    var body: some View {
        Text("\(id): \(counter)")
    }
}
