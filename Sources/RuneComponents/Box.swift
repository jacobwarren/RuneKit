import RuneLayout
import RuneANSI
import RuneUnicode

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

    /// Align self - overrides parent's alignItems for this specific item
    public let alignSelf: AlignSelf

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

    // MARK: - Flex Properties (RUNE-28)

    /// Flex grow factor - how much this item should grow relative to other items
    public let flexGrow: Float

    /// Flex shrink factor - how much this item should shrink relative to other items
    public let flexShrink: Float

    /// Flex basis - initial size before growing/shrinking
    public let flexBasis: Dimension

    /// Flex wrap behavior
    public let flexWrap: FlexWrap

    /// Minimum width constraint
    public let minWidth: Dimension

    /// Maximum width constraint
    public let maxWidth: Dimension

    /// Minimum height constraint
    public let minHeight: Dimension

    /// Maximum height constraint
    public let maxHeight: Dimension

    // MARK: - Visual Properties

    public let borderStyle: BorderStyle
    public let borderColor: ANSIColor?
    public let backgroundColor: ANSIColor?
    public let child: Component?
    public let children: [Component]

    public init(
        border: BorderStyle = .none,
        borderColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        flexDirection: YogaFlexDirection = .column,
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        alignSelf: AlignSelf = .auto,
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
        flexGrow: Float = 0,
        flexShrink: Float = 1,
        flexBasis: Dimension = .auto,
        flexWrap: FlexWrap = .noWrap,
        minWidth: Dimension = .auto,
        maxWidth: Dimension = .auto,
        minHeight: Dimension = .auto,
        maxHeight: Dimension = .auto,
        child: Component? = nil
    ) {
        self.borderStyle = border
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.flexDirection = flexDirection
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.alignSelf = alignSelf
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
        self.flexGrow = flexGrow
        self.flexShrink = flexShrink
        self.flexBasis = flexBasis
        self.flexWrap = flexWrap
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.child = child
        self.children = []
    }

    /// Initializer for multiple children
    public init(
        border: BorderStyle = .none,
        borderColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        flexDirection: YogaFlexDirection = .column,
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        alignSelf: AlignSelf = .auto,
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
        flexGrow: Float = 0,
        flexShrink: Float = 1,
        flexBasis: Dimension = .auto,
        flexWrap: FlexWrap = .noWrap,
        minWidth: Dimension = .auto,
        maxWidth: Dimension = .auto,
        minHeight: Dimension = .auto,
        maxHeight: Dimension = .auto,
        children: Component...
    ) {
        self.borderStyle = border
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.flexDirection = flexDirection
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.alignSelf = alignSelf
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
        self.flexGrow = flexGrow
        self.flexShrink = flexShrink
        self.flexBasis = flexBasis
        self.flexWrap = flexWrap
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.child = nil
        self.children = Array(children)
    }

    /// Internal initializer for array of children (used by helper functions)
    internal init(
        border: BorderStyle = .none,
        borderColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        flexDirection: YogaFlexDirection = .column,
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        alignSelf: AlignSelf = .auto,
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
        flexGrow: Float = 0,
        flexShrink: Float = 1,
        flexBasis: Dimension = .auto,
        flexWrap: FlexWrap = .noWrap,
        minWidth: Dimension = .auto,
        maxWidth: Dimension = .auto,
        minHeight: Dimension = .auto,
        maxHeight: Dimension = .auto,
        childrenArray: [Component]
    ) {
        self.borderStyle = border
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.flexDirection = flexDirection
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.alignSelf = alignSelf
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
        self.flexGrow = flexGrow
        self.flexShrink = flexShrink
        self.flexBasis = flexBasis
        self.flexWrap = flexWrap
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.child = nil
        self.children = childrenArray
    }

    // MARK: - Convenience Initializers (moved to BoxConvenience.swift)

    // MARK: - Layout Calculation (moved to BoxLayoutAdapter.swift)

    // calculateLayout_core removed; use extension in BoxLayoutAdapter.swift

    /* Moved: calculateLayout body is now in BoxLayoutAdapter.swift

        // Create Yoga node for this box
        let boxNode = YogaNode()

        // Apply layout properties to the box node
        boxNode.setFlexDirection(flexDirection)
        boxNode.setJustifyContent(justifyContent)
        boxNode.setAlignItems(alignItems)

        // Apply width/height constraints, respecting intrinsic sizing for .auto
        // This allows flex wrap to work correctly while preserving intrinsic sizing
        switch width {
        case .auto:
            // Let Yoga calculate intrinsic width based on children
            boxNode.setWidth(.auto)
        case .points(let value):
            // Constrain explicit width to container bounds
            let constrainedWidth = min(value, Float(containerRect.width))
            boxNode.setWidth(.points(constrainedWidth))
        case .percent(let value):
            // Calculate percentage of container width
            let percentWidth = Float(containerRect.width) * value / 100.0
            boxNode.setWidth(.points(percentWidth))
        }

        switch height {
        case .auto:
            // Let Yoga calculate intrinsic height based on children
            boxNode.setHeight(.auto)
        case .points(let value):
            // Constrain explicit height to container bounds
            let constrainedHeight = min(value, Float(containerRect.height))
            boxNode.setHeight(.points(constrainedHeight))
        case .percent(let value):
            // Calculate percentage of container height
            let percentHeight = Float(containerRect.height) * value / 100.0
            boxNode.setHeight(.points(percentHeight))
        }

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

        // Apply flex properties (RUNE-28)
        boxNode.setFlexGrow(flexGrow)
        boxNode.setFlexShrink(flexShrink)
        boxNode.setFlexBasis(flexBasis)
        boxNode.setFlexWrap(flexWrap)

        // Apply min/max constraints
        boxNode.setMinWidth(minWidth)
        boxNode.setMaxWidth(maxWidth)
        boxNode.setMinHeight(minHeight)
        boxNode.setMaxHeight(maxHeight)

        // Get all children (either from children array or single child)
        let allChildren: [Component] = children.isEmpty ? (child.map { [$0] } ?? []) : children

        // Create child nodes for layout calculation
        var childNodes: [YogaNode] = []
        for childComponent in allChildren {
            let childNode = YogaNode()

            // Set intrinsic size based on component type
            if let textComponent = childComponent as? Text {
                // For text components, use display width as intrinsic width
                let intrinsicWidth = Float(Width.displayWidth(of: textComponent.content))
                let intrinsicHeight: Float = 1 // Single line for now

                childNode.setWidth(.points(intrinsicWidth))
                childNode.setHeight(.points(intrinsicHeight))
            } else if let spacerComponent = childComponent as? Spacer {
                // For spacer components, use minimal intrinsic size but set flex properties
                let intrinsicSize = spacerComponent.intrinsicSize
                let flexProps = spacerComponent.flexProperties

                childNode.setWidth(.points(intrinsicSize.width))
                childNode.setHeight(.points(intrinsicSize.height))

                // Apply flex properties to make spacer consume available space
                childNode.setFlexGrow(flexProps.grow)
                childNode.setFlexShrink(flexProps.shrink)
                childNode.setFlexBasis(flexProps.basis)
            } else if let boxComponent = childComponent as? Box {
                // For box components, calculate intrinsic size if needed
                if boxComponent.width == .auto || boxComponent.height == .auto {
                    // Calculate intrinsic size by doing a preliminary layout
                    let intrinsicSize = BoxLayout.calculateIntrinsicSize(for: boxComponent)

                    // Use intrinsic size for auto dimensions, explicit size for others
                    let effectiveWidth: Dimension = boxComponent.width == .auto ? .points(intrinsicSize.width) : boxComponent.width
                    let effectiveHeight: Dimension = boxComponent.height == .auto ? .points(intrinsicSize.height) : boxComponent.height

                    childNode.setWidth(effectiveWidth)
                    childNode.setHeight(effectiveHeight)
                } else {
                    // Use explicit dimensions
                    childNode.setWidth(boxComponent.width)
                    childNode.setHeight(boxComponent.height)
                }

                // Apply flex properties from the child box
                childNode.setFlexGrow(boxComponent.flexGrow)
                childNode.setFlexShrink(boxComponent.flexShrink)
                childNode.setFlexBasis(boxComponent.flexBasis)

                // Apply min/max constraints
                childNode.setMinWidth(boxComponent.minWidth)
                childNode.setMaxWidth(boxComponent.maxWidth)
                childNode.setMinHeight(boxComponent.minHeight)
                childNode.setMaxHeight(boxComponent.maxHeight)

                // Apply align self property
                childNode.setAlignSelf(boxComponent.alignSelf)
            } else {
                // For other components, let them size themselves automatically
                childNode.setWidth(.auto)
                childNode.setHeight(.auto)

                // Apply default alignSelf for non-Box components
                childNode.setAlignSelf(.auto)
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

        // Get child rectangles (relative to content area) with overflow clipping
        var childRects: [FlexLayout.Rect] = []
        for childNode in childNodes {
            let childResult = layoutEngine.getLayoutResult(for: childNode)
            let childRect = FlexLayout.Rect(
                x: childResult.x,
                y: childResult.y,
                width: childResult.width,
                height: childResult.height
            )

            // Clip child to content area bounds (RUNE-28: overflow clipping)
            let clippedChildRect = FlexLayout.Rect(
                x: childRect.x,
                y: childRect.y,
                width: min(childRect.width, max(0, contentRect.width - childRect.x)),
                height: min(childRect.height, max(0, contentRect.height - childRect.y))
            )

            childRects.append(clippedChildRect)
        }

        return BoxLayoutResult(
            boxRect: boxRect,
            contentRect: contentRect,
            containerRect: containerRect,
            childRects: childRects
        )
    */

    // MARK: - Rendering (moved to BoxRendering.swift)


    /// Truncate a string to fit within a specific display width while preserving ANSI sequences
    ///
    /// This function safely truncates text that may contain ANSI escape sequences by:
    /// 1. Tokenizing the input to separate ANSI codes from text
    /// 2. Truncating only the visible text content by display width
    /// 3. Preserving all ANSI formatting codes
    ///
    /// - Parameters:
    ///   - text: The text to truncate (may contain ANSI codes)
    ///   - maxWidth: The maximum display width allowed
    /// - Returns: The truncated text that fits within maxWidth display columns
    // MARK: - Private helpers (moved to ANSISafeTruncation)
    // Truncation helpers moved to RuneANSI.ANSISafeTruncation

}
