/// RuneKit - A Swift library for terminal user interfaces
///
/// RuneKit is inspired by Ink (React for CLIs) and provides a declarative
/// way to build terminal-based user interfaces using Swift. It combines
/// the power of Swift's type system with efficient terminal rendering.
///
/// ## Architecture
///
/// RuneKit is built on four core subsystems:
///
/// 1. **Text Engine** (`RuneANSI` + `RuneUnicode`)
///    - ANSI escape sequence parsing and tokenization
///    - Accurate Unicode width calculations for emoji, CJK, and complex scripts
///    - Foundation for text wrapping and alignment
///
/// 2. **Layout Engine** (`RuneLayout`)
///    - Flexbox-inspired layout system optimized for terminals
///    - Constraint-based sizing and positioning
///    - Support for complex nested layouts
///
/// 3. **Renderer** (`RuneRenderer`)
///    - Efficient terminal frame rendering with ANSI escape sequences
///    - Actor-based thread-safe output management
///    - Cursor control and screen management
///
/// 4. **Components** (`RuneComponents`)
///    - Reusable UI building blocks (Text, Box, etc.)
///    - Layout-aware rendering within provided rectangles
///    - Foundation for complex UI composition
///
/// ## Usage
///
/// ```swift
/// import RuneKit
///
/// // Basic text rendering
/// let text = Text("Hello, RuneKit!")
/// let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
/// let lines = text.render(in: rect)
///
/// // ANSI tokenization
/// let tokenizer = ANSITokenizer()
/// let tokens = tokenizer.tokenize("\u{001B}[31mRed Text\u{001B}[0m")
///
/// // Unicode width calculation
/// let width = Width.displayWidth(of: "👨‍👩‍👧‍👦") // Returns 2
/// ```

// Re-export all modules for convenient access
@_exported import RuneANSI
@_exported import RuneComponents
@_exported import RuneLayout
@_exported import RuneRenderer
@_exported import RuneUnicode
