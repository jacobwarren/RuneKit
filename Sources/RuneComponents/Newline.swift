import RuneLayout

/// A component that renders exactly N newline characters
///
/// Newline is a convenience component for adding vertical spacing in terminal UIs.
/// It renders as empty lines and is useful for:
/// - Creating vertical space between components
/// - Adding consistent spacing in layouts
/// - Replacing manual newline handling in static and dynamic areas
///
/// ## Usage
///
/// ```swift
/// // Single newline
/// Newline(count: 1)
///
/// // Multiple newlines for spacing
/// Newline(count: 3)
///
/// // In a layout
/// Box(flexDirection: .column, children: [
///     Text("Header"),
///     Newline(count: 2),
///     Text("Content")
/// ])
/// ```
///
/// ## Behavior
///
/// - **Count**: Renders exactly `count` empty lines
/// - **Height constraint**: Respects container height, excess lines omitted
/// - **Width**: Ignores width constraint (newlines are width-agnostic)
/// - **SGR safety**: Produces no ANSI escape sequences
/// - **Negative count**: Treated as zero (no lines rendered)
///
/// ## Integration
///
/// Newline works seamlessly in both static and dynamic regions:
/// - **Static regions**: Lines never move during repaint
/// - **Dynamic regions**: Participates in layout and reconciliation
/// - **Console capture**: Compatible with stdout/stderr capture
public struct Newline: Component {
    /// The number of newlines to render
    public let count: Int

    /// Initialize a Newline component
    /// - Parameter count: Number of newlines to render (negative values treated as 0)
    public init(count: Int) {
        self.count = max(0, count) // Ensure non-negative
    }

    /// Render the newlines within the given rectangle
    /// - Parameter rect: The layout rectangle to render within
    /// - Returns: Array of empty strings representing newlines
    public func render(in rect: FlexLayout.Rect) -> [String] {
        // Handle zero height constraint
        guard rect.height > 0 else {
            return []
        }

        // Calculate actual lines to render (respect height constraint)
        let linesToRender = min(count, rect.height)

        // Return empty lines (newlines are represented as empty strings)
        return Array(repeating: "", count: linesToRender)
    }
}
