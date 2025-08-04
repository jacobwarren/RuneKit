import Foundation
import Testing
@testable import RuneRenderer

/// Integration tests for frame buffer cleanup and error handling
struct FrameBufferIntegrationTests {
    
    // MARK: - Error Handling Tests
    
    @Test("Cursor restoration on error")
    func cursorRestorationOnError() async {
        // This test will fail until we implement proper error handling
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)
        
        let frame = TerminalRenderer.Frame(
            lines: ["Test content"],
            width: 12,
            height: 1
        )
        
        // Act - Start rendering then simulate an error
        do {
            await frameBuffer.renderFrame(frame)
            // Simulate an error during rendering
            throw TestError.simulatedError
        } catch {
            // Error should trigger cleanup
        }
        
        output.closeFile()
        
        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        
        // Should show cursor even after error
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor visibility on error")
        
        // Cleanup
        input.closeFile()
    }
    
    @Test("Cleanup on frame buffer deinitialization")
    func cleanupOnDeinitialization() async {
        // This test will fail until we implement proper cleanup
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        
        do {
            let frameBuffer = FrameBuffer(output: output)
            
            let frame = TerminalRenderer.Frame(
                lines: ["Test content"],
                width: 12,
                height: 1
            )
            
            // Act
            await frameBuffer.renderFrame(frame)
            // frameBuffer goes out of scope here and should clean up
        }
        
        output.closeFile()
        
        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        
        // Should restore cursor on cleanup
        #expect(result.hasSuffix("\u{001B}[?25h"), "Should restore cursor on deinitialization")
        
        // Cleanup
        input.closeFile()
    }
    
    @Test("Multiple frame renders maintain state")
    func multipleFrameRendersMaintainState() async {
        // This test will fail until we implement proper state tracking
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)
        
        let frames = [
            TerminalRenderer.Frame(lines: ["Frame 1"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 2"], width: 7, height: 1),
            TerminalRenderer.Frame(lines: ["Frame 3"], width: 7, height: 1)
        ]
        
        // Act
        for frame in frames {
            await frameBuffer.renderFrame(frame)
        }
        
        output.closeFile()
        
        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        
        // Should track previous frame dimensions correctly
        let currentFrame = await frameBuffer.getCurrentFrame()
        #expect(currentFrame?.lines == ["Frame 3"], "Should track current frame correctly")
        #expect(currentFrame?.height == 1, "Should track current frame height")
        
        // Cleanup
        input.closeFile()
    }
    
    @Test("Frame buffer handles empty frames")
    func frameBufferHandlesEmptyFrames() async {
        // This test will fail until we implement empty frame handling
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)
        
        let emptyFrame = TerminalRenderer.Frame(
            lines: [],
            width: 0,
            height: 0
        )
        
        // Act
        await frameBuffer.renderFrame(emptyFrame)
        output.closeFile()
        
        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        
        // Should handle empty frame gracefully
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor for empty frame")
        #expect(result.contains("\u{001B}[?25h"), "Should show cursor after empty frame")
        
        // Cleanup
        input.closeFile()
    }
    
    @Test("Frame buffer preserves cursor position")
    func frameBufferPreservesCursorPosition() async {
        // This test will fail until we implement cursor position preservation
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)
        
        // Simulate cursor at position (5, 10) before rendering
        await frameBuffer.setCursorPosition(row: 5, column: 10)
        
        let frame = TerminalRenderer.Frame(
            lines: ["Test"],
            width: 4,
            height: 1
        )
        
        // Act
        await frameBuffer.renderFrame(frame)
        await frameBuffer.restoreCursor()
        output.closeFile()
        
        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        
        // Should restore original cursor position
        #expect(result.contains("\u{001B}[5;10H"), "Should restore cursor to original position")
        
        // Cleanup
        input.closeFile()
    }

    @Test("Frame buffer cleanup on abrupt termination")
    func frameBufferCleanupOnAbruptTermination() async {
        // This test simulates what happens when a process is terminated abruptly
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Create a frame buffer in a scope that will end abruptly
        do {
            let frameBuffer = FrameBuffer(output: output)

            let frame = TerminalRenderer.Frame(
                lines: ["Test content for termination"],
                width: 25,
                height: 1
            )

            // Act - Render frame then let frameBuffer go out of scope suddenly
            await frameBuffer.renderFrame(frame)

            // Simulate abrupt termination by ending the scope here
            // The deinit should restore the cursor
        }

        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should restore cursor on abrupt termination (via deinit)
        #expect(result.hasSuffix("\u{001B}[?25h"), "Should restore cursor on abrupt termination")

        // Cleanup
        input.closeFile()
    }

    @Test("Frame buffer handles multiple errors gracefully")
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
            height: 1
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

        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should handle multiple errors without corruption
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor after multiple errors")

        // Cleanup
        input.closeFile()
    }
}

/// Test error for simulating failures
enum TestError: Error {
    case simulatedError
    case anotherError
}
