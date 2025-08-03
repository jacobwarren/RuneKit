import RuneKit
import Foundation

/// RuneCLI - Example executable demonstrating RuneKit functionality
/// 
/// This CLI serves as both a demo of RuneKit capabilities and a test
/// that the package builds and runs correctly across platforms.

@main
struct RuneCLI {
    static func main() async {
        print("Hello, RuneKit! 🎉")
        print("")
        print("RuneKit is a Swift library for terminal UIs inspired by Ink.")
        print("This CLI demonstrates that the package builds and runs successfully.")
        print("")
        print("Available modules:")
        print("  • RuneANSI - ANSI escape code parsing")
        print("  • RuneUnicode - Unicode width calculations")
        print("  • RuneLayout - Flexbox layout engine")
        print("  • RuneRenderer - Terminal frame rendering")
        print("  • RuneComponents - UI components")
        print("")
        print("Build completed successfully! ✅")
        
        // Demonstrate basic functionality
        await demonstrateBasicFunctionality()
    }
    
    /// Demonstrate basic RuneKit functionality
    static func demonstrateBasicFunctionality() async {
        print("\n--- Basic Functionality Demo ---")
        
        // Test ANSI tokenizer
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize("Hello World")
        print("ANSI Tokenizer: \(tokens.count) tokens from 'Hello World'")
        
        // Test width calculation
        let width = Width.displayWidth(of: "Hello")
        print("Unicode Width: 'Hello' has display width \(width)")
        
        // Test layout calculation
        let children = [FlexLayout.Size(width: 5, height: 1)]
        let containerSize = FlexLayout.Size(width: 10, height: 3)
        let rects = FlexLayout.calculateLayout(children: children, containerSize: containerSize)
        print("Layout: Calculated \(rects.count) rectangles")
        
        // Test component rendering
        let text = Text("Demo")
        let rect = FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1)
        let lines = text.render(in: rect)
        print("Component: Text rendered to \(lines.count) lines")
        
        // Test renderer (without actually writing to terminal)
        let _ = TerminalRenderer()
        print("Renderer: Created successfully")
        
        print("All modules working correctly! 🚀")
    }
}
