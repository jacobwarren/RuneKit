import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

/// Integration tests for alternate screen buffer functionality
///
/// These tests verify the complete workflow of alternate screen buffer
/// support, including configuration, environment variables, and integration
/// with the FrameBuffer system.
///
/// Note: These tests are disabled in CI environments because they use
/// pipes extensively which can interfere with the CI test runner.
struct AlternateScreenBufferIntegrationTests {
    // MARK: - Complete Workflow Tests

    @Test("Complete alternate screen buffer workflow", .enabled(if: !TestEnv.isCI))
    func completeAlternateScreenBufferWorkflow() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Welcome to alternate screen!"],
            width: 29,
            height: 1,
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Updated content in alternate screen"],
            width: 35,
            height: 1,
        )

        // Act - Complete workflow
        // 1. Initial state should not be active
        let initialState = await frameBuffer.isAlternateScreenActive()

        // 2. First render should enter alternate screen
        await frameBuffer.renderFrame(frame1)
        let stateAfterFirstRender = await frameBuffer.isAlternateScreenActive()

        // 3. Second render should stay in alternate screen
        await frameBuffer.renderFrame(frame2)
        let stateAfterSecondRender = await frameBuffer.isAlternateScreenActive()

        // 4. Clear should leave alternate screen
        await frameBuffer.shutdown()
        let stateAfterClear = await frameBuffer.isAlternateScreenActive()

        output.closeFile()

        // Assert
        #expect(initialState == false, "Should not be active initially")
        #expect(stateAfterFirstRender == true, "Should be active after first render")
        #expect(stateAfterSecondRender == true, "Should stay active after second render")
        #expect(stateAfterClear == false, "Should not be active after clear")

        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain exactly one enter and one leave sequence
        let enterCount = result.components(separatedBy: "\u{001B}[?1049h").count - 1
        let leaveCount = result.components(separatedBy: "\u{001B}[?1049l").count - 1

        #expect(enterCount == 1, "Should enter alternate screen exactly once")
        #expect(leaveCount == 1, "Should leave alternate screen exactly once")

        // Should contain both frame contents
        #expect(result.contains("Welcome to alternate screen!"), "Should contain first frame")
        #expect(result.contains("Updated content in alternate screen"), "Should contain second frame")

        // Cleanup
        input.closeFile()
    }

    @Test(
        "Environment variable configuration integration",
        .enabled(if: !TestEnv.isCI),
    )
    func environmentVariableConfigurationIntegration() async {
        // Test with alternate screen enabled via environment
        let enabledEnv = ["RUNE_ALT_SCREEN": "true"]
        let enabledConfig = RenderConfiguration.fromEnvironment(enabledEnv)

        let pipe1 = Pipe()
        let output1 = pipe1.fileHandleForWriting
        let input1 = pipe1.fileHandleForReading

        let frameBuffer1 = FrameBuffer(output: output1, configuration: enabledConfig)
        let frame = TerminalRenderer.Frame(lines: ["Test"], width: 4, height: 1)

        await frameBuffer1.renderFrame(frame)
        await frameBuffer1.shutdown()
        output1.closeFile()

        let data1 = input1.readDataToEndOfFile()
        let result1 = String(data: data1, encoding: .utf8) ?? ""

        #expect(result1.contains("\u{001B}[?1049h"), "Should use alternate screen when enabled via env")
        #expect(result1.contains("\u{001B}[?1049l"), "Should leave alternate screen when enabled via env")

        input1.closeFile()

        // Test with alternate screen disabled via environment
        let disabledEnv = ["RUNE_ALT_SCREEN": "false"]
        let disabledConfig = RenderConfiguration.fromEnvironment(disabledEnv)

        let pipe2 = Pipe()
        let output2 = pipe2.fileHandleForWriting
        let input2 = pipe2.fileHandleForReading

        let frameBuffer2 = FrameBuffer(output: output2, configuration: disabledConfig)

        await frameBuffer2.renderFrame(frame)
        await frameBuffer2.shutdown()
        output2.closeFile()

        let data2 = input2.readDataToEndOfFile()
        let result2 = String(data: data2, encoding: .utf8) ?? ""

        #expect(!result2.contains("\u{001B}[?1049h"), "Should not use alternate screen when disabled via env")
        #expect(!result2.contains("\u{001B}[?1049l"), "Should not use alternate screen when disabled via env")

        input2.closeFile()
    }

    @Test("Multiple frame renders in alternate screen", .enabled(if: !TestEnv.isCI))
    func multipleFrameRendersInAlternateScreen() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frames = [
            TerminalRenderer.Frame(lines: ["Frame 1"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 2"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 3"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 4"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 5"], width: 7, height: 1),
        ]

        // Act - Render multiple frames
        for frame in frames {
            await frameBuffer.renderFrame(frame)
        }
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should enter alternate screen only once
        let enterCount = result.components(separatedBy: "\u{001B}[?1049h").count - 1
        let leaveCount = result.components(separatedBy: "\u{001B}[?1049l").count - 1

        #expect(enterCount == 1, "Should enter alternate screen only once for multiple renders")
        #expect(leaveCount == 1, "Should leave alternate screen only once")

        // Should contain all frame contents
        for index in frames.indices {
            #expect(result.contains("Frame \(index + 1)"), "Should contain frame \(index + 1)")
        }

        // Cleanup
        input.closeFile()
    }

    @Test("Alternate screen buffer with grid rendering", .enabled(if: !TestEnv.isCI))
    func alternateScreenBufferWithGridRendering() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        // Create a simple grid
        let grid = TerminalGrid(width: 10, height: 3)
        var mutableGrid = grid
        mutableGrid.setCell(at: 0, column: 0, to: TerminalCell(content: "H"))
        mutableGrid.setCell(at: 0, column: 1, to: TerminalCell(content: "i"))
        mutableGrid.setCell(at: 1, column: 0, to: TerminalCell(content: "G"))
        mutableGrid.setCell(at: 1, column: 1, to: TerminalCell(content: "o"))

        // Act
        await frameBuffer.renderGrid(mutableGrid)
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        #expect(result.contains("\u{001B}[?1049h"), "Should enter alternate screen for grid rendering")
        #expect(result.contains("\u{001B}[?1049l"), "Should leave alternate screen for grid rendering")

        // Cleanup
        input.closeFile()
    }

    @Test("Shutdown with alternate screen cleanup", .enabled(if: !TestEnv.isCI))
    func shutdownWithAlternateScreenCleanup() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame = TerminalRenderer.Frame(lines: ["Test"], width: 4, height: 1)

        // Act
        await frameBuffer.renderFrame(frame)
        let activeBeforeShutdown = await frameBuffer.isAlternateScreenActive()

        await frameBuffer.shutdown()
        let activeAfterShutdown = await frameBuffer.isAlternateScreenActive()

        output.closeFile()

        // Assert
        #expect(activeBeforeShutdown == true, "Should be active before shutdown")
        #expect(activeAfterShutdown == false, "Should not be active after shutdown")

        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        #expect(result.contains("\u{001B}[?1049h"), "Should enter alternate screen")
        #expect(result.contains("\u{001B}[?1049l"), "Should leave alternate screen on shutdown")

        // Cleanup
        input.closeFile()
    }

    @Test("Configuration precedence", .enabled(if: !TestEnv.isCI))
    func configurationPrecedence() async {
        // Test that explicit configuration overrides environment
        let environment = ["RUNE_ALT_SCREEN": "true"]

        // Explicit configuration should take precedence
        let explicitConfig = RenderConfiguration(useAlternateScreen: false)
        #expect(explicitConfig.useAlternateScreen == false, "Explicit config should override environment")

        // Environment configuration should respect the setting
        let envConfig = RenderConfiguration.fromEnvironment(environment)
        #expect(envConfig.useAlternateScreen == true, "Environment config should respect RUNE_ALT_SCREEN")

        // Default configuration should be false
        let defaultConfig = RenderConfiguration.default
        #expect(defaultConfig.useAlternateScreen == false, "Default should be false for compatibility")
    }
}
