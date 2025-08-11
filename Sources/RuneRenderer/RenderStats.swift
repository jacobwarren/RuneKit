import Foundation

/// Rendering strategy options
public enum RenderingStrategy: Sendable {
    case fullRedraw
    case deltaUpdate
    case scrollOptimized
}

/// Statistics from a rendering operation
public struct RenderStats: Sendable {
    public var strategy: RenderingStrategy = .fullRedraw
    public var linesChanged = 0
    public var bytesWritten = 0
    public var duration: TimeInterval = 0
    /// Total lines in the frame (for accurate efficiency computation)
    public var totalLines: Int?

    public var efficiency: Double {
        // If no changes, efficiency is perfect
        if linesChanged == 0 { return 1.0 }
        // Prefer accurate calculation when total is known
        if let total = totalLines, total > 0 {
            let efficiency = 1.0 - (Double(linesChanged) / Double(total))
            return max(0.0, min(1.0, efficiency))
        }
        // Fallback heuristic by strategy
        return strategy == .deltaUpdate ? 0.8 : 0.0
    }
}

/// Overall performance metrics for the renderer
public struct RendererPerformanceMetrics: Sendable {
    public let totalBytesWritten: Int
    public let lastRenderTime: Date
}
