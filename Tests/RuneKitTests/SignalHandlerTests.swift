import Foundation
import Testing
@testable import RuneKit

// MARK: - Signal Handling Tests

struct SignalHandlerTests {
    @Test("SignalHandler initialization")
    func signalHandlerInitialization() async {
        // Arrange & Act
        let handler = SignalHandler()

        // Assert
        let isInstalled = await handler.isInstalled
        #expect(!isInstalled, "Should not be installed initially")
    }

    @Test("SignalHandler install and cleanup")
    func signalHandlerInstallAndCleanup() async {
        // Arrange
        let handler = SignalHandler()

        // Use actor-isolated state for thread safety
        actor TestState {
            var cleanupCalled = false

            func setCleanupCalled() {
                cleanupCalled = true
            }

            func wasCleanupCalled() -> Bool {
                cleanupCalled
            }
        }

        let testState = TestState()

        // Act
        await handler.install {
            await testState.setCleanupCalled()
        }

        // Assert
        let isInstalledAfterInstall = await handler.isInstalled
        #expect(isInstalledAfterInstall, "Should be installed after install()")

        // Cleanup
        await handler.cleanup()
        let isInstalledAfterCleanup = await handler.isInstalled
        #expect(!isInstalledAfterCleanup, "Should not be installed after cleanup()")

        // Note: We can't easily test signal delivery in unit tests
        // but we can test the setup/teardown logic
    }

    @Test("SignalHandler graceful teardown callback")
    func signalHandlerGracefulTeardown() async {
        // Arrange
        let handler = SignalHandler()

        // Use actor-isolated state for thread safety
        actor TestState {
            var teardownCalled = false
            var teardownCallCount = 0

            func recordTeardown() {
                teardownCalled = true
                teardownCallCount += 1
            }

            func getTeardownState() -> (called: Bool, count: Int) {
                (teardownCalled, teardownCallCount)
            }
        }

        let testState = TestState()

        // Act
        await handler.install {
            await testState.recordTeardown()
        }

        // Simulate graceful teardown (without actual signal)
        await handler.performGracefulTeardown()

        // Assert
        let (teardownCalled, teardownCallCount) = await testState.getTeardownState()
        #expect(teardownCalled, "Teardown callback should be called")
        #expect(teardownCallCount == 1, "Teardown should be called exactly once")

        // Cleanup
        await handler.cleanup()
    }
}
