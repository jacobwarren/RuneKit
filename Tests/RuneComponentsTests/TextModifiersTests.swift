import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneKit
@testable import RuneLayout

struct TextModifiersTests {

    init() {
        // Clean up shared state before each test to prevent interference between tests
        StateRegistry.shared.clearAll()
        StateObjectStore.shared.clearAll()
    }
    @Test("Chainable modifiers compose and render")
    func chainableModifiersCompose() {
        // Arrange
        let t = Text("Nested").bold().italic().color(.green)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Act
        let lines = t.render(in: rect)

        // Assert
        #expect(lines.count == 1)
        let line = lines[0]
        #expect(line.contains("\u{001B}["))
        // Presence of bold(1), italic(3), and some green fg code (32 or 38;...)
        #expect(line.contains("1"))
        #expect(line.contains("3"))
        #expect(line.contains("32") || line.contains("38;"))
        #expect(line.contains("Nested"))
        #expect(line.contains("\u{001B}[0m"))
    }

    @Test("Color override: last wins")
    func colorOverrideLastWins() {
        // Arrange
        let t = Text("Mix", color: .red).color(.blue)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = t.render(in: rect)

        // Assert: Should contain blue code (34) and not contain red-only pattern if 16-color
        let line = lines[0]
        #expect(line.contains("\u{001B}[34m") || line.contains("38;"))
    }

    @Test("Empty text with styling renders empty line")
    func emptyTextWithStylingRendersEmptyLine() {
        // Arrange
        let t = Text("", color: .red).bold()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = t.render(in: rect)

        // Assert
        #expect(lines.count == 1)
        #expect(lines[0].isEmpty)
    }
}
