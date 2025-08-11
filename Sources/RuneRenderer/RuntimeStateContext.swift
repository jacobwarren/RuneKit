import Foundation
import RuneANSI

// Public task-local context for identity path propagation and per-render hooks
public enum RuntimeStateContext {
    @TaskLocal public static var currentPath = "root"
    @TaskLocal public static var recorder: (@Sendable (String) -> Void)?
    // Terminal profile for color capability, defaults to trueColor
    @TaskLocal public static var terminalProfile: TerminalProfile = .trueColor
    public static func record(_ path: String) { recorder?(path) }
}
