import Foundation

/// Determines when to force a full redraw based on frame/time cadence and quality.
public struct FullRedrawPolicy: Sendable {
    private var framesSinceFullRedraw: Int
    private var lastFullRedrawTime: Date
    private let maxFramesBetweenFullRedraws: Int
    private let maxTimeBetweenFullRedraws: TimeInterval

    public init(
        framesSinceFullRedraw: Int = 0,
        lastFullRedrawTime: Date = .distantPast,
        maxFramesBetweenFullRedraws: Int = 100,
        maxTimeBetweenFullRedraws: TimeInterval = 30.0,
    ) {
        self.framesSinceFullRedraw = framesSinceFullRedraw
        self.lastFullRedrawTime = lastFullRedrawTime
        self.maxFramesBetweenFullRedraws = maxFramesBetweenFullRedraws
        self.maxTimeBetweenFullRedraws = maxTimeBetweenFullRedraws
    }

    public mutating func updateCounters(afterFullRedrawAt time: Date) {
        framesSinceFullRedraw = 0
        lastFullRedrawTime = time
    }

    public mutating func incrementFrames() { framesSinceFullRedraw += 1 }

    public func shouldForceFullRedraw(now: Date, adaptiveQuality: Double) -> Bool {
        let timeSinceLast = now.timeIntervalSince(lastFullRedrawTime)
        return framesSinceFullRedraw >= maxFramesBetweenFullRedraws ||
            timeSinceLast >= maxTimeBetweenFullRedraws ||
            adaptiveQuality < 0.7
    }

    public func snapshot() -> (framesSince: Int, lastTime: Date) {
        (framesSinceFullRedraw, lastFullRedrawTime)
    }
}
