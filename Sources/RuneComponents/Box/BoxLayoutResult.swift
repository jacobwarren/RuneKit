import RuneLayout

/// Result of a layout calculation for a Box component
///
/// Coordinate system: terminal columns/rows. Rounding: 0.5 up; clamp negatives to 0.
/// Rect relationships: containerRect (input), boxRect (with margin), contentRect (inside padding), childRects.
public struct BoxLayoutResult {
    public let boxRect: FlexLayout.Rect
    public let contentRect: FlexLayout.Rect
    public let containerRect: FlexLayout.Rect
    public let childRects: [FlexLayout.Rect]

    public init(
        boxRect: FlexLayout.Rect,
        contentRect: FlexLayout.Rect,
        containerRect: FlexLayout.Rect,
        childRects: [FlexLayout.Rect] = [],
    ) {
        self.boxRect = boxRect
        self.contentRect = contentRect
        self.containerRect = containerRect
        self.childRects = childRects
    }
}
