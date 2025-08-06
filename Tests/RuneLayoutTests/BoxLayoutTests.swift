import Testing
@testable import RuneLayout
@testable import RuneComponents

/// Tests for Box layout with nested structures and complex scenarios (RUNE-27)
struct BoxLayoutTests {
    
    // MARK: - Nested Box Layout Tests
    
    @Test("Nested boxes with padding and margin")
    func nestedBoxesWithPaddingAndMargin() {
        // Arrange
        let innerBox = Box(
            paddingTop: 1,
            paddingRight: 1,
            paddingBottom: 1,
            paddingLeft: 1,
            child: Text("Inner")
        )
        
        let outerBox = Box(
            paddingTop: 2,
            paddingRight: 2,
            paddingBottom: 2,
            paddingLeft: 2,
            marginTop: 1,
            marginRight: 1,
            marginBottom: 1,
            marginLeft: 1,
            child: innerBox
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 15)
        
        // Act
        let layout = outerBox.calculateLayout(in: containerRect)
        
        // Assert
        // Outer box: margin=1 all sides, so positioned at (1,1) with size (18,13)
        // Outer box padding=2 all sides, so inner content at (3,3) with size (14,9)
        // Inner box padding=1 all sides, so text content at (4,4) with size (12,7)
        
        let expectedOuterBoxRect = FlexLayout.Rect(x: 1, y: 1, width: 18, height: 13)
        let expectedInnerContentRect = FlexLayout.Rect(x: 3, y: 3, width: 14, height: 9)
        let expectedTextContentRect = FlexLayout.Rect(x: 4, y: 4, width: 12, height: 7)
        
        #expect(layout.boxRect == expectedOuterBoxRect, "Outer box should account for margin")
        #expect(layout.contentRect == expectedInnerContentRect, "Inner content should account for outer padding")
        
        // Get inner box layout
        let innerLayout = innerBox.calculateLayout(in: expectedInnerContentRect)
        #expect(innerLayout.contentRect == expectedTextContentRect, "Text should account for inner padding")
    }
    
    @Test("Row layout with nested column layouts")
    func rowLayoutWithNestedColumns() {
        // Arrange
        let leftColumn = Box(
            flexDirection: .column,
            rowGap: 1,
            children: [
                Text("Left 1"),
                Text("Left 2")
            ]
        )
        
        let rightColumn = Box(
            flexDirection: .column,
            rowGap: 2,
            children: [
                Text("Right 1"),
                Text("Right 2"),
                Text("Right 3")
            ]
        )
        
        let mainRow = Box(
            flexDirection: .row,
            columnGap: 3,
            children: [leftColumn, rightColumn]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 12)
        
        // Act
        let layout = mainRow.calculateLayout(in: containerRect)
        
        // Assert
        // Left column intrinsic size: max("Left 1"=6, "Left 2"=6) = 6 width, (1+1+1) = 3 height
        // Right column intrinsic size: max("Right 1"=7, "Right 2"=7, "Right 3"=7) = 7 width, (1+2+1+2+1) = 7 height
        // With 3-column gap: 6 + 3 + 7 = 16 total width
        let expectedLeftRect = FlexLayout.Rect(x: 0, y: 0, width: 6, height: 3)
        let expectedRightRect = FlexLayout.Rect(x: 9, y: 0, width: 7, height: 7) // 6 + 3 gap

        #expect(layout.childRects.count == 2, "Should have two child rects")
        #expect(layout.childRects[0] == expectedLeftRect, "Left column should have correct rect")
        #expect(layout.childRects[1] == expectedRightRect, "Right column should have correct rect")
        
        // Test nested column layouts
        let leftLayout = leftColumn.calculateLayout(in: expectedLeftRect)
        // Left column children: "Left 1"=6x1, "Left 2"=6x1 with 1-row gap
        let expectedLeftChildren = [
            FlexLayout.Rect(x: 0, y: 0, width: 6, height: 1),
            FlexLayout.Rect(x: 0, y: 2, width: 6, height: 1) // 1 + 1 gap
        ]
        #expect(leftLayout.childRects == expectedLeftChildren, "Left column children should be spaced correctly")

        let rightLayout = rightColumn.calculateLayout(in: expectedRightRect)
        // Right column children: "Right 1"=7x1, "Right 2"=7x1, "Right 3"=7x1 with 2-row gaps
        let expectedRightChildren = [
            FlexLayout.Rect(x: 0, y: 0, width: 7, height: 1),
            FlexLayout.Rect(x: 0, y: 3, width: 7, height: 1), // 1 + 2 gap
            FlexLayout.Rect(x: 0, y: 6, width: 7, height: 1)  // 3 + 1 + 2 gap
        ]
        #expect(rightLayout.childRects == expectedRightChildren, "Right column children should be spaced correctly")
    }
    
    @Test("Complex nested layout with mixed properties")
    func complexNestedLayoutWithMixedProperties() {
        // Arrange
        let card = Box(
            border: .single,
            width: .points(25),
            height: .points(12),
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            marginTop: 1,
            marginRight: 1,
            marginBottom: 1,
            marginLeft: 1,
            child: Box(
                flexDirection: .column,
                rowGap: 1,
                children: [
                    Text("Title"),
                    Box(
                        flexDirection: .row,
                        columnGap: 2,
                        children: [
                            Text("Button 1"),
                            Text("Button 2")
                        ]
                    )
                ]
            )
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 40, height: 20)
        
        // Act
        let layout = card.calculateLayout(in: containerRect)
        
        // Assert
        // Card: margin=1, so positioned at (1,1) with fixed size (25,12)
        let expectedCardRect = FlexLayout.Rect(x: 1, y: 1, width: 25, height: 12)
        #expect(layout.boxRect == expectedCardRect, "Card should use fixed dimensions with margin")
        
        // Content area: padding top=1, right=2, bottom=1, left=2
        // So content at (3,2) with size (21,10) relative to container
        let expectedContentRect = FlexLayout.Rect(x: 3, y: 2, width: 21, height: 10)
        #expect(layout.contentRect == expectedContentRect, "Content should account for padding")
    }
    
    @Test("Edge case: Zero dimensions")
    func edgeCaseZeroDimensions() {
        // Arrange
        let box = Box(
            width: .points(0),
            height: .points(0),
            child: Text("Hidden")
        )
        let containerRect = FlexLayout.Rect(x: 5, y: 5, width: 20, height: 15)
        
        // Act
        let layout = box.calculateLayout(in: containerRect)
        
        // Assert
        let expectedBoxRect = FlexLayout.Rect(x: 5, y: 5, width: 0, height: 0)
        #expect(layout.boxRect == expectedBoxRect, "Zero-sized box should have zero dimensions")
        #expect(layout.contentRect == expectedBoxRect, "Content should also be zero-sized")
    }
    
    @Test("Edge case: Padding larger than container")
    func edgeCasePaddingLargerThanContainer() {
        // Arrange
        let box = Box(
            paddingTop: 10,
            paddingRight: 15,
            paddingBottom: 10,
            paddingLeft: 15,
            child: Text("Overflow")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 15)
        
        // Act
        let layout = box.calculateLayout(in: containerRect)
        
        // Assert
        // Padding: left=15, right=15 = 30 > container width=20
        // Padding: top=10, bottom=10 = 20 > container height=15
        // Content area should be clamped to minimum (0,0) or negative handled gracefully
        let expectedContentRect = FlexLayout.Rect(x: 15, y: 10, width: 0, height: 0) // Clamped to zero
        #expect(layout.contentRect.width >= 0, "Content width should not be negative")
        #expect(layout.contentRect.height >= 0, "Content height should not be negative")
    }
    
    @Test("Rounding rules for fractional coordinates")
    func roundingRulesForFractionalCoordinates() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            children: [
                Text("A"), Text("B"), Text("C")
            ]
        )
        // Use container width that doesn't divide evenly by 3
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 5)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // With intrinsic sizing (no flex grow), children use their content width
        // "A", "B", "C" each have width 1, so total width = 3
        #expect(layout.childRects.count == 3, "Should have three children")

        let totalWidth = layout.childRects.reduce(0) { $0 + $1.width }
        #expect(totalWidth == 3, "Total width should equal sum of intrinsic widths")

        // Verify coordinates are integers and positioned correctly
        let expectedRects = [
            FlexLayout.Rect(x: 0, y: 0, width: 1, height: 1), // "A"
            FlexLayout.Rect(x: 1, y: 0, width: 1, height: 1), // "B"
            FlexLayout.Rect(x: 2, y: 0, width: 1, height: 1)  // "C"
        ]

        for (index, rect) in layout.childRects.enumerated() {
            #expect(rect == expectedRects[index], "Child \(index) should have correct position and size")
            #expect(rect.x >= 0, "X coordinate should be non-negative integer")
            #expect(rect.y >= 0, "Y coordinate should be non-negative integer")
            #expect(rect.width >= 0, "Width should be non-negative integer")
            #expect(rect.height >= 0, "Height should be non-negative integer")
        }
    }
    
    @Test("Justify content and align items with padding")
    func justifyContentAndAlignItemsWithPadding() {
        // Arrange
        let box = Box(
            flexDirection: .row,
            justifyContent: .center,
            alignItems: .center,
            paddingTop: 2,
            paddingRight: 3,
            paddingBottom: 2,
            paddingLeft: 3,
            children: [
                Text("Centered")
            ]
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)
        
        // Act
        let layout = box.calculateLayout(in: containerRect)
        
        // Assert
        // Content area: (20-6)x(10-4) = 14x6, positioned at (3,2)
        let expectedContentRect = FlexLayout.Rect(x: 3, y: 2, width: 14, height: 6)
        #expect(layout.contentRect == expectedContentRect, "Content should account for padding")
        
        // Child should be centered within content area
        #expect(layout.childRects.count == 1, "Should have one child")
        let childRect = layout.childRects[0]
        
        // Child should be positioned relative to content area, not container
        #expect(childRect.x >= expectedContentRect.x, "Child should be within content area")
        #expect(childRect.y >= expectedContentRect.y, "Child should be within content area")
        #expect(childRect.x + childRect.width <= expectedContentRect.x + expectedContentRect.width, "Child should fit in content area")
        #expect(childRect.y + childRect.height <= expectedContentRect.y + expectedContentRect.height, "Child should fit in content area")
    }
}
