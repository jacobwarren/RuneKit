import Foundation
import Testing

/// Shared test environment helpers used by test targets to standardize CI/test detection.
public enum TestEnv {
    /// True when running under a CI environment (GitHub Actions, etc.)
    public static var isCI: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["CI"] != nil || env["GITHUB_ACTIONS"] != nil || env["BUILDKITE"] != nil || env["GITLAB_CI"] != nil
    }

    /// Test trait for timing-sensitive tests that should never run in CI
    public static let skipInCI: Test.Trait = .enabled(if: !isCI)

    /// Test trait for integration tests that use pipes/file handles and can hang in CI
    public static let skipIntegrationInCI: Test.Trait = .enabled(if: !isCI)

    /// Test trait for performance/benchmark tests that are unreliable in CI
    public static let skipBenchmarkInCI: Test.Trait = .enabled(if: !isCI)

    /// Test trait for input/interaction tests that don't work in headless CI
    public static let skipInputInCI: Test.Trait = .enabled(if: !isCI)
}

    /// True when running under XCTest or swift test (including swift-testing)
    public static var isUnderTestHarness: Bool {
        let env = ProcessInfo.processInfo.environment
        // Common markers for XCTest / SwiftPM
        if env["XCTestConfigurationFilePath"] != nil || env["SWIFTPM_TEST"] != nil {
            return true
        }
        // Heuristics for Apple's swift-testing runner (future-proof but harmless if absent)
        if env["SWIFT_TESTING"] != nil || env["SWIFT_TESTING_MODE"] != nil {
            return true
        }
        // Executable name/path often includes xctest when running tests
        let argv0 = ProcessInfo.processInfo.arguments.first ?? ""
        if argv0.contains(".xctest") || argv0.hasSuffix("xctest") {
            return true
        }
        return false
    }

    /// True when either CI or test harness is detected
    public static var isTestOrCI: Bool { isCI || isUnderTestHarness }
}
