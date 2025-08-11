import Foundation

/// Controls adaptive quality reduction under backpressure and provides grid preprocessing.
public struct AdaptiveQualityController: Sendable {
    private(set) var adaptiveQuality = 1.0

    public init() {}

    public mutating func reduceQualityOnBackpressure(current: Double) {
        adaptiveQuality = max(0.3, current * 0.9)
    }

    /// Apply adaptive quality - reduce grid resolution if under pressure
    public func apply(to grid: TerminalGrid) async -> TerminalGrid {
        if adaptiveQuality >= 0.9 || grid.height <= 10 {
            return grid
        }
        // Placeholder: return original grid until we implement downsampling
        return grid
    }
}
