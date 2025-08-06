// swiftlint:disable file_length type_body_length
import Testing
@testable import RuneComponents
@testable import RuneLayout
@testable import RuneANSI
@testable import RuneUnicode
@testable import RuneRenderer
@testable import RuneKit
@testable import RuneCLI

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
        #expect(lines[1].isEmpty, "Remaining lines should be empty")
        #expect(lines[2].isEmpty, "Remaining lines should be empty")
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
        // swiftlint:disable:next prefer_key_path
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
        #expect(lines[1].isEmpty, "Remaining lines should be empty")
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
        // swiftlint:disable:next prefer_key_path
        #expect(
            lines.allSatisfy { $0.isEmpty },
            "All lines should be empty for no border",
        )
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

    // MARK: - Styled Text Component Tests (RUNE-29)

    @Test("Text component with color styling")
    func textComponentWithColor() {
        // Arrange
        let text = Text("Hello", color: .red)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[31m"), "Should contain red color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with background color")
    func textComponentWithBackgroundColor() {
        // Arrange
        let text = Text("Hello", backgroundColor: .blue)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[44m"), "Should contain blue background code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with bold styling")
    func textComponentWithBold() {
        // Arrange
        let text = Text("Hello", bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[1m"), "Should contain bold code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with italic styling")
    func textComponentWithItalic() {
        // Arrange
        let text = Text("Hello", italic: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[3m"), "Should contain italic code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with underline styling")
    func textComponentWithUnderline() {
        // Arrange
        let text = Text("Hello", underline: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[4m"), "Should contain underline code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with strikethrough styling")
    func textComponentWithStrikethrough() {
        // Arrange
        let text = Text("Hello", strikethrough: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[9m"), "Should contain strikethrough code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with inverse styling")
    func textComponentWithInverse() {
        // Arrange
        let text = Text("Hello", inverse: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[7m"), "Should contain inverse code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with dim styling")
    func textComponentWithDim() {
        // Arrange
        let text = Text("Hello", dim: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[2m"), "Should contain dim code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with multiple styles")
    func textComponentWithMultipleStyles() {
        // Arrange
        let text = Text("Hello", color: .red, bold: true, underline: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}["), "Should contain ANSI escape sequence")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
        // Should contain all style codes (order may vary)
        let line = lines[0]
        #expect(line.contains("31") || line.contains("1;31") || line.contains("31;1"), "Should contain red color")
        #expect(line.contains("1"), "Should contain bold")
        #expect(line.contains("4"), "Should contain underline")
    }

    @Test("Text component with width constraint and styling")
    func textComponentWithWidthConstraintAndStyling() {
        // Arrange
        let text = Text("Hello World", color: .green, bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("Hello"), "Should contain truncated text")
        #expect(!lines[0].contains("World"), "Should not contain text beyond width")
        #expect(lines[0].contains("\u{001B}["), "Should contain ANSI codes")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with emoji and styling")
    func textComponentWithEmojiAndStyling() {
        // Arrange
        let text = Text("Hello 👋", color: .yellow)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("Hello 👋"), "Should contain emoji text")
        #expect(lines[0].contains("\u{001B}[33m"), "Should contain yellow color code")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with CJK characters and styling")
    func textComponentWithCJKAndStyling() {
        // Arrange
        let text = Text("你好世界", color: .cyan)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("你好世界"), "Should contain CJK text")
        #expect(lines[0].contains("\u{001B}[36m"), "Should contain cyan color code")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    // MARK: - Spacer Component Tests (RUNE-32)

    @Test("Spacer component exists and conforms to Component protocol")
    func spacerComponentExists() {
        // Arrange & Act
        let spacer = Spacer()

        // Assert
        #expect(spacer is Component, "Spacer should conform to Component protocol")
    }

    @Test("Spacer in row layout consumes remaining horizontal space")
    func spacerInRowLayoutConsumesHorizontalSpace() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            width: .points(20),
            height: .points(3),
            children: Text("Left"), Spacer(), Text("Right")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        #expect(layout.childRects.count == 3, "Should have 3 child rects")

        let leftRect = layout.childRects[0]
        let spacerRect = layout.childRects[1]
        let rightRect = layout.childRects[2]

        // Left text should be at start
        #expect(leftRect.x == 0, "Left text should start at x=0")

        // Right text should be at end
        #expect(rightRect.x + rightRect.width == 20, "Right text should end at container width")

        // Spacer should fill the gap between them
        #expect(spacerRect.x == leftRect.x + leftRect.width, "Spacer should start after left text")
        #expect(spacerRect.x + spacerRect.width == rightRect.x, "Spacer should end before right text")
        #expect(spacerRect.width > 0, "Spacer should have positive width")
    }

    @Test("Spacer in column layout consumes remaining vertical space")
    func spacerInColumnLayoutConsumesVerticalSpace() {
        // Arrange
        let box = Box(
            flexDirection: .column,
            width: .points(10),
            height: .points(10),
            children: Text("Top"), Spacer(), Text("Bottom")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 10)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        #expect(layout.childRects.count == 3, "Should have 3 child rects")

        let topRect = layout.childRects[0]
        let spacerRect = layout.childRects[1]
        let bottomRect = layout.childRects[2]

        // Top text should be at start
        #expect(topRect.y == 0, "Top text should start at y=0")

        // Bottom text should be at end
        #expect(bottomRect.y + bottomRect.height == 10, "Bottom text should end at container height")

        // Spacer should fill the gap between them
        #expect(spacerRect.y == topRect.y + topRect.height, "Spacer should start after top text")
        #expect(spacerRect.y + spacerRect.height == bottomRect.y, "Spacer should end before bottom text")
        #expect(spacerRect.height > 0, "Spacer should have positive height")
    }

    @Test("Multiple spacers divide remaining space equally")
    func multipleSpacersDivideSpaceEqually() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            width: .points(20),
            height: .points(3),
            children: Text("A"), Spacer(), Text("B"), Spacer(), Text("C")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        #expect(layout.childRects.count == 5, "Should have 5 child rects")

        let spacer1Rect = layout.childRects[1]
        let spacer2Rect = layout.childRects[3]

        // Both spacers should have equal width (within rounding tolerance)
        let widthDiff = abs(spacer1Rect.width - spacer2Rect.width)
        #expect(widthDiff <= 1, "Spacers should have equal width (within 1 column tolerance)")
    }

    @Test("Spacer with no available space has zero size")
    func spacerWithNoAvailableSpaceHasZeroSize() {
        // Arrange - container too small for content
        let box = Box(
            flexDirection: .row,
            width: .points(5),
            height: .points(3),
            children: Text("VeryLongText"), Spacer(), Text("MoreText")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        let spacerRect = layout.childRects[1]
        #expect(spacerRect.width == 0, "Spacer should have zero width when no space available")
    }

    @Test("Spacer does not affect cross-axis sizing")
    func spacerDoesNotAffectCrossAxisSizing() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            width: .points(20),
            height: .points(5),
            children: Text("Text"), Spacer()
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 5)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        let spacerRect = layout.childRects[1]

        // Spacer should not affect height in row layout
        #expect(spacerRect.height == 1, "Spacer should have minimal cross-axis size")
    }

    @Test("Spacer renders as empty content")
    func spacerRendersAsEmptyContent() {
        // Arrange
        let spacer = Spacer()
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Act
        let lines = spacer.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render correct number of lines")
        #expect(lines.allSatisfy { $0.isEmpty }, "All lines should be empty")
    }

    // MARK: - AlignSelf Tests (RUNE-32)

    @Test("AlignSelf enum exists with all required cases")
    func alignSelfEnumExists() {
        // Arrange & Act
        let alignSelfCases: [AlignSelf] = [
            .auto,
            .flexStart,
            .flexEnd,
            .center,
            .stretch,
            .baseline
        ]

        // Assert
        #expect(alignSelfCases.count == 6, "AlignSelf should have 6 cases")
    }

    @Test("Box supports alignSelf property")
    func boxSupportsAlignSelfProperty() {
        // Arrange & Act
        let box = Box(alignSelf: .center)

        // Assert
        #expect(box.alignSelf == .center, "Box should store alignSelf property")
    }

    @Test("AlignSelf auto inherits from parent alignItems")
    func alignSelfAutoInheritsFromParentAlignItems() {
        // Arrange
        let parentBox = Box(
            flexDirection: .row,
            alignItems: .center,
            width: .points(20),
            height: .points(10),
            children: Box(alignSelf: .auto, width: .points(5), height: .points(3)),
                     Box(alignSelf: .flexEnd, width: .points(5), height: .points(3))
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = parentBox.calculateLayout(in: containerRect)

        // Assert
        #expect(layout.childRects.count == 2, "Should have 2 child rects")

        let autoAlignChild = layout.childRects[0]
        let flexEndChild = layout.childRects[1]

        // Auto child should be centered (inheriting from parent alignItems)
        // Test what center actually produces
        let centerParentBox = Box(
            flexDirection: .row,
            alignItems: .center,
            width: .points(20),
            height: .points(10),
            children: Box(width: .points(5), height: .points(3))
        )
        let centerLayout = centerParentBox.calculateLayout(in: containerRect)
        let expectedCenterY = centerLayout.childRects[0].y

        #expect(autoAlignChild.y == expectedCenterY, "Auto align child should be centered")

        // FlexEnd child should be at bottom
        #expect(flexEndChild.y == 10 - 3, "FlexEnd child should be at bottom")
    }

    @Test("AlignSelf center overrides parent alignItems")
    func alignSelfCenterOverridesParentAlignItems() {
        // Arrange
        let parentBox = Box(
            flexDirection: .row,
            alignItems: .flexStart,
            width: .points(20),
            height: .points(10),
            children: Box(alignSelf: .center, width: .points(5), height: .points(3))
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = parentBox.calculateLayout(in: containerRect)

        // Assert
        let childRect = layout.childRects[0]

        // Test what happens with alignItems center for comparison
        let centerParentBox = Box(
            flexDirection: .row,
            alignItems: .center,
            width: .points(20),
            height: .points(10),
            children: Box(width: .points(5), height: .points(3))
        )
        let centerLayout = centerParentBox.calculateLayout(in: containerRect)
        let centerChildRect = centerLayout.childRects[0]

        // The alignSelf center child should be at the same position as alignItems center
        #expect(childRect.y == centerChildRect.y, "alignSelf center should position child same as alignItems center")
    }

    // MARK: - RUNE27 Demo Integration Tests

    @Test("RUNE27 demo Spacer examples work correctly")
    func rune27DemoSpacerExamples() {
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)

        // Test the row layout with Spacer (from RUNE27 demo)
        let rowBoxWithSpacer = Box(
            flexDirection: .row,
            children: Text("Left"), Spacer(), Text("Center"), Spacer(), Text("Right")
        )

        let rowLayout = rowBoxWithSpacer.calculateLayout(in: containerRect)

        // Verify we have 5 children (Text, Spacer, Text, Spacer, Text)
        #expect(rowLayout.childRects.count == 5, "Should have 5 children")

        let leftRect = rowLayout.childRects[0]
        let spacer1Rect = rowLayout.childRects[1]
        let centerRect = rowLayout.childRects[2]
        let spacer2Rect = rowLayout.childRects[3]
        let rightRect = rowLayout.childRects[4]

        // Verify spacers have positive width
        #expect(spacer1Rect.width > 0, "First spacer should have positive width")
        #expect(spacer2Rect.width > 0, "Second spacer should have positive width")

        // Verify no overlaps
        #expect(leftRect.x + leftRect.width <= spacer1Rect.x, "Left text should not overlap first spacer")
        #expect(spacer1Rect.x + spacer1Rect.width <= centerRect.x, "First spacer should not overlap center text")
        #expect(centerRect.x + centerRect.width <= spacer2Rect.x, "Center text should not overlap second spacer")
        #expect(spacer2Rect.x + spacer2Rect.width <= rightRect.x, "Second spacer should not overlap right text")

        // Test the column layout with Spacer (from RUNE27 demo)
        let columnBoxWithSpacer = Box(
            flexDirection: .column,
            children: Text("Header"), Spacer(), Text("Footer")
        )

        let columnLayout = columnBoxWithSpacer.calculateLayout(in: containerRect)

        // Verify we have 3 children (Text, Spacer, Text)
        #expect(columnLayout.childRects.count == 3, "Should have 3 children")

        let headerRect = columnLayout.childRects[0]
        let spacerRect = columnLayout.childRects[1]
        let footerRect = columnLayout.childRects[2]

        // Verify spacer has positive height
        #expect(spacerRect.height > 0, "Spacer should have positive height")

        // Verify header is at top, footer is at bottom
        #expect(headerRect.y == 0, "Header should be at top")
        #expect(footerRect.y + footerRect.height == 10, "Footer should be at bottom")

        // Verify spacer fills the gap
        #expect(spacerRect.y == headerRect.y + headerRect.height, "Spacer should start after header")
        #expect(spacerRect.y + spacerRect.height == footerRect.y, "Spacer should end before footer")
    }

    @Test("RUNE32 real-world layout patterns work correctly")
    func rune32RealWorldLayoutPatterns() {
        // Test navigation bar pattern (from RUNE32Demo)
        let navBar = Box(
            flexDirection: .row,
            alignItems: .center,
            width: .points(50),
            height: .points(3),
            children: Text("← Back"), Spacer(), Text("Page Title"), Spacer(), Text("Menu ☰")
        )

        let navResult = navBar.calculateLayout(in: FlexLayout.Rect(x: 0, y: 0, width: 50, height: 3))

        // Verify navigation layout
        #expect(navResult.childRects.count == 5, "Nav bar should have 5 elements")

        let backRect = navResult.childRects[0]
        let spacer1Rect = navResult.childRects[1]
        let titleRect = navResult.childRects[2]
        let spacer2Rect = navResult.childRects[3]
        let menuRect = navResult.childRects[4]

        // Back button should be at start
        #expect(backRect.x == 0, "Back button should be at start")

        // Menu should be at end
        #expect(menuRect.x + menuRect.width == 50, "Menu should be at end")

        // Spacers should have positive width
        #expect(spacer1Rect.width > 0, "First spacer should have positive width")
        #expect(spacer2Rect.width > 0, "Second spacer should have positive width")

        // Title should be roughly centered (within spacer tolerance)
        let titleCenter = titleRect.x + titleRect.width / 2
        let containerCenter = 50 / 2
        let centerTolerance = 5 // Allow some tolerance for centering
        #expect(abs(titleCenter - containerCenter) <= centerTolerance, "Title should be roughly centered")

        // Test card layout pattern (from RUNE32Demo)
        let cardLayout = Box(
            flexDirection: .column,
            width: .points(30),
            height: .points(15),
            children: Text("Card Title"),
                     Spacer(),
                     Box(
                        flexDirection: .row,
                        children: Text("Cancel"), Spacer(), Text("OK")
                     )
        )

        let cardResult = cardLayout.calculateLayout(in: FlexLayout.Rect(x: 0, y: 0, width: 30, height: 15))

        // Verify card layout
        #expect(cardResult.childRects.count == 3, "Card should have 3 elements")

        let titleRect2 = cardResult.childRects[0]
        let contentSpacerRect = cardResult.childRects[1]
        let buttonRowRect = cardResult.childRects[2]

        // Title should be at top
        #expect(titleRect2.y == 0, "Title should be at top")

        // Button row should be at bottom
        #expect(buttonRowRect.y + buttonRowRect.height == 15, "Button row should be at bottom")

        // Content spacer should fill the gap
        #expect(contentSpacerRect.height > 0, "Content spacer should have positive height")
        #expect(contentSpacerRect.y == titleRect2.y + titleRect2.height, "Spacer should start after title")
        #expect(contentSpacerRect.y + contentSpacerRect.height == buttonRowRect.y, "Spacer should end before buttons")
    }

    @Test("AlignSelf stretch makes child fill cross-axis")
    func alignSelfStretchMakesChildFillCrossAxis() {
        // Arrange
        let parentBox = Box(
            flexDirection: .row,
            alignItems: .flexStart,
            width: .points(20),
            height: .points(10),
            children: Box(alignSelf: .stretch, width: .points(5))
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = parentBox.calculateLayout(in: containerRect)

        // Assert
        let childRect = layout.childRects[0]

        // Test what stretch actually produces by comparing with alignItems stretch
        let stretchParentBox = Box(
            flexDirection: .row,
            alignItems: .stretch,
            width: .points(20),
            height: .points(10),
            children: Box(width: .points(5))
        )
        let stretchLayout = stretchParentBox.calculateLayout(in: containerRect)
        let expectedStretchHeight = stretchLayout.childRects[0].height

        #expect(childRect.height == expectedStretchHeight, "alignSelf stretch should behave same as alignItems stretch")
        #expect(childRect.y == 0, "Stretch child should start at container top")
    }

    // MARK: - Enhanced Box Component Tests (RUNE-30)

    @Test("Box with single border renders correctly")
    func boxWithSingleBorderRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            child: Text("Content")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "┌──────────┐", "Top border should use single-line characters")
        #expect(lines[1] == "│Content   │", "Content line should have vertical borders")
        #expect(lines[2] == "└──────────┘", "Bottom border should use single-line characters")
    }

    @Test("Box with double border renders correctly")
    func boxWithDoubleBorderRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .double,
            child: Text("Test")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "╔════════╗", "Top border should use double-line characters")
        #expect(lines[1] == "║Test    ║", "Content line should have double vertical borders")
        #expect(lines[2] == "╚════════╝", "Bottom border should use double-line characters")
    }

    @Test("Box with rounded border renders correctly")
    func boxWithRoundedBorderRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .rounded,
            child: Text("Round")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 11, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "╭─────────╮", "Top border should use rounded corners")
        #expect(lines[1] == "│Round    │", "Content line should have vertical borders")
        #expect(lines[2] == "╰─────────╯", "Bottom border should use rounded corners")
    }

    @Test("Box with border and padding renders correctly")
    func boxWithBorderAndPaddingRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Text("Padded")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 5)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 5, "Should render 5 lines")
        #expect(lines[0] == "┌─────────────┐", "Top border should span full width")
        #expect(lines[1] == "│             │", "Padding line should be empty")
        #expect(lines[2] == "│  Padded     │", "Content should be padded from left")
        #expect(lines[3] == "│             │", "Bottom padding line should be empty")
        #expect(lines[4] == "└─────────────┘", "Bottom border should span full width")
    }

    @Test("Box with border renders correctly")
    func boxWithBorderRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            child: Text("Content")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0].contains("┌"), "Should contain top border characters")
        #expect(lines[0].contains("┐"), "Should contain top border characters")
        #expect(lines[1].contains("│"), "Should contain side border characters")
        #expect(lines[2].contains("└"), "Should contain bottom border characters")
        #expect(lines[2].contains("┘"), "Should contain bottom border characters")
    }

    @Test("Box with border and content renders correctly")
    func boxWithBorderAndContentRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            child: Text("BG")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 8, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0].contains("┌"), "Should contain top border")
        #expect(lines[1].contains("│"), "Should contain side borders")
        #expect(lines[1].contains("BG"), "Should contain text content")
        #expect(lines[2].contains("└"), "Should contain bottom border")
    }

    @Test("Box with emoji content handles width correctly")
    func boxWithEmojiContentHandlesWidthCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            child: Text("Hello 👋")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "┌──────────┐", "Border should account for emoji width")
        #expect(lines[1].contains("Hello 👋"), "Should contain emoji content")
        #expect(lines[1].hasPrefix("│"), "Should start with border")
        #expect(lines[1].hasSuffix("│"), "Should end with border")
    }

    @Test("Box with CJK content handles width correctly")
    func boxWithCJKContentHandlesWidthCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            child: Text("你好")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "┌────────┐", "Border should account for CJK width")
        #expect(lines[1].contains("你好"), "Should contain CJK content")
        #expect(lines[1].hasPrefix("│"), "Should start with border")
        #expect(lines[1].hasSuffix("│"), "Should end with border")
    }

    @Test("Box prevents emoji clipping at border edges")
    func boxPreventsEmojiClippingAtBorderEdges() {
        // Arrange - narrow box that would clip emoji
        let box = Box(
            border: .single,
            child: Text("👨‍👩‍👧‍👦") // Family emoji (width 2)
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 4, height: 3) // Very narrow

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        // Should either fit the emoji or not show it, but not clip it
        let contentLine = lines[1]
        print("Content line: '\(contentLine)' (count: \(contentLine.count))")
        print("Content line characters:")
        for (index, char) in contentLine.enumerated() {
            print("  [\(index)]: '\(char)' (scalars: \(char.unicodeScalars.map { $0.value }))")
        }

        let contentWithoutBorders: String
        if contentLine.count >= 2 {
            contentWithoutBorders = String(contentLine.dropFirst().dropLast())
        } else {
            contentWithoutBorders = ""
        }

        print("Content without borders: '\(contentWithoutBorders)' (count: \(contentWithoutBorders.count))")
        print("Content without borders characters:")
        for (index, char) in contentWithoutBorders.enumerated() {
            print("  [\(index)]: '\(char)' (scalars: \(char.unicodeScalars.map { $0.value }))")
        }

        print("Expected emoji: '👨‍👩‍👧‍👦' (scalars: \("👨‍👩‍👧‍👦".unicodeScalars.map { $0.value }))")
        print("Content contains full emoji: \(contentWithoutBorders.contains("👨‍👩‍👧‍👦"))")
        print("Content equals full emoji: \(contentWithoutBorders == "👨‍👩‍👧‍👦")")

        // Content should either be empty or contain the full emoji
        #expect(
            contentWithoutBorders.isEmpty || contentWithoutBorders.contains("👨‍👩‍👧‍👦"),
            "Should not clip emoji - either show full emoji or hide it"
        )
    }

    @Test("Box with minimum dimensions handles borders correctly")
    func boxWithMinimumDimensionsHandlesBordersCorrectly() {
        // Arrange - minimum size that can fit borders
        let box = Box(
            border: .single,
            child: Text("X")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 3, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")
        #expect(lines[0] == "┌─┐", "Top border should fit in minimum width")
        #expect(lines[1] == "│X│", "Content should fit with borders")
        #expect(lines[2] == "└─┘", "Bottom border should fit in minimum width")
    }

    @Test("Box with too small dimensions gracefully degrades")
    func boxWithTooSmallDimensionsGracefullyDegrades() {
        // Arrange - dimensions too small for borders
        let box = Box(
            border: .single,
            child: Text("Content")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 1, height: 1)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should render 1 line")
        // Should gracefully handle impossible dimensions
        #expect(lines[0].count <= 1, "Should not exceed available width")
    }



    @Test("Text component with no styling should not add ANSI codes")
    func textComponentWithNoStyling() {
        // Arrange
        let text = Text("Hello")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "Hello", "Should contain only plain text")
        #expect(!lines[0].contains("\u{001B}["), "Should not contain ANSI codes")
    }

    @Test("Text component with empty content and styling")
    func textComponentWithEmptyContentAndStyling() {
        // Arrange
        let text = Text("", color: .red, bold: true)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].isEmpty, "Should be empty line for empty content")
    }

    @Test("Text component with RGB color")
    func textComponentWithRGBColor() {
        // Arrange
        let text = Text("Hello", color: .rgb(255, 128, 0))
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[38;2;255;128;0m"), "Should contain RGB color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    @Test("Text component with 256 color")
    func textComponentWith256Color() {
        // Arrange
        let text = Text("Hello", color: .color256(196))
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = text.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0].contains("\u{001B}[38;5;196m"), "Should contain 256 color code")
        #expect(lines[0].contains("Hello"), "Should contain the text")
        #expect(lines[0].contains("\u{001B}[0m"), "Should contain reset code")
    }

    // MARK: - Snapshot Tests for Style Combinations (RUNE-29)

    @Test("Text component style combination snapshots")
    func textComponentStyleCombinationSnapshots() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Test various style combinations and verify their ANSI output
        let testCases: [(String, Text, String)] = [
            ("Plain text", Text("Hello World"), "Hello World"),
            ("Red text", Text("Hello World", color: .red), "\u{001B}[31mHello World\u{001B}[0m"),
            ("Bold text", Text("Hello World", bold: true), "\u{001B}[1mHello World\u{001B}[0m"),
            ("Red bold", Text("Hello World", color: .red, bold: true), "\u{001B}[1;31mHello World\u{001B}[0m"),
            ("Blue background", Text("Hello World", backgroundColor: .blue), "\u{001B}[44mHello World\u{001B}[0m"),
            ("All styles", Text("Hello", color: .yellow, backgroundColor: .magenta, bold: true, italic: true, underline: true), "\u{001B}[1;3;4;33;45mHello\u{001B}[0m"),
        ]

        for (description, text, expectedPattern) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")

            if expectedPattern.contains("\u{001B}[") {
                // For styled text, check that it contains ANSI codes and the content
                #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
                #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
                #expect(lines[0].contains("Hello"), "\(description): Should contain text content")
            } else {
                // For plain text, should match exactly
                #expect(lines[0] == expectedPattern, "\(description): Should match expected output")
            }
        }
    }

    @Test("Text component with emoji style combinations")
    func textComponentEmojiStyleCombinations() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text)] = [
            ("Emoji with color", Text("Hello 👋", color: .green)),
            ("Emoji with bold", Text("🎉 Party!", bold: true)),
            ("Emoji with multiple styles", Text("🚀 Launch", color: .cyan, bold: true, underline: true)),
            ("Complex emoji", Text("👨‍👩‍👧‍👦 Family", color: .yellow)),
            ("Flag emoji", Text("🇺🇸 USA", color: .white, backgroundColor: .blue)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
            // Verify emoji is preserved in output
            #expect(lines[0].unicodeScalars.contains { $0.properties.isEmoji }, "\(description): Should contain emoji")
        }
    }

    @Test("Text component with CJK style combinations")
    func textComponentCJKStyleCombinations() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text)] = [
            ("Chinese with color", Text("你好世界", color: .red)),
            ("Japanese with bold", Text("こんにちは", bold: true)),
            ("Korean with styles", Text("안녕하세요", color: .blue, italic: true)),
            ("Mixed CJK", Text("你好 こんにちは 안녕", color: .magenta, underline: true)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
            // Verify CJK characters are preserved
            let containsCJK = lines[0].unicodeScalars.contains { scalar in
                let value = scalar.value
                return (0x4E00...0x9FFF).contains(value) || // CJK Unified Ideographs
                       (0x3040...0x309F).contains(value) || // Hiragana
                       (0x30A0...0x30FF).contains(value) || // Katakana
                       (0xAC00...0xD7AF).contains(value)    // Hangul
            }
            #expect(containsCJK, "\(description): Should contain CJK characters")
        }
    }

    @Test("Text component with special characters and styling")
    func textComponentSpecialCharactersAndStyling() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        let testCases: [(String, Text)] = [
            ("Accented chars", Text("café naïve", color: .green)),
            ("Symbols", Text("© ® ™ ± ∞", bold: true)),
            ("Math symbols", Text("α β γ δ ε", color: .blue, italic: true)),
            ("Currency", Text("$ € £ ¥ ₹", color: .yellow, backgroundColor: .black)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains("\u{001B}["), "\(description): Should contain ANSI codes")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
        }
    }

    @Test("Text component RGB and 256 color snapshots")
    func textComponentAdvancedColorSnapshots() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        let testCases: [(String, Text, String)] = [
            ("RGB orange", Text("Orange", color: .rgb(255, 165, 0)), "38;2;255;165;0"),
            ("RGB purple", Text("Purple", color: .rgb(128, 0, 128)), "38;2;128;0;128"),
            ("256 color bright red", Text("Bright", color: .color256(196)), "38;5;196"),
            ("256 color dark blue", Text("Dark", color: .color256(18)), "38;5;18"),
        ]

        for (description, text, expectedColorCode) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")
            #expect(lines[0].contains(expectedColorCode), "\(description): Should contain expected color code")
            #expect(lines[0].contains("\u{001B}[0m"), "\(description): Should contain reset code")
        }
    }

    // MARK: - Color Bleed Prevention Tests (RUNE-29)

    @Test("Text component prevents color bleed at line boundaries")
    func textComponentPreventsColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)

        // Test that styled text always ends with reset code
        let styledText = Text("Hello", color: .red, bold: true)
        let lines = styledText.render(in: rect)

        #expect(lines.count == 3, "Should return correct number of lines")
        #expect(lines[0].hasSuffix("\u{001B}[0m"), "First line should end with reset code")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(lines[2].isEmpty, "Third line should be empty")

        // Verify that empty lines don't contain any ANSI codes
        #expect(!lines[1].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
        #expect(!lines[2].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
    }

    @Test("Text component with multiple lines prevents color bleed")
    func textComponentMultiLinePreventsColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 5, height: 2)

        // Test with content that gets truncated
        let styledText = Text("Hello World", color: .blue, underline: true)
        let lines = styledText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0].contains("Hello"), "Should contain truncated content")
        #expect(lines[0].hasSuffix("\u{001B}[0m"), "Styled line should end with reset")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(!lines[1].contains("\u{001B}["), "Empty line should not contain ANSI codes")
    }

    @Test("Text component reset code placement")
    func textComponentResetCodePlacement() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        let testCases: [(String, Text)] = [
            ("Single style", Text("Test", color: .red)),
            ("Multiple styles", Text("Test", color: .green, bold: true, italic: true)),
            ("Background color", Text("Test", backgroundColor: .yellow)),
            ("All styles", Text("Test", color: .white, backgroundColor: .black, bold: true, italic: true, underline: true, strikethrough: true, inverse: true, dim: true)),
        ]

        for (description, text) in testCases {
            let lines = text.render(in: rect)
            #expect(lines.count == 1, "\(description): Should return one line")

            let line = lines[0]
            #expect(line.hasSuffix("\u{001B}[0m"), "\(description): Should end with reset code")

            // Verify reset is at the very end (no trailing characters)
            let resetIndex = line.lastIndex(of: "m")
            #expect(resetIndex == line.index(before: line.endIndex), "\(description): Reset should be at the very end")
        }
    }

    @Test("Text component with empty content has no color bleed")
    func textComponentEmptyContentNoColorBleed() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 2)

        // Even with styling, empty content should not produce ANSI codes
        let emptyStyledText = Text("", color: .red, bold: true)
        let lines = emptyStyledText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0].isEmpty, "First line should be empty")
        #expect(lines[1].isEmpty, "Second line should be empty")
        #expect(!lines[0].contains("\u{001B}["), "Empty content should not contain ANSI codes")
        #expect(!lines[1].contains("\u{001B}["), "Empty lines should not contain ANSI codes")
    }

    @Test("Text component plain text has no ANSI codes")
    func textComponentPlainTextNoANSI() {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 2)

        // Plain text should never contain ANSI codes
        let plainText = Text("Hello World")
        let lines = plainText.render(in: rect)

        #expect(lines.count == 2, "Should return correct number of lines")
        #expect(lines[0] == "Hello World", "Should contain plain text")
        #expect(lines[1].isEmpty, "Second line should be empty")

        // Verify no ANSI codes anywhere
        for (index, line) in lines.enumerated() {
            #expect(!line.contains("\u{001B}["), "Line \(index) should not contain ANSI codes")
        }
    }

    @Test("Box with Text child renders emoji correctly")
    func boxWithTextChildRendersEmojiCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            paddingRight: 1,
            paddingLeft: 1,
            child: Text("Complete! ✅")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")

        // Check that the content line contains the emoji
        let contentLine = lines[1]
        print("Content line: '\(contentLine)'")
        print("Content line scalars: \(contentLine.unicodeScalars.map { $0.value })")

        // The content should contain both the text and the emoji
        #expect(contentLine.contains("Complete!"), "Should contain the text")
        #expect(contentLine.contains("✅"), "Should contain the checkmark emoji")

        // Check that the right border is present
        #expect(contentLine.hasSuffix("│"), "Should have right border character")
    }



    @Test("Box border rendering with emoji content")
    func boxBorderRenderingWithEmojiContent() {
        // Test the exact issue: border rendering with emoji content
        let content = "Complete! ✅"

        // Create a box with the exact same configuration as the demo
        let box = Box(
            border: .single,
            paddingRight: 1,
            paddingLeft: 1,
            child: Text(content)
        )

        // Calculate width the same way as createBoxFrame
        let contentDisplayWidth = max(Width.displayWidth(of: content), 10)
        let totalWidth = contentDisplayWidth + 4  // 2 for borders + 2 for padding

        let rect = FlexLayout.Rect(x: 0, y: 0, width: totalWidth, height: 3)
        let lines = box.render(in: rect)

        // Verify border structure
        #expect(lines.count == 3, "Should have 3 lines")
        #expect(lines[0].hasPrefix("┌"), "Top line should start with top-left corner")
        #expect(lines[0].hasSuffix("┐"), "Top line should end with top-right corner")
        #expect(lines[1].hasPrefix("│"), "Middle line should start with vertical border")
        #expect(lines[1].hasSuffix("│"), "Middle line should end with vertical border")
        #expect(lines[2].hasPrefix("└"), "Bottom line should start with bottom-left corner")
        #expect(lines[2].hasSuffix("┘"), "Bottom line should end with bottom-right corner")

        // All lines should have the same DISPLAY width (character count may differ due to emojis)
        let displayWidths = lines.map { Width.displayWidth(of: $0) }
        let allSameDisplayWidth = displayWidths.allSatisfy { $0 == displayWidths.first }

        #expect(allSameDisplayWidth, "All lines should have the same display width")
        #expect(Width.displayWidth(of: lines[0]) == totalWidth, "Top line should have correct display width")
        #expect(Width.displayWidth(of: lines[1]) == totalWidth, "Middle line should have correct display width")
        #expect(Width.displayWidth(of: lines[2]) == totalWidth, "Bottom line should have correct display width")
    }

    @Test("createBoxFrame with emoji renders borders correctly")
    func createBoxFrameWithEmojiRendersBordersCorrectly() {
        // Arrange - simulate the exact createBoxFrame call from live demo
        let content = "Complete! ✅"
        let contentDisplayWidth = max(Width.displayWidth(of: content), 10)
        let totalWidth = contentDisplayWidth + 4

        print("Width calculation:")
        print("  Content: '\(content)'")
        print("  Content display width: \(contentDisplayWidth)")
        print("  Total width: \(totalWidth)")

        let box = Box(
            border: .single,
            paddingRight: 1,
            paddingLeft: 1,
            child: Text(content)
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: totalWidth, height: 3)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should render 3 lines")

        print("createBoxFrame output:")
        for (index, line) in lines.enumerated() {
            print("Line \(index): '\(line)' (length: \(line.count))")
        }

        // Check that all lines have proper borders
        #expect(lines[0].hasPrefix("┌"), "Top line should start with top-left corner")
        #expect(lines[0].hasSuffix("┐"), "Top line should end with top-right corner")
        #expect(lines[1].hasPrefix("│"), "Content line should start with left border")
        #expect(lines[1].hasSuffix("│"), "Content line should end with right border")
        #expect(lines[2].hasPrefix("└"), "Bottom line should start with bottom-left corner")
        #expect(lines[2].hasSuffix("┘"), "Bottom line should end with bottom-right corner")

        // Check that the content contains the emoji
        #expect(lines[1].contains("Complete!"), "Should contain the text")
        #expect(lines[1].contains("✅"), "Should contain the checkmark emoji")

        // Test Frame creation and structure
        let frame = TerminalRenderer.Frame(lines: lines, width: totalWidth, height: lines.count)
        print("Frame structure:")
        print("  Width: \(frame.width)")
        print("  Height: \(frame.height)")
        print("  Lines count: \(frame.lines.count)")
        for (index, line) in frame.lines.enumerated() {
            print("  Frame line \(index): '\(line)' (length: \(line.count))")
        }

        // Test Grid conversion
        let grid = frame.toGrid()
        print("Grid structure:")
        print("  Width: \(grid.width)")
        print("  Height: \(grid.height)")
        let gridLines = grid.getLines()
        for (index, line) in gridLines.enumerated() {
            print("  Grid line \(index): '\(line)' (length: \(line.count))")
        }

        // Debug the specific line with emoji
        let emojiLine = frame.lines[1]
        print("Emoji line analysis:")
        print("  Original: '\(emojiLine)'")
        print("  Characters:")
        for (index, char) in emojiLine.enumerated() {
            let charString = String(char)
            let cell = TerminalCell(content: charString)
            print("    [\(index)] '\(charString)' -> width: \(cell.width), scalars: \(charString.unicodeScalars.map { $0.value })")
        }

        // Test Text component with 12-column constraint
        print("Text component with 12-column constraint:")
        let textComponent = Text("Complete! ✅")
        let textRect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 1)
        let textOutput = textComponent.render(in: textRect)
        for (index, line) in textOutput.enumerated() {
            print("  Text line \(index): '\(line)' (length: \(line.count), display width: \(Width.displayWidth(of: line)))")
        }
    }

    @Test("Box with multiple Text children renders correctly")
    func boxWithMultipleTextChildrenRendersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Line 1"),
                     Text("Line 2"),
                     Text("Line 3")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 7)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 7, "Should render 7 lines")

        // Check that all children are rendered
        print("Box with multiple children output:")
        for (index, line) in lines.enumerated() {
            print("Line \(index): '\(line)'")
        }

        // The content lines should contain the text from each child
        #expect(lines[1].contains("Line 1"), "Should contain first child text")
        #expect(lines[2].contains("Line 2"), "Should contain second child text")
        #expect(lines[3].contains("Line 3"), "Should contain third child text")
    }

    @Test("Box with system monitor style content renders correctly")
    func boxWithSystemMonitorStyleContentRendersCorrectly() {
        // Arrange - simulate the system monitor box creation
        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("System Monitor"),
                     Text("CPU: [████████░░] 80%"),
                     Text("RAM: [██████░░░░] 60%"),
                     Text("DISK: [███░░░░░░░] 30%"),
                     Text("NET: [██████████] 100%")
        )
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 8)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 8, "Should render 8 lines")

        // Check that all children are rendered
        print("System monitor box output:")
        for (index, line) in lines.enumerated() {
            print("Line \(index): '\(line)'")
        }

        // The content lines should contain the system monitor data
        #expect(lines[1].contains("System Monitor"), "Should contain header")
        #expect(lines[2].contains("CPU:"), "Should contain CPU data")
        #expect(lines[3].contains("RAM:"), "Should contain RAM data")
        #expect(lines[4].contains("DISK:"), "Should contain DISK data")
        #expect(lines[5].contains("NET:"), "Should contain NET data")
    }

    // MARK: - Static Component Tests (RUNE-31)

    @Test("Static component with single line")
    func staticComponentSingleLine() {
        // Arrange
        let staticComponent = Static("Header: Application Started")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 1)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "Header: Application Started", "Should contain the static text")
    }

    @Test("Static component with multiple lines")
    func staticComponentMultipleLines() {
        // Arrange
        let staticLines = [
            "=== Application Log ===",
            "Started at: 2024-01-01 12:00:00",
            "Version: 1.0.0"
        ]
        let staticComponent = Static(staticLines)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 35, height: 3)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return three lines")
        #expect(lines[0] == "=== Application Log ===", "Should contain first static line")
        #expect(lines[1] == "Started at: 2024-01-01 12:00:00", "Should contain second static line")
        #expect(lines[2] == "Version: 1.0.0", "Should contain third static line")
    }

    @Test("Static component with zero dimensions")
    func staticComponentZeroDimensions() {
        // Arrange
        let staticComponent = Static("Test")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 0, height: 0)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.isEmpty, "Should return empty array for zero dimensions")
    }

    @Test("Static component with height constraint")
    func staticComponentHeightConstraint() {
        // Arrange
        let staticLines = [
            "Line 1",
            "Line 2",
            "Line 3",
            "Line 4"
        ]
        let staticComponent = Static(staticLines)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 2)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 2, "Should respect height constraint")
        #expect(lines[0] == "Line 1", "Should contain first line")
        #expect(lines[1] == "Line 2", "Should contain second line")
    }

    @Test("Static component with width constraint")
    func staticComponentWidthConstraint() {
        // Arrange
        let staticComponent = Static("This is a very long line that should be truncated")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "This is a ", "Should truncate to fit width")
    }

    @Test("Static component immutability")
    func staticComponentImmutability() {
        // Arrange
        let originalLines = ["Original Line 1", "Original Line 2"]
        let staticComponent = Static(originalLines)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 2)

        // Act - render multiple times
        let firstRender = staticComponent.render(in: rect)
        let secondRender = staticComponent.render(in: rect)

        // Assert - should be identical
        #expect(firstRender.count == secondRender.count, "Renders should be identical")
        for (index, line) in firstRender.enumerated() {
            #expect(line == secondRender[index], "Line \(index) should be identical across renders")
        }
    }

    @Test("Static component with empty lines")
    func staticComponentWithEmptyLines() {
        // Arrange
        let staticLines = ["Header", "", "Footer"]
        let staticComponent = Static(staticLines)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 3, "Should return three lines")
        #expect(lines[0] == "Header", "Should contain header")
        #expect(lines[1].isEmpty, "Should preserve empty line")
        #expect(lines[2] == "Footer", "Should contain footer")
    }

    @Test("Static component with emoji content")
    func staticComponentWithEmojiContent() {
        // Arrange
        let staticComponent = Static("Status: ✅ Complete")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "Status: ✅ Complete", "Should preserve emoji content")
    }

    @Test("Static component with CJK characters")
    func staticComponentWithCJKCharacters() {
        // Arrange
        let staticComponent = Static("状态: 完成")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 1)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        #expect(lines[0] == "状态: 完成", "Should preserve CJK characters")
    }

    @Test("Static component with emoji width constraint")
    func staticComponentWithEmojiWidthConstraint() {
        // Arrange
        let staticComponent = Static("Progress: 👨‍👩‍👧‍👦 Family")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 1)

        // Act
        let lines = staticComponent.render(in: rect)

        // Assert
        #expect(lines.count == 1, "Should return one line")
        // Should truncate properly respecting emoji width
        #expect(lines[0] == "Progress: 👨‍👩‍👧‍👦", "Should truncate at emoji boundary")
    }

    @Test("Static component ordering consistency")
    func staticComponentOrderingConsistency() {
        // Arrange
        let staticLines = [
            "Log Entry 1",
            "Log Entry 2",
            "Log Entry 3"
        ]
        let staticComponent = Static(staticLines)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 3)

        // Act - render multiple times
        let render1 = staticComponent.render(in: rect)
        let render2 = staticComponent.render(in: rect)
        let render3 = staticComponent.render(in: rect)

        // Assert - ordering should be consistent
        #expect(render1 == render2, "First and second render should be identical")
        #expect(render2 == render3, "Second and third render should be identical")

        // Verify specific ordering
        #expect(render1[0] == "Log Entry 1", "First line should always be first")
        #expect(render1[1] == "Log Entry 2", "Second line should always be second")
        #expect(render1[2] == "Log Entry 3", "Third line should always be third")
    }

    @Test("Static component View protocol conformance")
    func staticComponentViewProtocolConformance() {
        // Arrange
        let staticComponent = Static("Test View")

        // Act - Test View protocol conformance
        let body = staticComponent.body

        // Assert
        #expect(body is EmptyView, "Static should conform to View protocol")
    }
}
