import Testing
@testable import RuneLayout

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
}
