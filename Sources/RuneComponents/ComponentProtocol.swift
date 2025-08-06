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

/// Result of a layout calculation for a Box component
///
/// ## Coordinate System
/// All coordinates are in terminal columns/rows:
/// - (0,0) is top-left corner
/// - X increases rightward (columns)
/// - Y increases downward (rows)
/// - All values are integers (terminal cells)
///
/// ## Rounding Rules
/// When Yoga produces fractional coordinates, they are converted to integers using:
/// - Standard rounding (0.5 rounds up)
/// - Negative values are clamped to 0
/// - Dimensions are clamped to non-negative values
///
/// ## Rectangle Relationships
/// - `containerRect`: Original input rectangle
/// - `boxRect`: Box position within container (accounts for margin)
/// - `contentRect`: Content area within box (accounts for padding)
/// - `childRects`: Child positions relative to content area
public struct BoxLayoutResult {
    /// The rectangle occupied by the box itself (including margin)
    public let boxRect: FlexLayout.Rect

    /// The rectangle available for content (inside padding)
    public let contentRect: FlexLayout.Rect

    /// The rectangle occupied by the container (original input)
    public let containerRect: FlexLayout.Rect

    /// Layout rectangles for child components (relative to content area)
    public let childRects: [FlexLayout.Rect]

    /// Initialize a BoxLayoutResult
    public init(
        boxRect: FlexLayout.Rect,
        contentRect: FlexLayout.Rect,
        containerRect: FlexLayout.Rect,
        childRects: [FlexLayout.Rect] = []
    ) {
        self.boxRect = boxRect
        self.contentRect = contentRect
        self.containerRect = containerRect
        self.childRects = childRects
    }
}
