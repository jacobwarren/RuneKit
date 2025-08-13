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
    @TaskLocal public static var inputRegistrar: (@Sendable (_ id: String, _ handler: @escaping @Sendable (KeyEvent) async -> Void, _ isActive: Bool, _ requiresFocus: Bool) async -> (@Sendable () -> Void))?

    /// App context for controlling the running application (exit/clear) from within components/effects
    @TaskLocal public static var appContext: AppContext?

    // Focus registry task-locals
    /// Recorder invoked during render when a component calls useFocus(); the runtime binds this to collect focusable identity paths in render order.
    @TaskLocal public static var focusRecorder: (@Sendable (_ path: String) -> Void)?
    /// Currently focused identity path bound during render so useFocus() can return whether the current component is focused.
    @TaskLocal public static var focusedPath: String?
    /// Programmatic focus manager bound during render/effect commit for useFocusManager()
    @TaskLocal public static var focusManager: FocusManager?


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

    // MARK: - useApp
    /// Access the application context for programmatic control from components/effects
    /// The runtime binds this during render/effect commit; calling outside a render/effect will be a no-op stub.
    public static func useApp() -> AppContext {
        if let ctx = appContext { return ctx }
        // Fallback no-op context to keep tests/app code safe when not bound
        return AppContext(exit: { _ in }, clear: { })
    }

    // MARK: - Dependency token helpers

    /// Build a stable string token from a dependency array.
    /// nil => nil (run every commit); [] => "" (mount-only); non-empty => stable joined token
    private static func depsToken(from deps: [AnyHashable]?) -> String? {
        guard let deps else { return nil }
        if deps.isEmpty { return "" }
        let parts = deps.map { encodeValue($0) }
        return "n=\(deps.count)|" + parts.joined(separator: "|")
    }

    // Extracted helpers to keep complexity low while preserving exact encoding behavior
    private static func encodeValue(_ value: AnyHashable) -> String {
        if let encoded = encodeStringBool(value) { return encoded }
        if let encoded = encodeSignedInts(value) { return encoded }
        if let encoded = encodeUnsignedInts(value) { return encoded }
        if let encoded = encodeFloats(value) { return encoded }
        if let encoded = encodeIdentity(value) { return encoded }
        let typeName = String(describing: type(of: value.base))
        return "Val=" + escape(typeName) + "#" + escape(String(describing: value.base))
    }

    private static func encodeStringBool(_ value: AnyHashable) -> String? {
        switch value.base {
        case let str as String: return "Str=" + escape(str)
        case let bool as Bool: return "Bool=" + (bool ? "1" : "0")
        default: return nil
        }
    }

    private static func encodeSignedInts(_ value: AnyHashable) -> String? {
        switch value.base {
        case let int as Int: return "Int=" + String(int)
        case let int8 as Int8: return "Int8=" + String(int8)
        case let int16 as Int16: return "Int16=" + String(int16)
        case let int32 as Int32: return "Int32=" + String(int32)
        case let int64 as Int64: return "Int64=" + String(int64)
        default: return nil
        }
    }

    private static func encodeUnsignedInts(_ value: AnyHashable) -> String? {
        switch value.base {
        case let uint as UInt: return "UInt=" + String(uint)
        case let uint8 as UInt8: return "UInt8=" + String(uint8)
        case let uint16 as UInt16: return "UInt16=" + String(uint16)
        case let uint32 as UInt32: return "UInt32=" + String(uint32)
        case let uint64 as UInt64: return "UInt64=" + String(uint64)
        default: return nil
        }
    }

    private static func encodeFloats(_ value: AnyHashable) -> String? {
        switch value.base {
        case let float as Float: return "Float=" + String(float)
        case let double as Double: return "Double=" + String(double)
        default: return nil
        }
    }

    private static func encodeIdentity(_ value: AnyHashable) -> String? {
        if let ident = value.base as? IdentityToken {
            return "Ident=" + String(UInt(bitPattern: ObjectIdentifier(ident.identityObject)))
        }
        return nil
    }

    private static func escape(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "=", with: "\\=")
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


    // MARK: - Focus Manager API

    /// Manager for programmatic focus control exposed via useFocusManager()
    public struct FocusManager: Sendable {
        private let _next: @Sendable () async -> Void
        private let _previous: @Sendable () async -> Void
        private let _focusPath: @Sendable (String) async -> Bool
        private let _focusId: @Sendable (String) async -> Bool
        private let _focusedPath: @Sendable () async -> String?
        public init(
            next: @escaping @Sendable () async -> Void,
            previous: @escaping @Sendable () async -> Void,
            focusPath: @escaping @Sendable (String) async -> Bool,
            focusId: @escaping @Sendable (String) async -> Bool,
            focusedPath: @escaping @Sendable () async -> String?
        ) {
            self._next = next
            self._previous = previous
            self._focusPath = focusPath
            self._focusId = focusId
            self._focusedPath = focusedPath
        }
        public func next() async { await _next() }
        public func previous() async { await _previous() }
        public func focus(path: String) async -> Bool { await _focusPath(path) }
        public func focus(id: String) async -> Bool { await _focusId(id) }
        public func focusedPath() async -> String? { await _focusedPath() }
    }

    /// Access a FocusManager for programmatic focus control. Returns a no-op manager when not bound.
    public static func useFocusManager() -> FocusManager {
        if let mgr = focusManager { return mgr }
        return FocusManager(
            next: {},
            previous: {},
            focusPath: { _ in false },
            focusId: { _ in false },
            focusedPath: { nil }
        )
    }

    // MARK: - useFocus / Focus Manager

    /// Mark the current component as focusable and return whether it is currently focused.
    /// The runtime collects focusable identity paths during render via `focusRecorder` and binds
    /// the currently focused path via `focusedPath` so this returns true for exactly one element.
    /// When no focusables are registered in a frame, focus gating is disabled (broadcast semantics).
    public static func useFocus() -> Bool {
        let path = RuntimeStateContext.currentPath
        // Record this focusable in render order for the runtime to build the tab ring
        focusRecorder?(path)
        // Return whether this path is currently focused
        if let fp = focusedPath { return fp == path }
        return false
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
    ///   - requiresFocus: When true (default), events are delivered only when this component is focused if any focusables exist. When false, the handler is global and receives all events regardless of focus.
    public static func useInput(_ handler: @escaping @Sendable (KeyEvent) async -> Void, isActive: Bool = true, requiresFocus: Bool = true, fileID: StaticString = #fileID, line: UInt = #line) {
        let key = "__useInput::\(fileID):\(line)"
        // Re-run when active or focus requirement changes; stable when unchanged
        let token = (isActive ? "1" : "0") + (requiresFocus ? "F" : "G")
        useEffect(key, depsToken: token) {
            let path = RuntimeStateContext.currentPath
            let id = path + "::" + key
            if let registrar = inputRegistrar {
                let cleanup = await registrar(id, handler, isActive, requiresFocus)
                return cleanup
            } else {
                return nil
            }
        }
    }

    /// Back-compat overload without requiresFocus parameter (defaults to true)
    public static func useInput(_ handler: @escaping @Sendable (KeyEvent) async -> Void, isActive: Bool = true, fileID: StaticString = #fileID, line: UInt = #line) {
        useInput(handler, isActive: isActive, requiresFocus: true, fileID: fileID, line: line)
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
