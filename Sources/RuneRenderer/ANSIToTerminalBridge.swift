import Foundation
import RuneANSI

/// Bridge functions to convert ANSI TextAttributes/Color to Terminal types used by renderer
enum ANSIToTerminalBridge {
    // MARK: - Public API

    static func toTerminalAttributes(_ attrs: TextAttributes) -> TerminalAttributes {
        mapAttributes(attrs)
    }

    static func toTerminalColor(_ color: ANSIColor?) -> TerminalColor? {
        guard let color else { return nil }
        if let ansi = mapBasicAnsi(color) { return ansi }
        if let c256 = map256(color) { return c256 }
        if let rgb = mapRGB(color) { return rgb }
        return nil
    }

    // MARK: - Attributes Mapping

    private static func mapAttributes(_ attrs: TextAttributes) -> TerminalAttributes {
        var result: TerminalAttributes = .none
        // Compose via small checks to keep cyclomatic complexity low
        if attrs.bold { result.insert(.bold) }
        if attrs.dim { result.insert(.dim) }
        if attrs.italic { result.insert(.italic) }
        if attrs.underline { result.insert(.underline) }
        if attrs.inverse { result.insert(.reverse) }
        if attrs.strikethrough { result.insert(.strikethrough) }
        return result
    }

    // MARK: - Color Mapping

    private static func mapBasicAnsi(_ color: ANSIColor) -> TerminalColor? {
        if let basic = basicAnsiIndex(for: color) { return .ansi(basic) }
        return nil
    }

    private static func map256(_ color: ANSIColor) -> TerminalColor? {
        if case let .color256(index) = color { return .ansi(clampToByte(index)) }
        return nil
    }

    private static func mapRGB(_ color: ANSIColor) -> TerminalColor? {
        if case let .rgb(red, green, blue) = color { return .rgb(clampToByte(red), clampToByte(green), clampToByte(blue)) }
        return nil
    }

    private static func basicAnsiIndex(for color: ANSIColor) -> UInt8? {
        if let base = baseIndexMap[color] { return UInt8(base) }
        if let bright = brightIndexMap[color] { return UInt8(8 + bright) }
        return nil
    }

    // Lookup maps replace large switch statements
    private static let baseIndexMap: [ANSIColor: Int] = [
        .black: 0, .red: 1, .green: 2, .yellow: 3, .blue: 4, .magenta: 5, .cyan: 6, .white: 7,
    ]

    private static let brightIndexMap: [ANSIColor: Int] = [
        .brightBlack: 0, .brightRed: 1, .brightGreen: 2, .brightYellow: 3,
        .brightBlue: 4, .brightMagenta: 5, .brightCyan: 6, .brightWhite: 7,
    ]

    private static func clampToByte(_ value: Int) -> UInt8 {
        UInt8(max(0, min(255, value)))
    }
}
