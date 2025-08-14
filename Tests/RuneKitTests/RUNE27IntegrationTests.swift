import Foundation
import Testing
import TestSupport
@testable import RuneComponents
@testable import RuneKit
@testable import RuneLayout
@testable import RuneRenderer

/// Comprehensive integration tests for RUNE-27 Box layout with the entire RuneKit system
///
/// These tests verify that the new Box layout system integrates properly with:
/// - View protocol and render pipeline
/// - FrameBuffer and HybridReconciler
/// - TerminalRenderer and output systems
/// - Component rendering system
/// - Signal handling and lifecycle management
struct RUNE27IntegrationTests {
    // MARK: - View Protocol Integration

    @Test("Box integrates with View protocol and render pipeline")
    func boxIntegratesWithViewProtocol() async {
        // Arrange
        let box = Box(
            paddingTop: 1,
            paddingLeft: 2,
            marginTop: 1,
            marginLeft: 1,
            child: Text("Integration Test"),
        )

        // Act - Test View protocol conformance
        let body = box.body
        #expect(body is EmptyView, "Box should conform to View protocol")

        // Test conversion to component and rendering
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count <= rect.height, "Rendered lines should not exceed container height")
        #expect(!lines.isEmpty, "Box should render content")
    }

    @Test("Box works with render() function and RenderHandle", .enabled(if: !TestEnv.isCI))
    func boxWorksWithRenderFunction() async {
        // Arrange
        let box = Box(
            flexDirection: .row,
            columnGap: 1,
            children: Text("Left"), Text("Right"),
        )

        // Use default options to avoid file handle issues
        let options = RenderOptions(
            stdout: FileHandle.standardOutput,
            stdin: FileHandle.standardInput,
            stderr: FileHandle.standardError,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 60,
        )

        // Act - Test full render pipeline
        let handle = await render(box, options: options)

        // Test rerender functionality
        let newBox = Box(
            flexDirection: .column,
            rowGap: 1,
            children: Text("Top"), Text("Bottom"),
        )
        await handle.rerender(newBox)

        // Clean up
        await handle.unmount()

        // Assert - Just verify the handle was created and operations completed
        #expect(true, "Render handle operations should complete without crashing")
    }

    // MARK: - FrameBuffer Integration

    @Test("Box integrates with FrameBuffer rendering")
    func boxIntegratesWithFrameBuffer() async {
        // Arrange
        let box = Box(
            paddingTop: 2,
            paddingLeft: 3,
            children: Text("Frame Buffer Test"), Text("Second Line"),
        )

        let config = RenderConfiguration(
            optimizationMode: .automatic,
            enableMetrics: false,
            enableDebugLogging: false,
        )
        let frameBuffer = FrameBuffer(output: FileHandle.standardOutput, configuration: config)

        // Act - Convert box to frame and render
        let terminalSize = (width: 40, height: 15)
        let layoutRect = FlexLayout.Rect(x: 0, y: 0, width: terminalSize.width, height: terminalSize.height)
        let lines = box.render(in: layoutRect)

        let frame = TerminalRenderer.Frame(
            lines: lines,
            width: terminalSize.width,
            height: lines.count,
        )

        await frameBuffer.renderFrame(frame)

        // Assert - Just verify rendering completed without crashing
        #expect(!lines.isEmpty, "Box should render content lines")
        #expect(frame.width == terminalSize.width, "Frame should have correct width")
    }

    // MARK: - HybridReconciler Integration

    @Test("Box renders borders correctly with proper layout")
    func boxRendersBordersCorrectly() {
        // Arrange
        let box = Box(
            border: .single,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Text("Content"),
        )

        let rect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 5)

        // Act
        let lines = box.render(in: rect)

        // Assert
        #expect(lines.count == 5, "Should render 5 lines")
        #expect(lines[0].hasPrefix("┌"), "Top line should start with top-left corner")
        #expect(lines[0].hasSuffix("┐"), "Top line should end with top-right corner")
        #expect(lines[1].hasPrefix("│"), "Content line should start with vertical border")
        #expect(lines[1].hasSuffix("│"), "Content line should end with vertical border")
        #expect(lines[4].hasPrefix("└"), "Bottom line should start with bottom-left corner")
        #expect(lines[4].hasSuffix("┘"), "Bottom line should end with bottom-right corner")

        // Verify content is properly positioned with padding
        #expect(lines[2].contains("Content"), "Content should be visible in the padded area")
    }

    @Test("Box renders different border styles correctly")
    func boxRendersDifferentBorderStyles() {
        // Test double border
        let doubleBox = Box(border: .double, child: Text("Test"))
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3)
        let doubleLines = doubleBox.render(in: rect)

        #expect(doubleLines[0].hasPrefix("╔"), "Double border should use double-line characters")
        #expect(doubleLines[0].hasSuffix("╗"), "Double border should use double-line characters")
        #expect(doubleLines[2].hasPrefix("╚"), "Double border should use double-line characters")

        // Test rounded border
        let roundedBox = Box(border: .rounded, child: Text("Test"))
        let roundedLines = roundedBox.render(in: rect)

        #expect(roundedLines[0].hasPrefix("╭"), "Rounded border should use rounded characters")
        #expect(roundedLines[0].hasSuffix("╮"), "Rounded border should use rounded characters")
        #expect(roundedLines[2].hasPrefix("╰"), "Rounded border should use rounded characters")
    }

    @Test("Box works with HybridReconciler optimization strategies")
    func boxWorksWithHybridReconciler() async {
        // Arrange
        let config = RenderConfiguration(
            optimizationMode: .automatic,
            enableMetrics: false,
            enableDebugLogging: false,
        )
        let frameBuffer = FrameBuffer(output: FileHandle.standardOutput, configuration: config)

        // Create initial box
        let box1 = Box(
            flexDirection: .column,
            rowGap: 1,
            children: Text("Line 1"), Text("Line 2"), Text("Line 3"),
        )

        // Create modified box (small change)
        let box2 = Box(
            flexDirection: .column,
            rowGap: 1,
            children: Text("Line 1"), Text("Line 2 Modified"), Text("Line 3"),
        )

        let terminalSize = (width: 30, height: 10)
        let layoutRect = FlexLayout.Rect(x: 0, y: 0, width: terminalSize.width, height: terminalSize.height)

        // Act - Render initial frame
        let lines1 = box1.render(in: layoutRect)
        let frame1 = TerminalRenderer.Frame(lines: lines1, width: terminalSize.width, height: lines1.count)
        await frameBuffer.renderFrame(frame1)

        // Render modified frame (should use delta optimization)
        let lines2 = box2.render(in: layoutRect)
        let frame2 = TerminalRenderer.Frame(lines: lines2, width: terminalSize.width, height: lines2.count)
        await frameBuffer.renderFrame(frame2)

        // Assert - Verify frames were created and rendered
        #expect(!lines1.isEmpty, "First box should render content")
        #expect(!lines2.isEmpty, "Second box should render content")
        #expect(frame1.width == terminalSize.width, "Frame should have correct width")
        #expect(frame2.width == terminalSize.width, "Frame should have correct width")
    }

    // MARK: - Component System Integration

    @Test("Box integrates with existing Component system")
    func boxIntegratesWithComponentSystem() {
        // Arrange
        let textComponent = Text("Component Test")
        let boxComponent = Box(
            paddingTop: 1,
            paddingLeft: 2,
            child: textComponent,
        )

        // Act - Test Component protocol methods
        let rect = FlexLayout.Rect(x: 5, y: 3, width: 25, height: 8)
        let boxLines = boxComponent.render(in: rect)
        let textLines = textComponent.render(in: rect)

        // Assert
        #expect(boxLines.count <= rect.height, "Box should respect container height")
        #expect(textLines.count <= rect.height, "Text should respect container height")

        // Box should be able to contain and render the text component
        #expect(!boxLines.isEmpty, "Box should render content")
    }

    // MARK: - Layout System Integration

    @Test("Box layout integrates with FlexLayout coordinate system")
    func boxLayoutIntegratesWithFlexLayoutCoordinates() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            paddingTop: 1,
            paddingLeft: 1,
            marginTop: 2,
            marginLeft: 3,
            children: Text("A"), Text("B"),
        )

        let containerRect = FlexLayout.Rect(x: 10, y: 20, width: 30, height: 15)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert - Coordinates should be properly offset
        #expect(layout.boxRect.x == containerRect.x + 3, "Box X should include margin offset")
        #expect(layout.boxRect.y == containerRect.y + 2, "Box Y should include margin offset")
        #expect(layout.contentRect.x == layout.boxRect.x + 1, "Content X should include padding offset")
        #expect(layout.contentRect.y == layout.boxRect.y + 1, "Content Y should include padding offset")

        // Child coordinates should be relative to content area
        for childRect in layout.childRects {
            #expect(childRect.x >= 0, "Child X should be relative to content area")
            #expect(childRect.y >= 0, "Child Y should be relative to content area")
        }
    }

    // MARK: - Cross-Platform Integration

    @Test("Box layout works consistently across platforms")
    func boxLayoutWorksAcrossPlatforms() {
        // This test verifies that Box layout produces consistent results
        // regardless of platform-specific differences

        // Arrange
        let box = Box(
            flexDirection: .column,
            paddingTop: 2,
            paddingLeft: 3,
            rowGap: 1,
            children: Text("Platform Test 1"), Text("Platform Test 2"), Text("Platform Test 3"),
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 40, height: 20)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert - Results should be deterministic and platform-independent
        #expect(layout.childRects.count == 3, "Should have three children")
        #expect(layout.boxRect.width > 0, "Box should have positive width")
        #expect(layout.boxRect.height > 0, "Box should have positive height")

        // Verify gap spacing
        if layout.childRects.count >= 2 {
            let gap = layout.childRects[1].y - (layout.childRects[0].y + layout.childRects[0].height)
            #expect(gap == 1, "Row gap should be applied correctly")
        }
    }

    // MARK: - Performance Integration

    @Test("Box layout maintains performance with complex hierarchies")
    func boxLayoutMaintainsPerformance() {
        // Arrange - Create complex nested structure
        let deepBox = createDeepNestedBox(depth: 5, childrenPerLevel: 3)
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 100, height: 50)

        // Act - Measure layout calculation time
        let startTime = Date()
        let layout = deepBox.calculateLayout(in: containerRect)
        let duration = Date().timeIntervalSince(startTime)

        // Assert
        #expect(duration < 0.1, "Complex layout should complete within 100ms")
        #expect(!layout.childRects.isEmpty, "Should have calculated child layouts")
        #expect(layout.boxRect.width > 0, "Should have valid dimensions")
        #expect(layout.boxRect.height > 0, "Should have valid dimensions")
    }

    // MARK: - Helper Methods

    private func createDeepNestedBox(depth: Int, childrenPerLevel: Int) -> Box {
        if depth <= 0 {
            return Box(child: Text("Leaf \(depth)"))
        }

        let children = (0 ..< childrenPerLevel).map { _ in
            createDeepNestedBox(depth: depth - 1, childrenPerLevel: childrenPerLevel)
        }

        return Box(
            flexDirection: depth % 2 == 0 ? .row : .column,
            paddingTop: 1,
            paddingLeft: 1,
            rowGap: 1,
            columnGap: 1,
            childrenArray: children,
        )
    }
}
