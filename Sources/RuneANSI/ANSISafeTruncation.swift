import Foundation
import RuneUnicode

/// ANSI-safe truncation and width utilities.
///
/// Although these APIs are public for cross-module reuse (e.g. RuneComponents),
/// consider them internal utilities; behavior may evolve with RuneKit's ANSI/width rules.
public enum ANSISafeTruncation {
    /// Truncate a string to a maximum display width while preserving ANSI escape sequences.
    /// - Parameters:
    ///   - text: Input string (may contain ANSI sequences)
    ///   - maxWidth: Maximum display width in columns
    /// - Returns: ANSI-preserving truncated string that fits within maxWidth
    public static func truncateToDisplayWidth(_ text: String, maxWidth: Int) -> String {
        guard maxWidth > 0 else { return "" }
        // Fast path: no ANSI sequences
        if !text.contains("\u{001B}[") {
            return truncateSimple(text, maxWidth: maxWidth)
        }
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize(text)

        var result: [ANSIToken] = []
        var currentWidth = 0

        for token in tokens {
            switch token {
            case let .text(content):
                let remaining = maxWidth - currentWidth
                if remaining <= 0 { break }
                let truncatedContent = truncateSimple(content, maxWidth: remaining)
                if !truncatedContent.isEmpty {
                    result.append(.text(truncatedContent))
                    currentWidth += Width.displayWidth(of: truncatedContent)
                }
                // If we truncated this content, we're done
                if truncatedContent.count < content.count {
                    break
                }
            default:
                // Non-text tokens (ANSI codes) don't consume display width
                result.append(token)
            }
        }
        return tokenizer.encode(result)
    }

    /// Simple display-width based truncation for plain text (no ANSI sequences).
    public static func truncateSimple(_ text: String, maxWidth: Int) -> String {
        guard maxWidth > 0 else { return "" }
        var result = ""
        var currentWidth = 0
        for ch in text {
            let charWidth = Width.displayWidth(of: String(ch))
            if currentWidth + charWidth <= maxWidth {
                result.append(ch)
                currentWidth += charWidth
            } else {
                break
            }
        }
        return result
    }

    /// Calculate display width ignoring ANSI escape sequences.
    public static func displayWidthIgnoringANSI(_ text: String) -> Int {
        // Fast path
        if !text.contains("\u{001B}[") {
            return Width.displayWidth(of: text)
        }
        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()
        let tokens = tokenizer.tokenize(text)
        let styled = converter.tokensToStyledText(tokens)
        return Width.displayWidth(of: styled.plainText)
    }
}
