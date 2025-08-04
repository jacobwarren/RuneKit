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

        // Then render a shorter frame
        let shortFrame = TerminalRenderer.Frame(
            lines: ["New Line 1", "New Line 2"],
            width: 10,
            height: 2
        )

        // Act
        await frameBuffer.renderFrame(shortFrame)
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should use Ink.js-style line erasure for frame height shrinkage
        #expect(result.contains("\u{001B}[2K"), "Should contain line clear sequences")
        #expect(result.contains("\u{001B}[A"), "Should contain cursor up sequences")
        #expect(result.contains("\u{001B}[G"), "Should contain cursor to column 1 sequence")

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
        await frameBuffer.renderFrame(frame2)
        await frameBuffer.clear()
        output.closeFile()

        // Assert
        let data = input.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8) ?? ""

        // Should use line erasure (Ink.js style), not full screen clear
        #expect(result.contains("\u{001B}[2K"), "Should use line clear sequences")
        #expect(!result.contains("\u{001B}[2J"), "Should not use full screen clear for frame updates")

        // Should contain both frame contents
        #expect(result.contains("Frame 1 Content"), "Should contain first frame content")
        #expect(result.contains("Frame 2 Content"), "Should contain second frame content")

        // Cleanup
        input.closeFile()
    }
}
