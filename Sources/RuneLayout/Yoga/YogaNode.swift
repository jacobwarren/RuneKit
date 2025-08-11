import Foundation
import yoga.core

public final class YogaNode {
    let ref: YGNodeRef
    private var children: [YogaNode] = []
    public init() { ref = YGNodeNew() }
    deinit { YGNodeFree(ref) }
    public func addChild(_ child: YogaNode) { let idx = YGNodeGetChildCount(ref); YGNodeInsertChild(
        ref,
        child.ref,
        idx,
    ); children.append(child) }
    public func removeChild(_ child: YogaNode) { YGNodeRemoveChild(ref, child.ref); children.removeAll { $0 === child }
    }

    public func removeAllChildren() {
        while YGNodeGetChildCount(ref) > 0 {
            let childRef = YGNodeGetChild(ref, 0)
            YGNodeRemoveChild(ref, childRef)
        }
        children.removeAll()
    }

    public func setFlexDirection(_ direction: YogaFlexDirection) {
        YGNodeStyleSetFlexDirection(ref, direction.yogaValue)
    }

    public func setJustifyContent(_ justify: JustifyContent) { YGNodeStyleSetJustifyContent(ref, justify.yogaValue) }
    public func setAlignItems(_ align: AlignItems) { YGNodeStyleSetAlignItems(ref, align.yogaValue) }
    public func setAlignSelf(_ align: AlignSelf) { YGNodeStyleSetAlignSelf(ref, align.yogaValue) }
    public func setWidth(_ dimension: Dimension) { dimension.applyToYogaWidth(ref) }
    public func setHeight(_ dimension: Dimension) { dimension.applyToYogaHeight(ref) }
    public func setMinWidth(_ dimension: Dimension) { dimension.applyToYogaMinWidth(ref) }
    public func setMaxWidth(_ dimension: Dimension) { dimension.applyToYogaMaxWidth(ref) }
    public func setMinHeight(_ dimension: Dimension) { dimension.applyToYogaMinHeight(ref) }
    public func setMaxHeight(_ dimension: Dimension) { dimension.applyToYogaMaxHeight(ref) }
    public func setFlexGrow(_ value: Float) { YGNodeStyleSetFlexGrow(ref, value) }
    public func setFlexShrink(_ value: Float) { YGNodeStyleSetFlexShrink(ref, value) }
    public func setFlexBasis(_ dimension: Dimension) { dimension.applyToYogaFlexBasis(ref) }
    public func setFlexWrap(_ wrap: FlexWrap) { YGNodeStyleSetFlexWrap(ref, wrap.yogaValue) }
    public func setPadding(_ edge: Edge, _ value: Float) { YGNodeStyleSetPadding(ref, edge.yogaValue, value) }
    public func setMargin(_ edge: Edge, _ value: Float) { YGNodeStyleSetMargin(ref, edge.yogaValue, value) }
    public func setGap(_ gutter: Gutter, _ value: Float) { YGNodeStyleSetGap(ref, gutter.yogaValue, value) }
}
