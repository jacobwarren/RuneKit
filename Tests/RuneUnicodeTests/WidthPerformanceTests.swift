import Foundation
import Testing
@testable import RuneUnicode

/// Performance tests for Unicode width calculation functionality (RUNE-18)
struct WidthPerformanceTests {
    // MARK: - Performance Tests (RUNE-18)

    @Test("Performance benchmark: ASCII baseline")
    func performanceBenchmarkASCIIBaseline() {
        // Arrange - Pure ASCII strings for baseline measurement
        let asciiStrings = [
            "Hello, World!",
            "The quick brown fox jumps over the lazy dog",
            "ASCII text with numbers 123456789 and symbols !@#$%^&*()",
            String(repeating: "A", count: 100),
            String(repeating: "Hello World ", count: 50),
        ]

        // Act & Assert - Measure baseline performance
        let startTime = Date()

        for _ in 0 ..< 2_000 { // Run 2_000 iterations for better measurement
            for testString in asciiStrings {
                _ = Width.displayWidth(of: testString)
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Print performance results for documentation
        let totalCalculations = asciiStrings.count * 2_000
        print("ASCII baseline: \(totalCalculations) width calculations in \(String(format: "%.3f", duration)) seconds")
        print("ASCII rate: \(String(format: "%.0f", Double(totalCalculations) / duration)) calculations/second")

        // Store baseline for comparison (should be reasonably fast)
        #expect(duration < 1.0, "ASCII width calculation should be reasonably fast")
    }

    @Test("Performance benchmark: Enhanced width calculation")
    func performanceBenchmarkEnhanced() {
        // Arrange - Mixed content including emoji and CJK
        let mixedStrings = [
            "Hello 👍 World",
            "Text with emoji: 🌍 🚀 ⭐",
            "CJK characters: 你好世界",
            "Mixed: Hello 世界 🌍",
            "Complex emoji: 👨‍👩‍👧‍👦 🏳️‍⚧️",
            String(repeating: "表", count: 50), // CJK characters
            String(repeating: "🙂", count: 25), // Emoji
        ]

        // Act & Assert - Measure enhanced performance
        let startTime = Date()

        for _ in 0 ..< 1_000 { // Run 1_000 iterations
            for testString in mixedStrings {
                _ = Width.displayWidth(of: testString)
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Print performance results for documentation
        let totalCalculations = mixedStrings.count * 1_000
        print("Enhanced width: \(totalCalculations) width calculations in \(String(format: "%.3f", duration)) seconds")
        print("Enhanced rate: \(String(format: "%.0f", Double(totalCalculations) / duration)) calculations/second")

        // Assert performance is reasonable (within 2x of baseline expectation)
        #expect(duration < 1.0, "Enhanced width calculation should still be fast enough for real-time use")
    }

    @Test("Performance benchmark for common strings")
    func performanceBenchmark() {
        // Arrange - Create test strings of various types
        let testStrings = [
            "Hello, World!",
            "The quick brown fox jumps over the lazy dog",
            "ASCII text with numbers 123456789 and symbols !@#$%^&*()",
            "Text with accents: café, naïve, résumé, piñata",
            "Mixed content: Hello 世界 🌍",
            String(repeating: "A", count: 1_000), // Long ASCII string
            String(repeating: "À", count: 500), // Long string with accents
        ]

        // Act & Assert - Measure performance
        let startTime = Date()

        for _ in 0 ..< 1_000 { // Run 1_000 iterations
            for testString in testStrings {
                _ = Width.displayWidth(of: testString)
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Performance expectation: should complete in reasonable time
        // This is more of a smoke test than a strict performance requirement
        #expect(duration < 2.0, "Performance test took \(duration) seconds, expected < 2.0 seconds")

        print(
            "Performance benchmark: \(testStrings.count * 1_000) width calculations in \(String(format: "%.3f", duration)) seconds",
            )
    }
}
