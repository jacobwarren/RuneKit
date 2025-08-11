import RuneUnicode
import yoga.core

/// Basic flexbox layout engine for terminal UIs
///
/// This module provides a simplified flexbox implementation suitable for
/// terminal-based user interfaces. It handles layout calculation for
/// components arranged in flexible containers.
public enum FlexLayout {
    /// Represents a rectangular area in terminal coordinates
    public struct Rect: Equatable {
        public let x: Int
        public let y: Int
        public let width: Int
        public let height: Int

        public init(x: Int, y: Int, width: Int, height: Int) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }

    /// Size constraints for layout calculation
    public struct Size: Equatable {
        public let width: Int
        public let height: Int

        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }

    /// Flex direction for container layout
    public enum FlexDirection {
        case row
        case column
    }

    /// Justify content alignment
    public enum JustifyContent {
        case flexStart
        case flexEnd
        case center
        case spaceBetween
        case spaceAround
    }

    /// Layout calculation using Yoga flexbox engine
    /// - Parameters:
    ///   - children: Array of child sizes
    ///   - containerSize: Available container size
    ///   - direction: Flex direction
    /// - Returns: Array of calculated rectangles for children
    public static func calculateLayout(
        children: [Size],
        containerSize: Size,
        direction: FlexDirection = .row,
    ) -> [Rect] {
        // Handle empty children case
        guard !children.isEmpty else {
            return []
        }

        // Create root Yoga node
        let rootNode = YogaNode()

        // Configure root node
        let yogaDirection: YogaFlexDirection = direction == .row ? .row : .column
        rootNode.setFlexDirection(yogaDirection)
        rootNode.setWidth(.points(Float(containerSize.width)))
        rootNode.setHeight(.points(Float(containerSize.height)))

        // Create child nodes
        var childNodes: [YogaNode] = []
        for child in children {
            let childNode = YogaNode()
            childNode.setWidth(.points(Float(child.width)))
            childNode.setHeight(.points(Float(child.height)))
            rootNode.addChild(childNode)
            childNodes.append(childNode)
        }

        // Calculate layout
        let layoutEngine = YogaLayoutEngine.shared
        _ = layoutEngine.calculateLayout(
            for: rootNode,
            availableWidth: containerSize.width,
            availableHeight: containerSize.height,
        )

        // Extract results
        var rects: [Rect] = []
        for childNode in childNodes {
            let result = layoutEngine.getLayoutResult(for: childNode)
            rects.append(Rect(
                x: result.x,
                y: result.y,
                width: result.width,
                height: result.height,
            ))
        }

        return rects
    }
}
