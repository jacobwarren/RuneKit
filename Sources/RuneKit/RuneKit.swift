// swiftlint:disable file_length
// RuneKit - A Swift library for terminal user interfaces
//
// RuneKit is inspired by Ink (React for CLIs) and provides a declarative
// way to build terminal-based user interfaces using Swift. It combines
// the power of Swift's type system with efficient terminal rendering.
//
// ## Architecture
//
// RuneKit is built on four core subsystems:
///
/// 1. **Text Engine** (`RuneANSI` + `RuneUnicode`)
///    - ANSI escape sequence parsing and tokenization
///    - Accurate Unicode width calculations for emoji, CJK, and complex scripts
///    - Foundation for text wrapping and alignment
///
/// 2. **Layout Engine** (`RuneLayout`)
///    - Flexbox-inspired layout system optimized for terminals
///    - Constraint-based sizing and positioning
///    - Support for complex nested layouts
///
/// 3. **Renderer** (`RuneRenderer`)
///    - Efficient terminal frame rendering with ANSI escape sequences
///    - Actor-based thread-safe output management
///    - Cursor control and screen management
///
/// 4. **Components** (`RuneComponents`)
///    - Reusable UI building blocks (Text, Box, etc.)
///    - Layout-aware rendering within provided rectangles
///    - Foundation for complex UI composition
///
/// ## Usage
///
/// ```swift
/// import RuneKit
///
/// // Basic text rendering
/// let text = Text("Hello, RuneKit!")
/// let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
/// let lines = text.render(in: rect)
///
/// // ANSI tokenization
/// let tokenizer = ANSITokenizer()
/// let tokens = tokenizer.tokenize("\u{001B}[31mRed Text\u{001B}[0m")
///
/// // Unicode width calculation
/// let width = Width.displayWidth(of: "👨‍👩‍👧‍👦") // Returns 2
/// ```

/// RuneKit - A Swift library for terminal user interfaces
///
/// RuneKit is inspired by Ink (React for CLIs) and provides a declarative
/// way to build terminal-based user interfaces using Swift. It combines
/// the power of Swift's type system with efficient terminal rendering.
public enum RuneKit {}


public extension RuneKit {
    /// Convert a View into Frame synchronously for tests
    static func convertForTesting(_ view: some View) async -> TerminalRenderer.Frame {
        let tree = ComponentTreeReconciler()
        return convertViewToFrame(view, tree: tree, terminalProfile: TerminalProfile.xterm256)
    }
}

// Re-export all modules for convenient access
@_exported import RuneANSI
@_exported import RuneComponents
@_exported import RuneLayout
@_exported import RuneRenderer
@_exported import RuneUnicode

// MARK: - RUNE-24: render(_:options) API

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// Options for configuring the render function behavior
///
/// This structure provides comprehensive configuration for terminal rendering,
/// including I/O redirection, signal handling, console capture, and performance tuning.
/// Defaults are intelligently chosen based on TTY detection and CI environment heuristics.
public struct RenderOptions: Sendable {
    /// Output file handle for rendered content
    public let stdout: FileHandle

    /// Input file handle for user interaction
    public let stdin: FileHandle

    /// Error output file handle for logs and errors
    public let stderr: FileHandle

    /// Whether to exit gracefully on Ctrl+C (SIGINT/SIGTERM)
    public let exitOnCtrlC: Bool

    /// Whether to capture stdout/stderr and display logs above live region
    public let patchConsole: Bool

    /// Whether to use alternate screen buffer if available
    public let useAltScreen: Bool

    /// Whether to put stdin into raw mode (disable canonical/echo) for interactive input
    public let enableRawMode: Bool

    /// Whether to enable bracketed paste mode and emit paste events
    public let enableBracketedPaste: Bool

    /// Maximum frame rate cap (frames per second)
    public let fpsCap: Double

    /// Explicit terminal profile override (nil = use heuristic)
    public let terminalProfileOverride: TerminalProfile?

    // MARK: - Initialization

    /// Initialize with explicit options
    /// - Parameters:
    ///   - stdout: Output file handle (default: FileHandle.standardOutput)
    ///   - stdin: Input file handle (default: FileHandle.standardInput)
    ///   - stderr: Error output file handle (default: FileHandle.standardError)
    ///   - exitOnCtrlC: Exit on Ctrl+C (default: TTY-aware)
    ///   - patchConsole: Capture console output (default: TTY-aware)
    ///   - useAltScreen: Use alternate screen buffer (default: TTY-aware)
    ///   - fpsCap: Frame rate cap in FPS (default: 60.0)
    ///   - terminalProfile: Explicit terminal profile override (default: nil = heuristic)
    public init(
        stdout: FileHandle = FileHandle.standardOutput,
        stdin: FileHandle = FileHandle.standardInput,
        stderr: FileHandle = FileHandle.standardError,
        exitOnCtrlC: Bool? = nil,
        patchConsole: Bool? = nil,
        useAltScreen: Bool? = nil,
        enableRawMode: Bool? = nil,
        enableBracketedPaste: Bool? = nil,
        fpsCap: Double = 60.0,
        terminalProfile: TerminalProfile? = nil,
    ) {
        self.stdout = stdout
        self.stdin = stdin
        self.stderr = stderr
        self.fpsCap = fpsCap
        terminalProfileOverride = terminalProfile

        // Use TTY-aware defaults if not explicitly provided
        let isInteractive = Self.isInteractiveTerminal()
        let isCI = Self.isCIEnvironment()

        self.exitOnCtrlC = exitOnCtrlC ?? (isInteractive && !isCI)
        self.patchConsole = patchConsole ?? (isInteractive && !isCI)
        self.useAltScreen = useAltScreen ?? (isInteractive && !isCI)
        // Input defaults: raw + paste when interactive TTY and not CI
        self.enableRawMode = enableRawMode ?? (isInteractive && !isCI)
        self.enableBracketedPaste = enableBracketedPaste ?? (isInteractive && !isCI)
    }

    // MARK: - Environment Detection

    /// Detect if running in an interactive terminal (TTY)
    /// - Returns: True if stdout is connected to a TTY
    public static func isInteractiveTerminal() -> Bool {
        isatty(STDOUT_FILENO) == 1
    }

    /// Detect if running in a CI environment
    /// - Returns: True if common CI environment variables are present
    public static func isCIEnvironment() -> Bool {
        isCIEnvironment(ProcessInfo.processInfo.environment)
    }

    /// Detect if running in a CI environment with custom environment
    /// - Parameter environment: Environment variables dictionary
    /// - Returns: True if common CI environment variables are present
    public static func isCIEnvironment(_ environment: [String: String]) -> Bool {
        let ciIndicators = [
            "CI", "CONTINUOUS_INTEGRATION",
            "GITHUB_ACTIONS", "GITLAB_CI", "CIRCLECI",
            "TRAVIS", "JENKINS_URL", "BUILDKITE",
            "AZURE_PIPELINES", "TEAMCITY_VERSION",
        ]

        return ciIndicators.contains { environment[$0] != nil }
    }

    /// Create options from environment variables with intelligent defaults
    /// - Parameter environment: Environment variables (default: ProcessInfo.processInfo.environment)
    /// - Returns: RenderOptions configured based on environment
    public static func fromEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo
            .environment,
    ) -> RenderOptions {
        let isCI = isCIEnvironment(environment)
        let isInteractive = isInteractiveTerminal()
        let isTestHarness = environment["XCTestConfigurationFilePath"] != nil || environment["SWIFTPM_TEST"] != nil
        let envProfile = RenderOptions.terminalProfileFromEnvironment(environment)

        // CI/Test-harness specific defaults
        if isCI || isTestHarness {
            return RenderOptions(
                exitOnCtrlC: false,
                patchConsole: false, // never patch stdout/stderr under test runner
                useAltScreen: false,
                enableRawMode: false,
                enableBracketedPaste: false,
                fpsCap: 30.0,
                terminalProfile: envProfile,
            )
        }

        // Interactive terminal defaults (outside CI/tests)
        if isInteractive {
            return RenderOptions(
                exitOnCtrlC: true,
                patchConsole: true,
                useAltScreen: false, // default to main buffer like Ink
                enableRawMode: true,
                enableBracketedPaste: true,
                fpsCap: 60.0,
                terminalProfile: envProfile,
            )
        }

        // Non-interactive defaults (pipes, redirects)
        return RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 30.0,
            terminalProfile: envProfile,
        )
    }
}

// MARK: - Signal Handling

/// Thread-safe global signal handler state for C callbacks
@MainActor private var globalSignalHandler: SignalHandler?

/// C signal handler function
private func handleSignalC(_ signal: Int32) {
    // Handle signal in a task since we need async context
    Task { @MainActor in
        await globalSignalHandler?.handleSignal(signal)
    }
}

/// Actor-based signal handler for graceful application termination
///
/// This actor provides thread-safe signal handling for SIGINT (Ctrl+C) and SIGTERM,
/// allowing applications to perform cleanup before exiting. It integrates with the
/// render system to ensure proper teardown of terminal state.
public actor SignalHandler {
    /// Callback type for graceful teardown
    public typealias TeardownCallback = @Sendable () async -> Void

    /// Whether signal handlers are currently installed
    private(set) var isInstalled = false

    /// Teardown callback to execute on signal
    private var teardownCallback: TeardownCallback?

    /// Previous signal handlers for restoration
    private var previousSIGINTHandler: sig_t?
    private var previousSIGTERMHandler: sig_t?

    // MARK: - Initialization

    /// Initialize signal handler
    public init() {}

    /// Deinitializer ensures signal handlers are cleaned up
    deinit {
        // Note: Cannot perform async operations in deinit
        // Signal handler cleanup must be done explicitly via cleanup()
        // We can only do synchronous cleanup here
        if isInstalled {
            // Restore signal handlers synchronously
            if let previousHandler = previousSIGINTHandler {
                signal(SIGINT, previousHandler)
            }
            if let previousHandler = previousSIGTERMHandler {
                signal(SIGTERM, previousHandler)
            }
        }
    }

    // MARK: - Public Interface

    /// Install signal handlers for graceful termination
    /// - Parameter teardownCallback: Callback to execute on signal reception
    public func install(teardownCallback: @escaping TeardownCallback) async {
        guard !isInstalled else { return }

        self.teardownCallback = teardownCallback

        // Set global reference for C callback
        await MainActor.run {
            globalSignalHandler = self
        }

        // Install signal handlers
        previousSIGINTHandler = signal(SIGINT, handleSignalC)
        previousSIGTERMHandler = signal(SIGTERM, handleSignalC)

        isInstalled = true
    }

    /// Clean up signal handlers and restore previous handlers
    public func cleanup() async {
        guard isInstalled else { return }

        restoreSignalHandlers()
        teardownCallback = nil
        isInstalled = false

        // Clear global reference
        await MainActor.run {
            globalSignalHandler = nil
        }
    }

    /// Perform graceful teardown (for testing or manual invocation)
    public func performGracefulTeardown() async {
        await teardownCallback?()
    }

    // MARK: - Private Implementation

    /// Restore previous signal handlers
    private func restoreSignalHandlers() {
        if let previousHandler = previousSIGINTHandler {
            signal(SIGINT, previousHandler)
            previousSIGINTHandler = nil
        }

        if let previousHandler = previousSIGTERMHandler {
            signal(SIGTERM, previousHandler)
            previousSIGTERMHandler = nil
        }
    }

    /// Handle received signal
    func handleSignal(_ signal: Int32) async {
        switch signal {
        case SIGINT, SIGTERM:
            await performGracefulTeardown()
        // Note: In a real app, this would exit, but for testing we don't
        // exit(0)
        default:
            break
        }
    }
}

// MARK: - View Protocol and Render Function

/// Protocol for declarative UI views (similar to SwiftUI/Ink.js)
///
/// This protocol provides a declarative way to build terminal UIs,
/// where views describe what they should look like rather than how to render them.
public protocol View {
    /// The type of view representing the body of this view
    associatedtype Body: View

    /// The content and behavior of the view
    var body: Self.Body { get }
}

/// Views can optionally provide a stable identity to influence state preservation
public protocol ViewIdentifiable {
    /// A stable identity string for the view instance. When this changes between rerenders,
    /// the renderer resets internal diff state to avoid incorrectly preserving UI state.
    var viewIdentity: String? { get }
}

public extension ViewIdentifiable {
    var viewIdentity: String? { nil }
}

/// Empty view type for leaf views
public struct EmptyView: View {
    public var body: EmptyView { self }
    public init() {}
}

/// Make Text conform to View protocol
extension Text: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

/// Default: no explicit identity
extension Text: ViewIdentifiable {}

/// Make Box conform to View protocol
extension Box: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

extension Box: ViewIdentifiable {}

/// Make Static conform to View protocol
extension Static: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

extension Static: ViewIdentifiable {}

    // MARK: - View -> Component bridging for Box(children: ...)
    /// Adapter that allows using any View as a Component child inside Box initializers
    private struct ViewComponentAdapter<V: View>: Component {
        let view: V
        func render(in rect: FlexLayout.Rect) -> [String] {
            // Convert the stored View to a concrete Component using the current identity path context
            let path = RuntimeStateContext.currentPath
            let component = convertViewToComponent(view, currentPath: path)
            return component.render(in: rect)
        }
    }

    /// Existential adapter wrapping any View as a Component at render time
    private struct AnyViewComponent: Component {
        let view: any View
        func render(in rect: FlexLayout.Rect) -> [String] {
            let path = RuntimeStateContext.currentPath
            let component = convertViewToComponent(view, currentPath: path)
            return component.render(in: rect)
        }
    }

    /// Convenience overload to allow Box(children: ...) to accept View children with at least one element.
    /// This avoids ambiguity with Box() and other initializers.
    public extension Box {
        init(children first: any View, _ rest: any View...) {
            let items: [any View] = [first] + rest
            let comps: [Component] = items.map { AnyViewComponent(view: $0) }
            self.init(childrenArray: comps)
        }
    }

/// Make Newline conform to View protocol
extension Newline: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

extension Newline: ViewIdentifiable {}

/// Make Transform conform to View protocol
extension Transform: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

extension Transform: ViewIdentifiable {}

/// Handle for controlling a running render session
///
/// This actor provides control over a running terminal application,
/// allowing for programmatic updates, state queries, and graceful shutdown.
public actor RenderHandle {
    /// The frame buffer handling rendering
    private let frameBuffer: FrameBuffer

    /// Shadow component tree reconciler for lifecycle/state
    let componentTree = ComponentTreeReconciler()

    /// Signal handler for graceful termination
    private var signalHandler: SignalHandler?

    /// Input manager for raw-mode and key events
    private var inputManager: InputManager?

    /// Entry for an input handler; avoids large tuple lint violations
    private struct InputHandlerEntry {
        let active: Bool
        let requiresFocus: Bool
        let path: String
        let handler: @Sendable (KeyEvent) async -> Void
    }

    /// Registry of active input handlers keyed by effect id
    /// - requiresFocus: when true, the handler only receives events if focused when any focusables exist.
    private var inputHandlers: [String: InputHandlerEntry] = [:]

    /// Focus management state
    private var focusablesInOrder: [String] = [] // identity paths registered during last render
    private var focusedIndex: Int = 0
    private var focusedPath: String? {
        guard !focusablesInOrder.isEmpty else { return nil }
        if focusedIndex < 0 || focusedIndex >= focusablesInOrder.count { focusedIndex = 0 }
        return focusablesInOrder[focusedIndex]
    }

    // Build a Streams snapshot for hooks (useStdin/useStdout/useStderr)
    func streamsSnapshot() -> IOHooks.Streams {
        // Safely determine FDs for standard streams without touching NSStdIO wrappers that can throw
        func fd(for handle: FileHandle, fallback: Int32) -> Int32 {
            if handle === FileHandle.standardInput { return STDIN_FILENO }
            if handle === FileHandle.standardOutput { return STDOUT_FILENO }
            if handle === FileHandle.standardError { return STDERR_FILENO }
            return handle.fileDescriptor
        }
        let stdinFD = fd(for: options.stdin, fallback: STDIN_FILENO)
        let stdoutFD = fd(for: options.stdout, fallback: STDOUT_FILENO)
        let stderrFD = fd(for: options.stderr, fallback: STDERR_FILENO)
        let stdinIsTTY = isatty(stdinFD) == 1
        let stdoutIsTTY = isatty(stdoutFD) == 1
        let stderrIsTTY = isatty(stderrFD) == 1
        let isRaw = options.enableRawMode && stdinIsTTY
        return IOHooks.Streams(
            stdin: options.stdin,
            stdout: options.stdout,
            stderr: options.stderr,
            stdinIsTTY: stdinIsTTY,
            stdoutIsTTY: stdoutIsTTY,
            stderrIsTTY: stderrIsTTY,
            stdinIsRawMode: isRaw
        )
    }

    /// Whether the handle has been unmounted
    private var isUnmounted = false

    /// Render options used for this session
    private let options: RenderOptions

    /// Whether the render session is currently active
    public private(set) var isActive = true

    /// Continuations waiting for exit
    private var exitContinuations: [CheckedContinuation<Void, Never>] = []

    /// Last rendered view identity (type + explicit identity if provided).
    private var lastViewIdentity: String?

    /// Root rebuilder for hook-driven rerenders (captures last provided view)
    private var rootRebuilder: (() async -> Void)?

    /// Stable build-context path for hooks executed during the builder phase
    /// Ensures useRef/useMemo keys are consistent across rerenders for this handle
    private let buildContextPath: String = {
        let uuid = UUID().uuidString
        return "build#" + uuid
    }()

    /// Effect state: id -> (depsToken, cleanup)
    private var effects: [String: (deps: String?, cleanup: (() -> Void)?)] = [:]

    /// Exit status captured when app requests exit
    public struct ExitStatus: Sendable { public let code: Int32; public let errorDescription: String? }
    private var exitStatus: ExitStatus?

    /// Internal: set exit status once
    private func setExitStatusIfNeeded(_ status: ExitStatus) {
        if exitStatus == nil { exitStatus = status }
    }

    // Split markers retained, but keep methods inside actor to preserve access control
        /// Public accessor for exit status (nil until unmount requested)
        public func getExitStatus() async -> ExitStatus? { exitStatus }

        /// Helper invoked from requestRerender to avoid capturing non-Sendable state
        private func rerenderUsingRoot() async { await rootRebuilder?() }

        // MARK: - Input handler registration

        private func registerInputHandler(id: String, isActive: Bool, requiresFocus: Bool, path: String, handler: @escaping @Sendable (KeyEvent) async -> Void) -> @Sendable () -> Void {
            inputHandlers[id] = InputHandlerEntry(active: isActive, requiresFocus: requiresFocus, path: path, handler: handler)
            let cleanup: @Sendable () -> Void = { [weak self] in
                Task { await self?.removeInputHandler(id: id) }
            }
            return cleanup
        }

        /// Dispatch input to handlers observing focus gating rules. Also handles Tab/Shift+Tab to change focus.
        public func dispatchInput(_ event: KeyEvent) async {
            // Handle Tab / Shift+Tab focus movement first
            if case .key(let kind, let mods) = event {
                if kind == .tab {
                    if mods.contains(.shift) {
                        await focusPrevious()
                    } else {
                        await focusNext()
                    }
                    return
                }
            }

            // Snapshot handlers and focus state
            let handlers = inputHandlers
            let currentFocusPath = focusedPath
            let anyFocusables = !(focusablesInOrder.isEmpty)

            for (_, entry) in handlers where entry.active {
                if !anyFocusables || !entry.requiresFocus {
                    await entry.handler(event)
                } else if let fp = currentFocusPath, fp == entry.path {
                    await entry.handler(event)
                }
            }
        }

        // Focus movement helpers
        public func focusNext() async {
            guard !focusablesInOrder.isEmpty else { return }
            focusedIndex = (focusedIndex + 1) % focusablesInOrder.count
            await rerenderUsingRoot()
        }

        public func focusPrevious() async {
            guard !focusablesInOrder.isEmpty else { return }
            focusedIndex = (focusedIndex - 1 + focusablesInOrder.count) % focusablesInOrder.count
            await rerenderUsingRoot()
        }

        // Programmatic focus controls
        public nonisolated func currentFocusedPath() async -> String? { await self.focusedPath }
        public func focus(path: String) async -> Bool {
            guard let idx = focusablesInOrder.firstIndex(of: path) else { return false }
            focusedIndex = idx
            await rerenderUsingRoot()
            return true
        }
        public func focus(id: String) async -> Bool {
            guard let idx = focusablesInOrder.firstIndex(where: { path in
                // Match id as a full path segment
                path.split(separator: "/").contains(where: { $0 == id })
            }) else {
                return false
            }
            focusedIndex = idx
            await rerenderUsingRoot()
            return true
        }

        private func removeInputHandler(id: String) {
            inputHandlers.removeValue(forKey: id)
        }

        // Expose setter for initial focusables
        func setFocusables(_ paths: [String]) {
            focusablesInOrder = paths
            if focusedIndex >= focusablesInOrder.count { focusedIndex = max(0, focusablesInOrder.count - 1) }
        }

    // MARK: - Initialization

    /// Initialize render handle with frame buffer and options
    /// - Parameters:
    ///   - frameBuffer: Frame buffer for rendering
    ///   - signalHandler: Optional signal handler for Ctrl+C handling
    ///   - options: Render options used for this session
    init(frameBuffer: FrameBuffer, signalHandler: SignalHandler?, options: RenderOptions) {
        self.frameBuffer = frameBuffer
        self.signalHandler = signalHandler
        self.options = options
    }

    // MARK: - Public Interface

    /// Stop the render session and clean up resources
    public func stop() async {
        guard isActive else { return }

        // Clean up signal handler
        await signalHandler?.cleanup()

        // Stop input manager
        await inputManager?.stop()
        inputManager = nil

        // Clear the frame buffer
        await frameBuffer.clear()

        // Run effect cleanups
        runAllEffectCleanups()

        isActive = false
    }

    /// Unmount the render session and tear down all resources
    ///
    /// This method performs a complete teardown of the render session, including:
    /// - Cleaning up signal handlers
    /// - Clearing the frame buffer and restoring terminal state
    /// - Resolving any pending waitUntilExit() calls
    /// - Making the handle inactive
    ///
    /// This method is idempotent - multiple calls are safe and will not cause errors.
    /// After unmounting, the handle becomes inactive and cannot be used for rendering.
    public func unmount() async {
        // Idempotent - safe to call multiple times
        guard !isUnmounted else { return }

        // Mark as unmounted first to prevent race conditions
        isUnmounted = true
        isActive = false

        // Clean up signal handler
        await signalHandler?.cleanup()

        // Stop input manager
        await inputManager?.stop()
        inputManager = nil

        // Clear the frame buffer and restore terminal state
        await frameBuffer.clear()

        // Run effect cleanups and clear
        runAllEffectCleanups()
        effects.removeAll()

        // Resolve all pending waitUntilExit continuations
        let continuationsToResume = exitContinuations
        exitContinuations.removeAll()

        for continuation in continuationsToResume {
            continuation.resume()
        }
    }

    /// Wait until the render session exits
    ///
    /// This method suspends the current task until the render session is unmounted.
    /// If the session is already unmounted, this method returns immediately.
    /// Multiple concurrent calls to this method are safe and will all resolve when unmount() is called.
    ///
    /// This provides a way to wait for the application to terminate gracefully,
    /// similar to Ink's waitUntilExit functionality.
    public func waitUntilExit() async {
        // If already unmounted, return immediately
        guard !isUnmounted else { return }

        // Suspend until unmount() is called
        await withCheckedContinuation { continuation in
            exitContinuations.append(continuation)
        }
    }

    /// Check if signal handler is installed (for testing)
    public func hasSignalHandler() async -> Bool {
        guard let handler = signalHandler else { return false }
        return await handler.isInstalled
    }

    /// Check if console capture is active (for testing)
    public func hasConsoleCapture() async -> Bool {
        await frameBuffer.isConsoleCaptureActive()
    }

    /// Set the signal handler for this render session (internal use)
    /// - Parameter handler: Signal handler to associate with this session
    func setSignalHandler(_ handler: SignalHandler) async {
        signalHandler = handler
    }

    /// Set input manager (internal use)
    func setInputManager(_ mgr: InputManager) async {
        inputManager = mgr
    }

    /// Record exit status then unmount; idempotent
    func recordExitStatusAndUnmount(code: Int32, description: String?) async {
        setExitStatusIfNeeded(ExitStatus(code: code, errorDescription: description))
        await unmount()
    }

    /// Clear the screen or region based on render options
    ///
    /// This method clears the terminal content according to the current render configuration:
    /// - If using alternate screen buffer, it will clear the alternate screen
    /// - Otherwise, it clears the main screen content
    /// - Console capture logs are also cleared if active
    ///
    /// This method is safe to call multiple times and will not affect the handle's active state.
    /// The handle remains usable for further rendering operations after clearing.
    public func clear() async {
        // Clear the frame buffer which handles different clearing modes
        await frameBuffer.clear()
    }

    /// Update the rendered view (rerender with new content)
    ///
    /// This method updates the UI with a new view while preserving application state
    /// unless the view identity changes. State preservation behavior:
    ///
    /// **State Preservation Rules:**
    /// - Same view type with same identity: State is preserved across rerenders
    /// - Different view type or identity: State is reset to initial values
    /// - View hierarchy changes: State is preserved for matching subtrees
    ///
    /// **Identity Determination:**
    /// View identity is determined by the view's type and any explicit identity markers.
    /// For stateful views, consider implementing proper identity mechanisms to control
    /// when state should be preserved vs. reset.
    ///
    /// **Performance Notes:**
    /// This method is optimized for frequent updates and uses the hybrid reconciler
    /// to minimize terminal output. Multiple rapid calls are safe and efficient.
    ///

    /// This provides programmatic control over the rendered content and supports
    /// dynamic UI updates similar to Ink's rerender functionality.
    ///

        /// Align internal identity and reset diff/component tree if changed
        public func alignIdentity(_ identity: String) async {
            if lastViewIdentity != identity {
                await frameBuffer.resetDiffState()
                lastViewIdentity = identity
                await componentTree.reset()
            }
        }

    /// State preservation semantics:
    /// - If the incoming view has the same identity as the previous render, preserve
    ///   internal diff state for efficient updates.
    /// - If identity changes, reset diff state to avoid stale UI.
    ///
    /// - Parameter view: The new view to render
    public func rerender(_ view: some View) async {
        // Determine identity for state preservation
        let typeName = String(describing: type(of: view))
        let explicit = (view as? ViewIdentifiable)?.viewIdentity
        let identity = [typeName, explicit].compactMap(\.self).joined(separator: "#")
        if lastViewIdentity != identity {
            await frameBuffer.resetDiffState()
            lastViewIdentity = identity
            await componentTree.reset()
        }

        // Collect effects registered during this render
        let box = EffectCollectorBox()
        let streams = streamsSnapshot()
        let frame: TerminalRenderer.Frame = await RuntimeStateContext.$effectCollector.withValue({ id, deps, effect in
            box.add(id: id, deps: deps, effect: effect)
        }, operation: {
            // Bind IO streams for any hooks invoked during build/render
            await HooksRuntime.$ioStreams.withValue(streams) {
                // Begin a logical frame for the componentTree
                await componentTree.beginFrame(rootPath: identity)
            }
            // Compute frame while recording focusables and binding current focusedPath
            let focusables = HooksFocusCollector()
            let frame: TerminalRenderer.Frame = HooksRuntime.$focusedPath.withValue(self.focusedPath) {
                HooksRuntime.$focusRecorder.withValue({ path in
                    focusables.record(path)
                }, operation: {
                    convertViewToFrame(view, tree: componentTree, terminalProfile: options.terminalProfile)
                })
            }
            // Update focusables order and clamp focus index if needed
            self.focusablesInOrder = focusables.snapshot()
            if self.focusedIndex >= self.focusablesInOrder.count { self.focusedIndex = max(0, self.focusablesInOrder.count - 1) }
            await componentTree.endFrame()
            return frame
        })
        let collected = box.snapshot()

        // Render the frame
        await frameBuffer.renderFrame(frame)

        // Commit effects after frame commit, binding useApp() and I/O contexts
        let ctx = HooksRuntime.AppContext(exit: { [weak self] _ in
            guard let self else { return }
            await self.unmount()
        }, clear: { [weak self] in
            guard let self else { return }
            await self.clear()
        })
        await HooksRuntime.$appContext.withValue(ctx) {
            await HooksRuntime.$ioStreams.withValue(streams) {
                // Bind FocusManager during effects invocation so hooks can capture it
                let mgr = HooksRuntime.FocusManager(
                    next: { [weak self] in await self?.focusNext() },
                    previous: { [weak self] in await self?.focusPrevious() },
                    focusPath: { [weak self] path in await self?.focus(path: path) ?? false },
                    focusId: { [weak self] id in await self?.focus(id: id) ?? false },
                    focusedPath: { [weak self] in await self?.currentFocusedPath() }
                )
                await HooksRuntime.$focusManager.withValue(mgr) {
                    await commitEffects(collected)
                }
            }
        }
    }

    // MARK: - Effects commit/cleanup
    public func commitCollectedEffects(_ specs: [EffectCollectorBox.Entry]) async {
        await commitEffects(specs)
    }

    private func commitEffects(_ specs: [EffectCollectorBox.Entry]) async {
        // Build lookup of new specs
        var newMap: [String: (String?, @Sendable () async -> (() -> Void)?)] = [:]
        for entry in specs { newMap[entry.id] = (entry.deps, entry.effect) }

        // Clean up effects that disappeared
        for (id, entry) in effects where newMap[id] == nil {
            entry.cleanup?()
            effects.removeValue(forKey: id)
        }

        // For existing/new effects, run if deps changed, first mount, or if depsToken == nil (run every commit)
        for (id, pair) in newMap {
            let (depsToken, effect) = pair
            let prev = effects[id]
            let needsRun = prev == nil || depsToken == nil || prev?.deps != depsToken
            if needsRun {
                // Run previous cleanup if any
                prev?.cleanup?()
                // Give any scheduled tasks inside cleanup a chance to run (non-blocking)
                await Task.yield()
                // Bind requestRerender, inputRegistrar, and currentPath for this effect invocation
                let parts = id.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                let path = parts.first.map(String.init) ?? RuntimeStateContext.currentPath
                let cleanup = await RuntimeStateContext.$currentPath.withValue(path) {
                    await RuntimeStateContext.$requestRerender.withValue({ [weak self] in
                        guard let self else { return }
                        Task { await self.rerenderUsingRoot() }
                    }, operation: {
                        await HooksRuntime.$inputRegistrar.withValue({ [weak self] effectId, handler, isActive, requiresFocus in
                            guard let self else { return {} }
                            // Use the effectId's prefix before '::' to infer the component identity path
                            let parts = effectId.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                            let path = parts.first.map(String.init) ?? RuntimeStateContext.currentPath
                            let cleanup = await self.registerInputHandler(id: effectId, isActive: isActive, requiresFocus: requiresFocus, path: path, handler: handler)
                            return cleanup
                        }, operation: {
                            // Bind app and I/O contexts for useApp()/useStd* within effects
                            let ctx = HooksRuntime.AppContext(exit: { [weak self] err in
                                guard let self else { return }
                                // Compute exit status code
                                let code: Int32
                                if let prov = err as? AppExitCodeProviding { code = prov.exitCode } else if err != nil { code = 1 } else { code = 0 }
                                let description = err.map { String(describing: $0) }
                                await self.recordExitStatusAndUnmount(code: code, description: description)
                            }, clear: { [weak self] in
                                guard let self else { return }
                                await self.clear()
                            })
                            let streams = self.streamsSnapshot()
                            return await HooksRuntime.$appContext.withValue(ctx) {
                                await HooksRuntime.$ioStreams.withValue(streams) {
                                    let mgr = HooksRuntime.FocusManager(
                                        next: { [weak self] in await self?.focusNext() },
                                        previous: { [weak self] in await self?.focusPrevious() },
                                        focusPath: { [weak self] path in await self?.focus(path: path) ?? false },
                                        focusId: { [weak self] id in await self?.focus(id: id) ?? false },
                                        focusedPath: { [weak self] in await self?.currentFocusedPath() }
                                    )
                                    return await HooksRuntime.$focusManager.withValue(mgr) {
                                        await effect()
                                    }
                                }
                            }
                        })
                    })
                }
                effects[id] = (deps: depsToken, cleanup: cleanup)
            } else {
                // Preserve existing
                effects[id] = prev
            }
        }
    }

    private func runAllEffectCleanups() {
        for (_, entry) in effects { entry.cleanup?() }
    }

    /// Builder overload to construct the view and render within the same actor context
    /// Ensures hooks (useEffect) registered during build are captured and committed.
    public func rerender(_ build: @escaping @Sendable () -> some View) async {
        // Update root rebuilder to capture latest builder for hook-driven rerenders
        rootRebuilder = { [weak self] in
            guard let self else { return }
            await self.rerender(build)
        }

        // Collect effects during both build and render passes
        let box = EffectCollectorBox()
        let frame: TerminalRenderer.Frame = await RuntimeStateContext.$effectCollector.withValue({ id, deps, effect in
            box.add(id: id, deps: deps, effect: effect)
        }, operation: {
            // Build the view inside the effectCollector context so HooksRuntime.useEffect during build is recorded
            // Bind currentPath to a per-handle stable buildContextPath so hooks (useRef/useMemo) within build
            // use a stable path across rerenders, independent of lastViewIdentity.
            let view = HooksRuntime.$ioStreams.withValue(self.streamsSnapshot()) {
                RuntimeStateContext.$currentPath.withValue(self.buildContextPath) {
                    build()
                }
            }

            // Determine identity for state preservation
            let typeName = String(describing: type(of: view))
            let explicit = (view as? ViewIdentifiable)?.viewIdentity
            let identity = [typeName, explicit].compactMap(\.self).joined(separator: "#")
            if lastViewIdentity != identity {
                await frameBuffer.resetDiffState()
                lastViewIdentity = identity
                await componentTree.reset()
            }

            // Convert and render to a frame with bound IO streams
            await HooksRuntime.$ioStreams.withValue(self.streamsSnapshot()) {
                await componentTree.beginFrame(rootPath: identity)
            }
            let frame = HooksRuntime.$ioStreams.withValue(self.streamsSnapshot()) {
                convertViewToFrame(view, tree: componentTree, terminalProfile: options.terminalProfile)
            }
            await componentTree.endFrame()
            return frame
        })

        await frameBuffer.renderFrame(frame)

        // Commit collected effects with app and I/O context
        let streams = streamsSnapshot()
        await HooksRuntime.$ioStreams.withValue(streams) {
            let mgr = HooksRuntime.FocusManager(
                next: { [weak self] in await self?.focusNext() },
                previous: { [weak self] in await self?.focusPrevious() },
                focusPath: { [weak self] path in await self?.focus(path: path) ?? false },
                focusId: { [weak self] id in await self?.focus(id: id) ?? false },
                focusedPath: { [weak self] in await self?.currentFocusedPath() }
            )
            await HooksRuntime.$focusManager.withValue(mgr) {
                await commitEffects(box.snapshot())
            }
        }
    }

    /// Schedule periodic rerenders until cancelled or unmounted
    /// Returns a cancellation handle (Ticker) the caller can hold onto
    @discardableResult
    public func scheduleRerender(every interval: Duration, build: @escaping @Sendable () -> some View) -> Ticker {
        let ticker = Ticker(every: interval) { [weak self] in
            guard let self else { return }
            await self.rerender(build())
        }
        return ticker
    }

    // MARK: - Testing hook to inject input
    public func testingProcessInput(bytes: [UInt8]) async {
        await inputManager?.process(bytes: bytes)
    }

    /// Update the rendered view (for future programmatic updates)
    /// Note: This is a placeholder for future RUNE tickets
    public func update(_ view: some View) async {
        // Convert view to frame and render
        let frame = convertViewToFrame(view, tree: componentTree, terminalProfile: options.terminalProfile)
        await frameBuffer.renderFrame(frame)
    }
    }

// MARK: - View to Component Conversion

/// Convert a view to a renderable frame
/// - Parameter view: The view to convert
/// - Returns: TerminalRenderer.Frame ready for rendering
private func convertViewToFrame(
    _ view: some View,
    tree: ComponentTreeReconciler,
    terminalProfile: TerminalProfile,
) -> TerminalRenderer.Frame {
    // Get terminal size for layout
    let terminalSize = getTerminalSize()

    // Build identity path root from type name + optional explicit identity
    let typeName = String(describing: type(of: view))
    let explicit = (view as? ViewIdentifiable)?.viewIdentity
    let rootPath = [typeName, explicit].compactMap(\.self).joined(separator: "#")

    // Convert view to component within state context
    let component: Component = RuntimeStateContext.$currentPath.withValue(rootPath) {
        // During conversion, record child identity paths into the component tree
        ComponentTreeBinding.bindDuringRender(tree: tree) {
            // conversion does not emit nodes; children will record during render
        }
        return convertViewToComponent(view, currentPath: rootPath)
    }

    // Create layout rectangle for the full terminal
    let layoutRect = FlexLayout.Rect(
        x: 0,
        y: 0,
        width: terminalSize.width,
        height: terminalSize.height,
    )

    // Render component to lines, recording identity paths for reconciler
    let lines: [String] = ComponentTreeBinding.bindDuringRender(tree: tree) {
        RuntimeStateContext.withTerminalProfile(terminalProfile) {
            component.render(in: layoutRect)
        }
    }

    // Create frame
    return TerminalRenderer.Frame(
        lines: lines,
        width: terminalSize.width,
        height: lines.count,
    )
}

/// Convert a View to a Component for rendering
/// - Parameter view: The view to convert
/// - Returns: Component that can be rendered
private func convertViewToComponent(_ view: some View, currentPath: String) -> Component {
    // Handle different view types (leaf components just return themselves)
    if let textView = view as? Text {
        return textView
    } else if let boxView = view as? Box {
        return boxView
    } else if let staticView = view as? Static {
        return staticView
    } else if let newlineView = view as? Newline {
        return newlineView
    } else if let transformView = view as? Transform {
        return transformView
    }

    // For composite views, resolve the body and propagate identity path.
    // Instead of emitting a placeholder, evaluate `body` generically and recurse.
    let childTypeName = String(describing: type(of: view))
    let explicit = (view as? ViewIdentifiable)?.viewIdentity
    let childPath = [currentPath, childTypeName, explicit].compactMap(\.self).joined(separator: "/")

    func resolveComposite<V: View>(_ view: V, path: String) -> Component {
        RuntimeStateContext.$currentPath.withValue(path) {
            convertViewToComponent(view.body, currentPath: path)
        }
    }

    return resolveComposite(view, path: childPath)
}

/// Get terminal size with fallback
/// - Returns: Terminal size (width, height)
public func getTerminalSize() -> (width: Int, height: Int) {
    // Try to get terminal size using ioctl
    #if os(Linux)
    var winsize = Glibc.winsize()
    let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &winsize)
    #else
    var winsize = Darwin.winsize()
    let result = ioctl(STDOUT_FILENO, TIOCGWINSZ, &winsize)
    #endif

    if result == 0, winsize.ws_col > 0, winsize.ws_row > 0 {
        return (width: Int(winsize.ws_col), height: Int(winsize.ws_row))
    }

    // Fallback to default size
    return (width: 80, height: 24)
}

/// Top-level render function for RuneKit applications
///
/// This function starts a terminal application with the given view and options.
/// It handles all the setup including signal handlers, console capture, and
/// frame buffer initialization based on the provided options.
private func installSignalHandlerIfNeeded(on handle: RenderHandle, options: RenderOptions) async {
    guard options.exitOnCtrlC else { return }
    let handler = SignalHandler()
    await handler.install {
        await handle.unmount()
        exit(0)
    }
    await handle.setSignalHandler(handler)
}

///
/// - Parameters:
///   - view: The root view to render
///   - options: Render options (defaults to environment-aware settings)
/// - Returns: RenderHandle for controlling the render session
public func render(_ view: some View, options: RenderOptions = RenderOptions.fromEnvironment()) async -> RenderHandle {
    // Create render configuration from options
    // Map RenderOptions to RenderConfiguration, honoring fpsCap for timing
    let performance = RenderConfiguration.PerformanceTuning(
        maxLinesForDiff: 1000,
        minEfficiencyThreshold: 0.7,
        maxFrameRate: options.fpsCap,
        writeBufferSize: 8192,
    )
    let renderConfig = RenderConfiguration(
        optimizationMode: .automatic,
        performance: performance,
        enableMetrics: false,
        enableDebugLogging: false,
        hideCursorDuringRender: true,
        useAlternateScreen: options.useAltScreen,
        enableConsoleCapture: options.patchConsole,
    )

    // Create frame buffer with custom output
    let frameBuffer = FrameBuffer(output: options.stdout, configuration: renderConfig)

    // Create render handle first (needed for signal handler callback)
    let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

    // Set up signal handler if requested
    await installSignalHandlerIfNeeded(on: handle, options: options)

    // Set up input manager for key events and paste detection
    // Only duplicate stdout for controlOut when we actually need to emit control sequences
    // (i.e., bracketed paste enabled or console patching enabled). Otherwise, reuse stdout
    // so that Pipe readers see EOF as soon as the test closes the write end, even if the
    // input manager wasn't stopped explicitly.
    let (controlOut, shouldCloseControlOutOnStop): (FileHandle, Bool) = {
        if options.enableBracketedPaste || options.patchConsole {
            #if os(Linux)
            let dupfd = Glibc.dup(options.stdout.fileDescriptor)
            #else
            let dupfd = Darwin.dup(options.stdout.fileDescriptor)
            #endif
            if dupfd >= 0 {
                return (FileHandle(fileDescriptor: dupfd, closeOnDealloc: true), true)
            } else {
                return (options.stdout, false)
            }
        } else {
            return (options.stdout, false)
        }
    }()
    let inputMgr = InputManager(
        input: options.stdin,
        controlOut: controlOut,
        enableRawMode: options.enableRawMode,
        enableBracketedPaste: options.enableBracketedPaste,
        exitOnCtrlC: options.exitOnCtrlC,
        closeControlOutOnStop: shouldCloseControlOutOnStop
    )
    await inputMgr.setEventHandler { event in
        switch event {
        case .ctrlC where options.exitOnCtrlC:
            await handle.unmount()
        case .ctrlD where options.exitOnCtrlC:
            await handle.unmount()
        default:
            // Dispatch to any active useInput handlers registered via HooksRuntime
            await handle.dispatchInput(event)
        }
    }
    await inputMgr.start()
    await handle.setInputManager(inputMgr)

    // Initial render: collect effects and render without sending non-Sendable view across actor boundary.
    // Mirrors RenderHandle.rerender(view) semantics (identity/reset + effect collection/commit).
    let typeName = String(describing: type(of: view))
    let explicit = (view as? ViewIdentifiable)?.viewIdentity
    let identity = [typeName, explicit].compactMap(\.self).joined(separator: "#")

    // Build frame (collecting effects) and commit them; split helpers to keep this function small
    let (frame, effectsBox) = await buildInitialFrame(view, identity: identity, handle: handle, options: options)
    await frameBuffer.renderFrame(frame)
    await commitInitialEffects(for: view, identity: identity, handle: handle, options: options, effects: effectsBox)

    // After initial effects commit, perform an extra pass to record focusables
    await handle.componentTree.beginFrame(rootPath: identity)
    let initialFocusablesCollector = HooksFocusCollector()
    _ = HooksRuntime.$focusedPath.withValue(nil) {
        HooksRuntime.$focusRecorder.withValue({ path in
            initialFocusablesCollector.record(path)
        }, operation: {
            convertViewToFrame(view, tree: handle.componentTree, terminalProfile: options.terminalProfile)
        })
    }
    await handle.componentTree.endFrame()
    await handle.setFocusables(initialFocusablesCollector.snapshot())

    return handle
}

private func buildInitialFrame(_ view: some View, identity: String, handle: RenderHandle, options: RenderOptions) async -> (TerminalRenderer.Frame, EffectCollectorBox) {
    await handle.componentTree.beginFrame(rootPath: identity)
    let box = EffectCollectorBox()
    let frame: TerminalRenderer.Frame = await RuntimeStateContext.$effectCollector.withValue({ id, deps, effect in
        box.add(id: id, deps: deps, effect: effect)
    }, operation: {
        convertViewToFrame(view, tree: handle.componentTree, terminalProfile: options.terminalProfile)
    })
    await handle.componentTree.endFrame()
    return (frame, box)
}

private func commitInitialEffects(for view: some View, identity: String, handle: RenderHandle, options: RenderOptions, effects: EffectCollectorBox) async {
    let ctx = HooksRuntime.AppContext(exit: { err in
        let code: Int32
        if let prov = err as? AppExitCodeProviding { code = prov.exitCode } else if err != nil { code = 1 } else { code = 0 }
        let desc = err.map { String(describing: $0) }
        await handle.recordExitStatusAndUnmount(code: code, description: desc)
    }, clear: { await handle.clear() })
    let streams = await handle.streamsSnapshot()
    await HooksRuntime.$appContext.withValue(ctx) {
        await HooksRuntime.$ioStreams.withValue(streams) {
            await handle.commitCollectedEffects(effects.snapshot())
        }
    }
}
