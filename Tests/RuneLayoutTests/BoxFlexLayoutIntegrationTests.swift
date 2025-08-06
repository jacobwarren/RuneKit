import Foundation
import Testing
@testable import RuneLayout
@testable import RuneComponents

/// Integration tests between Box layout system and FlexLayout system (RUNE-27)
/// 
/// These tests ensure that the new Box.calculateLayout() method integrates properly
/// with the existing FlexLayout.calculateLayout() system and maintains backward compatibility.
struct BoxFlexLayoutIntegrationTests {
    // MARK: - Backward Compatibility Tests

    @Test("FlexLayout.calculateLayout still works with existing API")
    func flexLayoutBackwardCompatibility() {
        // Arrange
        let children = [
            FlexLayout.Size(width: 5, height: 2),
            FlexLayout.Size(width: 7, height: 3),
            FlexLayout.Size(width: 4, height: 1)
        ]
        let containerSize = FlexLayout.Size(width: 20, height: 10)

        // Act - FlexLayout defaults to row direction
        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize
        )

        // Assert - children should be laid out horizontally (row)
        #expect(rects.count == 3, "Should return rect for each child")
        #expect(rects[0] == FlexLayout.Rect(x: 0, y: 0, width: 5, height: 2), "First child positioned correctly")
        #expect(rects[1] == FlexLayout.Rect(x: 5, y: 0, width: 7, height: 3), "Second child positioned correctly")
        #expect(rects[2] == FlexLayout.Rect(x: 12, y: 0, width: 4, height: 1), "Third child positioned correctly")
    }

    @Test("Box layout produces compatible rectangles with FlexLayout")
    func boxLayoutCompatibleWithFlexLayout() {
        // Arrange - use row direction to match FlexLayout default
        let box = Box(
            flexDirection: .row,
            children: Text("First"), Text("Second"), Text("Third")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let boxLayout = box.calculateLayout(in: containerRect)

        // Compare with equivalent FlexLayout call (defaults to row)
        let flexChildren = [
            FlexLayout.Size(width: 5, height: 1),
            FlexLayout.Size(width: 6, height: 1),
            FlexLayout.Size(width: 5, height: 1)
        ]
        let flexRects = FlexLayout.calculateLayout(
            children: flexChildren,
            containerSize: FlexLayout.Size(width: 20, height: 10)
        )

        // Assert
        #expect(boxLayout.childRects.count == flexRects.count, "Same number of children")
        for (index, (boxRect, flexRect)) in zip(boxLayout.childRects, flexRects).enumerated() {
            #expect(boxRect.x == flexRect.x, "Child \(index) X coordinate matches")
            #expect(boxRect.y == flexRect.y, "Child \(index) Y coordinate matches")
            #expect(boxRect.width == flexRect.width, "Child \(index) width matches")
            #expect(boxRect.height == flexRect.height, "Child \(index) height matches")
        }
    }

    // MARK: - Integration with Existing Components

    @Test("Box layout integrates with Text component sizing")
    func boxLayoutWithTextComponentSizing() {
        // Arrange
        let text1 = Text("Hello")      // Should be 5x1
        let text2 = Text("World!")     // Should be 6x1

        let box = Box(
            flexDirection: .row,
            columnGap: 1,
            children: text1, text2
        )
        let containerRect = FlexLayout.Rect(x: 10, y: 5, width: 30, height: 8)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        let expectedChildRects = [
            FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1),  // "Hello"
            FlexLayout.Rect(x: 6, y: 0, width: 6, height: 1)   // "World!" (5 + 1 gap)
        ]
        #expect(layout.childRects == expectedChildRects, "Text components sized correctly")
        #expect(layout.boxRect == containerRect, "Box fills container when no margin")
        #expect(layout.contentRect == containerRect, "Content fills box when no padding")
    }

    @Test("Box layout works with nested Box components")
    func boxLayoutWithNestedBoxComponents() {
        // Arrange
        let innerBox1 = Box(
            flexDirection: .column,
            children: Text("A"), Text("B")  // 1x1 each, total 1x2
        )
        let innerBox2 = Box(
            flexDirection: .column,
            children: Text("C"), Text("D"), Text("E")  // 1x1 each, total 1x3
        )

        let outerBox = Box(
            flexDirection: .row,
            columnGap: 2,
            children: innerBox1, innerBox2
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = outerBox.calculateLayout(in: containerRect)

        // Assert
        // Inner boxes should be positioned with gap
        let expectedChildRects = [
            FlexLayout.Rect(x: 0, y: 0, width: 1, height: 2),  // innerBox1
            FlexLayout.Rect(x: 3, y: 0, width: 1, height: 3)   // innerBox2 (1 + 2 gap)
        ]
        #expect(layout.childRects == expectedChildRects, "Nested boxes positioned correctly")

        // Test nested layout calculation
        let innerLayout1 = innerBox1.calculateLayout(in: expectedChildRects[0])
        let expectedInnerRects1 = [
            FlexLayout.Rect(x: 0, y: 0, width: 1, height: 1),  // "A"
            FlexLayout.Rect(x: 0, y: 1, width: 1, height: 1)   // "B"
        ]
        #expect(innerLayout1.childRects == expectedInnerRects1, "First nested box children correct")

        let innerLayout2 = innerBox2.calculateLayout(in: expectedChildRects[1])
        let expectedInnerRects2 = [
            FlexLayout.Rect(x: 0, y: 0, width: 1, height: 1),  // "C"
            FlexLayout.Rect(x: 0, y: 1, width: 1, height: 1),  // "D"
            FlexLayout.Rect(x: 0, y: 2, width: 1, height: 1)   // "E"
        ]
        #expect(innerLayout2.childRects == expectedInnerRects2, "Second nested box children correct")
    }

    // MARK: - FlexLayout System Integration

    @Test("Box layout respects FlexLayout coordinate system")
    func boxLayoutRespectsFlexLayoutCoordinateSystem() {
        // Arrange
        let box = Box(
            paddingTop: 1,
            paddingLeft: 1,
            marginTop: 2,
            marginLeft: 3,
            child: Text("Test")
        )
        let containerRect = FlexLayout.Rect(x: 10, y: 20, width: 15, height: 8)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Box should be positioned with margin relative to container
        let expectedBoxRect = FlexLayout.Rect(x: 13, y: 22, width: 12, height: 6)  // container + margin
        #expect(layout.boxRect == expectedBoxRect, "Box positioned with margin offset")

        // Content should be positioned with padding relative to box
        let expectedContentRect = FlexLayout.Rect(x: 14, y: 23, width: 11, height: 5)  // box + padding
        #expect(layout.contentRect == expectedContentRect, "Content positioned with padding offset")

        // Container should be preserved
        #expect(layout.containerRect == containerRect, "Container rect preserved")
    }

    @Test("Box layout handles FlexLayout.Rect edge cases")
    func boxLayoutHandlesFlexLayoutRectEdgeCases() {
        // Test with zero-sized container
        let box1 = Box(child: Text("Test"))
        let zeroRect = FlexLayout.Rect(x: 5, y: 5, width: 0, height: 0)
        let layout1 = box1.calculateLayout(in: zeroRect)

        #expect(layout1.boxRect == zeroRect, "Zero-sized container handled")
        #expect(layout1.contentRect == zeroRect, "Zero-sized content handled")

        // Test with large coordinates
        let largeRect = FlexLayout.Rect(x: 1000, y: 2000, width: 50, height: 25)
        let layout2 = box1.calculateLayout(in: largeRect)

        #expect(layout2.boxRect == largeRect, "Large coordinates handled")
        #expect(layout2.contentRect == largeRect, "Large content coordinates handled")
    }

    // MARK: - Performance and Memory Integration

    @Test("Box layout doesn't interfere with FlexLayout performance")
    func boxLayoutPerformanceIntegration() {
        // Arrange
        let startTime = Date()

        // Create many boxes to test performance
        var layouts: [BoxLayoutResult] = []
        for i in 0..<100 {
            let box = Box(
                flexDirection: i % 2 == 0 ? .row : .column,
                paddingTop: Float(i % 3),
                paddingLeft: Float(i % 4),
                children: Text("Item \(i)"), Text("Child \(i)")
            )
            let containerRect = FlexLayout.Rect(x: i, y: i, width: 20, height: 10)

            // Act
            let layout = box.calculateLayout(in: containerRect)
            layouts.append(layout)
        }

        let duration = Date().timeIntervalSince(startTime)

        // Assert
        #expect(layouts.count == 100, "All layouts calculated")
        #expect(duration < 1.0, "Performance should be reasonable (< 1 second for 100 layouts)")

        // Verify no memory leaks by checking a few layouts
        #expect(layouts[0].childRects.count == 2, "First layout has correct children")
        #expect(layouts[99].childRects.count == 2, "Last layout has correct children")
    }

    // MARK: - API Consistency Tests

    @Test("Box layout API is consistent with FlexLayout patterns")
    func boxLayoutAPIConsistency() {
        // Both systems should use the same Rect type
        let flexRect = FlexLayout.Rect(x: 1, y: 2, width: 10, height: 5)
        let box = Box(child: Text("Test"))
        let boxLayout = box.calculateLayout(in: flexRect)

        // Should return same Rect type
        #expect(type(of: boxLayout.boxRect) == type(of: flexRect), "Same Rect type used")
        #expect(type(of: boxLayout.contentRect) == type(of: flexRect), "Same Rect type used")
        #expect(type(of: boxLayout.containerRect) == type(of: flexRect), "Same Rect type used")

        // Child rects should be array of same type
        if !boxLayout.childRects.isEmpty {
            #expect(type(of: boxLayout.childRects[0]) == type(of: flexRect), "Child rects same type")
        }
    }

    @Test("Box layout maintains FlexLayout immutability principles")
    func boxLayoutImmutabilityPrinciples() {
        // Arrange
        let originalRect = FlexLayout.Rect(x: 5, y: 10, width: 20, height: 15)
        let box = Box(
            paddingTop: 2,
            paddingLeft: 3,
            child: Text("Immutable")
        )

        // Act
        let layout1 = box.calculateLayout(in: originalRect)
        let layout2 = box.calculateLayout(in: originalRect)

        // Assert
        // Multiple calls should produce identical results
        #expect(layout1.boxRect == layout2.boxRect, "Repeated calls produce same box rect")
        #expect(layout1.contentRect == layout2.contentRect, "Repeated calls produce same content rect")
        #expect(layout1.containerRect == layout2.containerRect, "Repeated calls produce same container rect")
        #expect(layout1.childRects == layout2.childRects, "Repeated calls produce same child rects")

        // Original rect should be unchanged
        #expect(originalRect == FlexLayout.Rect(x: 5, y: 10, width: 20, height: 15), "Input rect unchanged")
    }
}
