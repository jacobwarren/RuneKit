import Foundation

extension Float {
    /// Convert Yoga float coordinate to terminal integer coordinate (0.5 rounds up, negatives clamped)
    func roundedToTerminal() -> Int {
        max(0, Int(rounded()))
    }
}
