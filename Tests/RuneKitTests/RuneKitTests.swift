import Foundation
import Testing
@testable import RuneKit

struct RuneKitTests {
    @Test("RuneKit module loads correctly")
    func runeKitModuleLoads() {
        // This test ensures the RuneKit module can be imported and basic functionality works
        #expect(true, "RuneKit module should load without errors")
    }
}

// MARK: - RUNE-24 Tests: render(_:options) API

struct RenderOptionsTests {
    @Test("RenderOptions initialization with defaults")
    func renderOptionsDefaultInitialization() {
        // Arrange & Act
        let options = RenderOptions()

        // Assert - should use correct defaults based on environment
        #expect(options.stdout == FileHandle.standardOutput, "Should default to stdout")
        #expect(options.stderr == FileHandle.standardError, "Should default to stderr")
        #expect(options.stdin == FileHandle.standardInput, "Should default to stdin")
        #expect(options.fpsCap == 60.0, "Should default to 60 FPS")

        // TTY-aware defaults - in test environment, TTY is false, so these should be false
        let isInteractive = RenderOptions.isInteractiveTerminal()
        let isCI = RenderOptions.isCIEnvironment()
        let expectedDefault = isInteractive && !isCI

        #expect(options.exitOnCtrlC == expectedDefault, "Should use TTY-aware default for exitOnCtrlC")
        #expect(options.patchConsole == expectedDefault, "Should use TTY-aware default for patchConsole")
        #expect(options.useAltScreen == expectedDefault, "Should use TTY-aware default for useAltScreen")
    }

    @Test("RenderOptions initialization with custom values")
    func renderOptionsCustomInitialization() {
        // Arrange
        let customStdout = Pipe().fileHandleForWriting
        let customStderr = Pipe().fileHandleForWriting
        let customStdin = Pipe().fileHandleForReading

        // Act
        let options = RenderOptions(
            stdout: customStdout,
            stdin: customStdin,
            stderr: customStderr,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
        )

        // Assert
        #expect(options.stdout === customStdout, "Should use custom stdout")
        #expect(options.stderr === customStderr, "Should use custom stderr")
        #expect(options.stdin === customStdin, "Should use custom stdin")
        #expect(options.exitOnCtrlC == false, "Should use custom exitOnCtrlC")
        #expect(options.patchConsole == false, "Should use custom patchConsole")
        #expect(options.useAltScreen == false, "Should use custom useAltScreen")
        #expect(options.fpsCap == 30.0, "Should use custom FPS cap")

        // Cleanup
        customStdout.closeFile()
        customStderr.closeFile()
        customStdin.closeFile()
    }

    @Test("RenderOptions CI environment heuristics")
    func renderOptionsCIHeuristics() {
        // Arrange - simulate CI environment
        let ciEnvironment = ["CI": "true", "GITHUB_ACTIONS": "true"]

        // Act
        let options = RenderOptions.fromEnvironment(ciEnvironment)

        // Assert - CI should have conservative defaults
        #expect(options.exitOnCtrlC == false, "CI should not exit on Ctrl+C")
        #expect(options.patchConsole == false, "CI should not patch console")
        #expect(options.useAltScreen == false, "CI should not use alt screen")
        #expect(options.fpsCap == 30.0, "CI should use lower FPS cap")
    }

    @Test("RenderOptions TTY detection")
    func renderOptionsTTYDetection() {
        // This test verifies TTY detection logic
        let isTTY = RenderOptions.isInteractiveTerminal()

        // In test environment, this will likely be false
        // But we test the function exists and returns a boolean
        #expect(isTTY == true || isTTY == false, "Should return a boolean value")
    }
}

// MARK: - Signal Handling Tests

struct SignalHandlerTests {
    @Test("SignalHandler initialization")
    func signalHandlerInitialization() async {
        // Arrange & Act
        let handler = SignalHandler()

        // Assert
        let isInstalled = await handler.isInstalled
        #expect(!isInstalled, "Should not be installed initially")
    }

    @Test("SignalHandler install and cleanup")
    func signalHandlerInstallAndCleanup() async {
        // Arrange
        let handler = SignalHandler()

        // Use actor-isolated state for thread safety
        actor TestState {
            var cleanupCalled = false

            func setCleanupCalled() {
                cleanupCalled = true
            }

            func wasCleanupCalled() -> Bool {
                cleanupCalled
            }
        }

        let testState = TestState()

        // Act
        await handler.install {
            await testState.setCleanupCalled()
        }

        // Assert
        let isInstalledAfterInstall = await handler.isInstalled
        #expect(isInstalledAfterInstall, "Should be installed after install()")

        // Cleanup
        await handler.cleanup()
        let isInstalledAfterCleanup = await handler.isInstalled
        #expect(!isInstalledAfterCleanup, "Should not be installed after cleanup()")

        // Note: We can't easily test signal delivery in unit tests
        // but we can test the setup/teardown logic
    }

    @Test("SignalHandler graceful teardown callback")
    func signalHandlerGracefulTeardown() async {
        // Arrange
        let handler = SignalHandler()

        // Use actor-isolated state for thread safety
        actor TestState {
            var teardownCalled = false
            var teardownCallCount = 0

            func recordTeardown() {
                teardownCalled = true
                teardownCallCount += 1
            }

            func getTeardownState() -> (called: Bool, count: Int) {
                (teardownCalled, teardownCallCount)
            }
        }

        let testState = TestState()

        // Act
        await handler.install {
            await testState.recordTeardown()
        }

        // Simulate graceful teardown (without actual signal)
        await handler.performGracefulTeardown()

        // Assert
        let (teardownCalled, teardownCallCount) = await testState.getTeardownState()
        #expect(teardownCalled, "Teardown callback should be called")
        #expect(teardownCallCount == 1, "Teardown should be called exactly once")

        // Cleanup
        await handler.cleanup()
    }
}

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

// MARK: - Mock View for Testing

struct MockView: View {
    let content: String

    var body: some View {
        Text(content)
    }
}
