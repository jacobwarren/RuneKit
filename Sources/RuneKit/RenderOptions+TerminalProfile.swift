import Foundation
import RuneANSI
import RuneRenderer

public extension RenderOptions {
    /// Determine a TerminalProfile with explicit override > env > heuristic
    var terminalProfile: TerminalProfile {
        if let override = terminalProfileOverride { return override }
        let env = ProcessInfo.processInfo.environment
        if let fromEnv = Self.terminalProfileFromEnvironment(env) { return fromEnv }
        // Heuristic: prefer truecolor if detected, then 256, optionally no-color
        if let ct = env["COLORTERM"], ct.lowercased().contains("truecolor") || ct.contains("24bit") {
            return .trueColor
        }
        if let term = env["TERM"], term.contains("256color") { return .xterm256 }
        if env["NO_COLOR"] != nil { return .noColor }
        return .basic16
    }

    static func terminalProfileFromEnvironment(_ env: [String: String]) -> TerminalProfile? {
        if let profileString = env["RUNE_TERMINAL_PROFILE"]?.lowercased() {
            switch profileString {
            case "truecolor", "24bit": return .trueColor
            case "256", "xterm256": return .xterm256
            case "16", "basic16": return .basic16
            case "none", "no_color", "nocolor": return .noColor
            default: break
            }
        }
        return nil
    }
}

public extension RuntimeStateContext {
    /// Helper to run a render sub-tree with a specific terminal profile
    static func withTerminalProfile<T>(_ profile: TerminalProfile, perform: () -> T) -> T {
        RuntimeStateContext.$terminalProfile.withValue(profile) {
            perform()
        }
    }
}
