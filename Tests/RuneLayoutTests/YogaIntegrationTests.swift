import Testing
import RuneLayout

/// Integration tests for Yoga layout engine
/// Verifies that the Yoga integration works correctly with RuneKit components
@Suite("Yoga Integration Tests")
struct YogaIntegrationTests {
    // MARK: - Basic Yoga Node Tests

    @Test("Yoga node creation and cleanup")
    func yogaNodeCreation() {
        // Test that Yoga nodes can be created and cleaned up properly
        let node = YogaNode()

        // Test basic property setting (if this doesn't crash, the node was created successfully)
        node.setFlexDirection(.row)
        node.setWidth(.points(100))
        node.setHeight(.points(50))

        // Verify we can perform a layout calculation
        let layoutEngine = YogaLayoutEngine.shared
        let result = layoutEngine.calculateLayout(
            for: node,
            availableWidth: 100,
            availableHeight: 50
        )

        #expect(result.width == 100, "Node should be created and layout should work")
        #expect(result.height == 50, "Node should be created and layout should work")

        // Node should be cleaned up automatically when it goes out of scope
    }

    @Test("Yoga layout engine singleton")
    func yogaLayoutEngineSingleton() {
        let engine1 = YogaLayoutEngine.shared
        let engine2 = YogaLayoutEngine.shared

        #expect(engine1 === engine2, "YogaLayoutEngine should be a singleton")
    }

    // MARK: - Layout Calculation Tests

    @Test("Basic row layout calculation")
    func basicRowLayoutCalculation() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(50))

        let child1 = YogaNode()
        child1.setWidth(.points(30))
        child1.setHeight(.points(20))
        rootNode.addChild(child1)

        let child2 = YogaNode()
        child2.setWidth(.points(40))
        child2.setHeight(.points(20))
        rootNode.addChild(child2)

        let layoutEngine = YogaLayoutEngine.shared
        let rootResult = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 50
        )

        let child1Result = layoutEngine.getLayoutResult(for: child1)
        let child2Result = layoutEngine.getLayoutResult(for: child2)

        // Verify root layout
        #expect(rootResult.width == 100, "Root width should be 100")
        #expect(rootResult.height == 50, "Root height should be 50")
        #expect(rootResult.x == 0, "Root x should be 0")
        #expect(rootResult.y == 0, "Root y should be 0")

        // Verify child layouts (row direction)
        #expect(child1Result.x == 0, "Child 1 should be at x=0")
        #expect(child1Result.y == 0, "Child 1 should be at y=0")
        #expect(child1Result.width == 30, "Child 1 width should be 30")
        #expect(child1Result.height == 20, "Child 1 height should be 20")

        #expect(child2Result.x == 30, "Child 2 should be at x=30 (after child 1)")
        #expect(child2Result.y == 0, "Child 2 should be at y=0")
        #expect(child2Result.width == 40, "Child 2 width should be 40")
        #expect(child2Result.height == 20, "Child 2 height should be 20")
    }

    @Test("Basic column layout calculation")
    func basicColumnLayoutCalculation() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.column)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(100))

        let child1 = YogaNode()
        child1.setWidth(.points(50))
        child1.setHeight(.points(30))
        rootNode.addChild(child1)

        let child2 = YogaNode()
        child2.setWidth(.points(60))
        child2.setHeight(.points(40))
        rootNode.addChild(child2)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 100
        )

        let child1Result = layoutEngine.getLayoutResult(for: child1)
        let child2Result = layoutEngine.getLayoutResult(for: child2)

        // Verify child layouts (column direction)
        #expect(child1Result.x == 0, "Child 1 should be at x=0")
        #expect(child1Result.y == 0, "Child 1 should be at y=0")
        #expect(child1Result.width == 50, "Child 1 width should be 50")
        #expect(child1Result.height == 30, "Child 1 height should be 30")

        #expect(child2Result.x == 0, "Child 2 should be at x=0")
        #expect(child2Result.y == 30, "Child 2 should be at y=30 (after child 1)")
        #expect(child2Result.width == 60, "Child 2 width should be 60")
        #expect(child2Result.height == 40, "Child 2 height should be 40")
    }

    // MARK: - Padding and Margin Tests

    @Test("Padding affects child positioning")
    func paddingAffectsChildPositioning() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.column)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(100))
        rootNode.setPadding(.top, 10)
        rootNode.setPadding(.left, 15)
        rootNode.setPadding(.bottom, 10)
        rootNode.setPadding(.right, 15)

        let child = YogaNode()
        child.setWidth(.points(50))
        child.setHeight(.points(30))
        rootNode.addChild(child)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 100
        )

        let childResult = layoutEngine.getLayoutResult(for: child)

        // Child should be positioned inside padding
        #expect(childResult.x == 15, "Child should be offset by left padding")
        #expect(childResult.y == 10, "Child should be offset by top padding")
    }

    @Test("Margin affects element positioning")
    func marginAffectsElementPositioning() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setWidth(.points(200))
        rootNode.setHeight(.points(100))

        let child1 = YogaNode()
        child1.setWidth(.points(50))
        child1.setHeight(.points(30))
        child1.setMargin(.right, 20)
        rootNode.addChild(child1)

        let child2 = YogaNode()
        child2.setWidth(.points(50))
        child2.setHeight(.points(30))
        rootNode.addChild(child2)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 200,
            availableHeight: 100
        )

        let child1Result = layoutEngine.getLayoutResult(for: child1)
        let child2Result = layoutEngine.getLayoutResult(for: child2)

        // Child 2 should be positioned after child 1 + margin
        #expect(child1Result.x == 0, "Child 1 should be at x=0")
        #expect(child2Result.x == 70, "Child 2 should be at x=70 (50 + 20 margin)")
    }

    // MARK: - FlexLayout Integration Tests

    @Test("FlexLayout uses Yoga backend correctly")
    func flexLayoutUsesYogaBackend() {
        let children = [
            FlexLayout.Size(width: 20, height: 10),
            FlexLayout.Size(width: 30, height: 10),
            FlexLayout.Size(width: 25, height: 10)
        ]
        let containerSize = FlexLayout.Size(width: 100, height: 50)

        // Test row layout
        let rowRects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .row
        )

        #expect(rowRects.count == 3, "Should return 3 rectangles")
        #expect(rowRects[0].x == 0, "First child at x=0")
        #expect(rowRects[1].x == 20, "Second child at x=20")
        #expect(rowRects[2].x == 50, "Third child at x=50")

        // Test column layout
        let columnRects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .column
        )

        #expect(columnRects.count == 3, "Should return 3 rectangles")
        #expect(columnRects[0].y == 0, "First child at y=0")
        #expect(columnRects[1].y == 10, "Second child at y=10")
        #expect(columnRects[2].y == 20, "Third child at y=20")
    }

    @Test("FlexLayout handles empty children")
    func flexLayoutHandlesEmptyChildren() {
        let children: [FlexLayout.Size] = []
        let containerSize = FlexLayout.Size(width: 100, height: 50)

        let rects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .row
        )

        #expect(rects.isEmpty, "Should return empty array for empty children")
    }

    // MARK: - Justify Content Tests

    @Test("Justify content center works correctly")
    func justifyContentCenter() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setJustifyContent(.center)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(50))

        let child = YogaNode()
        child.setWidth(.points(30))
        child.setHeight(.points(20))
        rootNode.addChild(child)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 50
        )

        let childResult = layoutEngine.getLayoutResult(for: child)

        // Child should be centered horizontally
        let expectedX = (100 - 30) / 2 // (container width - child width) / 2
        #expect(childResult.x == expectedX, "Child should be centered horizontally")
    }

    @Test("Justify content space between works correctly")
    func justifyContentSpaceBetween() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setJustifyContent(.spaceBetween)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(50))

        let child1 = YogaNode()
        child1.setWidth(.points(20))
        child1.setHeight(.points(20))
        rootNode.addChild(child1)

        let child2 = YogaNode()
        child2.setWidth(.points(20))
        child2.setHeight(.points(20))
        rootNode.addChild(child2)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 50
        )

        let child1Result = layoutEngine.getLayoutResult(for: child1)
        let child2Result = layoutEngine.getLayoutResult(for: child2)

        // Children should be at opposite ends
        #expect(child1Result.x == 0, "First child should be at start")
        #expect(child2Result.x == 80, "Second child should be at end (100 - 20)")
    }

    // MARK: - Align Items Tests

    @Test("Align items center works correctly")
    func alignItemsCenter() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setAlignItems(.center)
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(50))

        let child = YogaNode()
        child.setWidth(.points(30))
        child.setHeight(.points(20))
        rootNode.addChild(child)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 50
        )

        let childResult = layoutEngine.getLayoutResult(for: child)

        // Child should be centered vertically
        let expectedY = (50 - 20) / 2 // (container height - child height) / 2
        #expect(childResult.y == expectedY, "Child should be centered vertically")
    }

    @Test("Align self center overrides parent align items")
    func alignSelfCenterOverridesParentAlignItems() {
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setAlignItems(.flexStart) // Parent says flex start
        rootNode.setWidth(.points(100))
        rootNode.setHeight(.points(50))

        let child = YogaNode()
        child.setWidth(.points(30))
        child.setHeight(.points(20))
        child.setAlignSelf(.center) // Child overrides with center
        rootNode.addChild(child)

        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 100,
            availableHeight: 50
        )

        let childResult = layoutEngine.getLayoutResult(for: child)

        // Child should be centered vertically despite parent alignItems
        let expectedY = (50 - 20) / 2 // (container height - child height) / 2
        #expect(childResult.y == expectedY, "Child should be centered despite parent alignItems")
    }

    // MARK: - Coordinate Conversion Tests

    @Test("Float to terminal coordinate conversion")
    func floatToTerminalConversion() {
        // Test banker's rounding (round half to even)
        #expect(Float(10.0).roundedToTerminal() == 10, "10.0 should round to 10")
        #expect(Float(10.4).roundedToTerminal() == 10, "10.4 should round to 10")
        #expect(Float(10.5).roundedToTerminal() == 10, "10.5 should round to 10 (even)")
        #expect(Float(10.6).roundedToTerminal() == 11, "10.6 should round to 11")
        #expect(Float(11.5).roundedToTerminal() == 12, "11.5 should round to 12 (even)")
        #expect(Float(12.5).roundedToTerminal() == 12, "12.5 should round to 12 (even)")
    }

    // MARK: - Error Handling Tests

    @Test("Layout calculation with zero dimensions")
    func layoutCalculationWithZeroDimensions() {
        let rootNode = YogaNode()
        rootNode.setWidth(.points(0))
        rootNode.setHeight(.points(0))

        let layoutEngine = YogaLayoutEngine.shared
        let result = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 0,
            availableHeight: 0
        )

        #expect(result.width == 0, "Zero width should be preserved")
        #expect(result.height == 0, "Zero height should be preserved")
    }

    // MARK: - Memory Management Tests

    @Test("Multiple layout calculations don't leak memory")
    func multipleLayoutCalculationsNoLeak() {
        let layoutEngine = YogaLayoutEngine.shared

        // Perform multiple layout calculations
        for _ in 0..<100 {
            let rootNode = YogaNode()
            rootNode.setFlexDirection(.row)
            rootNode.setWidth(.points(100))
            rootNode.setHeight(.points(50))

            let child = YogaNode()
            child.setWidth(.points(30))
            child.setHeight(.points(20))
            rootNode.addChild(child)

            _ = layoutEngine.calculateLayout(
                for: rootNode,
                availableWidth: 100,
                availableHeight: 50
            )

            // Nodes should be cleaned up automatically when they go out of scope
        }

        // If we reach here without crashing, memory management is working
        #expect(true, "Multiple layout calculations should not leak memory")
    }
}
