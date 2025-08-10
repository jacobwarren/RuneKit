import Foundation

/// Shared test environment helpers used by test targets to standardize CI/test detection.
public enum TestEnv {
    /// True when running under a CI environment (GitHub Actions, etc.)
    public static var isCI: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["CI"] != nil || env["GITHUB_ACTIONS"] != nil || env["BUILDKITE"] != nil || env["GITLAB_CI"] != nil
    }

    /// True when running under XCTest or swift test
    public static var isUnderTestHarness: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil || env["SWIFTPM_TEST"] != nil
    }

    /// True when either CI or test harness is detected
    public static var isTestOrCI: Bool { isCI || isUnderTestHarness }
}

