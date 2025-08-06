import RuneANSI

// MARK: - Terminal Coordinate Conversion

extension Float {
    /// Convert Yoga float coordinate to terminal integer coordinate
    ///
    /// Uses standard rounding (0.5 rounds up) and clamps negative values to 0.
    /// This ensures all terminal coordinates are valid non-negative integers.
    func roundedToTerminal() -> Int {
        return max(0, Int(self.rounded()))
    }
}

// MARK: - ANSIColor Extensions for Box Component

extension ANSIColor {
    /// Generate ANSI escape sequence for foreground color
    var foregroundSequence: String {
        switch self {
        case .black: return "\u{001B}[30m"
        case .red: return "\u{001B}[31m"
        case .green: return "\u{001B}[32m"
        case .yellow: return "\u{001B}[33m"
        case .blue: return "\u{001B}[34m"
        case .magenta: return "\u{001B}[35m"
        case .cyan: return "\u{001B}[36m"
        case .white: return "\u{001B}[37m"
        case .brightBlack: return "\u{001B}[90m"
        case .brightRed: return "\u{001B}[91m"
        case .brightGreen: return "\u{001B}[92m"
        case .brightYellow: return "\u{001B}[93m"
        case .brightBlue: return "\u{001B}[94m"
        case .brightMagenta: return "\u{001B}[95m"
        case .brightCyan: return "\u{001B}[96m"
        case .brightWhite: return "\u{001B}[97m"
        case .color256(let index): return "\u{001B}[38;5;\(index)m"
        case .rgb(let r, let g, let b): return "\u{001B}[38;2;\(r);\(g);\(b)m"
        }
    }

    /// Generate ANSI escape sequence for background color
    var backgroundSequence: String {
        switch self {
        case .black: return "\u{001B}[40m"
        case .red: return "\u{001B}[41m"
        case .green: return "\u{001B}[42m"
        case .yellow: return "\u{001B}[43m"
        case .blue: return "\u{001B}[44m"
        case .magenta: return "\u{001B}[45m"
        case .cyan: return "\u{001B}[46m"
        case .white: return "\u{001B}[47m"
        case .brightBlack: return "\u{001B}[100m"
        case .brightRed: return "\u{001B}[101m"
        case .brightGreen: return "\u{001B}[102m"
        case .brightYellow: return "\u{001B}[103m"
        case .brightBlue: return "\u{001B}[104m"
        case .brightMagenta: return "\u{001B}[105m"
        case .brightCyan: return "\u{001B}[106m"
        case .brightWhite: return "\u{001B}[107m"
        case .color256(let index): return "\u{001B}[48;5;\(index)m"
        case .rgb(let r, let g, let b): return "\u{001B}[48;2;\(r);\(g);\(b)m"
        }
    }
}
