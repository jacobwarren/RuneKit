import Foundation
import RuneUnicode

/// Utilities for ANSI-aware slicing, wrapping, and truncation without breaking escape sequences
/// Invariants:
/// - Never splits a grapheme cluster (e.g. emoji/ZWJ sequences stay intact)
/// - Never emits invalid or truncated ANSI sequences; SGR is reopened on right side as needed
/// - truncateVisibleColumns always appends an SGR reset (ESC[0m) to prevent style leakage
public enum LineComposer {
    /// Split a string at a visible column boundary, preserving ANSI sequences in both halves.
    /// - Returns: (left, right)
    public static func splitVisibleColumns(_ input: String, at column: Int) -> (String, String) {
        if column <= 0 { return ("", input) }
        let tokenizer = ANSITokenizer()
        let tokens = tokenizer.tokenize(input)
        var left: [ANSIToken] = []
        var right: [ANSIToken] = []
        var widthSoFar = 0
        var state = SGRStateMachine()

        func params(for attrs: TextAttributes) -> [Int]? {
            var p: [Int] = []
            if attrs.bold { p.append(1) }
            if attrs.italic { p.append(3) }
            if attrs.underline { p.append(4) }
            if attrs.inverse { p.append(7) }
            if attrs.strikethrough { p.append(9) }
            if attrs.dim { p.append(2) }
            if let c = attrs.color { p.append(contentsOf: encodeColor(c, isForeground: true)) }
            if let b = attrs.backgroundColor { p.append(contentsOf: encodeColor(b, isForeground: false)) }
            return p.isEmpty ? nil : p
        }

        func encodeColor(_ c: ANSIColor, isForeground: Bool) -> [Int] {
            switch c {
            case .black: return [ (isForeground ? 30 : 40) ]
            case .red: return [ (isForeground ? 31 : 41) ]
            case .green: return [ (isForeground ? 32 : 42) ]
            case .yellow: return [ (isForeground ? 33 : 43) ]
            case .blue: return [ (isForeground ? 34 : 44) ]
            case .magenta: return [ (isForeground ? 35 : 45) ]
            case .cyan: return [ (isForeground ? 36 : 46) ]
            case .white: return [ (isForeground ? 37 : 47) ]
            case .brightBlack: return [ (isForeground ? 90 : 100) ]
            case .brightRed: return [ (isForeground ? 91 : 101) ]
            case .brightGreen: return [ (isForeground ? 92 : 102) ]
            case .brightYellow: return [ (isForeground ? 93 : 103) ]
            case .brightBlue: return [ (isForeground ? 94 : 104) ]
            case .brightMagenta: return [ (isForeground ? 95 : 105) ]
            case .brightCyan: return [ (isForeground ? 96 : 106) ]
            case .brightWhite: return [ (isForeground ? 97 : 107) ]
            case .color256(let idx): return [ (isForeground ? 38 : 48), 5, max(0, min(255, idx)) ]
            case .rgb(let r, let g, let b): return [ (isForeground ? 38 : 48), 2, max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)) ]
            }
        }

        var splitting = false
        for token in tokens {
            if splitting {
                right.append(token)
                continue
            }
            switch token {
            case .sgr(let params):
                _ = state.apply(params)
                left.append(token)
            case .text(let s):
                if widthSoFar >= column {
                    // everything goes right including current token
                    if let p = params(for: state.attributes) { right.append(.sgr(p)) }
                    right.append(.text(s))
                    splitting = true
                    continue
                }
                var currentTextLeft = ""
                var currentTextRight = ""
                var injectedSGR = false
                for ch in s {
                    if splitting {
                        currentTextRight.append(ch)
                        continue
                    }
                    let w = max(1, Width.displayWidth(of: String(ch)))
                    if widthSoFar + w <= column {
                        currentTextLeft.append(ch)
                        widthSoFar += w
                    } else {
                        // split here, send SGR once to the right side
                        if !injectedSGR, let p = params(for: state.attributes) { right.append(.sgr(p)); injectedSGR = true }
                        currentTextRight.append(ch)
                        splitting = true
                    }
                }
                if !currentTextLeft.isEmpty { left.append(.text(currentTextLeft)) }
                if !currentTextRight.isEmpty { right.append(.text(currentTextRight)) }
            default:
                left.append(token)
            }
        }

        let leftStr = tokenizer.encode(left)
        let rightStr = tokenizer.encode(right)
        return (leftStr, rightStr)
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
        while !remaining.isEmpty && safety < 10000 {
            let (left, right) = splitVisibleColumns(remaining, at: width)
            lines.append(left)
            remaining = right
            if right.isEmpty { break }
            safety += 1
        }
        return lines
    }
}

