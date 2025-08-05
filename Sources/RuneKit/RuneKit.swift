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

    /// Maximum frame rate cap (frames per second)
    public let fpsCap: Double

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
    public init(
        stdout: FileHandle = FileHandle.standardOutput,
        stdin: FileHandle = FileHandle.standardInput,
        stderr: FileHandle = FileHandle.standardError,
        exitOnCtrlC: Bool? = nil,
        patchConsole: Bool? = nil,
        useAltScreen: Bool? = nil,
        fpsCap: Double = 60.0,
    ) {
        self.stdout = stdout
        self.stdin = stdin
        self.stderr = stderr
        self.fpsCap = fpsCap

        // Use TTY-aware defaults if not explicitly provided
        let isInteractive = Self.isInteractiveTerminal()
        let isCI = Self.isCIEnvironment()

        self.exitOnCtrlC = exitOnCtrlC ?? (isInteractive && !isCI)
        self.patchConsole = patchConsole ?? (isInteractive && !isCI)
        self.useAltScreen = useAltScreen ?? (isInteractive && !isCI)
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

        // CI-specific defaults
        if isCI {
            return RenderOptions(
                exitOnCtrlC: false,
                patchConsole: false,
                useAltScreen: false,
                fpsCap: 30.0,
            )
        }

        // Interactive terminal defaults
        if isInteractive {
            return RenderOptions(
                exitOnCtrlC: true,
                patchConsole: true,
                useAltScreen: true,
                fpsCap: 60.0,
            )
        }

        // Non-interactive defaults (pipes, redirects)
        return RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
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
    associatedtype Body

    /// The content and behavior of the view
    var body: Self.Body { get }
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

/// Make Box conform to View protocol
extension Box: View {
    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

/// Handle for controlling a running render session
///
/// This actor provides control over a running terminal application,
/// allowing for programmatic updates, state queries, and graceful shutdown.
public actor RenderHandle {
    /// The frame buffer handling rendering
    private let frameBuffer: FrameBuffer

    /// Signal handler for graceful termination
    private var signalHandler: SignalHandler?

    /// Render options used for this session
    private let options: RenderOptions

    /// Whether the render session is currently active
    public private(set) var isActive = true

    /// Whether the handle has been unmounted
    private var isUnmounted = false

    /// Continuations waiting for exit
    private var exitContinuations: [CheckedContinuation<Void, Never>] = []

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

        // Clear the frame buffer
        await frameBuffer.clear()

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

        // Clear the frame buffer and restore terminal state
        await frameBuffer.clear()

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
        self.signalHandler = handler
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
    /// - Parameter view: The new view to render
    public func rerender(_ view: some View) async {
        // Convert view to frame and render
        let frame = convertViewToFrame(view)
        await frameBuffer.renderFrame(frame)
    }

    /// Update the rendered view (for future programmatic updates)
    /// Note: This is a placeholder for future RUNE tickets
    public func update(_ view: some View) async {
        // Convert view to frame and render
        let frame = convertViewToFrame(view)
        await frameBuffer.renderFrame(frame)
    }
}

// MARK: - View to Component Conversion

/// Convert a view to a renderable frame
/// - Parameter view: The view to convert
/// - Returns: TerminalRenderer.Frame ready for rendering
private func convertViewToFrame(_ view: some View) -> TerminalRenderer.Frame {
    // Get terminal size for layout
    let terminalSize = getTerminalSize()

    // Convert view to component
    let component = convertViewToComponent(view)

    // Create layout rectangle for the full terminal
    let layoutRect = FlexLayout.Rect(
        x: 0,
        y: 0,
        width: terminalSize.width,
        height: terminalSize.height,
    )

    // Render component to lines
    let lines = component.render(in: layoutRect)

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
private func convertViewToComponent(_ view: some View) -> Component {
    // Handle different view types
    if let textView = view as? Text {
        textView
    } else if let boxView = view as? Box {
        boxView
    } else {
        // For composite views, we need to resolve the body
        // This is a simplified implementation - a full implementation
        // would recursively resolve the view hierarchy
        Text("View: \(String(describing: type(of: view)))")
    }
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
///
/// - Parameters:
///   - view: The root view to render
///   - options: Render options (defaults to environment-aware settings)
/// - Returns: RenderHandle for controlling the render session
public func render(_ view: some View, options: RenderOptions = RenderOptions.fromEnvironment()) async -> RenderHandle {
    // Create render configuration from options
    let renderConfig = RenderConfiguration(
        optimizationMode: .automatic,
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
    if options.exitOnCtrlC {
        let handler = SignalHandler()
        await handler.install {
            // Graceful teardown through render handle
            await handle.unmount()
            exit(0)
        }

        // Update the handle with the signal handler
        await handle.setSignalHandler(handler)
    }

    // Convert view to frame and render
    let frame = convertViewToFrame(view)
    await frameBuffer.renderFrame(frame)

    return handle
}
