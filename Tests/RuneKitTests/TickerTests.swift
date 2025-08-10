import Foundation
import Testing
@testable import RuneKit

@Suite("Ticker tests")
struct TickerTests {
    @Test("Ticker ticks and cancellation stops future ticks (robust)")
    func tickerTicksAndCancels() async {
        // Arrange
        let interval: Duration = .milliseconds(40)
        let counter = Counter()
        let ticker = Ticker(every: interval) {
            await counter.increment()
        }

        // Wait for at least some ticks with a generous timeout to avoid flakiness on CI
        let start = Date()
        let deadline = start.addingTimeInterval(0.8)
        while await counter.value < 2 && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        let seen = await counter.value
        #expect(seen >= 1, "Ticker should tick at least once within 800ms; got \(seen)")

        // Cancel and ensure it stops ticking (allowing a small in-flight race)
        ticker.cancel()
        let countAtCancel = await counter.value
        try? await Task.sleep(for: .milliseconds(200))
        let countAfter = await counter.value
        #expect(countAfter <= countAtCancel + 1, "Ticker should stop or at most deliver one in-flight tick after cancel; before=\(countAtCancel), after=\(countAfter)")

        // Idempotent cancel
        ticker.cancel()
    }
}

actor Counter {
    private(set) var value: Int = 0
    func increment() { value += 1 }
}

