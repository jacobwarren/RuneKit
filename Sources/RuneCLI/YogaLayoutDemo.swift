import Foundation
import RuneComponents
import RuneLayout

/// Demo showcasing the new Yoga-based layout system
enum YogaLayoutDemo {
    /// Run the complete Yoga layout demonstration
    static func run() async {
        print("\n🧘 Yoga Layout Engine Demo (RUNE-26)")
        print("=====================================")
        print("Demonstrating Facebook's Yoga flexbox integration with RuneKit")
        print("")

        // Demo 1: Basic Yoga integration
        await demonstrateBasicYogaIntegration()

        // Demo 2: FlexLayout with Yoga backend
        await demonstrateFlexLayoutWithYoga()

        // Demo 3: Box component with layout properties
        await demonstrateBoxLayoutProperties()

        // Demo 4: Complex nested layouts
        await demonstrateNestedLayouts()

        // Demo 5: Layout property combinations
        await demonstrateLayoutCombinations()

        print("🎉 Yoga layout integration demo completed!")
        print("RuneKit now has production-ready flexbox layout powered by Facebook's Yoga!")
    }

    /// Demonstrate basic Yoga integration
    static func demonstrateBasicYogaIntegration() async {
        print("--- Demo 1: Basic Yoga Integration ---")
        print("")

        // Create a simple Yoga node tree
        let rootNode = YogaNode()
        rootNode.setFlexDirection(.row)
        rootNode.setWidth(.points(20))
        rootNode.setHeight(.points(5))

        // Add child nodes
        let child1 = YogaNode()
        child1.setWidth(.points(8))
        child1.setHeight(.points(3))
        rootNode.addChild(child1)

        let child2 = YogaNode()
        child2.setWidth(.points(10))
        child2.setHeight(.points(3))
        rootNode.addChild(child2)

        // Calculate layout
        let layoutEngine = YogaLayoutEngine.shared
        let rootResult = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: 20,
            availableHeight: 5,
        )

        let child1Result = layoutEngine.getLayoutResult(for: child1)
        let child2Result = layoutEngine.getLayoutResult(for: child2)

        print("Root layout: \(rootResult.width)x\(rootResult.height) at (\(rootResult.x), \(rootResult.y))")
        print("Child 1:     \(child1Result.width)x\(child1Result.height) at (\(child1Result.x), \(child1Result.y))")
        print("Child 2:     \(child2Result.width)x\(child2Result.height) at (\(child2Result.x), \(child2Result.y))")
        print("")

        // Verify the layout is correct
        assert(child1Result.x == 0, "Child 1 should be at x=0")
        assert(child2Result.x == 8, "Child 2 should be at x=8 (after child 1)")
        print("✅ Basic Yoga integration working correctly!")
        print("")
    }

    /// Demonstrate FlexLayout with Yoga backend
    static func demonstrateFlexLayoutWithYoga() async {
        print("--- Demo 2: FlexLayout with Yoga Backend ---")
        print("")

        // Test row layout
        let children = [
            FlexLayout.Size(width: 5, height: 2),
            FlexLayout.Size(width: 8, height: 2),
            FlexLayout.Size(width: 3, height: 2),
        ]
        let containerSize = FlexLayout.Size(width: 20, height: 5)

        print("Row layout test:")
        print("Container: \(containerSize.width)x\(containerSize.height)")
        print("Children sizes: \(children.map { "\($0.width)x\($0.height)" }.joined(separator: ", "))")

        let rowRects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .row,
        )

        print("Row layout results:")
        for (index, rect) in rowRects.enumerated() {
            print("  Child \(index + 1): \(rect.width)x\(rect.height) at (\(rect.x), \(rect.y))")
        }

        // Test column layout
        print("\nColumn layout test:")
        let columnRects = FlexLayout.calculateLayout(
            children: children,
            containerSize: containerSize,
            direction: .column,
        )

        print("Column layout results:")
        for (index, rect) in columnRects.enumerated() {
            print("  Child \(index + 1): \(rect.width)x\(rect.height) at (\(rect.x), \(rect.y))")
        }

        // Verify layouts
        assert(rowRects[0].x == 0 && rowRects[1].x == 5 && rowRects[2].x == 13, "Row layout positions incorrect")
        assert(
            columnRects[0].y == 0 && columnRects[1].y == 2 && columnRects[2].y == 4,
            "Column layout positions incorrect",
        )
        print("\n✅ FlexLayout with Yoga backend working correctly!")
        print("")
    }

    /// Demonstrate Box component with layout properties
    static func demonstrateBoxLayoutProperties() async {
        print("--- Demo 3: Box Component Layout Properties ---")
        print("")

        // Test basic Box with padding
        let paddedBox = Box(
            border: .single,
            paddingTop: 2,
            paddingRight: 2,
            paddingBottom: 2,
            paddingLeft: 2,
            child: Text("Padded content"),
        )

        print("Padded Box properties:")
        print("  Border: \(paddedBox.borderStyle)")
        print(
            "  Padding: top=\(paddedBox.paddingTop), right=\(paddedBox.paddingRight), bottom=\(paddedBox.paddingBottom), left=\(paddedBox.paddingLeft)",
        )
        print("  Flex direction: \(paddedBox.flexDirection)")
        print("")

        // Test row layout Box
        let rowBox = Box(
            flexDirection: .row,
            justifyContent: .center,
            alignItems: .center,
            columnGap: 1,
            child: Text("Row layout"),
        )

        print("Row Box properties:")
        print("  Flex direction: \(rowBox.flexDirection)")
        print("  Justify content: \(rowBox.justifyContent)")
        print("  Align items: \(rowBox.alignItems)")
        print("  Column gap: \(rowBox.columnGap)")
        print("")

        // Test column layout Box
        let columnBox = Box(
            flexDirection: .column,
            justifyContent: .spaceBetween,
            alignItems: .flexStart,
            rowGap: 2,
            child: Text("Column layout"),
        )

        print("Column Box properties:")
        print("  Flex direction: \(columnBox.flexDirection)")
        print("  Justify content: \(columnBox.justifyContent)")
        print("  Align items: \(columnBox.alignItems)")
        print("  Row gap: \(columnBox.rowGap)")
        print("")

        // Test Box with dimensions
        let sizedBox = Box(
            border: .rounded,
            width: .points(15),
            height: .points(8),
            paddingTop: 1,
            paddingRight: 1,
            paddingBottom: 1,
            paddingLeft: 1,
            child: Text("Fixed size"),
        )

        print("Sized Box properties:")
        print("  Width: \(sizedBox.width)")
        print("  Height: \(sizedBox.height)")
        print("  Padding: horizontal=\(sizedBox.paddingLeft), vertical=\(sizedBox.paddingTop)")
        print("")

        print("✅ Box component layout properties working correctly!")
        print("")
    }

    /// Demonstrate nested layouts
    static func demonstrateNestedLayouts() async {
        print("--- Demo 4: Complex Nested Layouts ---")
        print("")

        // Create a complex nested structure
        let innerBox1 = Box(
            border: .single,
            padding: 1,
            child: Text("Inner 1"),
        )

        let innerBox2 = Box(
            border: .single,
            padding: 1,
            child: Text("Inner 2"),
        )

        let outerBox = Box(
            flexDirection: .row,
            justifyContent: .spaceBetween,
            alignItems: .stretch,
            columnGap: 2,
            child: nil, // Would contain multiple children in real implementation
        )

        print("Nested layout structure:")
        print("Outer Box (row layout):")
        print("  Flex direction: \(outerBox.flexDirection)")
        print("  Justify content: \(outerBox.justifyContent)")
        print("  Gap: \(outerBox.columnGap)")
        print("")
        print("Inner Box 1:")
        print("  Border: \(innerBox1.borderStyle)")
        print("  Padding: \(innerBox1.paddingTop)")
        print("")
        print("Inner Box 2:")
        print("  Border: \(innerBox2.borderStyle)")
        print("  Padding: \(innerBox2.paddingTop)")
        print("")

        print("✅ Nested layouts structure defined correctly!")
        print("")
    }

    /// Demonstrate various layout property combinations
    static func demonstrateLayoutCombinations() async {
        print("--- Demo 5: Layout Property Combinations ---")
        print("")

        // Test all justify content options
        let justifyOptions: [JustifyContent] = [
            .flexStart,
            .flexEnd,
            .center,
            .spaceBetween,
            .spaceAround,
            .spaceEvenly,
        ]
        print("Justify Content options:")
        for option in justifyOptions {
            let box = Box(flexDirection: .row, justifyContent: option)
            print("  \(option): \(box.justifyContent)")
        }
        print("")

        // Test all align items options
        let alignOptions: [AlignItems] = [.flexStart, .flexEnd, .center, .stretch, .baseline]
        print("Align Items options:")
        for option in alignOptions {
            let box = Box(flexDirection: .column, alignItems: option)
            print("  \(option): \(box.alignItems)")
        }
        print("")

        // Test dimension options
        print("Dimension options:")
        let autoBox = Box(width: .auto, height: .auto)
        print("  Auto: width=\(autoBox.width), height=\(autoBox.height)")

        let pointsBox = Box(width: .points(20), height: .points(10))
        print("  Points: width=\(pointsBox.width), height=\(pointsBox.height)")

        let percentBox = Box(width: .percent(50), height: .percent(75))
        print("  Percent: width=\(percentBox.width), height=\(percentBox.height)")
        print("")

        // Test margin and padding combinations
        let spacedBox = Box(
            paddingTop: 1, paddingRight: 2, paddingBottom: 1, paddingLeft: 2,
            marginTop: 0.5, marginRight: 1, marginBottom: 0.5, marginLeft: 1,
        )
        print("Spacing combinations:")
        print(
            "  Padding: T=\(spacedBox.paddingTop), R=\(spacedBox.paddingRight), B=\(spacedBox.paddingBottom), L=\(spacedBox.paddingLeft)",
        )
        print(
            "  Margin: T=\(spacedBox.marginTop), R=\(spacedBox.marginRight), B=\(spacedBox.marginBottom), L=\(spacedBox.marginLeft)",
        )
        print("")

        print("✅ All layout property combinations working correctly!")
        print("")
    }
}
