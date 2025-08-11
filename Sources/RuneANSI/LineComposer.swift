import Foundation
import RuneUnicode

/// Utilities for ANSI-aware slicing, wrapping, and truncation without breaking escape sequences
/// Invariants:
/// - Never splits a grapheme cluster (e.g. emoji/ZWJ sequences stay intact)
/// - Never emits invalid or truncated ANSI sequences; SGR is reopened on right side as needed
/// - truncateVisibleColumns always appends an SGR reset (ESC[0m) to prevent style leakage
public enum LineComposer {
    // MARK: - Public API

    /// Split a string at a visible column boundary, preserving ANSI sequences in both halves.
    /// - Returns: (left, right)
    public static func splitVisibleColumns(_ input: String, at column: Int) -> (String, String) {
        if column <= 0 { return ("", input) }
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize(input)

        // Delegate to segmentation helper to reduce complexity in public API
        let (leftTokens, rightTokens) = segmentTokens(tokens, at: column)
        return assembleStrings(leftTokens: leftTokens, rightTokens: rightTokens, tokenizer: tokenizer)
    }

    /// Truncate to a visible width, appending a reset to avoid style leakage
    public static func truncateVisibleColumns(_ input: String, to width: Int) -> String {
        let (left, _) = splitVisibleColumns(input, at: width)
        if left.isEmpty { return left }
        // ensure reset
        return left + "\u{001B}[0m"
    }

    /// Wrap a single line into multiple lines at a given width. ANSI is preserved.
    public static func wrapToWidth(_ input: String, width: Int) -> [String] {
        if width <= 0 { return [input] }
        var remaining = input
        var lines: [String] = []
        var safety = 0
        while !remaining.isEmpty, safety < 10000 {
            let (left, right) = splitVisibleColumns(remaining, at: width)
            lines.append(left)
            remaining = right
            if right.isEmpty { break }
            safety += 1
        }
        return lines
    }

    // MARK: - Internal helpers (behavior-preserving)

    /// Token segmentation: splits tokens into left/right preserving ANSI and graphemes
    private static func segmentTokens(_ tokens: [ANSIToken], at column: Int) -> ([ANSIToken], [ANSIToken]) {
        var left: [ANSIToken] = []
        var right: [ANSIToken] = []
        var ctx = SplitContext(state: SGRStateMachine(), column: column, widthSoFar: 0, splitting: false)

        for token in tokens {
            if ctx.splitting {
                right.append(token)
                continue
            }
            switch token {
            case let .sgr(params):
                _ = ctx.state.apply(params)
                left.append(token)
            case let .text(textFragment):
                handleTextToken(textFragment, ctx: &ctx, left: &left, right: &right)
            default:
                left.append(token)
            }
        }
        return (left, right)
    }

    /// Assemble strings from tokens using the provided tokenizer
    private static func assembleStrings(leftTokens: [ANSIToken], rightTokens: [ANSIToken], tokenizer: ANSITokenizer) -> (String, String) {
        let leftStr = tokenizer.encode(leftTokens)
        let rightStr = tokenizer.encode(rightTokens)
        return (leftStr, rightStr)
    }

    /// Build SGR parameters from attributes; keeps original ordering to preserve behavior
    private static func sgrParams(for attrs: TextAttributes) -> [Int]? {
        var params: [Int] = []
        if attrs.bold { params.append(1) }
        if attrs.italic { params.append(3) }
        if attrs.underline { params.append(4) }
        if attrs.inverse { params.append(7) }
        if attrs.strikethrough { params.append(9) }
        if attrs.dim { params.append(2) }
        if let color = attrs.color { params.append(contentsOf: encodeColorParams(color, isForeground: true)) }
        if let background = attrs.backgroundColor { params.append(contentsOf: encodeColorParams(background, isForeground: false)) }
        return params.isEmpty ? nil : params
    }

    private struct SplitContext {
        var state: SGRStateMachine
        var column: Int
        var widthSoFar: Int
        var splitting: Bool
    }

    /// Handle a text token, splitting by visible columns without breaking grapheme clusters
    private static func handleTextToken(
        _ textFragment: String,
        ctx: inout SplitContext,
        left: inout [ANSIToken],
        right: inout [ANSIToken]
    ) {
        if ctx.widthSoFar >= ctx.column {
            if let params = sgrParams(for: ctx.state.attributes) { right.append(.sgr(params)) }
            right.append(.text(textFragment))
            ctx.splitting = true
            return
        }
        var currentTextLeft = ""
        var currentTextRight = ""
        var injectedSGR = false
        for grapheme in textFragment {
            if ctx.splitting {
                currentTextRight.append(grapheme)
                continue
            }
            let charWidth = max(1, Width.displayWidth(of: String(grapheme)))
            if ctx.widthSoFar + charWidth <= ctx.column {
                currentTextLeft.append(grapheme)
                ctx.widthSoFar += charWidth
            } else {
                if !injectedSGR, let params = sgrParams(for: ctx.state.attributes) { right.append(.sgr(params)); injectedSGR = true }
                currentTextRight.append(grapheme)
                ctx.splitting = true
            }
        }
        if !currentTextLeft.isEmpty { left.append(.text(currentTextLeft)) }
        if !currentTextRight.isEmpty { right.append(.text(currentTextRight)) }
    }

    /// Encode color to SGR parameters; preserves original mapping exactly
    private static func encodeColorParams(_ color: ANSIColor, isForeground: Bool) -> [Int] {
        switch color {
        case let .color256(index):
            return [isForeground ? 38 : 48, 5, max(0, min(255, index))]
        case let .rgb(red, green, blue):
            return [
                isForeground ? 38 : 48,
                2,
                max(0, min(255, red)),
                max(0, min(255, green)),
                max(0, min(255, blue)),
            ]
        default:
            if let pair = simpleColorMap[color] {
                return [isForeground ? pair.fg : pair.bg]
            }
            // Fallback to reset if unmapped; preserves prior behavior for unknowns
            return []
        }
    }

    private static let simpleColorMap: [ANSIColor: (fg: Int, bg: Int)] = [
        .black: (30, 40),
        .red: (31, 41),
        .green: (32, 42),
        .yellow: (33, 43),
        .blue: (34, 44),
        .magenta: (35, 45),
        .cyan: (36, 46),
        .white: (37, 47),
        .brightBlack: (90, 100),
        .brightRed: (91, 101),
        .brightGreen: (92, 102),
        .brightYellow: (93, 103),
        .brightBlue: (94, 104),
        .brightMagenta: (95, 105),
        .brightCyan: (96, 106),
        .brightWhite: (97, 107),
    ]
}
