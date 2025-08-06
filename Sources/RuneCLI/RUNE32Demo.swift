import Foundation
import RuneComponents
import RuneLayout

/// RUNE-32: Spacer and Alignment Properties Demo
/// 
/// This demo showcases:
/// - Spacer component usage in row and column layouts
/// - AlignSelf property overriding parent alignItems
/// - Comprehensive alignment combinations
/// - Real-world layout patterns using Spacer
public struct RUNE32Demo {
    
    /// Run the complete RUNE-32 demo
    public static func run() {
        print("\n🎯 RUNE-32: Spacer and Alignment Properties Demo")
        print("=================================================")
        print("Demonstrating flexible spacing and precise alignment control")
        print("")
        
        spacerBasicsDemo()
        alignSelfDemo()
        alignmentMatrixDemo()
        realWorldLayoutsDemo()
        
        print("\n✅ RUNE-32 Demo completed!")
        print("Spacer and alignment properties provide powerful layout control!")
    }
    
    // MARK: - Spacer Basics
    
    private static func spacerBasicsDemo() {
        print("📏 Demo 1: Spacer Basics")
        print("========================")
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 40, height: 8)
        
        // Row layout: Push elements apart
        print("\n🔄 Row Layout - Push Apart:")
        let rowLayout = Box(
            flexDirection: .row,
            children: Text("Start"), Spacer(), Text("End")
        )
        
        let rowResult = rowLayout.calculateLayout(in: containerRect)
        print("  Container: \(containerRect)")
        for (index, rect) in rowResult.childRects.enumerated() {
            let type = index == 1 ? "Spacer" : "Text"
            print("    \(type): \(rect)")
        }
        
        // Column layout: Push to top and bottom
        print("\n📋 Column Layout - Push to Edges:")
        let columnLayout = Box(
            flexDirection: .column,
            children: Text("Header"), Spacer(), Text("Footer")
        )
        
        let columnResult = columnLayout.calculateLayout(in: containerRect)
        print("  Container: \(containerRect)")
        for (index, rect) in columnResult.childRects.enumerated() {
            let type = index == 1 ? "Spacer" : "Text"
            print("    \(type): \(rect)")
        }
        
        // Multiple spacers: Even distribution
        print("\n⚖️  Multiple Spacers - Even Distribution:")
        let evenDistribution = Box(
            flexDirection: .row,
            children: Text("A"), Spacer(), Text("B"), Spacer(), Text("C"), Spacer(), Text("D")
        )
        
        let evenResult = evenDistribution.calculateLayout(in: containerRect)
        print("  Container: \(containerRect)")
        for (index, rect) in evenResult.childRects.enumerated() {
            let type = index % 2 == 0 ? "Text" : "Spacer"
            print("    \(type): \(rect)")
        }
    }
    
    // MARK: - AlignSelf Demo
    
    private static func alignSelfDemo() {
        print("\n🎯 Demo 2: AlignSelf Property")
        print("=============================")
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 30, height: 12)
        
        // AlignSelf overriding parent alignItems
        print("\n🔄 AlignSelf Override (Row Layout):")
        let alignSelfRow = Box(
            flexDirection: .row,
            alignItems: .flexStart, // Parent says: align to start
            width: .points(30),
            height: .points(12),
            children: 
                Box(alignSelf: .auto, width: .points(4), height: .points(2)),      // Inherits flexStart
                Box(alignSelf: .center, width: .points(4), height: .points(2)),    // Override: center
                Box(alignSelf: .flexEnd, width: .points(4), height: .points(2)),   // Override: end
                Box(alignSelf: .stretch, width: .points(4))                        // Override: stretch
        )
        
        let alignSelfResult = alignSelfRow.calculateLayout(in: containerRect)
        print("  Container: \(containerRect)")
        print("  Parent alignItems: flexStart")
        
        let alignSelfLabels = ["auto(→start)", "center", "flexEnd", "stretch"]
        for (index, rect) in alignSelfResult.childRects.enumerated() {
            print("    Child \(index) (\(alignSelfLabels[index])): \(rect)")
        }
        
        // Column layout with alignSelf
        print("\n📋 AlignSelf Override (Column Layout):")
        let alignSelfColumn = Box(
            flexDirection: .column,
            alignItems: .flexEnd, // Parent says: align to end
            width: .points(30),
            height: .points(12),
            children:
                Box(alignSelf: .auto, width: .points(4), height: .points(2)),      // Inherits flexEnd
                Box(alignSelf: .center, width: .points(4), height: .points(2)),    // Override: center
                Box(alignSelf: .flexStart, width: .points(4), height: .points(2))  // Override: start
        )
        
        let columnResult = alignSelfColumn.calculateLayout(in: containerRect)
        print("  Container: \(containerRect)")
        print("  Parent alignItems: flexEnd")
        
        let columnLabels = ["auto(→end)", "center", "flexStart"]
        for (index, rect) in columnResult.childRects.enumerated() {
            print("    Child \(index) (\(columnLabels[index])): \(rect)")
        }
    }
    
    // MARK: - Alignment Matrix
    
    private static func alignmentMatrixDemo() {
        print("\n🎯 Demo 3: Alignment Matrix")
        print("============================")
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)
        
        // Test key alignment combinations
        let alignmentCombos: [(JustifyContent, AlignItems, String)] = [
            (.flexStart, .flexStart, "start-start"),
            (.center, .center, "center-center"),
            (.flexEnd, .flexEnd, "end-end"),
            (.spaceBetween, .center, "space-between-center"),
            (.spaceAround, .stretch, "space-around-stretch")
        ]
        
        for (justify, align, label) in alignmentCombos {
            print("\n🎯 \(label.uppercased()):")
            
            let alignmentBox = Box(
                flexDirection: .row,
                justifyContent: justify,
                alignItems: align,
                width: .points(20),
                height: .points(10),
                children: Box(width: .points(3), height: .points(2)),
                         Box(width: .points(3), height: .points(2)),
                         Box(width: .points(3), height: .points(2))
            )
            
            let result = alignmentBox.calculateLayout(in: containerRect)
            print("  justifyContent: \(justify), alignItems: \(align)")
            print("  Container: \(containerRect)")
            for (index, rect) in result.childRects.enumerated() {
                print("    Child \(index): \(rect)")
            }
        }
    }
    
    // MARK: - Real-World Layouts
    
    private static func realWorldLayoutsDemo() {
        print("\n🎯 Demo 4: Real-World Layout Patterns")
        print("======================================")
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 50, height: 15)
        
        // Navigation bar pattern
        print("\n🧭 Navigation Bar Pattern:")
        let navBar = Box(
            flexDirection: .row,
            alignItems: .center,
            width: .points(50),
            height: .points(3),
            children: Text("← Back"), Spacer(), Text("Page Title"), Spacer(), Text("Menu ☰")
        )
        
        let navResult = navBar.calculateLayout(in: FlexLayout.Rect(x: 0, y: 0, width: 50, height: 3))
        print("  Navigation Layout:")
        let navLabels = ["Back", "Spacer", "Title", "Spacer", "Menu"]
        for (index, rect) in navResult.childRects.enumerated() {
            print("    \(navLabels[index]): \(rect)")
        }
        
        // Card layout pattern
        print("\n🃏 Card Layout Pattern:")
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
        print("  Card Layout:")
        print("    Title: \(cardResult.childRects[0])")
        print("    Content Spacer: \(cardResult.childRects[1])")
        print("    Button Row: \(cardResult.childRects[2])")
        
        // Sidebar layout pattern
        print("\n📱 Sidebar Layout Pattern:")
        let sidebarLayout = Box(
            flexDirection: .row,
            width: .points(50),
            height: .points(15),
            children: Box(
                        flexDirection: .column,
                        width: .points(12),
                        children: Text("Nav Item 1"), Text("Nav Item 2"), Spacer(), Text("Settings")
                     ),
                     Spacer(),
                     Box(
                        flexDirection: .column,
                        children: Text("Main Content"), Spacer(), Text("Status Bar")
                     )
        )
        
        let sidebarResult = sidebarLayout.calculateLayout(in: containerRect)
        print("  Sidebar Layout:")
        print("    Sidebar: \(sidebarResult.childRects[0])")
        print("    Content Spacer: \(sidebarResult.childRects[1])")
        print("    Main Area: \(sidebarResult.childRects[2])")
    }
}
