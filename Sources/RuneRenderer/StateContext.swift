import Foundation

// Public task-local context for identity path propagation and per-render hooks
public enum RuntimeStateContext {
    @TaskLocal public static var currentPath: String = "root"
    @TaskLocal public static var recorder: (@Sendable (String) -> Void)?
    public static func record(_ path: String) { recorder?(path) }
}

