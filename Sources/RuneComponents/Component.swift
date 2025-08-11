import RuneLayout

/// Base protocol for all RuneKit components
///
/// Components are the building blocks of RuneKit UIs. They define how
/// content should be rendered within a given layout rectangle.
public protocol Component {
    /// Render the component to an array of strings
    /// - Parameter rect: The layout rectangle to render within
    /// - Returns: Array of strings representing the rendered content
    func render(in rect: FlexLayout.Rect) -> [String]
}
