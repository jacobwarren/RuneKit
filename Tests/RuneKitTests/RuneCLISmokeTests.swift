import Foundation
import Testing

struct RuneCLISmokeTests {
    // Try to locate the built products directory where RuneCLI resides
    static func productsDirectory() -> URL? {
        #if os(macOS)
        // In SwiftPM tests on macOS, the test bundle sits next to the products dir
        if let bundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        return nil
        #else
        // On Linux, Bundle.main.bundleURL typically points to the products dir
        return Bundle.main.bundleURL
        #endif
    }

    static func cliExecutableURL() -> URL? {
        guard let dir = productsDirectory() else { return nil }
        let primary = dir.appendingPathComponent("RuneCLI", isDirectory: false)
        if FileManager.default.isExecutableFile(atPath: primary.path) { return primary }
        #if os(macOS)
        // In some cases, the CLI may be nested under a toolchain-specific directory
        // Try one directory up (rare, but harmless)
        let parent = dir.deletingLastPathComponent().appendingPathComponent("RuneCLI")
        if FileManager.default.isExecutableFile(atPath: parent.path) { return parent }
        #endif
        return nil
    }

    static func canLocateCLI() -> Bool { cliExecutableURL() != nil }

    @Test("RuneCLI exits promptly in test mode", .enabled(if: RuneCLISmokeTests.canLocateCLI()))
    func runeCLIExitsPromptly() async throws {
        guard let exe = Self.cliExecutableURL() else { return }

        let proc = Process()
        proc.executableURL = exe

        var env = ProcessInfo.processInfo.environment
        // Ensure CLI recognizes test/non-interactive mode and returns immediately
        env["SWIFTPM_TEST"] = "1"
        env["CI"] = "1" // also triggers immediate return
        proc.environment = env

        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = outPipe

        try proc.run()
        proc.waitUntilExit()

        let status = proc.terminationStatus
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        #expect(status == 0, "RuneCLI should exit with code 0 (status: \(status))\nOutput:\n\(output)")
        #expect(output.contains("skipping demos") || output.isEmpty, "CLI should detect test mode and skip demos")
    }
}

