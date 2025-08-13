import Foundation
import Testing
@testable import RuneKit

// Simple probe actor to count rerenders safely across concurrency boundaries
actor RerenderProbe {
    private(set) var count: Int = 0
    func increment() { count += 1 }
}

struct ResizeHandlingTests {
    @Test("Debounced resize burst triggers a single rerender")
    func debouncedSingleRerender() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        let probe = RerenderProbe()
        await handle.rerender {
            Task { await probe.increment() }
            return Text("Initial")
        }

        // Install a resize observer with a short debounce for test
        let observer = ResizeObserver(debounceInterval: .milliseconds(20))
        await observer.install { [weak handle] in
            guard let handle else { return }
            await handle.testingAlignIdentityForCurrentBuilder()
            await handle.testingRerenderUsingRoot()
        }

        // Act: Fire multiple resize notifications rapidly
        for _ in 0..<10 { await observer.notifyResizeEvent() }

        // Allow debounce to elapse
        try? await Task.sleep(for: .milliseconds(80))

        // Assert: exactly one additional rerender
        let count = await probe.count
        #expect(count == 2, "Expected exactly one rerender after burst; got \(count)")

        // Cleanup
        await observer.cleanup()
        await handle.stop()
        output.closeFile()
    }

    @Test("Two distinct bursts cause two rerenders")
    func twoBurstsTwoRerenders() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        let probe = RerenderProbe()
        await handle.rerender {
            Task { await probe.increment() }
            return Text("Initial")
        }

        let observer = ResizeObserver(debounceInterval: .milliseconds(20))
        await observer.install { [weak handle] in
            guard let handle else { return }
            await handle.testingAlignIdentityForCurrentBuilder()
            await handle.testingRerenderUsingRoot()
        }

        // Act: First burst
        for _ in 0..<5 { await observer.notifyResizeEvent() }
        try? await Task.sleep(for: .milliseconds(60))
        // Second burst
        for _ in 0..<5 { await observer.notifyResizeEvent() }
        try? await Task.sleep(for: .milliseconds(80))

        // Assert: two additional rerenders beyond initial
        let count = await probe.count
        #expect(count == 3, "Expected two rerenders across two bursts; got \(count)")

        // Cleanup
        await observer.cleanup()
        await handle.stop()
        output.closeFile()
    }

    @Test("Resize during render does not crash and yields a single repaint per burst")
    func resizeDuringRenderIsSafe() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        let probe = RerenderProbe()
        // Initial render
        await handle.rerender {
            Task { await probe.increment() }
            // Simulate heavier render work by building a larger view tree
            return Box(children:
                Text(String(repeating: "A", count: 100)),
                Text(String(repeating: "B", count: 100)),
                Text(String(repeating: "C", count: 100))
            )
        }

        let observer = ResizeObserver(debounceInterval: .milliseconds(25))
        await observer.install { [weak handle] in
            guard let handle else { return }
            await handle.testingAlignIdentityForCurrentBuilder()
            await handle.testingRerenderUsingRoot()
        }

        // Act: Trigger resize notifications while scheduling another rerender
        for _ in 0..<8 { await observer.notifyResizeEvent() }
        try? await Task.sleep(for: .milliseconds(70))

        // Assert: one additional rerender
        let count = await probe.count
        #expect(count == 2, "Expected exactly one extra rerender after resize burst; got \(count)")

        // Cleanup
        await observer.cleanup()
        await handle.stop()
        output.closeFile()
    }
}

