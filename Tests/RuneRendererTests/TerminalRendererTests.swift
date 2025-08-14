import Foundation
import Testing
import TestSupport
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
        let cap = PipeCapture()
        let output = cap.start()

        // Act
        _ = TerminalRenderer(output: output)

        // Assert - Just verify it can be created without crashing
        // Note: renderer is non-optional, so this test just verifies no crash during init
        #expect(Bool(true), "Renderer should initialize with custom output")

        // Cleanup
        _ = await cap.finishAndReadString()
    }

    // MARK: - Basic Rendering Tests

    @Test("Render simple frame")
    func renderSimpleFrame() async {
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        let frame = TerminalRenderer.Frame(
            lines: ["Hello", "World"],
            width: 5, // Use exact width to avoid padding
            height: 2,
        )

        // Act
        await renderer.render(frame)

        // Assert
        let result = await cap.finishAndReadString()

        // Should contain the frame content and ANSI sequences
        #expect(result.contains("Hello"), "Should contain first line content")
        #expect(result.contains("World"), "Should contain second line content")
        #expect(result.contains("\u{001B}[?25l"), "Should hide cursor during rendering")
        #expect(result.contains("\u{001B}[?25h"), "Should show cursor after rendering")

    }

    @Test("Clear screen")
    func clearScreen() async {
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.clear()

        // Assert
        let result = await cap.finishAndReadString()
        #expect(
            result == "\u{001B}[2J\u{001B}[H\u{001B}[?25h",
            "Should output clear screen ANSI sequence and show cursor",
        )
    }

    @Test("Move cursor")
    func testMoveCursor() async {
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.moveCursor(to: 5, column: 10)

        // Assert
        let result = await cap.finishAndReadString()
        #expect(result == "\u{001B}[5;10H", "Should output cursor move ANSI sequence")
    }

    @Test("Hide cursor")
    func testHideCursor() async {
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.hideCursor()

        // Assert
        let result = await cap.finishAndReadString()
        #expect(result == "\u{001B}[?25l", "Should output hide cursor ANSI sequence")
    }

    @Test("Show cursor")
    func testShowCursor() async {
        // Arrange
        let cap = PipeCapture()
        let output = cap.start()
        let renderer = TerminalRenderer(output: output)

        // Act
        await renderer.hideCursor() // First hide cursor
        await renderer.showCursor() // Then show it

        // Assert
        let result = await cap.finishAndReadString()
        #expect(result == "\u{001B}[?25l\u{001B}[?25h", "Should output hide then show cursor ANSI sequences")
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
}
