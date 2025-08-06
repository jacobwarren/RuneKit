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

// MARK: - Terminal Coordinate Conversion

extension Float {
    /// Convert Yoga float coordinate to terminal integer coordinate
    ///
    /// Uses standard rounding (0.5 rounds up) and clamps negative values to 0.
    /// This ensures all terminal coordinates are valid non-negative integers.
    func roundedToTerminal() -> Int {
        return max(0, Int(self.rounded()))
    }
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
    public let children: [Component]

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
        self.children = []
    }

    /// Initializer for multiple children
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
        children: [Component]
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
        self.child = nil
        self.children = children
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

    // MARK: - Layout Calculation

    /// Calculate intrinsic size for a component
    /// - Parameter component: The component to calculate size for
    /// - Returns: Intrinsic size as (width, height)
    private func calculateIntrinsicSize(for component: Component) -> (width: Float, height: Float) {
        if let textComponent = component as? Text {
            return (width: Float(textComponent.content.count), height: 1.0)
        } else if let boxComponent = component as? Box {
            // For box components, calculate based on their children
            let allChildren = boxComponent.children.isEmpty ? (boxComponent.child.map { [$0] } ?? []) : boxComponent.children

            if allChildren.isEmpty {
                return (width: 0.0, height: 0.0)
            }

            var totalWidth: Float = 0
            var totalHeight: Float = 0
            var maxWidth: Float = 0
            var maxHeight: Float = 0

            for child in allChildren {
                let childSize = calculateIntrinsicSize(for: child)

                if boxComponent.flexDirection == .row {
                    totalWidth += childSize.width
                    maxHeight = max(maxHeight, childSize.height)
                } else {
                    maxWidth = max(maxWidth, childSize.width)
                    totalHeight += childSize.height
                }
            }

            // Add gaps
            let gapCount = max(0, allChildren.count - 1)
            if boxComponent.flexDirection == .row {
                totalWidth += Float(gapCount) * boxComponent.columnGap
                return (width: totalWidth + boxComponent.paddingLeft + boxComponent.paddingRight,
                       height: maxHeight + boxComponent.paddingTop + boxComponent.paddingBottom)
            } else {
                totalHeight += Float(gapCount) * boxComponent.rowGap
                return (width: maxWidth + boxComponent.paddingLeft + boxComponent.paddingRight,
                       height: totalHeight + boxComponent.paddingTop + boxComponent.paddingBottom)
            }
        }

        // Default fallback
        return (width: 0.0, height: 0.0)
    }

    /// Calculate layout for this box within the given container rectangle
    /// - Parameter containerRect: The container rectangle to layout within
    /// - Returns: Layout result with calculated rectangles
    public func calculateLayout(in containerRect: FlexLayout.Rect) -> BoxLayoutResult {
        // Create Yoga node for this box
        let boxNode = YogaNode()

        // Apply layout properties to the box node
        boxNode.setFlexDirection(flexDirection)
        boxNode.setJustifyContent(justifyContent)
        boxNode.setAlignItems(alignItems)
        boxNode.setWidth(width)
        boxNode.setHeight(height)

        // Apply padding
        boxNode.setPadding(.top, paddingTop)
        boxNode.setPadding(.right, paddingRight)
        boxNode.setPadding(.bottom, paddingBottom)
        boxNode.setPadding(.left, paddingLeft)

        // Apply margin
        boxNode.setMargin(.top, marginTop)
        boxNode.setMargin(.right, marginRight)
        boxNode.setMargin(.bottom, marginBottom)
        boxNode.setMargin(.left, marginLeft)

        // Apply gap
        boxNode.setGap(.row, rowGap)
        boxNode.setGap(.column, columnGap)

        // Get all children (either from children array or single child)
        let allChildren: [Component] = children.isEmpty ? (child.map { [$0] } ?? []) : children

        // Create child nodes for layout calculation
        var childNodes: [YogaNode] = []
        for childComponent in allChildren {
            let childNode = YogaNode()

            // Set intrinsic size based on component type
            if let textComponent = childComponent as? Text {
                // For text components, use content length as intrinsic width
                let intrinsicWidth = Float(textComponent.content.count)
                let intrinsicHeight: Float = 1 // Single line for now

                childNode.setWidth(.points(intrinsicWidth))
                childNode.setHeight(.points(intrinsicHeight))
            } else if let boxComponent = childComponent as? Box {
                // For box components, calculate their intrinsic size recursively
                let intrinsicSize = calculateIntrinsicSize(for: boxComponent)
                childNode.setWidth(.points(intrinsicSize.width))
                childNode.setHeight(.points(intrinsicSize.height))
            } else {
                // For other components, let them size themselves automatically
                childNode.setWidth(.auto)
                childNode.setHeight(.auto)
            }

            boxNode.addChild(childNode)
            childNodes.append(childNode)
        }

        // Calculate layout using Yoga
        let layoutEngine = YogaLayoutEngine.shared
        let rootResult = layoutEngine.calculateLayout(
            for: boxNode,
            availableWidth: containerRect.width,
            availableHeight: containerRect.height
        )

        // Calculate box rectangle (accounting for margin)
        let boxRect = FlexLayout.Rect(
            x: containerRect.x + Int(marginLeft.roundedToTerminal()),
            y: containerRect.y + Int(marginTop.roundedToTerminal()),
            width: rootResult.width,
            height: rootResult.height
        )

        // Calculate content rectangle (inside padding)
        let contentRect = FlexLayout.Rect(
            x: boxRect.x + Int(paddingLeft.roundedToTerminal()),
            y: boxRect.y + Int(paddingTop.roundedToTerminal()),
            width: max(0, boxRect.width - Int((paddingLeft + paddingRight).roundedToTerminal())),
            height: max(0, boxRect.height - Int((paddingTop + paddingBottom).roundedToTerminal()))
        )

        // Get child rectangles (relative to content area)
        var childRects: [FlexLayout.Rect] = []
        for childNode in childNodes {
            let childResult = layoutEngine.getLayoutResult(for: childNode)
            let childRect = FlexLayout.Rect(
                x: childResult.x,
                y: childResult.y,
                width: childResult.width,
                height: childResult.height
            )
            childRects.append(childRect)
        }

        return BoxLayoutResult(
            boxRect: boxRect,
            contentRect: contentRect,
            containerRect: containerRect,
            childRects: childRects
        )
    }

    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Calculate content area (accounting for border and padding)
        let borderWidth = borderStyle != .none ? 1 : 0
        let contentX = borderWidth + Int(paddingLeft)
        let contentY = borderWidth + Int(paddingTop)
        let contentWidth = max(0, rect.width - 2 * borderWidth - Int(paddingLeft) - Int(paddingRight))
        let contentHeight = max(0, rect.height - 2 * borderWidth - Int(paddingTop) - Int(paddingBottom))

        // Start with empty lines - only fill with spaces if we have borders
        var lines: [String]
        if borderStyle != .none {
            lines = Array(repeating: String(repeating: " ", count: rect.width), count: rect.height)
        } else {
            lines = Array(repeating: "", count: rect.height)
        }

        // Render child content if present
        if let child, contentWidth > 0, contentHeight > 0 {
            let contentRect = FlexLayout.Rect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            let childLines = child.render(in: contentRect)

            // Place child content within the content area
            for (index, childLine) in childLines.enumerated() {
                let lineY = contentY + index
                if lineY >= 0 && lineY < lines.count {
                    let startX = contentX
                    let endX = min(startX + childLine.count, rect.width)
                    if startX < rect.width && endX > startX {
                        if borderStyle != .none {
                            // With borders, we need to maintain the full-width line
                            let prefix = String(lines[lineY].prefix(startX))
                            let content = String(childLine.prefix(endX - startX))
                            let suffix = String(lines[lineY].dropFirst(startX + content.count))
                            lines[lineY] = prefix + content + suffix
                        } else {
                            // Without borders, just place the content with appropriate padding
                            let padding = String(repeating: " ", count: startX)
                            lines[lineY] = padding + String(childLine.prefix(endX - startX))
                        }
                    }
                }
            }
        }

        // Render border if specified (after content so it overlays)
        if borderStyle != .none {
            renderBorder(into: &lines, rect: rect, style: borderStyle)
        }

        return lines
    }

    /// Render border into the lines array
    /// - Parameters:
    ///   - lines: The lines array to modify
    ///   - rect: The rectangle to draw the border in
    ///   - style: The border style to use
    private func renderBorder(into lines: inout [String], rect: FlexLayout.Rect, style: BorderStyle) {
        let borderChars = getBorderChars(for: style)

        // For simplicity, assume border is drawn at the start of the render area
        let width = rect.width
        let height = rect.height

        // Top border
        if height > 0 {
            lines[0] = borderChars.topLeft +
                      String(repeating: borderChars.horizontal, count: max(0, width - 2)) +
                      borderChars.topRight
        }

        // Side borders (middle lines)
        for y in 1..<(height - 1) {
            if y < lines.count {
                let existingLine = lines[y]
                let paddedLine = existingLine.padding(toLength: width, withPad: " ", startingAt: 0)
                lines[y] = borderChars.vertical +
                          String(paddedLine.dropFirst().dropLast()) +
                          borderChars.vertical
            }
        }

        // Bottom border
        if height > 1 {
            let bottomIndex = height - 1
            if bottomIndex < lines.count {
                lines[bottomIndex] = borderChars.bottomLeft +
                                   String(repeating: borderChars.horizontal, count: max(0, width - 2)) +
                                   borderChars.bottomRight
            }
        }
    }

    /// Build a single border line
    private func buildBorderLine(
        startX: Int,
        endX: Int,
        leftChar: String,
        rightChar: String,
        fillChar: String,
        totalWidth: Int
    ) -> String {
        var line = String(repeating: " ", count: totalWidth)

        // Left border character
        if startX < totalWidth {
            let prefix = String(repeating: " ", count: startX)
            let suffix = line.dropFirst(startX + 1)
            line = prefix + leftChar + suffix
        }

        // Fill middle
        if endX > startX + 1 {
            let fillStart = startX + 1
            let fillEnd = min(endX, totalWidth - 1)
            let fillLength = fillEnd - fillStart
            if fillLength > 0 {
                let prefix = String(line.prefix(fillStart))
                let fill = String(repeating: fillChar, count: fillLength)
                let suffix = String(line.dropFirst(fillEnd))
                line = prefix + fill + suffix
            }
        }

        // Right border character
        if endX < totalWidth && endX > startX {
            let prefix = String(line.prefix(endX))
            let suffix = line.dropFirst(endX + 1)
            line = prefix + rightChar + suffix
        }

        return line
    }

    /// Get border characters for a given style
    private func getBorderChars(for style: BorderStyle) -> BorderChars {
        switch style {
        case .none:
            return BorderChars(
                topLeft: " ", topRight: " ", bottomLeft: " ", bottomRight: " ",
                horizontal: " ", vertical: " "
            )
        case .single:
            return BorderChars(
                topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘",
                horizontal: "─", vertical: "│"
            )
        case .double:
            return BorderChars(
                topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝",
                horizontal: "═", vertical: "║"
            )
        case .rounded:
            return BorderChars(
                topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯",
                horizontal: "─", vertical: "│"
            )
        }
    }
}

/// Border characters for drawing borders
private struct BorderChars {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
}
