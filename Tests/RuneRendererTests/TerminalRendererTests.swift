import Foundation
import Testing
@testable import RuneRenderer

/// Tests for terminal renderer functionality following TDD principles
struct TerminalRendererTests {
    // MARK: - Frame Tests

    @Test("Frame initialization")
    func frameInitialization() {
        // Arrange
        let lines = ["Hello", "World"]
        let width = 10
        let height = 5

        // Act
        let frame = TerminalRenderer.Frame(lines: lines, width: width, height: height)

        // Assert
        #expect(frame.lines == lines, "Frame should store lines correctly")
        #expect(frame.width == width, "Frame should store width correctly")
        #expect(frame.height == height, "Frame should store height correctly")
    }

    @Test("Empty frame")
    func emptyFrame() {
        // Arrange
        let lines: [String] = []
        let width = 0
        let height = 0

        // Act
        let frame = TerminalRenderer.Frame(lines: lines, width: width, height: height)

        // Assert
        #expect(frame.lines.isEmpty, "Empty frame should have no lines")
        #expect(frame.width == 0, "Empty frame should have zero width")
        #expect(frame.height == 0, "Empty frame should have zero height")
    }

    // MARK: - Renderer Initialization Tests

    @Test("Renderer initialization with default output")
    func rendererInitializationDefault() async {
        // Act
        _ = TerminalRenderer()

        // Assert - Just verify it can be created without crashing
        // Note: renderer is non-optional, so this test just verifies no crash during init
        #expect(Bool(true), "Renderer should initialize successfully")
    }

    @Test("Renderer initialization with custom output")
    func rendererInitializationCustom() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting

        // Act
        _ = TerminalRenderer(output: output)

        // Assert - Just verify it can be created without crashing
        // Note: renderer is non-optional, so this test just verifies no crash during init
        #expect(Bool(true), "Renderer should initialize with custom output")

        // Cleanup
        output.closeFile()
    }

    // MARK: - Basic Rendering Tests

    @Test("Render simple frame")
    func renderSimpleFrame() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let renderer = TerminalRenderer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Hello", "World"],
            width: 5,  // Use exact width to avoid padding
            height: 2,
            )

        // Act
        await renderer.render(frame)
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain the frame content and ANSI sequences
        #expect(result.contains("Hello"), "Should contain first line content")
        #expect(result.contains("World"), "Should contain second line content")
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor during rendering")
        #expect(result.contains("\u{001B}[?25h"), "Should show cursor after rendering")

        // Cleanup
        input.closeFile()
    }

    @Test("Clear screen")
    func clearScreen() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[2J\u{001B}[H\u{001B}[?25h", "Should output clear screen ANSI sequence and show cursor")

        // Cleanup
        input.closeFile()
    }

    @Test("Move cursor")
    func testMoveCursor() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.moveCursor(to: 5, column: 10)
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[5;10H", "Should output cursor move ANSI sequence")

        // Cleanup
        input.closeFile()
    }

    @Test("Hide cursor")
    func testHideCursor() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.hideCursor()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[?25l", "Should output hide cursor ANSI sequence")

        // Cleanup
        input.closeFile()
    }

    @Test("Show cursor")
    func testShowCursor() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.hideCursor()  // First hide cursor
        await renderer.showCursor()  // Then show it
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[?25l\u{001B}[?25h", "Should output hide then show cursor ANSI sequences")

        // Cleanup
        input.closeFile()
    }

    // MARK: - Frame Buffer Tests (RUNE-20)

    @Test("Frame buffer initialization")
    func frameBufferInitialization() async {
        // This test will fail until we implement FrameBuffer
        // Arrange & Act
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let frameBuffer = FrameBuffer(output: output)

        // Assert
        let currentFrame = await frameBuffer.getCurrentFrame()
        #expect(currentFrame == nil, "New frame buffer should have no current frame")

        // Cleanup
        output.closeFile()
    }

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
        #expect(!result.contains("\u{001B}[?1049h"), "Should not contain alternate screen enter sequence")
        #expect(!result.contains("\u{001B}[?1049l"), "Should not contain alternate screen leave sequence")

        // Should contain both frame contents
        #expect(result.contains("Frame 1"), "Should contain first frame content")
        #expect(result.contains("Frame 2"), "Should contain second frame content")

        // Debug output
        print("Debug: Raw output length: \(result.count)")
        print("Debug: Contains Frame 1: \(result.contains("Frame 1"))")
        print("Debug: Contains Frame 2: \(result.contains("Frame 2"))")
        print("Debug: Raw output (first 200 chars): \(String(result.prefix(200)))")

        // Show ANSI sequences
        let escapedOutput = result.replacingOccurrences(of: "\u{001B}", with: "\\e")
        print("Debug: Escaped output: \(String(escapedOutput.prefix(200)))")

        // Check for cursor positioning sequences
        let hasCursorPositioning = result.contains("\u{001B}[")
        print("Debug: Contains cursor positioning: \(hasCursorPositioning)")

        // Cleanup
        input.closeFile()
    }

    @Test("Frame buffer renders frames in sequence correctly")
    func frameBufferRendersFramesInSequenceCorrectly() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output)

        // Create frames with different heights to test shrinkage
        let tallFrame = TerminalRenderer.Frame(
            lines: ["Line 1", "Line 2", "Line 3"],
            width: 6,
            height: 3
        )

        let shortFrame = TerminalRenderer.Frame(
            lines: ["Short"],
            width: 5,
            height: 1
        )

        // Act
        await frameBuffer.renderFrame(tallFrame)
        await frameBuffer.renderFrame(shortFrame)
        await frameBuffer.clear()

        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain both frame contents
        #expect(result.contains("Line 1"), "Should contain tall frame content")
        #expect(result.contains("Line 2"), "Should contain tall frame content")
        #expect(result.contains("Line 3"), "Should contain tall frame content")
        #expect(result.contains("Short"), "Should contain short frame content")

        // Should contain proper ANSI sequences for frame transitions
        #expect(result.contains("\u{001B}[2J\u{001B}[H"), "Should contain screen clear sequence")
        #expect(result.contains("\u{001B}[1;1H"), "Should contain cursor positioning")
        #expect(result.contains("\u{001B}[2K"), "Should contain line clear sequence")

        // The key test: should contain sequences that clear lines beyond the short frame
        // When shrinking from 3 lines to 1 line, lines 2 and 3 should be cleared
        let hasLineClearingForShrinkage = result.contains("\u{001B}[2;1H") && result.contains("\u{001B}[3;1H")
        #expect(hasLineClearingForShrinkage, "Should clear lines when frame shrinks")

        print("Debug: Frame sequence test - Raw output length: \(result.count)")
        let escapedOutput = result.replacingOccurrences(of: "\u{001B}", with: "\\e")
        print("Debug: Frame sequence test - Escaped output: \(String(escapedOutput.prefix(300)))")

        // Cleanup
        input.closeFile()
    }

    @Test("Live frame buffer demo simulation")
    func liveFrameBufferDemoSimulation() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output)

        // Create simple loading frames like in the demo
        let loadingContents = ["Loading...", "Loading.", "Loading..", "Loading..."]
        let loadingFrames = loadingContents.map { content in
            TerminalRenderer.Frame(
                lines: [
                    "┌────────────┐",
                    "│ \(content) │",
                    "└────────────┘"
                ],
                width: 14,
                height: 3
            )
        }

        // Act - simulate the loading animation
        for frame in loadingFrames {
            await frameBuffer.renderFrame(frame)
        }

        // Final completion frame
        let completeFrame = TerminalRenderer.Frame(
            lines: [
                "┌──────────────┐",
                "│ Complete! ✅ │",
                "└──────────────┘"
            ],
            width: 16,
            height: 3
        )
        await frameBuffer.renderFrame(completeFrame)

        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should contain all frame contents
        #expect(result.contains("Loading..."), "Should contain Loading...")
        #expect(result.contains("Loading."), "Should contain Loading.")
        #expect(result.contains("Loading.."), "Should contain Loading..")
        #expect(result.contains("Complete! ✅"), "Should contain Complete!")

        // Should contain proper cursor positioning sequences
        #expect(result.contains("\u{001B}["), "Should contain ANSI escape sequences")

        // Debug output to understand the sequence
        let escapedOutput = result.replacingOccurrences(of: "\u{001B}", with: "\\e")
        print("Debug: Live demo simulation output: \(String(escapedOutput.prefix(500)))")

        // Cleanup
        input.closeFile()
    }

    @Test("Coalescing fix verification")
    func coalescingFixVerification() async {
        // Arrange
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let frameBuffer = FrameBuffer(output: output)

        // Create frames like in the live demo
        let frame1 = TerminalRenderer.Frame(
            lines: ["┌────────────┐", "│ Loading... │", "└────────────┘"],
            width: 14, height: 3
        )

        let frame2 = TerminalRenderer.Frame(
            lines: ["┌──────────┐", "│ Loading. │", "└──────────┘"],
            width: 12, height: 3
        )

        let finalFrame = TerminalRenderer.Frame(
            lines: ["┌──────────────┐", "│ Complete! ✅ │", "└──────────────┘"],
            width: 16, height: 3
        )

        // Act - render frames rapidly to test coalescing
        await frameBuffer.renderFrame(frame1)
        await frameBuffer.renderFrame(frame2)
        await frameBuffer.renderFrame(finalFrame)

        // Wait for any coalesced updates to complete
        await frameBuffer.waitForPendingUpdates()

        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // The final frame should definitely be present
        #expect(result.contains("Complete! ✅"), "Final frame should be rendered")

        // Should contain proper ANSI sequences
        #expect(result.contains("\u{001B}["), "Should contain ANSI escape sequences")

        print("Coalescing test output contains Complete frame: \(result.contains("Complete! ✅"))")

        // Cleanup
        input.closeFile()
    }
}
