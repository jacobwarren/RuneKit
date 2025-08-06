import yoga.core
import Foundation

// MARK: - Cross-Platform Yoga Enum Helpers

/// Cross-platform helper functions to handle Yoga enum initialization differences
/// between macOS (Int32, optional) and Linux (UInt32, non-optional) versions
private extension YGDirection {
    static func create(rawValue: Int) -> YGDirection {
        #if os(macOS)
        return YGDirection(rawValue: Int32(rawValue))!
        #else
        return YGDirection(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGFlexDirection {
    static func create(rawValue: Int) -> YGFlexDirection {
        #if os(macOS)
        return YGFlexDirection(rawValue: Int32(rawValue))!
        #else
        return YGFlexDirection(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGJustify {
    static func create(rawValue: Int) -> YGJustify {
        #if os(macOS)
        return YGJustify(rawValue: Int32(rawValue))!
        #else
        return YGJustify(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGAlign {
    static func create(rawValue: Int) -> YGAlign {
        #if os(macOS)
        return YGAlign(rawValue: Int32(rawValue))!
        #else
        return YGAlign(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGEdge {
    static func create(rawValue: Int) -> YGEdge {
        #if os(macOS)
        return YGEdge(rawValue: Int32(rawValue))!
        #else
        return YGEdge(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGGutter {
    static func create(rawValue: Int) -> YGGutter {
        #if os(macOS)
        return YGGutter(rawValue: Int32(rawValue))!
        #else
        return YGGutter(rawValue: UInt32(rawValue))
        #endif
    }
}

private extension YGWrap {
    static func create(rawValue: Int) -> YGWrap {
        #if os(macOS)
        return YGWrap(rawValue: Int32(rawValue))!
        #else
        return YGWrap(rawValue: UInt32(rawValue))
        #endif
    }
}

// MARK: - Yoga Swift Wrapper

/// Swift wrapper for Yoga layout engine
/// Provides a safe, Swift-friendly interface to Facebook's Yoga C++ layout engine
public final class YogaLayoutEngine: Sendable {
    // MARK: - Core Types

    /// Represents a layout result with terminal coordinates
    public struct LayoutResult {
        public let x: Int
        public let y: Int
        public let width: Int
        public let height: Int

        internal init(node: YGNodeRef) {
            self.x = YGNodeLayoutGetLeft(node).roundedToTerminal()
            self.y = YGNodeLayoutGetTop(node).roundedToTerminal()
            self.width = YGNodeLayoutGetWidth(node).roundedToTerminal()
            self.height = YGNodeLayoutGetHeight(node).roundedToTerminal()
        }

        public init(x: Int, y: Int, width: Int, height: Int) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }

    // MARK: - Shared Instance

    public static let shared = YogaLayoutEngine()

    private init() {}

    // MARK: - Layout Calculation

    /// Calculate layout for a node tree
    /// - Parameters:
    ///   - rootNode: The root node to calculate layout for
    ///   - availableWidth: Available width in terminal columns
    ///   - availableHeight: Available height in terminal rows
    /// - Returns: Layout result for the root node
    public func calculateLayout(
        for rootNode: YogaNode,
        availableWidth: Int,
        availableHeight: Int
    ) -> LayoutResult {
        // Convert terminal dimensions to Yoga coordinates
        let yogaWidth = Float(availableWidth)
        let yogaHeight = Float(availableHeight)

        // Perform layout calculation
        YGNodeCalculateLayout(
            rootNode.ref,
            yogaWidth,
            yogaHeight,
            YGDirection.create(rawValue: 1) // YGDirectionLTR = 1
        )

        // Convert result back to terminal coordinates
        return LayoutResult(node: rootNode.ref)
    }

    /// Get layout result for any node in the tree after calculation
    /// - Parameter node: The node to get layout for
    /// - Returns: Layout result for the node
    public func getLayoutResult(for node: YogaNode) -> LayoutResult {
        return LayoutResult(node: node.ref)
    }
}

// MARK: - Yoga Node Wrapper

/// Swift wrapper for YGNodeRef
/// Provides automatic memory management and type-safe property access
public final class YogaNode {
    internal let ref: YGNodeRef
    private var children: [YogaNode] = []

    public init() {
        ref = YGNodeNew()
    }

    deinit {
        YGNodeFree(ref)
    }

    // MARK: - Tree Management

    /// Add a child node
    /// - Parameter child: The child node to add
    public func addChild(_ child: YogaNode) {
        let childCount = YGNodeGetChildCount(ref)
        YGNodeInsertChild(ref, child.ref, childCount)
        children.append(child)
    }

    /// Remove a child node
    /// - Parameter child: The child node to remove
    public func removeChild(_ child: YogaNode) {
        YGNodeRemoveChild(ref, child.ref)
        children.removeAll { $0 === child }
    }

    /// Remove all children
    public func removeAllChildren() {
        while YGNodeGetChildCount(ref) > 0 {
            let childRef = YGNodeGetChild(ref, 0)
            YGNodeRemoveChild(ref, childRef)
        }
        children.removeAll()
    }

    // MARK: - Style Properties

    /// Set flex direction
    /// - Parameter direction: The flex direction
    public func setFlexDirection(_ direction: YogaFlexDirection) {
        YGNodeStyleSetFlexDirection(ref, direction.yogaValue)
    }

    /// Set justify content
    /// - Parameter justify: The justify content value
    public func setJustifyContent(_ justify: JustifyContent) {
        YGNodeStyleSetJustifyContent(ref, justify.yogaValue)
    }

    /// Set align items
    /// - Parameter align: The align items value
    public func setAlignItems(_ align: AlignItems) {
        YGNodeStyleSetAlignItems(ref, align.yogaValue)
    }

    /// Set align self
    /// - Parameter align: The align self value
    public func setAlignSelf(_ align: AlignSelf) {
        YGNodeStyleSetAlignSelf(ref, align.yogaValue)
    }

    /// Set width
    /// - Parameter width: The width dimension
    public func setWidth(_ width: Dimension) {
        width.applyToYogaWidth(ref)
    }

    /// Set height
    /// - Parameter height: The height dimension
    public func setHeight(_ height: Dimension) {
        height.applyToYogaHeight(ref)
    }

    /// Set padding for an edge
    /// - Parameters:
    ///   - edge: The edge to set padding for
    ///   - value: The padding value in terminal units
    public func setPadding(_ edge: Edge, _ value: Float) {
        YGNodeStyleSetPadding(ref, edge.yogaValue, value)
    }

    /// Set margin for an edge
    /// - Parameters:
    ///   - edge: The edge to set margin for
    ///   - value: The margin value in terminal units
    public func setMargin(_ edge: Edge, _ value: Float) {
        YGNodeStyleSetMargin(ref, edge.yogaValue, value)
    }

    // MARK: - Flex Properties (RUNE-28)

    /// Set flex grow factor
    /// - Parameter grow: The flex grow value
    public func setFlexGrow(_ grow: Float) {
        YGNodeStyleSetFlexGrow(ref, grow)
    }

    /// Set flex shrink factor
    /// - Parameter shrink: The flex shrink value
    public func setFlexShrink(_ shrink: Float) {
        YGNodeStyleSetFlexShrink(ref, shrink)
    }

    /// Set flex basis
    /// - Parameter basis: The flex basis dimension
    public func setFlexBasis(_ basis: Dimension) {
        basis.applyToYogaFlexBasis(ref)
    }

    /// Set flex wrap
    /// - Parameter wrap: The flex wrap value
    public func setFlexWrap(_ wrap: FlexWrap) {
        YGNodeStyleSetFlexWrap(ref, wrap.yogaValue)
    }

    /// Set minimum width
    /// - Parameter minWidth: The minimum width dimension
    public func setMinWidth(_ minWidth: Dimension) {
        minWidth.applyToYogaMinWidth(ref)
    }

    /// Set maximum width
    /// - Parameter maxWidth: The maximum width dimension
    public func setMaxWidth(_ maxWidth: Dimension) {
        maxWidth.applyToYogaMaxWidth(ref)
    }

    /// Set minimum height
    /// - Parameter minHeight: The minimum height dimension
    public func setMinHeight(_ minHeight: Dimension) {
        minHeight.applyToYogaMinHeight(ref)
    }

    /// Set maximum height
    /// - Parameter maxHeight: The maximum height dimension
    public func setMaxHeight(_ maxHeight: Dimension) {
        maxHeight.applyToYogaMaxHeight(ref)
    }

    /// Set gap between children
    /// - Parameters:
    ///   - gutter: The gutter type (row or column)
    ///   - value: The gap value in terminal units
    public func setGap(_ gutter: Gutter, _ value: Float) {
        YGNodeStyleSetGap(ref, gutter.yogaValue, value)
    }
}

// MARK: - Supporting Types

/// Flex direction enumeration for Yoga (distinct from FlexLayout.FlexDirection)
public enum YogaFlexDirection {
    case row
    case column
    case rowReverse
    case columnReverse

    internal var yogaValue: YGFlexDirection {
        switch self {
        case .row: return YGFlexDirection.create(rawValue: 2) // YGFlexDirectionRow
        case .column: return YGFlexDirection.create(rawValue: 0) // YGFlexDirectionColumn
        case .rowReverse: return YGFlexDirection.create(rawValue: 3) // YGFlexDirectionRowReverse
        case .columnReverse: return YGFlexDirection.create(rawValue: 1) // YGFlexDirectionColumnReverse
        }
    }
}

/// Justify content enumeration
public enum JustifyContent: Sendable {
    case flexStart
    case flexEnd
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly

    internal var yogaValue: YGJustify {
        switch self {
        case .flexStart: return YGJustify.create(rawValue: 0) // YGJustifyFlexStart
        case .flexEnd: return YGJustify.create(rawValue: 2) // YGJustifyFlexEnd
        case .center: return YGJustify.create(rawValue: 1) // YGJustifyCenter
        case .spaceBetween: return YGJustify.create(rawValue: 3) // YGJustifySpaceBetween
        case .spaceAround: return YGJustify.create(rawValue: 4) // YGJustifySpaceAround
        case .spaceEvenly: return YGJustify.create(rawValue: 5) // YGJustifySpaceEvenly
        }
    }
}

/// Align items enumeration
public enum AlignItems: Sendable {
    case flexStart
    case flexEnd
    case center
    case stretch
    case baseline

    internal var yogaValue: YGAlign {
        switch self {
        case .flexStart: return YGAlign.create(rawValue: 1) // YGAlignFlexStart
        case .flexEnd: return YGAlign.create(rawValue: 3) // YGAlignFlexEnd
        case .center: return YGAlign.create(rawValue: 2) // YGAlignCenter
        case .stretch: return YGAlign.create(rawValue: 4) // YGAlignStretch
        case .baseline: return YGAlign.create(rawValue: 5) // YGAlignBaseline
        }
    }
}

/// Align self enumeration for individual item alignment
public enum AlignSelf: Sendable {
    case auto
    case flexStart
    case flexEnd
    case center
    case stretch
    case baseline

    internal var yogaValue: YGAlign {
        switch self {
        case .auto: return YGAlign.create(rawValue: 0) // YGAlignAuto
        case .flexStart: return YGAlign.create(rawValue: 1) // YGAlignFlexStart
        case .flexEnd: return YGAlign.create(rawValue: 3) // YGAlignFlexEnd
        case .center: return YGAlign.create(rawValue: 2) // YGAlignCenter
        case .stretch: return YGAlign.create(rawValue: 4) // YGAlignStretch
        case .baseline: return YGAlign.create(rawValue: 5) // YGAlignBaseline
        }
    }
}

/// Flex wrap enumeration
public enum FlexWrap {
    case noWrap
    case wrap
    case wrapReverse

    internal var yogaValue: YGWrap {
        switch self {
        case .noWrap: return YGWrap.create(rawValue: 0) // YGWrapNoWrap
        case .wrap: return YGWrap.create(rawValue: 1) // YGWrapWrap
        case .wrapReverse: return YGWrap.create(rawValue: 2) // YGWrapWrapReverse
        }
    }
}

/// Dimension type for width/height values
public enum Dimension: Equatable {
    case auto
    case points(Float)
    case percent(Float)

    internal func applyToYogaWidth(_ node: YGNodeRef) {
        switch self {
        case .auto:
            YGNodeStyleSetWidthAuto(node)
        case .points(let value):
            YGNodeStyleSetWidth(node, value)
        case .percent(let value):
            YGNodeStyleSetWidthPercent(node, value)
        }
    }

    internal func applyToYogaHeight(_ node: YGNodeRef) {
        switch self {
        case .auto:
            YGNodeStyleSetHeightAuto(node)
        case .points(let value):
            YGNodeStyleSetHeight(node, value)
        case .percent(let value):
            YGNodeStyleSetHeightPercent(node, value)
        }
    }

    internal func applyToYogaFlexBasis(_ node: YGNodeRef) {
        switch self {
        case .auto:
            YGNodeStyleSetFlexBasisAuto(node)
        case .points(let value):
            YGNodeStyleSetFlexBasis(node, value)
        case .percent(let value):
            YGNodeStyleSetFlexBasisPercent(node, value)
        }
    }

    internal func applyToYogaMinWidth(_ node: YGNodeRef) {
        switch self {
        case .auto:
            // Yoga doesn't have auto for min width, use 0
            YGNodeStyleSetMinWidth(node, 0)
        case .points(let value):
            YGNodeStyleSetMinWidth(node, value)
        case .percent(let value):
            YGNodeStyleSetMinWidthPercent(node, value)
        }
    }

    internal func applyToYogaMaxWidth(_ node: YGNodeRef) {
        switch self {
        case .auto:
            // Yoga doesn't have auto for max width, use undefined (NaN)
            YGNodeStyleSetMaxWidth(node, Float.nan)
        case .points(let value):
            YGNodeStyleSetMaxWidth(node, value)
        case .percent(let value):
            YGNodeStyleSetMaxWidthPercent(node, value)
        }
    }

    internal func applyToYogaMinHeight(_ node: YGNodeRef) {
        switch self {
        case .auto:
            // Yoga doesn't have auto for min height, use 0
            YGNodeStyleSetMinHeight(node, 0)
        case .points(let value):
            YGNodeStyleSetMinHeight(node, value)
        case .percent(let value):
            YGNodeStyleSetMinHeightPercent(node, value)
        }
    }

    internal func applyToYogaMaxHeight(_ node: YGNodeRef) {
        switch self {
        case .auto:
            // Yoga doesn't have auto for max height, use undefined (NaN)
            YGNodeStyleSetMaxHeight(node, Float.nan)
        case .points(let value):
            YGNodeStyleSetMaxHeight(node, value)
        case .percent(let value):
            YGNodeStyleSetMaxHeightPercent(node, value)
        }
    }
}

/// Edge enumeration for padding/margin
public enum Edge {
    case left
    case top
    case right
    case bottom
    case start
    case end
    case horizontal
    case vertical
    case all

    internal var yogaValue: YGEdge {
        switch self {
        case .left: return YGEdge.create(rawValue: 0) // YGEdgeLeft
        case .top: return YGEdge.create(rawValue: 1) // YGEdgeTop
        case .right: return YGEdge.create(rawValue: 2) // YGEdgeRight
        case .bottom: return YGEdge.create(rawValue: 3) // YGEdgeBottom
        case .start: return YGEdge.create(rawValue: 4) // YGEdgeStart
        case .end: return YGEdge.create(rawValue: 5) // YGEdgeEnd
        case .horizontal: return YGEdge.create(rawValue: 6) // YGEdgeHorizontal
        case .vertical: return YGEdge.create(rawValue: 7) // YGEdgeVertical
        case .all: return YGEdge.create(rawValue: 8) // YGEdgeAll
        }
    }
}

/// Gutter enumeration for gaps
public enum Gutter {
    case column
    case row
    case all

    internal var yogaValue: YGGutter {
        switch self {
        case .column: return YGGutter.create(rawValue: 0) // YGGutterColumn
        case .row: return YGGutter.create(rawValue: 1) // YGGutterRow
        case .all: return YGGutter.create(rawValue: 2) // YGGutterAll
        }
    }
}

// MARK: - Float Extensions

public extension Float {
    /// Round float to terminal integer coordinate using banker's rounding
    func roundedToTerminal() -> Int {
        return Int(self.rounded(.toNearestOrEven))
    }
}
