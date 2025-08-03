import Testing
@testable import RuneComponents
@testable import RuneLayout

/// Tests for component functionality following TDD principles
struct ComponentTests {
    // MARK: - Text Component Tests

    @Test("Text component with simple content")
    func textComponentSimple() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "First line should contain the text")
        #expect(lines[1] == "", "Remaining lines should be empty")
        #expect(lines[2] == "", "Remaining lines should be empty")
    }

    @Test("Text component with content longer than width")
    func textComponentTruncation() {
        // Arrange
        let text = Text("Hello World This Is Long")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "Should truncate content to fit width")
    }

    @Test("Text component with zero dimensions")
    func textComponentZeroDimensions() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 0)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero dimensions")
    }

    @Test("Text component with zero width")
    func textComponentZeroWidth() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 3)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero width")
    }

    @Test("Text component with zero height")
    func textComponentZeroHeight() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 0)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero height")
    }

    // MARK: - Box Component Tests

    @Test("Empty box component")
    func emptyBoxComponent() {
        // Arrange
        let box = Box()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines.allSatisfy { $0.isEmpty }, "All lines should be empty")
    }

    @Test("Box with text child")
    func boxWithTextChild() {
        // Arrange
        let text = Text("Hello")
        let box = Box(child: text)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 2)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0] == "Hello", "Should render child content")
        #expect(lines[1] == "", "Remaining lines should be empty")
    }

    @Test("Box with border style none")
    func boxBorderStyleNone() {
        // Arrange
        let box = Box(border: .none)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines.allSatisfy { $0.isEmpty }, "All lines should be empty for no border")
    }

    @Test("Box with zero dimensions")
    func boxZeroDimensions() {
        // Arrange
        let box = Box()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 0)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero dimensions")
    }
}
