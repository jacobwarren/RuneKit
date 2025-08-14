import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

/// Integration tests for frame buffer cleanup and error handling
///
/// Note: These tests are disabled in CI environments because they use
/// pipes extensively which can interfere with the CI test runner.
@Suite("Frame buffer integration tests", TestEnv.skipIntegrationInCI)
struct FrameBufferIntegrationTests {
    // MARK: - Error Handling Tests

    @Test("Cursor restoration on error", .enabled(if: !TestEnv.isCI))
    func cursorRestorationOnError() async {
        // This test will fail until we implement proper error handling
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let frameBuffer = FrameBuffer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Test content"],
            width: 12,
            height: 1,
        )

        // Act - Start rendering then simulate an error
        do {
            await frameBuffer.renderFrame(frame)
            await frameBuffer.waitForPendingUpdates()
            // Simulate an error during rendering
            throw TestError.simulatedError
        } catch {
            // Error should trigger cleanup
        }

        // Cleanup
        await frameBuffer.shutdown()

        // Assert
        let result = await cap.finishAndReadString()

        // Should show cursor even after error
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor visibility on error")
    }

    @Test("Cleanup on frame buffer deinitialization", .enabled(if: !TestEnv.isCI))
    func cleanupOnDeinitialization() async {
        // This test will fail until we implement proper cleanup
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()

        do {
            let frameBuffer = FrameBuffer(output: output)

            let frame = TerminalRenderer.Frame(
                lines: ["Test content"],
                width: 12,
                height: 1,
            )

            // Act
            await frameBuffer.renderFrame(frame)
            await frameBuffer.waitForPendingUpdates()

            // Explicit cleanup (since deinit can't do async operations)
            await frameBuffer.restoreCursor()
        }

        // Assert
        let result = await cap.finishAndReadString()

        // Should restore cursor on cleanup
        #expect(result.hasSuffix("\u{001B}[?25h"), "Should restore cursor on explicit cleanup")
    }

    @Test("Multiple frame renders maintain state", .enabled(if: !TestEnv.isCI))
    func multipleFrameRendersMaintainState() async {
        // Test that multiple frame renders work correctly with line erasure
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let frameBuffer = FrameBuffer(output: output)

        let frames = [
            TerminalRenderer.Frame(lines: ["Frame 1"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 2"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 3"], width: 7, height: 1),
        ]

        // Act
        for (index, frame) in frames.enumerated() {
            await frameBuffer.renderFrame(frame)
            await frameBuffer.waitForPendingUpdates() // Wait for each frame to complete

            // Add delay between frames to avoid rate limiting
            if index < frames.count - 1 {
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms (50 FPS)
            }
        }

        await frameBuffer.shutdown()

        // Assert
        let result = await cap.finishAndReadString()

        // Should contain all frame content and proper ANSI sequences
        #expect(result.contains("Frame 1"), "Should contain first frame")
        #expect(result.contains("Frame 2"), "Should contain second frame")
        #expect(result.contains("Frame 3"), "Should contain third frame")
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor during rendering")
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor on clear")
    }

    @Test("Frame buffer handles empty frames", .enabled(if: !TestEnv.isCI))
    func frameBufferHandlesEmptyFrames() async {
        // This test will fail until we implement empty frame handling
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let frameBuffer = FrameBuffer(output: output)

        let emptyFrame = TerminalRenderer.Frame(
            lines: [],
            width: 0,
            height: 0,
        )

        // Act
        await frameBuffer.renderFrameImmediate(emptyFrame)

        // Cleanup first to ensure pipe is properly closed
        await frameBuffer.shutdown()

        // Assert
        let result = await cap.finishAndReadString()

        // Should handle empty frame gracefully
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor for empty frame")
        #expect(result.contains("\u{001B}[?25h"), "Should show cursor after empty frame")
    }

    @Test("Frame buffer handles cursor management", .enabled(if: !TestEnv.isCI))
    func frameBufferHandlesCursorManagement() async {
        // Test that cursor is properly hidden and restored
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let frameBuffer = FrameBuffer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Test"],
            width: 4,
            height: 1,
        )

        // Act
        await frameBuffer.renderFrame(frame)
        await frameBuffer.waitForPendingUpdates()
        await frameBuffer.shutdown()

        // Assert
        let result = await cap.finishAndReadString()

        // Should hide cursor during rendering and restore on clear
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor during rendering")
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor on clear")
    }

    @Test("Frame buffer cleanup on abrupt termination", .enabled(if: !TestEnv.isCI))
    func frameBufferCleanupOnAbruptTermination() async {
        // This test simulates what happens when a process is terminated abruptly
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Create a frame buffer in a scope that will end abruptly
        let frameBuffer = FrameBuffer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Test content for termination"],
            width: 25,
            height: 1,
        )

        // Act - Render frame then shut down properly
        await frameBuffer.renderFrame(frame)
        await frameBuffer.waitForPendingUpdates() // Wait for rendering to complete

        // Explicitly restore cursor before termination (since deinit cannot do async operations)
        await frameBuffer.restoreCursor()

        // Properly shutdown to ensure OutputWriter is closed
        await frameBuffer.shutdown()

        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should restore cursor on abrupt termination (via explicit call)
        #expect(result.hasSuffix("\u{001B}[?25h"), "Should restore cursor on abrupt termination")

        // Cleanup
        input.closeFile()
    }

    @Test(
        "Frame buffer handles multiple errors gracefully",
        .enabled(if: !TestEnv.isCI),
    )
    func frameBufferHandlesMultipleErrorsGracefully() async {
        // This test ensures that multiple error conditions don't cause issues
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Error test"],
            width: 10,
            height: 1,
        )

        // Act - Multiple operations that could fail
        do {
            await frameBuffer.renderFrame(frame)
            await frameBuffer.renderFrame(frame) // Render again
            throw TestError.simulatedError
        } catch {
            // First error
        }

        do {
            await frameBuffer.renderFrame(frame) // Try to render after error
            throw TestError.anotherError
        } catch {
            // Second error
        }

        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should handle multiple errors without corruption
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor after multiple errors")

        // Cleanup
        input.closeFile()
    }

    @Test("Frame buffer handles frame height shrinkage", .enabled(if: !TestEnv.isCI))
    func frameBufferHandlesFrameHeightShrinkage() async {
        // Test the core functionality from RUNE-20: correct erase when frame height shrinks
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)

        let tallFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 6,
            height: 4,
        )

        let shortFrame = TerminalRenderer.Frame(
            lines: ["Short"],
            width: 5,
            height: 1,
        )

        // Act - Render tall frame then short frame
        await frameBuffer.renderFrame(tallFrame)
        await frameBuffer.waitForPendingUpdates() // Wait for first frame to complete

        // Add delay to avoid rate limiting
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        await frameBuffer.renderFrameImmediate(shortFrame) // Use immediate rendering for second frame
        await frameBuffer.shutdown()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain erase sequences for the tall frame
        #expect(result.contains("\u{001B}[2K"), "Should contain line clear sequences")
        #expect(result.contains("\u{001B}[G"), "Should contain cursor to column 1 sequence")
        // Delta rendering uses absolute positioning, not cursor up sequences
        let hasAbsolutePositioning = result.contains("\u{001B}[1;1H") || result.contains("\u{001B}[2;1H") || result
            .contains("\u{001B}[3;1H")
        #expect(hasAbsolutePositioning, "Should contain absolute cursor positioning sequences")

        // Should contain both frame contents
        #expect(result.contains("Line 1"), "Should contain tall frame content")
        #expect(result.contains("Short"), "Should contain short frame content")

        // Cleanup
        input.closeFile()
    }
}

/// Test error for simulating failures
enum TestError: Error {
    case simulatedError
    case anotherError
}
