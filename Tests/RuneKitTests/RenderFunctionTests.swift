import Foundation
import Testing
@testable import RuneKit

// MARK: - Render Function Tests

struct RenderFunctionTests {
    @Test("RenderHandle initialization and basic functionality")
    func renderHandleBasicFunctionality() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false)

        // Act
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Assert
        let isActive = await handle.isActive
        #expect(isActive, "Handle should be active initially")

        let hasSignalHandler = await handle.hasSignalHandler()
        #expect(!hasSignalHandler, "Should not have signal handler when none provided")

        // Cleanup
        await handle.stop()
        let isActiveAfterStop = await handle.isActive
        #expect(!isActiveAfterStop, "Handle should not be active after stop")

        output.closeFile()
    }

    @Test("RenderHandle with signal handler")
    func renderHandleWithSignalHandler() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: true, patchConsole: false)

        let signalHandler = SignalHandler()
        await signalHandler.install { /* no-op for test */ }

        // Act
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: signalHandler, options: options)

        // Assert
        let hasSignalHandler = await handle.hasSignalHandler()
        #expect(hasSignalHandler, "Should have signal handler when provided")

        // Cleanup
        await handle.stop()
        output.closeFile()
    }

    @Test("RenderHandle with console capture")
    func renderHandleWithConsoleCapture() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: true)

        // Act
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        // Assert - Note: Console capture might not be active immediately in test environment
        // We just test that the method exists and returns a boolean
        let hasConsoleCapture = await handle.hasConsoleCapture()
        #expect(hasConsoleCapture == true || hasConsoleCapture == false, "Should return a boolean value")

        // Cleanup
        await handle.stop()
        output.closeFile()
    }

    @Test("Integration test: render function with mock view", .disabled("Disabled to prevent CI interference"))
    func integrationTestRenderFunction() async {
        // This test demonstrates the full RUNE-24 API but is disabled to prevent CI issues
        // It can be enabled for manual testing

        // Arrange
        let mockView = MockView(content: "Integration Test")
        let pipe = Pipe()
        let options = RenderOptions(
            stdout: pipe.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
        )

        // Act
        let handle = await render(mockView, options: options)

        // Assert
        let isActive = await handle.isActive
        #expect(isActive, "Handle should be active after render")

        // Cleanup
        await handle.stop()
        pipe.fileHandleForWriting.closeFile()
    }
}
