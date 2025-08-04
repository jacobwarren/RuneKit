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
}
