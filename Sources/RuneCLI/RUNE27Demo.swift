import Foundation
import RuneComponents
import RuneLayout

/// Demo for RUNE-27: Box layout with padding/margin/gap
public struct RUNE27Demo {
    public static func run() {
        runBasicDemo()
        runRowLayoutDemo()
        runColumnLayoutDemo()
        runNestedLayoutDemo()
        runFixedDimensionsDemo()
        runBorderDemo()
        printSummary()
    }

    private static func runBasicDemo() {
        print("🎯 RUNE-27 Demo: Box Layout with Padding/Margin/Gap")
        print("=" * 60)

        print("\n📦 Demo 1: Box with padding and margin")
        let basicBox = Box(
            paddingTop: 2,
            paddingRight: 3,
            paddingBottom: 2,
            paddingLeft: 3,
            marginTop: 1,
            marginRight: 1,
            marginBottom: 1,
            marginLeft: 1,
            child: Text("Hello, World!")
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let layout1 = basicBox.calculateLayout(in: containerRect)

        print("Container: \(containerRect)")
        print("Box rect:  \(layout1.boxRect)")
        print("Content:   \(layout1.contentRect)")
    }

    private static func runRowLayoutDemo() {
        print("\n🔄 Demo 2: Row layout - comparing gap vs Spacer")

        // Old way: using columnGap
        print("\n  📏 Using columnGap (old way):")
        let rowBoxWithGap = Box(
            flexDirection: .row,
            columnGap: 2,
            children: Text("First"), Text("Second"), Text("Third")
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let layoutWithGap = rowBoxWithGap.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        print("Children:")
        for (index, rect) in layoutWithGap.childRects.enumerated() {
            print("      Child \(index): \(rect)")
        }

        // New way: using Spacer for flexible spacing
        print("\n  🚀 Using Spacer (new way - flexible spacing):")
        let rowBoxWithSpacer = Box(
            flexDirection: .row,
            children: Text("Left"), Spacer(), Text("Center"), Spacer(), Text("Right")
        )

        let layoutWithSpacer = rowBoxWithSpacer.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        for (index, rect) in layoutWithSpacer.childRects.enumerated() {
            let componentType = index % 2 == 0 ? "Text" : "Spacer"
            print("      \(componentType) \(index): \(rect)")
        }
    }

    private static func runColumnLayoutDemo() {
        print("\n📋 Demo 3: Column layout - comparing gap vs Spacer")

        // Old way: using rowGap
        print("\n  📏 Using rowGap (old way):")
        let columnBoxWithGap = Box(
            flexDirection: .column,
            rowGap: 1,
            children: Text("Item A"), Text("Item B"), Text("Item C")
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let layoutWithGap = columnBoxWithGap.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        print("Children:")
        for (index, rect) in layoutWithGap.childRects.enumerated() {
            print("      Child \(index): \(rect)")
        }

        // New way: using Spacer for flexible spacing
        print("\n  🚀 Using Spacer (new way - push to edges):")
        let columnBoxWithSpacer = Box(
            flexDirection: .column,
            children: Text("Header"), Spacer(), Text("Footer")
        )

        let layoutWithSpacer = columnBoxWithSpacer.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        for (index, rect) in layoutWithSpacer.childRects.enumerated() {
            let componentType = index == 1 ? "Spacer" : "Text"
            print("      \(componentType) \(index): \(rect)")
        }
    }

    private static func runNestedLayoutDemo() {
        print("\n🏗️  Demo 4: Nested boxes - comparing gap vs Spacer")

        // Old way: using columnGap
        print("\n  📏 Using columnGap (old way):")
        let nestedBoxWithGap = Box(
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Box(
                flexDirection: .row,
                columnGap: 1,
                children: Text("Left"), Text("Right")
            )
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let layoutWithGap = nestedBoxWithGap.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        print("    Outer box: \(layoutWithGap.boxRect)")
        print("    Content:   \(layoutWithGap.contentRect)")

        // Get inner layout
        if let innerBox = nestedBoxWithGap.child as? Box {
            let innerLayout = innerBox.calculateLayout(in: layoutWithGap.contentRect)
            print("    Inner children:")
            for (index, rect) in innerLayout.childRects.enumerated() {
                print("      Child \(index): \(rect)")
            }
        }

        // New way: using Spacer to push elements apart
        print("\n  🚀 Using Spacer (new way - push apart):")
        let nestedBoxWithSpacer = Box(
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Box(
                flexDirection: .row,
                children: Text("Left"), Spacer(), Text("Right")
            )
        )

        let layoutWithSpacer = nestedBoxWithSpacer.calculateLayout(in: containerRect)
        print("    Container: \(containerRect)")
        print("    Outer box: \(layoutWithSpacer.boxRect)")
        print("    Content:   \(layoutWithSpacer.contentRect)")

        // Get inner layout
        if let innerBox = nestedBoxWithSpacer.child as? Box {
            let innerLayout = innerBox.calculateLayout(in: layoutWithSpacer.contentRect)
            print("    Inner children:")
            for (index, rect) in innerLayout.childRects.enumerated() {
                let componentType = index == 1 ? "Spacer" : "Text"
                print("      \(componentType) \(index): \(rect)")
            }
        }
    }

    private static func runFixedDimensionsDemo() {
        print("\n📏 Demo 5: Fixed dimensions")
        let fixedBox = Box(
            width: .points(15),
            height: .points(6),
            paddingTop: 1,
            paddingRight: 1,
            paddingBottom: 1,
            paddingLeft: 1,
            child: Text("Fixed Size")
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 10)
        let layout5 = fixedBox.calculateLayout(in: containerRect)
        print("Container: \(containerRect)")
        print("Fixed box: \(layout5.boxRect)")
        print("Content:   \(layout5.contentRect)")
    }

    private static func printSummary() {
        print("\n✅ RUNE-27 implementation complete!")
        print("Features implemented:")
        print("  • Row/column direction")
        print("  • Padding per-edge (top, right, bottom, left)")
        print("  • Margin per-edge (top, right, bottom, left)")
        print("  • Column and row gaps")
        print("  • Fixed and percentage dimensions")
        print("  • Nested layouts")
        print("  • Proper coordinate rounding")
        print("  • Intrinsic sizing for Text components")
        print("  • Border rendering with proper layout integration")
    }

    /// Demo showing Box component with border rendering
    public static func runBorderDemo() {
        print("\n🎨 RUNE-27 Border Demo: Box with Proper Border Rendering")
        print("=" * 60)

        // Demo 1: Simple bordered box
        print("\n📦 Demo 1: Simple bordered box")
        let borderedBox = Box(
            border: .single,
            paddingTop: 1,
            paddingRight: 2,
            paddingBottom: 1,
            paddingLeft: 2,
            child: Text("Hello, Borders!")
        )

        let rect1 = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 5)
        let lines1 = borderedBox.render(in: rect1)

        print("Rendered output:")
        for line in lines1 {
            print("  \(line)")
        }

        // Demo 2: Different border styles
        print("\n🎭 Demo 2: Different border styles")
        let styles: [(Box.BorderStyle, String)] = [
            (.single, "Single"),
            (.double, "Double"),
            (.rounded, "Rounded")
        ]

        for (style, name) in styles {
            let styledBox = Box(
                border: style,
                paddingTop: 0,
                paddingRight: 1,
                paddingBottom: 0,
                paddingLeft: 1,
                child: Text(name)
            )

            let rect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 3)
            let lines = styledBox.render(in: rect)

            print("\n\(name) border:")
            for line in lines {
                print("  \(line)")
            }
        }

        print("\n✅ Border rendering demo complete!")
        print("This shows how Box components now properly render borders")
        print("using the layout system and width calculations.")
    }
}

extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
