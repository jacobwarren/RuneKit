import Foundation

/// Internal protocol to type-erase Identity wrappers for encoding.
public protocol IdentityToken {
    var identityObject: AnyObject { get }
}

/// Wrap an object to opt into identity-based dependency semantics.
/// Usage: deps: [Identity(myObj)]
public struct Identity<T: AnyObject>: Hashable, CustomStringConvertible, @unchecked Sendable, IdentityToken {
    public let object: T
    public init(_ object: T) { self.object = object }
    public var description: String { "Identity(\(String(describing: type(of: object))))" }

    public static func == (lhs: Identity<T>, rhs: Identity<T>) -> Bool { lhs.object === rhs.object }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(object)) }

    // IdentityToken
    public var identityObject: AnyObject { object }
}
