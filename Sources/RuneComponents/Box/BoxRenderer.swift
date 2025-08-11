import RuneANSI
import RuneLayout
import RuneUnicode

/// Border characters for drawing borders
struct BorderChars {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
}

/// Handles rendering functionality for Box components
enum BoxRenderer {
    /// Render border into the lines array
    /// - Parameters:
    ///   - lines: The lines array to modify
    ///   - rect: The rectangle to draw the border in
    ///   - style: The border style to use
    ///   - color: Optional ANSI color to apply to border glyphs
    static func renderBorder(
        into lines: inout [String],
        rect: FlexLayout.Rect,
        style: Box.BorderStyle,
        color: ANSIColor? = nil,
    ) {
        let borderChars = getBorderChars(for: style)

        // For simplicity, assume border is drawn at the start of the render area
        let width = rect.width
        let height = rect.height

        let colorPrefix: String = if let color { color.foregroundSequence } else { "" }
        let reset = colorPrefix.isEmpty ? "" : "\u{001B}[0m"

        // Gracefully handle dimensions too small for borders
        guard width >= 2, height >= 1 else {
            // If dimensions are too small, fill with spaces or truncate to fit
            for y in 0 ..< height where y < lines.count {
                lines[y] = String(repeating: " ", count: min(width, lines[y].count))
            }
            return
        }

        // Top border
        if height > 0 {
            let middle = String(repeating: borderChars.horizontal, count: max(0, width - 2))
            lines[0] = colorPrefix + borderChars.topLeft + middle + borderChars.topRight + reset
        }

        // Bottom border
        if height > 1 {
            let middle = String(repeating: borderChars.horizontal, count: max(0, width - 2))
            lines[height - 1] = colorPrefix + borderChars.bottomLeft + middle + borderChars.bottomRight + reset
        }

        // Side borders (middle lines)
        if height > 2 { // Only process middle lines if height > 2
            for y in 1 ..< (height - 1) where y < lines.count {
                let existingLine = lines[y]
                // Preserve middle content (after dropping borders if present)
                let middleContent = String(existingLine.dropFirst().dropLast())
                lines[y] = colorPrefix + borderChars.vertical + reset + middleContent + colorPrefix + borderChars
                    .vertical + reset
            }
        }
    }

    /// Adjust content to exactly match a target display width
    /// - Parameters:
    ///   - content: The content to adjust (may contain ANSI)
    ///   - targetWidth: The target display width
    /// - Returns: Content that has exactly the target display width
    static func adjustContentToDisplayWidth(_ content: String, targetWidth: Int) -> String {
        let currentDisplayWidth = ANSISafeTruncation.displayWidthIgnoringANSI(content)

        if currentDisplayWidth < targetWidth {
            // Pad with spaces to reach target display width
            let paddingNeeded = targetWidth - currentDisplayWidth
            return content + String(repeating: " ", count: paddingNeeded)
        } else if currentDisplayWidth > targetWidth {
            // Truncate to fit target display width (ANSI-safe)
            return ANSISafeTruncation.truncateToDisplayWidth(content, maxWidth: targetWidth)
        } else {
            // Already the correct display width
            return content
        }
    }

    /// Truncate a string to fit within a specific display width (ANSI-safe)
    /// - Parameters:
    ///   - text: The text to truncate (may contain ANSI)
    ///   - maxWidth: The maximum display width allowed
    /// - Returns: The truncated text that fits within maxWidth display columns
    static func truncateToDisplayWidth(_ text: String, maxWidth: Int) -> String {
        ANSISafeTruncation.truncateToDisplayWidth(text, maxWidth: maxWidth)
    }

    /// Build a single border line
    static func buildBorderLine(
        startX: Int,
        endX: Int,
        leftChar: String,
        rightChar: String,
        fillChar: String,
    ) -> String {
        var line = ""

        // Add characters before the border section
        for _ in 0 ..< startX {
            line += " "
        }

        // Add left border character
        line += leftChar

        // Add fill characters
        let fillWidth = max(0, endX - startX - 2) // -2 for left and right chars
        for _ in 0 ..< fillWidth {
            line += fillChar
        }

        // Add right border character
        line += rightChar

        // Note: We no longer pad to a target total width; caller is responsible for alignment

        return line
    }

    /// Get border characters for a given style
    static func getBorderChars(for style: Box.BorderStyle) -> BorderChars {
        switch style {
        case .none:
            BorderChars(
                topLeft: " ", topRight: " ", bottomLeft: " ", bottomRight: " ",
                horizontal: " ", vertical: " ",
            )
        case .single:
            BorderChars(
                topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘",
                horizontal: "─", vertical: "│",
            )
        case .double:
            BorderChars(
                topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝",
                horizontal: "═", vertical: "║",
            )
        case .rounded:
            BorderChars(
                topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯",
                horizontal: "─", vertical: "│",
            )
        }
    }
}
