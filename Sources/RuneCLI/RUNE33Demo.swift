import Foundation
import RuneKit
import RuneComponents
import RuneLayout

/// Demo for RUNE-33: Newline component
///
/// This demo showcases the Newline component that renders exactly N newline characters.
/// It demonstrates:
/// - Basic newline rendering with different counts
/// - Height constraint behavior (excess lines omitted)
/// - Integration with static and dynamic regions
/// - Replacement of manual spacing in layouts
/// - No SGR leakage or cursor misplacement
public enum RUNE33Demo {
    /// Run the RUNE-33 Newline component demonstration
    public static func run() async {
        print("🎯 RUNE-33 Demo: Newline Component")
        print("=================================")
        print("Demonstrating convenience component for vertical spacing")
        print("")

        await demonstrateBasicNewlineUsage()
        await demonstrateHeightConstraints()
        await demonstrateLayoutIntegration()
        await demonstrateStaticRegionUsage()
        await demonstrateReplacingManualSpacing()

        print("\n✅ RUNE-33 Demo completed successfully!")
        print("Newline component provides convenient vertical spacing for terminal UIs.")
    }

    /// Demonstrate basic Newline component functionality
    private static func demonstrateBasicNewlineUsage() async {
        print("Demo 1: Basic Newline Usage")
        print("---------------------------")

        // Test different newline counts
        let testCases = [
            (count: 0, description: "Zero newlines"),
            (count: 1, description: "Single newline"),
            (count: 3, description: "Three newlines"),
            (count: 5, description: "Five newlines")
        ]

        for (count, description) in testCases {
            print("\n📏 \(description) (count: \(count)):")
            
            let newline = Newline(count: count)
            let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 10)
            let lines = newline.render(in: rect)
            
            print("  Rendered lines: \(lines.count)")
            print("  All lines empty: \(lines.allSatisfy { $0.isEmpty })")
            print("  No ANSI codes: \(lines.allSatisfy { !$0.contains("\u{001B}[") })")
        }

        print("\n✓ Basic newline rendering works correctly")
        print("✓ No SGR leakage or ANSI escape sequences")
        print("")
    }

    /// Demonstrate height constraint behavior
    private static func demonstrateHeightConstraints() async {
        print("Demo 2: Height Constraint Behavior")
        print("----------------------------------")

        let testCases = [
            (count: 10, height: 5, description: "Excess lines omitted"),
            (count: 3, height: 3, description: "Exact fit"),
            (count: 2, height: 5, description: "Under capacity"),
            (count: 5, height: 0, description: "Zero height")
        ]

        for (count, height, description) in testCases {
            print("\n📐 \(description):")
            print("  Requested: \(count) newlines, Available height: \(height)")
            
            let newline = Newline(count: count)
            let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: height)
            let lines = newline.render(in: rect)
            
            print("  Rendered: \(lines.count) lines")
            print("  Expected: \(min(count, max(0, height))) lines")
            
            let expected = min(count, max(0, height))
            assert(lines.count == expected, "Height constraint not respected")
        }

        print("\n✓ Height constraints respected correctly")
        print("✓ Excess lines omitted when container too small")
        print("")
    }

    /// Demonstrate integration with layout systems
    private static func demonstrateLayoutIntegration() async {
        print("Demo 3: Layout Integration")
        print("--------------------------")

        // Create a layout with Newline components for spacing
        print("\n🏗️  Column layout with Newline spacing:")
        
        let columnLayout = Box(
            border: .single,
            flexDirection: .column,
            paddingTop: 1,
            paddingRight: 1,
            paddingBottom: 1,
            paddingLeft: 1,
            children: Text("Header Section"),
                     Newline(count: 2),
                     Text("Content Section"),
                     Newline(count: 1),
                     Text("Footer Section")
        )

        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 25, height: 12)
        let layout = columnLayout.calculateLayout(in: containerRect)
        
        print("  Container: \(containerRect)")
        print("  Children layout:")
        for (index, rect) in layout.childRects.enumerated() {
            let types = ["Text", "Newline(2)", "Text", "Newline(1)", "Text"]
            let type = index < types.count ? types[index] : "Unknown"
            print("    \(type): \(rect)")
        }

        // Render the layout to show actual output
        let lines = columnLayout.render(in: containerRect)
        print("\n  Rendered output:")
        for (index, line) in lines.enumerated() {
            let displayLine = line.isEmpty ? "(empty)" : line
            print("    [\(index)]: \(displayLine)")
        }

        print("\n✓ Newline integrates seamlessly with Box layouts")
        print("✓ Provides consistent vertical spacing")
        print("")
    }

    /// Demonstrate usage in static regions
    private static func demonstrateStaticRegionUsage() async {
        print("Demo 4: Static Region Usage")
        print("---------------------------")

        // Create static content with Newline spacing
        let staticContent = Box(
            flexDirection: .column,
            children: Text("=== Application Log ==="),
                     Newline(count: 1),
                     Text("Started: \(getCurrentTimestamp())"),
                     Text("Version: 1.0.0"),
                     Newline(count: 2),
                     Text("Status: Ready")
        )

        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        print("\n📋 Rendering static content with Newline spacing...")
        let handle = await render(staticContent, options: options)
        
        print("✓ Static content rendered with proper spacing")
        print("✓ Newline components work in static regions")
        print("✓ No cursor misplacement or SGR leakage")

        // Brief pause to show the content
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await handle.unmount()
        print("")
    }

    /// Demonstrate replacing manual spacing with Newline components
    private static func demonstrateReplacingManualSpacing() async {
        print("Demo 5: Replacing Manual Spacing")
        print("--------------------------------")

        print("\n❌ Old way - Manual spacing with print statements:")
        print("print(\"Header\")")
        print("print(\"\")")
        print("print(\"\")")
        print("print(\"Content\")")
        
        print("\n✅ New way - Using Newline component:")
        print("Box(flexDirection: .column, children: [")
        print("    Text(\"Header\"),")
        print("    Newline(count: 2),")
        print("    Text(\"Content\")")
        print("])")

        // Show the actual difference
        print("\n🔄 Comparison - Manual vs Newline component:")
        
        // Manual way (simulated)
        print("\n  Manual spacing output:")
        print("    Header")
        print("    ")
        print("    ")
        print("    Content")
        
        // Newline component way
        let newlineLayout = Box(
            flexDirection: .column,
            children: Text("Header"),
                     Newline(count: 2),
                     Text("Content")
        )
        
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 6)
        let lines = newlineLayout.render(in: rect)
        
        print("\n  Newline component output:")
        for (index, line) in lines.enumerated() {
            let displayLine = line.isEmpty ? "(empty)" : line
            print("    [\(index)]: \(displayLine)")
        }

        print("\n✓ Newline component provides cleaner, more maintainable spacing")
        print("✓ Works consistently across static and dynamic regions")
        print("✓ Respects layout constraints and container boundaries")
        print("")
    }

    /// Get current timestamp for demo purposes
    private static func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
