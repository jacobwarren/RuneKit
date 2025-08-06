import Testing
@testable import RuneLayout
@testable import RuneComponents

/// Tests for flexbox layout functionality following TDD principles
struct FlexLayoutTests {
    // MARK: - Basic Layout Tests

    @Test("Empty children array returns empty rects")
    func emptyChildrenLayout() {
        // Arrange
        let children: [FlexLayout.Size] = []
        let containerSize = FlexLayout.Size(width: 10, height: 5)

        // Act
        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
        )

        // Assert
        #expect(rects.isEmpty, "Empty children should return empty rects array")
    }

    @Test("Single child layout")
    func singleChildLayout() {
        // Arrange
        let children = [FlexLayout.Size(width: 5, height: 3)]
        let containerSize = FlexLayout.Size(width: 10, height: 5)

        // Act
        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
        )

        // Assert
        let expected = [FlexLayout.Rect(x: 0, y: 0, width: 5, height: 3)]
        #expect(rects == expected, "Single child should be positioned at origin")
    }

    @Test("Multiple children in row direction")
    func multipleChildrenRowLayout() {
        // Arrange
        let children = [
            FlexLayout.Size(width: 3, height: 2),
            FlexLayout.Size(width: 4, height: 2),
            FlexLayout.Size(width: 2, height: 2),
        ]
        let containerSize = FlexLayout.Size(width: 15, height: 5)

        // Act
        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .row,
        )

        // Assert
        let expected = [
            FlexLayout.Rect(x: 0, y: 0, width: 3, height: 2),
            FlexLayout.Rect(x: 3, y: 0, width: 4, height: 2),
            FlexLayout.Rect(x: 7, y: 0, width: 2, height: 2),
        ]
        #expect(rects == expected, "Children should be laid out horizontally")
    }

    @Test("Multiple children in column direction")
    func multipleChildrenColumnLayout() {
        // Arrange
        let children = [
            FlexLayout.Size(width: 5, height: 2),
            FlexLayout.Size(width: 5, height: 3),
            FlexLayout.Size(width: 5, height: 1),
        ]
        let containerSize = FlexLayout.Size(width: 10, height: 15)

        // Act
        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .column,
        )

        // Assert
        let expected = [
            FlexLayout.Rect(x: 0, y: 0, width: 5, height: 2),
            FlexLayout.Rect(x: 0, y: 2, width: 5, height: 3),
            FlexLayout.Rect(x: 0, y: 5, width: 5, height: 1),
        ]
        #expect(rects == expected, "Children should be laid out vertically")
    }

    // MARK: - Size and Rect Tests

    @Test("Size equality")
    func sizeEquality() {
        // Arrange
        let size1 = FlexLayout.Size(width: 10, height: 5)
        let size2 = FlexLayout.Size(width: 10, height: 5)
        let size3 = FlexLayout.Size(width: 8, height: 5)

        // Assert
        #expect(size1 == size2, "Identical sizes should be equal")
        #expect(size1 != size3, "Different sizes should not be equal")
    }

    @Test("Rect equality")
    func rectEquality() {
        // Arrange
        let rect1 = FlexLayout.Rect(x: 1, y: 2, width: 10, height: 5)
        let rect2 = FlexLayout.Rect(x: 1, y: 2, width: 10, height: 5)
        let rect3 = FlexLayout.Rect(x: 2, y: 2, width: 10, height: 5)

        // Assert
        #expect(rect1 == rect2, "Identical rects should be equal")
        #expect(rect1 != rect3, "Different rects should not be equal")
    }

    // MARK: - Box Layout Tests (RUNE-27)

    @Test("Box with padding produces correct layout")
    func boxWithPaddingLayout() {
        // Arrange
        let box = Box(
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Text("Content")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Content should be positioned inside padding
        // Container: 20x10, padding: top=1, right=2, bottom=1, left=2
        // Content area: x=2, y=1, width=16, height=8
        let expectedContentRect = FlexLayout.Rect(x: 2, y: 1, width: 16, height: 8)
        #expect(layout.contentRect == expectedContentRect, "Content should be positioned inside padding")
        #expect(layout.containerRect == containerRect, "Container rect should be preserved")
    }

    @Test("Box with margin affects positioning")
    func boxWithMarginLayout() {
        // Arrange
        let box = Box(
            marginTop: 2,
            marginRight: 1,
            marginBottom: 2,
            marginLeft: 1,
            child: Text("Content")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Margin should affect the box's position within its container
        // Available space: 20x10, margin: top=2, right=1, bottom=2, left=1
        // Box area: x=1, y=2, width=18, height=6
        let expectedBoxRect = FlexLayout.Rect(x: 1, y: 2, width: 18, height: 6)
        #expect(layout.boxRect == expectedBoxRect, "Box should be positioned with margin offset")
    }

    @Test("Box row layout with column gap")
    func boxRowLayoutWithGap() {
        // Arrange
        let children = [
            Text("First"),
            Text("Second"),
            Text("Third")
        ]
        let box = Box(
            flexDirection: .row,
            columnGap: 2,
            children: children
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 5)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Children should be laid out horizontally with 2-column gaps
        // Text intrinsic sizes: "First"=5, "Second"=6, "Third"=5
        // With 2-column gaps: 5 + 2 + 6 + 2 + 5 = 20 total width
        let expectedChildRects = [
            FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1),  // "First"
            FlexLayout.Rect(x: 7, y: 0, width: 6, height: 1),  // "Second" (5 + 2 gap)
            FlexLayout.Rect(x: 15, y: 0, width: 5, height: 1)  // "Third" (7 + 6 + 2 gap)
        ]
        #expect(layout.childRects == expectedChildRects, "Children should be spaced with column gap")
    }

    @Test("Box column layout with row gap")
    func boxColumnLayoutWithGap() {
        // Arrange
        let children = [
            Text("First"),
            Text("Second"),
            Text("Third")
        ]
        let box = Box(
            flexDirection: .column,
            rowGap: 1,
            children: children
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 15)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Children should be laid out vertically with 1-row gaps
        // Text intrinsic sizes: all have height=1, width="First"=5, "Second"=6, "Third"=5
        // With 1-row gaps: 1 + 1 + 1 + 1 + 1 = 5 total height
        let expectedChildRects = [
            FlexLayout.Rect(x: 0, y: 0, width: 5, height: 1),  // "First"
            FlexLayout.Rect(x: 0, y: 2, width: 6, height: 1),  // "Second" (1 + 1 gap)
            FlexLayout.Rect(x: 0, y: 4, width: 5, height: 1)   // "Third" (2 + 1 + 1 gap)
        ]
        #expect(layout.childRects == expectedChildRects, "Children should be spaced with row gap")
    }

    @Test("Box with fixed dimensions")
    func boxWithFixedDimensions() {
        // Arrange
        let box = Box(
            width: .points(15),
            height: .points(8),
            child: Text("Fixed")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 20)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Box should use fixed dimensions regardless of container size
        let expectedBoxRect = FlexLayout.Rect(x: 0, y: 0, width: 15, height: 8)
        #expect(layout.boxRect == expectedBoxRect, "Box should use fixed dimensions")
        #expect(layout.contentRect == expectedBoxRect, "Content should fill box when no padding")
    }

    @Test("Box with percentage dimensions")
    func boxWithPercentageDimensions() {
        // Arrange
        let box = Box(
            width: .percent(50),
            height: .percent(75),
            child: Text("Percent")
        )
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 12)

        // Act
        let layout = box.calculateLayout(in: containerRect)

        // Assert
        // Box should use percentage of container dimensions
        // 50% of 20 = 10, 75% of 12 = 9
        let expectedBoxRect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 9)
        #expect(layout.boxRect == expectedBoxRect, "Box should use percentage dimensions")
    }
}
