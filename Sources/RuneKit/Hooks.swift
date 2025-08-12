import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

// Minimal hooks-style API: useEffect, requestRerender, useRef/useMemo, and useInput
// Effects are registered during render and executed after the frame commits.
// Cleanups run on dependency change or unmount.

public enum HooksRuntime {
    // MARK: - Task-local registrars bound by the runtime during effect execution

    /// Registrar for input handlers; bound by RenderHandle.commitEffects while invoking effects.
    /// Returns a synchronous cleanup closure to unsubscribe.
    @TaskLocal public static var inputRegistrar: (@Sendable (_ id: String, _ handler: @escaping @Sendable (KeyEvent) async -> Void, _ isActive: Bool) async -> (@Sendable () -> Void))?

    /// App context for controlling the running application (exit/clear) from within components/effects
    @TaskLocal public static var appContext: AppContext?

    /// I/O streams context bound by the runtime during build/render and effect commits
    @TaskLocal public static var ioStreams: Streams?

    /// Lightweight app control surface exposed to hooks. Methods are async and actor-hopping safe.
    public struct AppContext: Sendable {
        private let _exit: @Sendable (Error?) async -> Void
        private let _clear: @Sendable () async -> Void
        public init(exit: @escaping @Sendable (Error?) async -> Void, clear: @escaping @Sendable () async -> Void) {
            self._exit = exit
            self._clear = clear
        }
        /// Request application exit (graceful unmount). Error is optional and currently informational.
        public func exit(_ error: Error? = nil) async { await _exit(error) }
        /// Clear the current live region or screen according to render options.
        public func clear() async { await _clear() }
    }

    /// Streams + metadata snapshot for hooks access. FileHandles are not Sendable; mark container unchecked.
    public final class Streams: @unchecked Sendable {
        public let stdin: FileHandle
        public let stdout: FileHandle
        public let stderr: FileHandle
        public let stdinIsTTY: Bool
        public let stdoutIsTTY: Bool
        public let stderrIsTTY: Bool
        public let stdinIsRawMode: Bool
        public init(stdin: FileHandle, stdout: FileHandle, stderr: FileHandle,
                    stdinIsTTY: Bool, stdoutIsTTY: Bool, stderrIsTTY: Bool,
                    stdinIsRawMode: Bool) {
            self.stdin = stdin
            self.stdout = stdout
            self.stderr = stderr
            self.stdinIsTTY = stdinIsTTY
            self.stdoutIsTTY = stdoutIsTTY
            self.stderrIsTTY = stderrIsTTY
            self.stdinIsRawMode = stdinIsRawMode
        }
    }

    // MARK: - useApp
    /// Access the application context for programmatic control from components/effects
    /// The runtime binds this during render/effect commit; calling outside a render/effect will be a no-op stub.
    public static func useApp() -> AppContext {
        if let ctx = appContext { return ctx }
        // Fallback no-op context to keep tests/app code safe when not bound
        return AppContext(exit: { _ in }, clear: { })
    }

    // MARK: - useStdin/useStdout/useStderr
    public struct StdinInfo { public let handle: FileHandle; public let isTTY: Bool; public let isRawMode: Bool }
    public struct StdoutInfo { public let handle: FileHandle; public let isTTY: Bool }
    public struct StderrInfo { public let handle: FileHandle; public let isTTY: Bool }

    /// Expose configured stdin stream and metadata
    public static func useStdin() -> StdinInfo {
        if let s = ioStreams {
            return StdinInfo(handle: s.stdin, isTTY: s.stdinIsTTY, isRawMode: s.stdinIsRawMode)
        }
        // Fallback: standard input with best-effort metadata
        let isTty = isatty(STDIN_FILENO) == 1
        return StdinInfo(handle: FileHandle.standardInput, isTTY: isTty, isRawMode: false)
    }

    /// Expose configured stdout stream and metadata
    public static func useStdout() -> StdoutInfo {
        if let s = ioStreams {
            return StdoutInfo(handle: s.stdout, isTTY: s.stdoutIsTTY)
        }
        let isTty = isatty(STDOUT_FILENO) == 1
        return StdoutInfo(handle: FileHandle.standardOutput, isTTY: isTty)
    }

    /// Expose configured stderr stream and metadata
    public static func useStderr() -> StderrInfo {
        if let s = ioStreams {
            return StderrInfo(handle: s.stderr, isTTY: s.stderrIsTTY)
        }
        let isTty = isatty(STDERR_FILENO) == 1
        return StderrInfo(handle: FileHandle.standardError, isTTY: isTty)
    }

    // MARK: - Dependency token helpers

    /// Build a stable string token from a dependency array.
    /// nil => nil (run every commit); [] => "" (mount-only); non-empty => stable joined token
    private static func depsToken(from deps: [AnyHashable]?) -> String? {
        guard let deps else { return nil }
        if deps.isEmpty { return "" }
        // Stable textual encoding with escaping to reduce collision risk
        func escape(_ s: String) -> String { s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "=", with: "\\=") }
        func encode(_ v: AnyHashable) -> String {
            switch v.base {
            case let s as String: return "Str=" + escape(s)
            case let b as Bool: return "Bool=" + (b ? "1" : "0")
            case let i as Int: return "Int=" + String(i)
            case let i8 as Int8: return "Int8=" + String(i8)
            case let i16 as Int16: return "Int16=" + String(i16)
            case let i32 as Int32: return "Int32=" + String(i32)
            case let i64 as Int64: return "Int64=" + String(i64)
            case let u as UInt: return "UInt=" + String(u)
            case let u8 as UInt8: return "UInt8=" + String(u8)
            case let u16 as UInt16: return "UInt16=" + String(u16)
            case let u32 as UInt32: return "UInt32=" + String(u32)
            case let u64 as UInt64: return "UInt64=" + String(u64)
            case let f as Float: return "Float=" + String(f)
            case let d as Double: return "Double=" + String(d)
            case let ident as IdentityToken:
                // Identity wrapper: encode by object identifier only
                return "Ident=" + String(UInt(bitPattern: ObjectIdentifier(ident.identityObject)))
            default:
                // Fallback to type + description only
                let typeName = String(describing: type(of: v.base))
                return "Val=" + escape(typeName) + "#" + escape(String(describing: v.base))
            }
        }
        let parts = deps.map { encode($0) }
        return "n=\(deps.count)|" + parts.joined(separator: "|")
    }

    // MARK: - Effects

    /// Register an effect for the current identity path with a stable key
    /// - Parameters:
    ///   - key: Stable key for this effect at the current path
    ///   - depsToken: Optional dependency token; if changed, cleanup then re-run
    ///   - effect: Async closure run after commit; returns optional sync cleanup closure
    ///
    /// Dependency guidelines:
    /// - Use stable primitives (Int, String, Bool, Double, etc.) in deps when possible.
    /// - Floating-point semantics follow Swift stringification:
    ///   * NaN compares stable-to-stable across commits ("nan"); does not trigger rerun by itself
    ///   * Signed zeroes "0.0" vs "-0.0" are distinct and will trigger reruns when changed
    /// - For object identity-based deps, wrap your object with Identity(obj). This encodes ObjectIdentifier only.
    /// - Avoid relying on the fallback (type + description) unless your type's description is stable across commits.
    /// Note: No default value to avoid ambiguity with the deps-array overload.
    public static func useEffect(_ key: String, depsToken: String?, _ effect: @escaping @Sendable () async -> (() -> Void)?) {
        let path = RuntimeStateContext.currentPath
        let id = path + "::" + key
        RuntimeStateContext.effectCollector?(id, depsToken, effect)
    }

    /// Ergonomic overload: deps array sugar
    /// - nil deps: run every commit; []: mount/unmount only; non-empty: rerun when any changes
    public static func useEffect(_ key: String, deps: [AnyHashable]? = nil, _ effect: @escaping @Sendable () async -> (() -> Void)?) {
        useEffect(key, depsToken: depsToken(from: deps), effect)
    }

    /// Request a rerender of the current application (bound by the runtime during render)
    public static func requestRerender() {
        RuntimeStateContext.requestRerender?()
    }

    // MARK: - useInput

    /// Registers a keyboard input handler for the current component.
    ///
    /// Lifecycle and timing:
    /// - The handler is subscribed during the post-render effect commit phase and unsubscribed when the effect
    ///   cleans up (on deps change or unmount).
    /// - Handlers are invoked on the RenderHandle actor when decoded KeyEvent values arrive from InputManager.
    ///
    /// isActive semantics and deps:
    /// - Passing isActive=false prevents events from being delivered to this handler; switching to true re-subscribes.
    /// - The hook uses useEffect internally with a stable key; it re-runs when isActive changes.
    ///
    /// Unsubscription:
    /// - The cleanup ensures the handler is removed from the RenderHandle registry on deps change and unmount, avoiding leaks.
    ///
    /// Interaction with exitOnCtrlC:
    /// - When RenderOptions.exitOnCtrlC is true, ctrlC/ctrlD trigger unmount and are not delivered to handlers.
    ///   Otherwise, ctrlC/ctrlD are delivered as KeyEvent.ctrlC/ctrlD.
    ///
    /// - Parameters:
    ///   - handler: Async closure receiving decoded KeyEvent values.
    ///   - isActive: When false, events are ignored for this handler (toggled via deps).
    public static func useInput(_ handler: @escaping @Sendable (KeyEvent) async -> Void, isActive: Bool = true, fileID: StaticString = #fileID, line: UInt = #line) {
        let key = "__useInput::\(fileID):\(line)"
        // Re-run when active flag changes; stable when unchanged
        let token = isActive ? "1" : "0"
        useEffect(key, depsToken: token) {
            let path = RuntimeStateContext.currentPath
            let id = path + "::" + key
            if let registrar = inputRegistrar {
                let cleanup = await registrar(id, handler, isActive)
                return cleanup
            } else {
                return nil
            }
        }
    }

    // MARK: - useRef

    public final class Ref<T>: @unchecked Sendable {
        public var current: T
        public init(_ value: T) { current = value }
    }

    /// Stable mutable container that persists across rerenders and does not trigger rerenders when mutated
    public static func useRef<T>(_ initial: @autoclosure @escaping () -> T, fileID: StaticString = #fileID, line: UInt = #line) -> Ref<T> {
        let path = RuntimeStateContext.currentPath
        let key = "__ref::\(fileID):\(line)"
        return StateRegistry.shared.get(path: path, key: key, initial: Ref<T>(initial()))
    }

    /// Explicit-key overload for useRef when call-site based keys are not stable across platforms or builds
    /// Prefer the default overload in app code; this exists primarily for tests and advanced cases.
    public static func useRef<T>(key: String, _ initial: @autoclosure @escaping () -> T) -> Ref<T> {
        let path = RuntimeStateContext.currentPath
        let k = "__ref::\(key)"
        return StateRegistry.shared.get(path: path, key: k, initial: Ref<T>(initial()))
    }

    // MARK: - useMemo

    private struct MemoEntry<T> {
        var token: String?
        var value: T
    }

    /// Memoize a computed value using dependency array semantics. Recompute when deps change.
    /// See useEffect doc for dependency guidelines and Identity wrapper usage.
    public static func useMemo<T>(_ compute: @escaping () -> T, deps: [AnyHashable]? = nil, fileID: StaticString = #fileID, line: UInt = #line) -> T {
        let path = RuntimeStateContext.currentPath
        let key = "__memo::\(fileID):\(line)"
        let token = depsToken(from: deps)

        if token == nil {
            // Always recompute; do not overwrite stored token/value to avoid creating state churn
            let newValue = compute()
            // Keep last value cached for potential future []/non-empty deps usage at same site
            if let existing: MemoEntry<T> = StateRegistry.shared.getIfExists(path: path, key: key) {


                StateRegistry.shared.set(path: path, key: key, value: MemoEntry(token: existing.token, value: newValue))
            } else {
                StateRegistry.shared.set(path: path, key: key, value: MemoEntry(token: nil, value: newValue))
            }
            return newValue
        }

        var entry: MemoEntry<T> = StateRegistry.shared.get(path: path, key: key, initial: MemoEntry(token: token, value: compute()))
        if entry.token != token {
            let newValue = compute()
            entry = MemoEntry(token: token, value: newValue)
            StateRegistry.shared.set(path: path, key: key, value: entry)
            return newValue
        } else {
            return entry.value
        }
    }
}
