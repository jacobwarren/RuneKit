import Foundation
import Testing
import TestSupport
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneLayout

/// RUNE-35: Ensure Text props parity with Ink for style combinations and graceful failures
struct TextStyleParityTests {
    @Test("Text supports combined styles including inverse and colors")
    func textSupportsCombinedStyles() {
        // Arrange
        let text = Text(
            "Hello",
            color: .yellow,
            backgroundColor: .blue,
            bold: true,
            italic: true,
            underline: true,
            strikethrough: true,
            inverse: true,
            dim: true,
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should render one line")
        let line = lines[0]
        #expect(line.contains("\u{001B}["), "Should contain SGR codes")
        // Expect codes for multiple styles; order may vary
        for code in ["1", "2", "3", "4", "7", "9"] { // bold, dim, italic, underline, inverse, strike
            #expect(line.contains(code), "Should contain SGR code \(code)")
        }
        #expect(line.contains("33") || line.contains("38;"), "Should contain some fg color code")
        #expect(line.contains("44") || line.contains("48;"), "Should contain some bg color code")
        #expect(line.contains("Hello"), "Should contain text")
        #expect(line.contains("\u{001B}[0m"), "Should end with reset")
    }

    @Test("Text ignores invalid color components when using RGB/256")
    func textIgnoresInvalidColorComponents() {
        // Arrange: invalid colors via attributes init path
        let attrs = TextAttributes(color: .rgb(300, -1, 256), backgroundColor: .color256(300))
        let text = Text("Bad", attributes: attrs)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert: Should not include 38;2 or 48;5 sequences
        #expect(lines.count == 1, "Should render one line")
        let line = lines[0]
        #expect(!line.contains("\u{001B}[38;2"), "Invalid fg RGB should be omitted")
        #expect(!line.contains("\u{001B}[48;5"), "Invalid bg 256 should be omitted")
        #expect(line.contains("Bad"), "Text should be present")
    }
}
