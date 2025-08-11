import Foundation
import RuneLayout
import RuneRenderer

/// A simple wrapper that assigns a stable identity to any child component
public struct Identified: Component, ComponentIdentifiable {
    public let id: String
    public let child: Component
    public init(_ id: String, child: Component) {
        self.id = id
        self.child = child
    }

    public var componentIdentity: String? { id }
    public func render(in rect: FlexLayout.Rect) -> [String] {
        let current = RuntimeStateContext.currentPath
        let childPath = [current, "Identified", id].joined(separator: "/")
        RuntimeStateContext.record(childPath)
        return RuntimeStateContext.$currentPath.withValue(childPath) {
            child.render(in: rect)
        }
    }
}
