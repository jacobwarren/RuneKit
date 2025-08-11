import Foundation

/// Optional identity a Component can expose so that state can be preserved across rerenders
/// even when parents reorder children. If nil, parent may fall back to index.
public protocol ComponentIdentifiable {
    var componentIdentity: String? { get }
}

public extension ComponentIdentifiable {
    var componentIdentity: String? { nil }
}
