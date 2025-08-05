import Testing
import Foundation
@testable import RuneRenderer

/// Tests for alternate screen buffer functionality (RUNE-22)
///
/// These tests verify the alternate screen buffer implementation including
/// enter/leave operations, fallback behavior, and integration with FrameBuffer.
struct AlternateScreenBufferTests {
    // MARK: - Alternate Screen Buffer Tests (RUNE-22)

    @Test("AlternateScreenBuffer initialization")
    func alternateScreenBufferInitialization() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting

        // Act
        let altScreen = AlternateScreenBuffer(output: output)

        // Assert
        let isActive = await altScreen.isActive
        #expect(isActive == false, "New alternate screen buffer should not be active")

        // Cleanup
        output.closeFile()
    }

    @Test("AlternateScreenBuffer enter sequence")
    func alternateScreenBufferEnterSequence() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let altScreen = AlternateScreenBuffer(output: output)

        // Act
        await altScreen.enter()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[?1049h", "Should output alternate screen enter sequence")

        let isActive = await altScreen.isActive
        #expect(isActive == true, "Should be active after entering")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer leave sequence")
    func alternateScreenBufferLeaveSequence() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let altScreen = AlternateScreenBuffer(output: output)

        // Enter first, then leave
        await altScreen.enter()

        // Act
        await altScreen.leave()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result.contains("\u{001B}[?1049h"), "Should contain enter sequence")
        #expect(result.contains("\u{001B}[?1049l"), "Should contain leave sequence")

        let isActive = await altScreen.isActive
        #expect(isActive == false, "Should not be active after leaving")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer double enter is safe")
    func alternateScreenBufferDoubleEnterIsSafe() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let altScreen = AlternateScreenBuffer(output: output)

        // Act - Enter twice
        await altScreen.enter()
        await altScreen.enter()
        output.closeFile()

        // Assert - Should only have one enter sequence
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        let enterCount = result.components(separatedBy: "\u{001B}[?1049h").count - 1
        #expect(enterCount == 1, "Should only enter alternate screen once")

        let isActive = await altScreen.isActive
        #expect(isActive == true, "Should still be active")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer double leave is safe")
    func alternateScreenBufferDoubleLeaveIsSafe() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let altScreen = AlternateScreenBuffer(output: output)

        // Enter first, then leave twice
        await altScreen.enter()
        await altScreen.leave()

        // Act - Leave again
        await altScreen.leave()
        output.closeFile()

        // Assert - Should only have one leave sequence
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        let leaveCount = result.components(separatedBy: "\u{001B}[?1049l").count - 1
        #expect(leaveCount == 1, "Should only leave alternate screen once")

        let isActive = await altScreen.isActive
        #expect(isActive == false, "Should not be active")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer explicit cleanup")
    func alternateScreenBufferExplicitCleanup() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Act - Create, enter, and explicitly leave alternate screen
        let altScreen = AlternateScreenBuffer(output: output)
        await altScreen.enter()
        await altScreen.leave()
        output.closeFile()

        // Assert - Should contain both enter and leave sequences
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result.contains("\u{001B}[?1049h"), "Should contain enter sequence")
        #expect(result.contains("\u{001B}[?1049l"), "Should contain leave sequence")

        // Cleanup
        input.closeFile()
    }

    @Test("Region repaint with cursor management")
    func regionRepaintWithCursorManagement() async {
        // Test that cursor is properly managed during frame rendering
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2"],
            width: 10,
            height: 2
        )

        // Act
        await frameBuffer.renderFrame(frame1)
        await frameBuffer.waitForPendingUpdates()  // Wait for coalesced updates to complete
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should hide cursor during rendering and restore on clear
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor during rendering")
        #expect(result.contains("\u{001B}[?25h"), "Should restore cursor on clear")
        #expect(result.contains("Line 1"), "Should contain frame content")
        #expect(result.contains("Line 2"), "Should contain frame content")

        // Cleanup
        input.closeFile()
    }

    @Test("Frame height shrinkage cleanup")
    func frameHeightShrinkageCleanup() async {
        // Test that extra lines are properly erased when frame height shrinks (RUNE-20)
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)

        // First render a tall frame
        let tallFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3", "Line 4"],
            width: 10,
            height: 4
        )
        await frameBuffer.renderFrame(tallFrame)
        await frameBuffer.waitForPendingUpdates()  // Wait for first frame to complete

        // Then render a shorter frame
        let shortFrame = TerminalRenderer.Frame(
            lines: ["New Line 1", "New Line 2"],
            width: 10,
            height: 2
        )

        // Act
        // Add delay to avoid rate limiting
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        await frameBuffer.renderFrameImmediate(shortFrame)  // Use immediate rendering to bypass coalescing
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should use line-diff style rendering for frame height shrinkage
        #expect(result.contains("\u{001B}[2K"), "Should contain line clear sequences")
        #expect(result.contains("\u{001B}[G"), "Should contain cursor to column 1 sequence")
        // Delta rendering uses absolute positioning, not cursor up sequences
        let hasAbsolutePositioning = result.contains("\u{001B}[1;1H") || result.contains("\u{001B}[2;1H") || result.contains("\u{001B}[3;1H")
        #expect(hasAbsolutePositioning, "Should contain absolute cursor positioning sequences")

        // Should contain both frame contents
        #expect(result.contains("Line 1"), "Should contain tall frame content")
        #expect(result.contains("New Line 1"), "Should contain short frame content")

        // Cleanup
        input.closeFile()
    }

    @Test("In-place repaint without flicker")
    func inPlaceRepaintWithoutFlicker() async {
        // Test that frames are rendered in-place using line erasure (Ink.js style)
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let frameBuffer = FrameBuffer(output: output)

        let frame1 = TerminalRenderer.Frame(
            lines: ["Frame 1 Content"],
            width: 15,
            height: 1
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["Frame 2 Content"],
            width: 15,
            height: 1
        )

        // Act - Render two frames in sequence
        await frameBuffer.renderFrame(frame1)
        await frameBuffer.waitForPendingUpdates()  // Wait for first frame to complete

        // Add delay to avoid rate limiting
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        await frameBuffer.renderFrameImmediate(frame2)  // Use immediate rendering for second frame
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should use line erasure for frame updates (first frame may use full screen clear)
        #expect(result.contains("\u{001B}[2K"), "Should use line clear sequences")
        // Second frame should use delta update with absolute positioning
        let hasAbsolutePositioning = result.contains("\u{001B}[1;1H") || result.contains("\u{001B}[2;1H")
        #expect(hasAbsolutePositioning, "Should contain absolute cursor positioning for delta updates")

        // Should contain both frame contents
        #expect(result.contains("Frame 1 Content"), "Should contain first frame content")
        #expect(result.contains("Frame 2 Content"), "Should contain second frame content")

        // Cleanup
        input.closeFile()
    }

    @Test("FrameBuffer with alternate screen buffer enabled")
    func frameBufferWithAlternateScreenBufferEnabled() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: true)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame = TerminalRenderer.Frame(
            lines: ["Hello Alt Screen"],
            width: 16,
            height: 1
        )

        // Act
        await frameBuffer.renderFrame(frame)
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should enter alternate screen at start and leave at end
        #expect(result.contains("\u{001B}[?1049h"), "Should enter alternate screen")
        #expect(result.contains("\u{001B}[?1049l"), "Should leave alternate screen")
        #expect(result.contains("Hello Alt Screen"), "Should contain frame content")

        // Cleanup
        input.closeFile()
    }

    @Test("FrameBuffer with alternate screen buffer disabled")
    func frameBufferWithAlternateScreenBufferDisabled() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame = TerminalRenderer.Frame(
            lines: ["Hello Main Screen"],
            width: 17,
            height: 1
        )

        // Act
        await frameBuffer.renderFrame(frame)
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should NOT use alternate screen sequences
        #expect(!result.contains("\u{001B}[?1049h"), "Should not enter alternate screen")
        #expect(!result.contains("\u{001B}[?1049l"), "Should not leave alternate screen")
        #expect(result.contains("Hello Main Screen"), "Should contain frame content")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer fallback behavior")
    func alternateScreenBufferFallbackBehavior() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Create alternate screen buffer with fallback disabled
        let altScreen = AlternateScreenBuffer(output: output, enableFallback: false)

        // Act
        await altScreen.enterWithFallback()
        await altScreen.leaveWithFallback()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // With fallback disabled, should still try alternate screen sequences
        #expect(result.contains("\u{001B}[?1049h"), "Should attempt alternate screen enter")
        #expect(result.contains("\u{001B}[?1049l"), "Should attempt alternate screen leave")

        // Cleanup
        input.closeFile()
    }

    @Test("AlternateScreenBuffer with fallback enabled")
    func alternateScreenBufferWithFallbackEnabled() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Create alternate screen buffer with fallback enabled
        let altScreen = AlternateScreenBuffer(output: output, enableFallback: true)

        // Act
        await altScreen.enterWithFallback()
        await altScreen.leaveWithFallback()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain either alternate screen sequences or fallback clear
        let hasAltScreen = result.contains("\u{001B}[?1049h") && result.contains("\u{001B}[?1049l")
        let hasFallback = result.contains("\u{001B}[2J\u{001B}[H")
        #expect(hasAltScreen || hasFallback, "Should use either alternate screen or fallback")

        // Cleanup
        input.closeFile()
    }

    @Test("Debug: FrameBuffer default behavior without alternate screen")
    func debugFrameBufferDefaultBehavior() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        // Use default configuration (should not use alternate screen)
        let config = RenderConfiguration.default
        let frameBuffer = FrameBuffer(output: output, configuration: config)

        let frame1 = TerminalRenderer.Frame(lines: ["Frame 1"], width: 7, height: 1)
        let frame2 = TerminalRenderer.Frame(lines: ["Frame 2"], width: 7, height: 1)

        // Act
        let initialState = await frameBuffer.isAlternateScreenActive()
        await frameBuffer.renderFrame(frame1)
        let stateAfterFrame1 = await frameBuffer.isAlternateScreenActive()
        await frameBuffer.renderFrame(frame2)
        let stateAfterFrame2 = await frameBuffer.isAlternateScreenActive()
        await frameBuffer.clear()
        let stateAfterClear = await frameBuffer.isAlternateScreenActive()

        output.closeFile()

        // Assert
        #expect(initialState == false, "Should not be active initially with default config")
        #expect(stateAfterFrame1 == false, "Should not be active after first frame with default config")
        #expect(stateAfterFrame2 == false, "Should not be active after second frame with default config")
        #expect(stateAfterClear == false, "Should not be active after clear with default config")

        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should NOT contain alternate screen sequences
        #expect(!result.contains("\u{001B}[?1049h"), "Should not contain alternate screen enter")
        #expect(!result.contains("\u{001B}[?1049l"), "Should not contain alternate screen leave")

        // Cleanup
        input.closeFile()
    }
}
