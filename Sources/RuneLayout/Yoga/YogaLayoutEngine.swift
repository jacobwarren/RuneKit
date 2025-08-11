import Foundation
import yoga.core

// MARK: - Cross-Platform Yoga Enum Helpers (kept temporarily)

extension YGDirection {
    static func create(rawValue: Int) -> YGDirection {
        #if os(macOS)
        return YGDirection(rawValue: Int32(rawValue))!
        #else
        return YGDirection(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGFlexDirection {
    static func create(rawValue: Int) -> YGFlexDirection {
        #if os(macOS)
        return YGFlexDirection(rawValue: Int32(rawValue))!
        #else
        return YGFlexDirection(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGJustify {
    static func create(rawValue: Int) -> YGJustify {
        #if os(macOS)
        return YGJustify(rawValue: Int32(rawValue))!
        #else
        return YGJustify(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGAlign {
    static func create(rawValue: Int) -> YGAlign {
        #if os(macOS)
        return YGAlign(rawValue: Int32(rawValue))!
        #else
        return YGAlign(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGEdge {
    static func create(rawValue: Int) -> YGEdge {
        #if os(macOS)
        return YGEdge(rawValue: Int32(rawValue))!
        #else
        return YGEdge(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGGutter {
    static func create(rawValue: Int) -> YGGutter {
        #if os(macOS)
        return YGGutter(rawValue: Int32(rawValue))!
        #else
        return YGGutter(rawValue: UInt32(rawValue))
        #endif
    }
}

extension YGWrap {
    static func create(rawValue: Int) -> YGWrap {
        #if os(macOS)
        return YGWrap(rawValue: Int32(rawValue))!
        #else
        return YGWrap(rawValue: UInt32(rawValue))
        #endif
    }
}

public final class YogaLayoutEngine: Sendable {
    public struct LayoutResult {
        public let x: Int
        public let y: Int
        public let width: Int
        public let height: Int
        init(node: YGNodeRef) {
            x = YGNodeLayoutGetLeft(node).roundedToTerminal()
            y = YGNodeLayoutGetTop(node).roundedToTerminal()
            width = YGNodeLayoutGetWidth(node).roundedToTerminal()
            height = YGNodeLayoutGetHeight(node).roundedToTerminal()
        }

        public init(x: Int, y: Int, width: Int, height: Int) {
            self.x = x; self.y = y; self.width = width; self.height = height
        }
    }

    public static let shared = YogaLayoutEngine()
    private init() {}
    public func calculateLayout(for rootNode: YogaNode, availableWidth: Int, availableHeight: Int) -> LayoutResult {
        YGNodeCalculateLayout(
            rootNode.ref,
            Float(availableWidth),
            Float(availableHeight),
            YGDirection.create(rawValue: 1),
        )
        return LayoutResult(node: rootNode.ref)
    }

    public func getLayoutResult(for node: YogaNode) -> LayoutResult { LayoutResult(node: node.ref) }
}

public extension Float { func roundedToTerminal() -> Int { Int(rounded(.toNearestOrEven)) } }
