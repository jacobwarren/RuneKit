import RuneANSI

extension ANSIColor {
    var foregroundSequence: String {
        switch self {
        case .black: "\u{001B}[30m"
        case .red: "\u{001B}[31m"
        case .green: "\u{001B}[32m"
        case .yellow: "\u{001B}[33m"
        case .blue: "\u{001B}[34m"
        case .magenta: "\u{001B}[35m"
        case .cyan: "\u{001B}[36m"
        case .white: "\u{001B}[37m"
        case .brightBlack: "\u{001B}[90m"
        case .brightRed: "\u{001B}[91m"
        case .brightGreen: "\u{001B}[92m"
        case .brightYellow: "\u{001B}[93m"
        case .brightBlue: "\u{001B}[94m"
        case .brightMagenta: "\u{001B}[95m"
        case .brightCyan: "\u{001B}[96m"
        case .brightWhite: "\u{001B}[97m"
        case let .color256(index): "\u{001B}[38;5;\(index)m"
        case let .rgb(red, green, blue): "\u{001B}[38;2;\(red);\(green);\(blue)m"
        }
    }

    var backgroundSequence: String {
        switch self {
        case .black: "\u{001B}[40m"
        case .red: "\u{001B}[41m"
        case .green: "\u{001B}[42m"
        case .yellow: "\u{001B}[43m"
        case .blue: "\u{001B}[44m"
        case .magenta: "\u{001B}[45m"
        case .cyan: "\u{001B}[46m"
        case .white: "\u{001B}[47m"
        case .brightBlack: "\u{001B}[100m"
        case .brightRed: "\u{001B}[101m"
        case .brightGreen: "\u{001B}[102m"
        case .brightYellow: "\u{001B}[103m"
        case .brightBlue: "\u{001B}[104m"
        case .brightMagenta: "\u{001B}[105m"
        case .brightCyan: "\u{001B}[106m"
        case .brightWhite: "\u{001B}[107m"
        case let .color256(index): "\u{001B}[48;5;\(index)m"
        case let .rgb(red, green, blue): "\u{001B}[48;2;\(red);\(green);\(blue)m"
        }
    }
}
