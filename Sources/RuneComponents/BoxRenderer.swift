import RuneLayout
import RuneANSI
import RuneUnicode

/// Border characters for drawing borders
internal struct BorderChars {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
}

/// Handles rendering functionality for Box components
internal struct BoxRenderer {
    
    /// Render border into the lines array
    /// - Parameters:
    ///   - lines: The lines array to modify
    ///   - rect: The rectangle to draw the border in
    ///   - style: The border style to use
    static func renderBorder(into lines: inout [String], rect: FlexLayout.Rect, style: Box.BorderStyle) {
        let borderChars = getBorderChars(for: style)

        // For simplicity, assume border is drawn at the start of the render area
        let width = rect.width
        let height = rect.height

        // Gracefully handle dimensions too small for borders
        guard width >= 2 && height >= 1 else {
            // If dimensions are too small, fill with spaces or truncate to fit
            for y in 0..<height {
                if y < lines.count {
                    lines[y] = String(repeating: " ", count: min(width, lines[y].count))
                }
            }
            return
        }

        // Top border
        if height > 0 {
            lines[0] = borderChars.topLeft +
                      String(repeating: borderChars.horizontal, count: max(0, width - 2)) +
                      borderChars.topRight
        }

        // Bottom border
        if height > 1 {
            lines[height - 1] = borderChars.bottomLeft +
                               String(repeating: borderChars.horizontal, count: max(0, width - 2)) +
                               borderChars.bottomRight
        }

        // Side borders (middle lines)
        if height > 2 {  // Only process middle lines if height > 2
            for y in 1..<(height - 1) {
                if y < lines.count {
                    let existingLine = lines[y]
                    
                    // For middle lines, just add vertical borders to the existing content
                    // The content area is already properly sized
                    let middleContent = String(existingLine.dropFirst().dropLast())
                    lines[y] = borderChars.vertical + middleContent + borderChars.vertical
                }
            }
        }
    }

    /// Adjust content to exactly match a target display width
    /// - Parameters:
    ///   - content: The content to adjust
    ///   - targetWidth: The target display width
    /// - Returns: Content that has exactly the target display width
    static func adjustContentToDisplayWidth(_ content: String, targetWidth: Int) -> String {
        let currentDisplayWidth = Width.displayWidth(of: content)

        if currentDisplayWidth < targetWidth {
            // Pad with spaces to reach target display width
            let paddingNeeded = targetWidth - currentDisplayWidth
            return content + String(repeating: " ", count: paddingNeeded)
        } else if currentDisplayWidth > targetWidth {
            // Truncate to fit target display width
            return truncateToDisplayWidth(content, maxWidth: targetWidth)
        } else {
            // Already the correct display width
            return content
        }
    }

    /// Truncate a string to fit within a specific display width
    /// - Parameters:
    ///   - text: The text to truncate
    ///   - maxWidth: The maximum display width allowed
    /// - Returns: The truncated text that fits within maxWidth display columns
    static func truncateToDisplayWidth(_ text: String, maxWidth: Int) -> String {
        guard maxWidth > 0 else { return "" }

        var result = ""
        var currentWidth = 0

        for char in text {
            let charWidth = Width.displayWidth(of: String(char))
            if currentWidth + charWidth <= maxWidth {
                result.append(char)
                currentWidth += charWidth
            } else {
                break
            }
        }

        return result
    }

    /// Build a single border line
    static func buildBorderLine(
        startX: Int,
        endX: Int,
        leftChar: String,
        rightChar: String,
        fillChar: String,
        totalWidth: Int
    ) -> String {
        var line = ""

        // Add characters before the border section
        for _ in 0..<startX {
            line += " "
        }

        // Add left border character
        line += leftChar

        // Add fill characters
        let fillWidth = max(0, endX - startX - 2)  // -2 for left and right chars
        for _ in 0..<fillWidth {
            line += fillChar
        }

        // Add right border character
        line += rightChar

        // Add characters after the border section
        let remainingWidth = max(0, totalWidth - line.count)
        for _ in 0..<remainingWidth {
            line += " "
        }

        return line
    }

    /// Get border characters for a given style
    static func getBorderChars(for style: Box.BorderStyle) -> BorderChars {
        switch style {
        case .none:
            return BorderChars(
                topLeft: " ", topRight: " ", bottomLeft: " ", bottomRight: " ",
                horizontal: " ", vertical: " "
            )
        case .single:
            return BorderChars(
                topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘",
                horizontal: "─", vertical: "│"
            )
        case .double:
            return BorderChars(
                topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝",
                horizontal: "═", vertical: "║"
            )
        case .rounded:
            return BorderChars(
                topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯",
                horizontal: "─", vertical: "│"
            )
        }
    }
}
