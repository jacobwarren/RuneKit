import Foundation
import RuneANSI

/// Bridge functions to convert ANSI TextAttributes/Color to Terminal types used by renderer
enum ANSIToTerminalBridge {
    static func toTerminalAttributes(_ attrs: TextAttributes) -> TerminalAttributes {
        var t: TerminalAttributes = .none
        if attrs.bold { t.insert(.bold) }
        if attrs.dim { t.insert(.dim) }
        if attrs.italic { t.insert(.italic) }
        if attrs.underline { t.insert(.underline) }
        if attrs.inverse { t.insert(.reverse) }
        if attrs.strikethrough { t.insert(.strikethrough) }
        return t
    }

    static func toTerminalColor(_ c: ANSIColor?) -> TerminalColor? {
        guard let c else { return nil }
        switch c {
        case .black: return .ansi(0)
        case .red: return .ansi(1)
        case .green: return .ansi(2)
        case .yellow: return .ansi(3)
        case .blue: return .ansi(4)
        case .magenta: return .ansi(5)
        case .cyan: return .ansi(6)
        case .white: return .ansi(7)
        case .brightBlack: return .ansi(8)
        case .brightRed: return .ansi(9)
        case .brightGreen: return .ansi(10)
        case .brightYellow: return .ansi(11)
        case .brightBlue: return .ansi(12)
        case .brightMagenta: return .ansi(13)
        case .brightCyan: return .ansi(14)
        case .brightWhite: return .ansi(15)
        case .color256(let idx): return .ansi(UInt8(max(0, min(255, idx))))
        case .rgb(let r, let g, let b):
            return .rgb(UInt8(max(0, min(255, r))), UInt8(max(0, min(255, g))), UInt8(max(0, min(255, b))))
        }
    }
}

