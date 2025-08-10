import RuneLayout
import RuneUnicode

/// A static text component for immutable content that never reflows
///
/// Static components are designed for content that should remain fixed
/// above the dynamic region of a terminal application. This is ideal for:
/// - Application headers and titles
/// - Log entries that should not move
/// - Status information that persists
/// - Immutable output that should stay in place
///
/// Key features:
/// - Lines never move during repaint operations
/// - Consistent ordering with interleaved logs
/// - Width-aware truncation for terminal constraints
/// - Immutable content that doesn't change between renders
///
/// ## Usage
///
/// ```swift
/// // Single line static content
/// let header = Static("=== Application Started ===")
///
/// // Multiple lines of static content
/// let logHeader = Static([
///     "Application Log",
///     "Started: 2024-01-01 12:00:00",
///     "Version: 1.0.0"
/// ])
/// ```
///
/// ## Integration with Console Capture
///
/// Static components work seamlessly with RuneKit's console capture system
/// to ensure proper ordering of static content and captured logs. When used
/// with FrameBuffer's console capture, static lines appear above the dynamic
/// region and maintain their position regardless of application updates.
public struct Static: Component {
    /// The static lines to display
    private let lines: [String]

    /// Initialize with a single line of static content
    /// - Parameter line: The static text line to display
    public init(_ line: String) {
        self.lines = [line]
    }

    /// Initialize with multiple lines of static content
    /// - Parameter lines: Array of static text lines to display
    public init(_ lines: [String]) {
        self.lines = lines
    }

    /// Render the static content within the given rectangle
    /// - Parameter rect: The layout rectangle to render within
    /// - Returns: Array of strings representing the static content
    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Take only as many lines as fit in the height
        let visibleLines = Array(lines.prefix(rect.height))

        // Truncate each line to fit within the width constraint
        let truncatedLines = visibleLines.map { line in
            truncateToDisplayWidth(line, maxWidth: rect.width)
        }

        return truncatedLines
    }
}

/// Truncate a string to fit within a maximum display width
/// This function respects Unicode character boundaries and emoji width
/// - Parameters:
///   - text: The text to truncate
///   - maxWidth: Maximum display width in terminal columns
/// - Returns: Truncated string that fits within the width
private func truncateToDisplayWidth(_ text: String, maxWidth: Int) -> String {
    ANSISafeTruncation.truncateToDisplayWidth(text, maxWidth: maxWidth)
}
