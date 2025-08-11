import RuneANSI
import RuneLayout
import RuneUnicode

public extension Box {
    /// Calculate layout for this box within the given container rectangle
    /// - Parameter containerRect: The container rectangle to layout within
    /// - Returns: Layout result with calculated rectangles
    func calculateLayout(in containerRect: FlexLayout.Rect) -> BoxLayoutResult {
        let boxNode = YogaNode()
        configureRootBoxNode(boxNode, in: containerRect)

        // Determine children
        let allChildren: [Component] = children.isEmpty ? (child.map { [$0] } ?? []) : children

        // Create child nodes and attach
        let childNodes = createChildNodes(for: allChildren)
        for node in childNodes { boxNode.addChild(node) }

        // Compute layout and rects
        let layout = computeLayout(for: boxNode, childNodes: childNodes, containerRect: containerRect)

        return BoxLayoutResult(
            boxRect: layout.boxRect,
            contentRect: layout.contentRect,
            containerRect: containerRect,
            childRects: layout.childRects,
        )
    }

    // MARK: - Helpers (extracted to reduce complexity)

    private func configureRootBoxNode(_ boxNode: YogaNode, in containerRect: FlexLayout.Rect) {
        boxNode.setFlexDirection(flexDirection)
        boxNode.setJustifyContent(justifyContent)
        boxNode.setAlignItems(alignItems)

        // Width/height constraints
        switch width {
        case .auto:
            boxNode.setWidth(.auto)
        case let .points(value):
            let constrainedWidth = min(value, Float(containerRect.width))
            boxNode.setWidth(.points(constrainedWidth))
        case let .percent(value):
            let percentWidth = Float(containerRect.width) * value / 100.0
            boxNode.setWidth(.points(percentWidth))
        }
        switch height {
        case .auto:
            boxNode.setHeight(.auto)
        case let .points(value):
            let constrainedHeight = min(value, Float(containerRect.height))
            boxNode.setHeight(.points(constrainedHeight))
        case let .percent(value):
            let percentHeight = Float(containerRect.height) * value / 100.0
            boxNode.setHeight(.points(percentHeight))
        }

        // Spacing
        boxNode.setPadding(.top, paddingTop)
        boxNode.setPadding(.right, paddingRight)
        boxNode.setPadding(.bottom, paddingBottom)
        boxNode.setPadding(.left, paddingLeft)
        boxNode.setMargin(.top, marginTop)
        boxNode.setMargin(.right, marginRight)
        boxNode.setMargin(.bottom, marginBottom)
        boxNode.setMargin(.left, marginLeft)
        boxNode.setGap(.row, rowGap)
        boxNode.setGap(.column, columnGap)

        // Flex
        boxNode.setFlexGrow(flexGrow)
        boxNode.setFlexShrink(flexShrink)
        boxNode.setFlexBasis(flexBasis)
        boxNode.setFlexWrap(flexWrap)

        // Constraints
        boxNode.setMinWidth(minWidth)
        boxNode.setMaxWidth(maxWidth)
        boxNode.setMinHeight(minHeight)
        boxNode.setMaxHeight(maxHeight)
    }

    private func createChildNodes(for allChildren: [Component]) -> [YogaNode] {
        var result: [YogaNode] = []
        result.reserveCapacity(allChildren.count)
        for childComponent in allChildren {
            let childNode = YogaNode()
            if let textComponent = childComponent as? Text {
                let intrinsicWidth = Float(Width.displayWidth(of: textComponent.content))
                let intrinsicHeight: Float = 1
                childNode.setWidth(.points(intrinsicWidth))
                childNode.setHeight(.points(intrinsicHeight))
            } else if let spacerComponent = childComponent as? Spacer {
                let intrinsicSize = spacerComponent.intrinsicSize
                let flexProps = spacerComponent.flexProperties
                childNode.setWidth(.points(intrinsicSize.width))
                childNode.setHeight(.points(intrinsicSize.height))
                childNode.setFlexGrow(flexProps.grow)
                childNode.setFlexShrink(flexProps.shrink)
                childNode.setFlexBasis(flexProps.basis)
            } else if let boxComponent = childComponent as? Box {
                if boxComponent.width == .auto || boxComponent.height == .auto {
                    let intrinsicSize = BoxLayout.calculateIntrinsicSize(for: boxComponent)
                    let effectiveWidth: Dimension = boxComponent.width == .auto ? .points(intrinsicSize.width) : boxComponent.width
                    let effectiveHeight: Dimension = boxComponent.height == .auto ? .points(intrinsicSize.height) : boxComponent.height
                    childNode.setWidth(effectiveWidth)
                    childNode.setHeight(effectiveHeight)
                } else {
                    childNode.setWidth(boxComponent.width)
                    childNode.setHeight(boxComponent.height)
                }
                childNode.setFlexGrow(boxComponent.flexGrow)
                childNode.setFlexShrink(boxComponent.flexShrink)
                childNode.setFlexBasis(boxComponent.flexBasis)
                childNode.setMinWidth(boxComponent.minWidth)
                childNode.setMaxWidth(boxComponent.maxWidth)
                childNode.setMinHeight(boxComponent.minHeight)
                childNode.setMaxHeight(boxComponent.maxHeight)
                childNode.setAlignSelf(boxComponent.alignSelf)
            } else {
                childNode.setWidth(.auto)
                childNode.setHeight(.auto)
                childNode.setAlignSelf(.auto)
            }
            result.append(childNode)
        }
        return result
    }

    private struct ComputedLayout { let boxRect: FlexLayout.Rect; let contentRect: FlexLayout.Rect; let childRects: [FlexLayout.Rect] }

    private func computeLayout(for boxNode: YogaNode, childNodes: [YogaNode], containerRect: FlexLayout.Rect) -> ComputedLayout {
        let layoutEngine = YogaLayoutEngine.shared
        let rootResult = layoutEngine.calculateLayout(
            for: boxNode,
            availableWidth: containerRect.width,
            availableHeight: containerRect.height
        )
        let boxRect = FlexLayout.Rect(
            x: containerRect.x + Int(marginLeft.roundedToTerminal()),
            y: containerRect.y + Int(marginTop.roundedToTerminal()),
            width: rootResult.width,
            height: rootResult.height
        )
        let contentRect = FlexLayout.Rect(
            x: boxRect.x + Int(paddingLeft.roundedToTerminal()),
            y: boxRect.y + Int(paddingTop.roundedToTerminal()),
            width: max(0, boxRect.width - Int((paddingLeft + paddingRight).roundedToTerminal())),
            height: max(0, boxRect.height - Int((paddingTop + paddingBottom).roundedToTerminal()))
        )
        var childRects: [FlexLayout.Rect] = []
        childRects.reserveCapacity(childNodes.count)
        for childNode in childNodes {
            let childResult = layoutEngine.getLayoutResult(for: childNode)
            let childRect = FlexLayout.Rect(x: childResult.x, y: childResult.y, width: childResult.width, height: childResult.height)
            let clippedChildRect = FlexLayout.Rect(
                x: childRect.x,
                y: childRect.y,
                width: min(childRect.width, max(0, contentRect.width - childRect.x)),
                height: min(childRect.height, max(0, contentRect.height - childRect.y))
            )
            childRects.append(clippedChildRect)
        }
        return ComputedLayout(boxRect: boxRect, contentRect: contentRect, childRects: childRects)
    }
}
