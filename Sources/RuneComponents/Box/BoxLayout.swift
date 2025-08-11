import RuneLayout
import RuneUnicode

/// Handles layout calculation functionality for Box components
enum BoxLayout {
    /// Calculate intrinsic size for a component
    /// - Parameter component: The component to calculate size for
    /// - Returns: Intrinsic size as (width, height)
    static func calculateIntrinsicSize(for component: Component) -> (width: Float, height: Float) {
        if let textComponent = component as? Text {
            return (width: Float(Width.displayWidth(of: textComponent.content)), height: 1.0)
        } else if let spacerComponent = component as? Spacer {
            return spacerComponent.intrinsicSize
        } else if let boxComponent = component as? Box {
            // For box components, calculate based on their children
            let allChildren = boxComponent.children.isEmpty ? (boxComponent.child.map { [$0] } ?? []) : boxComponent
                .children

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
                return (
                    width: totalWidth + boxComponent.paddingLeft + boxComponent.paddingRight,
                    height: maxHeight + boxComponent.paddingTop + boxComponent.paddingBottom,
                )
            } else {
                totalHeight += Float(gapCount) * boxComponent.rowGap
                return (
                    width: maxWidth + boxComponent.paddingLeft + boxComponent.paddingRight,
                    height: totalHeight + boxComponent.paddingTop + boxComponent.paddingBottom,
                )
            }
        }

        // Default fallback
        return (width: 0.0, height: 0.0)
    }
}
