import Foundation
import Testing
@testable import RuneKit

@Suite("Ticker tests")
struct TickerTests {
    @Test("Ticker ticks approximately N times and cancels cleanly")
    func tickerTicksAndCancels() async {
        // Arrange
        let expectationCount = 4
        let interval: Duration = .milliseconds(25)
        let start = Date()
        let counter = Counter()
        let ticker = Ticker(every: interval) {
            await counter.increment()
        }

        // Act: wait ~ a bit over N intervals
        try? await Task.sleep(for: .milliseconds(120))
        ticker.cancel()
        let elapsed = Date().timeIntervalSince(start)
        let count = await counter.value

        // Assert: allow some jitter, expect at least ~3 ticks and not exploding
        #expect(count >= 3 && count <= 6, "Tick count should be in a small window; got \(count)")
        #expect(elapsed >= 0.10 && elapsed <= 0.30, "Elapsed should be reasonable; got \(elapsed)")

        // Ensure cancelling again is safe
        ticker.cancel()
    }
}

actor Counter {
    private(set) var value: Int = 0
    func increment() { value += 1 }
}

