import Foundation

/// StateObject-like owner semantics, where the object is created once per identity path
/// and preserved across rerenders while identity remains stable.
public final class StateObjectStore: @unchecked Sendable {
    public static let shared = StateObjectStore()
    private let queue = DispatchQueue(label: "rk.state.objectStore")
    private var storage: [String: AnyObject] = [:]

    public func object<ObjectType: AnyObject>(path: String, key: String, create: () -> ObjectType) -> ObjectType {
        queue.sync {
            let composite = path + "::" + key
            if let existing = storage[composite] as? ObjectType {
                return existing
            }
            let newObj = create()
            storage[composite] = newObj
            return newObj
        }
    }

    public func reset(path: String) { queue.sync { storage = storage.filter { !$0.key.hasPrefix(path + "::") } } }
    public func clearAll() { queue.sync { storage.removeAll() } }
}

@propertyWrapper
public struct StateObject<ObjectType: AnyObject> {
    private let identityPath: String
    private let key: String
    private var instance: ObjectType

    public init(_ key: String, create: () -> ObjectType) {
        self.identityPath = RuntimeStateContext.currentPath
        self.key = key
        self.instance = StateObjectStore.shared.object(path: identityPath, key: key, create: create)
    }

    public var wrappedValue: ObjectType { instance }
}

