import RuneLayout
import RuneANSI
import RuneUnicode

// Layout calculation for Box extracted into an extension (no behavior change)
extension Box {
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
    }
}

