import Foundation

public extension ANSIColor {
    /// Initialize from hex string like "#RRGGBB" or "RRGGBB"
    static func fromHex(_ hex: String) -> ANSIColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6, let value = Int(hexString, radix: 16) else { return nil }
        let red = (value >> 16) & 0xFF
        let green = (value >> 8) & 0xFF
        let blue = value & 0xFF
        return .rgb(red, green, blue)
    }
}
