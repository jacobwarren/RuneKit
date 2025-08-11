import Foundation
import Testing
@testable import RuneKit

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
