import RuneLayout
import Foundation

@_exported import RuneANSI
@_exported import RuneUnicode

/// A component that applies string transformations to its child's rendered output
///
/// Transform renders its child component to a string, then applies a synchronous
/// transformation function to the result. The transformation is ANSI-safe, meaning
/// it preserves ANSI escape sequences by re-tokenizing the output if needed.
///
/// This component is useful for applying last-mile string effects like:
/// - Text case transformations (uppercase, lowercase, title case)
/// - String replacements and substitutions
/// - Text formatting and decoration
/// - Dynamic content modification
///
/// ## Key Features
/// - **ANSI-Safe**: Preserves ANSI escape sequences during transformation
/// - **Chainable**: Multiple Transform components can be nested
/// - **Performance Aware**: Minimal overhead with optional optimizations
/// - **Unicode Safe**: Handles emoji, CJK characters, and complex Unicode correctly
///
/// ## Usage
///
/// ```swift
/// // Simple case transformation
/// Transform(transform: { $0.uppercased() }) {
///     Text("hello world", color: .red)
/// }
/// // Result: "HELLO WORLD" in red
///
/// // String replacement
/// Transform(transform: { text in
///     text.replacingOccurrences(of: "Loading", with: "Processing")
/// }) {
///     Text("Loading...", bold: true)
/// }
/// // Result: "Processing..." in bold
///
/// // Chained transformations
/// Transform(transform: { $0.uppercased() }) {
///     Transform(transform: { $0.replacingOccurrences(of: "world", with: "universe") }) {
///         Text("hello world")
///     }
/// }
/// // Result: "HELLO UNIVERSE"
/// ```
///
/// ## ANSI Safety
///
/// Transform automatically handles ANSI escape sequences by:
/// 1. Tokenizing the rendered output to separate text from ANSI codes
/// 2. Applying the transformation only to text tokens
/// 3. Re-encoding the tokens back to a string with preserved ANSI sequences
///
/// This ensures that styling information is never corrupted during transformation.
///
/// ## Performance Considerations
///
/// - Transformations are applied synchronously during render
/// - ANSI tokenization adds minimal overhead for styled content
/// - Plain text (no ANSI) is transformed directly without tokenization
/// - Consider caching results for expensive transformations
public struct Transform: Component {
    /// The transformation function to apply to the rendered output
    private let transformFunction: (String) -> String

    /// The child component to render and transform
    private let child: Component

    /// Initialize a Transform component with a transformation function and child
    ///
    /// - Parameters:
    ///   - transform: Function that takes a string and returns a transformed string
    ///   - child: The child component to render and transform
    public init(transform: @escaping (String) -> String, @ComponentBuilder child: () -> Component) {
        self.transformFunction = transform
        self.child = child()
    }

    /// Initialize a Transform component with a transformation function and explicit child
    ///
    /// - Parameters:
    ///   - transform: Function that takes a string and returns a transformed string
    ///   - child: The child component to render and transform
    public init(transform: @escaping (String) -> String, child: Component) {
        self.transformFunction = transform
        self.child = child
    }

    /// Initialize a Transform component with a time-aware transformation function
    ///
    /// - Parameters:
    ///   - transform: Function that takes (string, currentTime) and returns a transformed string
    ///   - child: The child component to render and transform
    public init(timeAware transform: @escaping (String, TimeInterval) -> String, @ComponentBuilder child: () -> Component) {
        self.transformFunction = { input in
            let now = Date().timeIntervalSince1970
            return TransformANSISafety.applySafely(to: input, time: now, transform: transform)
        }
        self.child = child()
    }

    /// Initialize a Transform component with a time-aware transformation function and explicit child
    /// - Parameters:
    ///   - transform: Function that takes (string, currentTime) and returns a transformed string
    ///   - child: The child component to render and transform
    public init(timeAware transform: @escaping (String, TimeInterval) -> String, child: Component) {
        self.transformFunction = { input in
            let now = Date().timeIntervalSince1970
            return TransformANSISafety.applySafely(to: input, time: now, transform: transform)
        }
        self.child = child
    }

    /// Render the component by applying transformation to child's output
    ///
    /// This method:
    /// 1. Renders the child component to get string lines
    /// 2. Applies the transformation function to each line individually
    /// 3. Handles ANSI sequences safely if present
    /// 4. Returns the transformed lines
    ///
    /// - Parameter rect: The layout rectangle to render within
    /// - Returns: Array of transformed strings representing the rendered content
    public func render(in rect: FlexLayout.Rect) -> [String] {
        // Handle zero dimensions early
        guard rect.width > 0 && rect.height > 0 else {
            return []
        }

        // Render child component with identity path extended
        let childPath = [RuntimeStateContext.currentPath, "Transform"].joined(separator: "/")
        RuntimeStateContext.record(childPath)
        let childLines = RuntimeStateContext.$currentPath.withValue(childPath) {
            child.render(in: rect)
        }

        // Handle empty child output
        guard !childLines.isEmpty else {
            return Array(repeating: "", count: rect.height)
        }

        // Apply transformation to each line individually
        // Skip transformation for empty lines to avoid unwanted content
        let transformedLines = childLines.map { line in
            if line.isEmpty {
                return line // Don't transform empty lines
            } else {
                return TransformANSISafety.applySafely(to: line, transform: transformFunction)
            }
        }

        // Ensure we return exactly the expected number of lines
        let paddingNeeded = rect.height - transformedLines.count

        if paddingNeeded > 0 {
            return transformedLines + Array(repeating: "", count: paddingNeeded)
        } else {
            return Array(transformedLines.prefix(rect.height))
        }
    }



    /// Apply transformation safely, preserving ANSI sequences
    ///
    /// This method detects whether the input contains ANSI escape sequences
    /// and handles them appropriately:
    /// - For plain text: applies transformation directly
    /// - For ANSI text: tokenizes, transforms text tokens only, re-encodes
    ///
    /// - Parameter input: The input string to transform
    /// - Returns: The transformed string with ANSI sequences preserved
}

/// Result builder for Transform component children
@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock(_ component: Component) -> Component {
        component
    }
}
