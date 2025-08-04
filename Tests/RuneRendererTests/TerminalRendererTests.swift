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
            width: 10,
            height: 2,
        )

        // Act
        await renderer.render(frame)
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "Hello\nWorld", "Should render frame content correctly")

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
        #expect(result == "\u{001B}[2J\u{001B}[H", "Should output clear screen ANSI sequence")

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
        await renderer.showCursor()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""
        #expect(result == "\u{001B}[?25h", "Should output show cursor ANSI sequence")

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

    @Test("Region repaint with cursor management")
    func regionRepaintWithCursorManagement() async {
        // This test will fail until we implement region repaint
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
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should hide cursor, move to origin, clear region, write content, show cursor
        let expectedSequence = "\u{001B}[?25l\u{001B}[H\u{001B}[2JLine 1\nLine 2\u{001B}[?25h"
        #expect(result == expectedSequence, "Should perform complete region repaint with cursor management")

        // Cleanup
        input.closeFile()
    }

    @Test("Frame height shrinkage cleanup")
    func frameHeightShrinkageCleanup() async {
        // This test will fail until we implement proper frame height tracking
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

        // Then render a shorter frame
        let shortFrame = TerminalRenderer.Frame(
            lines: ["New Line 1", "New Line 2"],
            width: 10,
            height: 2
        )

        // Act
        await frameBuffer.renderFrame(shortFrame)
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should clear the extra lines from the previous frame
        #expect(result.contains("\u{001B}[3;1H\u{001B}[K"), "Should clear line 3 from previous frame")
        #expect(result.contains("\u{001B}[4;1H\u{001B}[K"), "Should clear line 4 from previous frame")

        // Cleanup
        input.closeFile()
    }

    @Test("In-place repaint without flicker")
    func inPlaceRepaintWithoutFlicker() async {
        // This test will fail until we implement proper in-place rendering
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
        await frameBuffer.renderFrame(frame2)
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should not contain full screen clear for second frame
        let clearCount = result.components(separatedBy: "\u{001B}[2J").count - 1
        #expect(clearCount == 1, "Should only clear screen once for initial frame")

        // Should contain both frame contents
        #expect(result.contains("Frame 1 Content"), "Should contain first frame content")
        #expect(result.contains("Frame 2 Content"), "Should contain second frame content")

        // Cleanup
        input.closeFile()
    }
}
