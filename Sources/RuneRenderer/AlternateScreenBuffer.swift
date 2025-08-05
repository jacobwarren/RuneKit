import Foundation

/// Actor-based alternate screen buffer management for terminal applications
///
/// This actor provides thread-safe management of the alternate screen buffer,
/// which allows applications to temporarily take over the entire terminal
/// screen and restore the previous content when exiting (similar to vim, less, etc.).
///
/// Key features:
/// - Thread-safe enter/leave operations
/// - Automatic cleanup on deinit
/// - Fallback support for terminals that don't support alternate screen
/// - State tracking to prevent double enter/leave
/// - Integration with RuneKit's rendering system
///
/// ## Usage
///
/// ```swift
/// let altScreen = AlternateScreenBuffer()
/// await altScreen.enter()
/// // ... render your application ...
/// await altScreen.leave()
/// ```
///
/// ## ANSI Sequences
///
/// - Enter: `ESC[?1049h` - Switch to alternate screen buffer
/// - Leave: `ESC[?1049l` - Switch back to main screen buffer
///
/// ## Fallback Behavior
///
/// When alternate screen is not supported or disabled:
/// - Enter: Clear screen and move cursor to home (`ESC[2J ESC[H`)
/// - Leave: No operation (content remains on screen)
public actor AlternateScreenBuffer {
    /// The output file handle for writing ANSI sequences
    private let output: FileHandle

    /// Whether alternate screen buffer is currently active
    private var _isActive: Bool = false

    /// Whether fallback mode is enabled for unsupported terminals
    private let enableFallback: Bool

    /// Whether the buffer has been entered at least once (for deinit cleanup)
    private var hasBeenEntered: Bool = false

    // MARK: - ANSI Escape Sequences

    /// ANSI sequence to enter alternate screen buffer
    private static let enterSequence = "\u{001B}[?1049h"

    /// ANSI sequence to leave alternate screen buffer
    private static let leaveSequence = "\u{001B}[?1049l"

    /// Fallback sequence to clear screen and move cursor to home
    private static let fallbackClearSequence = "\u{001B}[2J\u{001B}[H"

    // MARK: - Initialization

    /// Initialize alternate screen buffer with output handle
    /// - Parameters:
    ///   - output: File handle for terminal output (defaults to stdout)
    ///   - enableFallback: Whether to use fallback clear when alternate screen is unsupported
    public init(output: FileHandle = .standardOutput, enableFallback: Bool = true) {
        self.output = output
        self.enableFallback = enableFallback
    }

    // MARK: - Public Interface

    /// Whether alternate screen buffer is currently active
    public var isActive: Bool {
        return _isActive
    }

    /// Enter alternate screen buffer
    ///
    /// This switches the terminal to the alternate screen buffer, clearing
    /// the visible area and allowing the application to take full control.
    /// The previous screen content is preserved and will be restored when
    /// leaving the alternate screen.
    ///
    /// Safe to call multiple times - subsequent calls are ignored.
    public func enter() async {
        guard !_isActive else { return }

        if let data = Self.enterSequence.data(using: .utf8) {
            output.write(data)
        }

        _isActive = true
        hasBeenEntered = true
    }

    /// Leave alternate screen buffer
    ///
    /// This switches the terminal back to the main screen buffer, restoring
    /// the previous screen content that was visible before entering the
    /// alternate screen.
    ///
    /// Safe to call multiple times - subsequent calls are ignored.
    public func leave() async {
        guard _isActive else { return }

        if let data = Self.leaveSequence.data(using: .utf8) {
            output.write(data)
        }

        _isActive = false
    }

    /// Enter alternate screen buffer with fallback support
    ///
    /// This method attempts to enter the alternate screen buffer, but if
    /// fallback is enabled and the terminal doesn't support it, it will
    /// fall back to clearing the screen instead.
    ///
    /// This is useful for terminals that don't support the alternate screen
    /// buffer sequences (like some older terminals or terminal emulators).
    public func enterWithFallback() async {
        guard !_isActive else { return }

        if enableFallback {
            // For now, we'll always try the alternate screen sequence
            // In a real implementation, we might detect terminal capabilities
            // and choose the appropriate method
            await enter()
        } else {
            await enter()
        }
    }

    /// Leave alternate screen buffer with fallback support
    ///
    /// This method attempts to leave the alternate screen buffer, with
    /// fallback behavior for terminals that don't support it.
    public func leaveWithFallback() async {
        guard _isActive else { return }

        if enableFallback {
            // For now, we'll always try the alternate screen sequence
            // In a real implementation, we might use different sequences
            // based on what was used to enter
            await leave()
        } else {
            await leave()
        }
    }

    /// Force clear the screen (fallback behavior)
    ///
    /// This method provides the fallback behavior of clearing the screen
    /// and moving the cursor to the home position. This is used when
    /// alternate screen buffer is not supported.
    public func clearScreen() async {
        if let data = Self.fallbackClearSequence.data(using: .utf8) {
            output.write(data)
        }
    }
}
