import RuneLayout
import RuneRenderer

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

/// A simple text component
public struct Text: Component {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func render(in rect: FlexLayout.Rect) -> [String] {
        // TODO: Implement proper text rendering with wrapping
        // For now, just return the content as a single line
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Simple implementation: just return the content, truncated if needed
        let truncated = String(content.prefix(rect.width))
        var lines = [truncated]

        // Fill remaining height with empty lines
        while lines.count < rect.height {
            lines.append("")
        }

        return lines
    }
}

/// A container component with optional border
public struct Box: Component {
    public enum BorderStyle {
        case none
        case single
        case double
        case rounded
    }

    public let borderStyle: BorderStyle
    public let child: Component?

    public init(border: BorderStyle = .none, child: Component? = nil) {
        borderStyle = border
        self.child = child
    }

    public func render(in rect: FlexLayout.Rect) -> [String] {
        // TODO: Implement proper box rendering with borders
        // For now, just render the child if present
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        if let child {
            return child.render(in: rect)
        } else {
            // Return empty lines
            return Array(repeating: "", count: rect.height)
        }
    }
}
