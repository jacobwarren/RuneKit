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

/// A container component with optional border and layout properties
public struct Box: Component {
    public enum BorderStyle {
        case none
        case single
        case double
        case rounded
    }

    // MARK: - Layout Properties

    /// Flex direction for child layout
    public let flexDirection: YogaFlexDirection

    /// Justify content along main axis
    public let justifyContent: JustifyContent

    /// Align items along cross axis
    public let alignItems: AlignItems

    /// Width dimension
    public let width: Dimension

    /// Height dimension
    public let height: Dimension

    /// Padding values for each edge
    public let paddingTop: Float
    public let paddingRight: Float
    public let paddingBottom: Float
    public let paddingLeft: Float

    /// Margin values for each edge
    public let marginTop: Float
    public let marginRight: Float
    public let marginBottom: Float
    public let marginLeft: Float

    /// Gap between children
    public let rowGap: Float
    public let columnGap: Float

    // MARK: - Visual Properties

    public let borderStyle: BorderStyle
    public let child: Component?

    public init(
        border: BorderStyle = .none,
        flexDirection: YogaFlexDirection = .column,
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        width: Dimension = .auto,
        height: Dimension = .auto,
        paddingTop: Float = 0,
        paddingRight: Float = 0,
        paddingBottom: Float = 0,
        paddingLeft: Float = 0,
        marginTop: Float = 0,
        marginRight: Float = 0,
        marginBottom: Float = 0,
        marginLeft: Float = 0,
        rowGap: Float = 0,
        columnGap: Float = 0,
        child: Component? = nil
    ) {
        self.borderStyle = border
        self.flexDirection = flexDirection
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.width = width
        self.height = height
        self.paddingTop = paddingTop
        self.paddingRight = paddingRight
        self.paddingBottom = paddingBottom
        self.paddingLeft = paddingLeft
        self.marginTop = marginTop
        self.marginRight = marginRight
        self.marginBottom = marginBottom
        self.marginLeft = marginLeft
        self.rowGap = rowGap
        self.columnGap = columnGap
        self.child = child
    }

    // MARK: - Convenience Initializers

    /// Convenience initializer for simple padding
    public init(
        border: BorderStyle = .none,
        padding: Float,
        child: Component? = nil
    ) {
        self.init(
            border: border,
            paddingTop: padding,
            paddingRight: padding,
            paddingBottom: padding,
            paddingLeft: padding,
            child: child
        )
    }

    /// Convenience initializer for horizontal and vertical padding
    public init(
        border: BorderStyle = .none,
        paddingHorizontal: Float = 0,
        paddingVertical: Float = 0,
        child: Component? = nil
    ) {
        self.init(
            border: border,
            paddingTop: paddingVertical,
            paddingRight: paddingHorizontal,
            paddingBottom: paddingVertical,
            paddingLeft: paddingHorizontal,
            child: child
        )
    }

    /// Convenience initializer for flex row layout
    public static func row(
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        gap: Float = 0,
        child: Component? = nil
    ) -> Box {
        return Box(
            flexDirection: .row,
            justifyContent: justifyContent,
            alignItems: alignItems,
            columnGap: gap,
            child: child
        )
    }

    /// Convenience initializer for flex column layout
    public static func column(
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        gap: Float = 0,
        child: Component? = nil
    ) -> Box {
        return Box(
            flexDirection: .column,
            justifyContent: justifyContent,
            alignItems: alignItems,
            rowGap: gap,
            child: child
        )
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
