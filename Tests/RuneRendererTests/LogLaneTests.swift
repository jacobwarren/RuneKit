import Testing
import Foundation
@testable import RuneRenderer

/// Tests for LogLane formatting and display functionality
struct LogLaneTests {
    @Test("LogLane initialization")
    func logLaneInitialization() {
        // Arrange & Act
        let logLane = LogLane()

        // Assert
        #expect(logLane.configuration.maxDisplayLines == 10, "Default max display lines should be 10")
        #expect(logLane.configuration.showTimestamps == true, "Default should show timestamps")
        #expect(logLane.configuration.useColors == true, "Default should use colors")
    }

    @Test("LogLane custom configuration")
    func logLaneCustomConfiguration() {
        // Arrange & Act
        let config = LogLane.Configuration(
            maxDisplayLines: 5,
            showTimestamps: false,
            useColors: false
        )
        let logLane = LogLane(configuration: config)

        // Assert
        #expect(logLane.configuration.maxDisplayLines == 5, "Should use custom max display lines")
        #expect(logLane.configuration.showTimestamps == false, "Should use custom timestamp setting")
        #expect(logLane.configuration.useColors == false, "Should use custom color setting")
    }

    @Test("LogLane formats single log line")
    func logLaneFormatsSingleLogLine() {
        // Arrange
        let logLane = LogLane(showTimestamps: false, useColors: false)
        let logLine = ConsoleCapture.LogLine(
            content: "Test log message",
            timestamp: Date(),
            source: .stdout
        )

        // Act
        let formatted = logLane.formatLogLine(logLine, terminalWidth: 80)

        // Assert
        #expect(formatted.count == 1, "Should return single formatted line")
        #expect(formatted[0].contains("Test log message"), "Should contain log content")
        #expect(formatted[0].contains("│"), "Should contain stdout prefix")
    }

    @Test("LogLane formats stderr with different prefix")
    func logLaneFormatsStderrWithDifferentPrefix() {
        // Arrange
        let logLane = LogLane(showTimestamps: false, useColors: false)
        let stderrLine = ConsoleCapture.LogLine(
            content: "Error message",
            timestamp: Date(),
            source: .stderr
        )

        // Act
        let formatted = logLane.formatLogLine(stderrLine, terminalWidth: 80)

        // Assert
        #expect(formatted.count == 1, "Should return single formatted line")
        #expect(formatted[0].contains("Error message"), "Should contain error content")
        #expect(formatted[0].contains("⚠"), "Should contain stderr prefix")
    }

    @Test("LogLane includes timestamps when enabled")
    func logLaneIncludesTimestampsWhenEnabled() {
        // Arrange
        let logLane = LogLane(showTimestamps: true, useColors: false)
        let logLine = ConsoleCapture.LogLine(
            content: "Timestamped message",
            timestamp: Date(),
            source: .stdout
        )

        // Act
        let formatted = logLane.formatLogLine(logLine, terminalWidth: 80)

        // Assert
        #expect(formatted.count == 1, "Should return single formatted line")
        #expect(formatted[0].contains("["), "Should contain timestamp bracket")
        #expect(formatted[0].contains("]"), "Should contain timestamp bracket")
        #expect(formatted[0].contains("Timestamped message"), "Should contain log content")
    }

    @Test("LogLane wraps long lines")
    func logLaneWrapsLongLines() {
        // Arrange
        let logLane = LogLane(showTimestamps: false, useColors: false)
        let longMessage = String(repeating: "A", count: 100) // 100 character message
        let logLine = ConsoleCapture.LogLine(
            content: longMessage,
            timestamp: Date(),
            source: .stdout
        )

        // Act
        let formatted = logLane.formatLogLine(logLine, terminalWidth: 50)

        // Assert
        #expect(formatted.count > 1, "Should wrap long line into multiple lines")

        // Check that all content is preserved (remove spaces added by wrapping)
        let combinedContent = formatted.joined().replacingOccurrences(of: " ", with: "")
        let cleanLongMessage = longMessage.replacingOccurrences(of: " ", with: "")
        #expect(combinedContent.contains(cleanLongMessage), "Should preserve all content when wrapping")
    }

    @Test("LogLane formats multiple logs")
    func logLaneFormatsMultipleLogs() {
        // Arrange
        let logLane = LogLane(showTimestamps: false, useColors: false)
        let logs = [
            ConsoleCapture.LogLine(content: "Log 1", timestamp: Date(), source: .stdout),
            ConsoleCapture.LogLine(content: "Log 2", timestamp: Date(), source: .stderr),
            ConsoleCapture.LogLine(content: "Log 3", timestamp: Date(), source: .stdout)
        ]

        // Act
        let formatted = logLane.formatLogs(logs, terminalWidth: 80)

        // Assert
        #expect(formatted.count == 3, "Should format all logs")
        #expect(formatted[0].contains("Log 1"), "Should contain first log")
        #expect(formatted[1].contains("Log 2"), "Should contain second log")
        #expect(formatted[2].contains("Log 3"), "Should contain third log")
    }

    @Test("LogLane respects max display lines")
    func logLaneRespectsMaxDisplayLines() {
        // Arrange
        let logLane = LogLane(maxDisplayLines: 2, showTimestamps: false, useColors: false)
        let logs = [
            ConsoleCapture.LogLine(content: "Log 1", timestamp: Date(), source: .stdout),
            ConsoleCapture.LogLine(content: "Log 2", timestamp: Date(), source: .stdout),
            ConsoleCapture.LogLine(content: "Log 3", timestamp: Date(), source: .stdout),
            ConsoleCapture.LogLine(content: "Log 4", timestamp: Date(), source: .stdout)
        ]

        // Act
        let formatted = logLane.formatLogs(logs, terminalWidth: 80)

        // Assert
        #expect(formatted.count <= 2, "Should not exceed max display lines")

        // Should show the most recent logs
        #expect(formatted.last?.contains("Log 4") == true, "Should show most recent log")
    }

    @Test("LogLane calculates display height")
    func logLaneCalculatesDisplayHeight() {
        // Arrange
        let logLane = LogLane(showTimestamps: false, useColors: false)
        let logs = [
            ConsoleCapture.LogLine(content: "Log 1", timestamp: Date(), source: .stdout),
            ConsoleCapture.LogLine(content: "Log 2", timestamp: Date(), source: .stdout)
        ]

        // Act
        let height = logLane.calculateDisplayHeight(logs, terminalWidth: 80)

        // Assert
        #expect(height == 2, "Should calculate correct height for 2 logs")
    }

    @Test("LogLane creates separator")
    func logLaneCreatesSeparator() {
        // Arrange
        let logLane = LogLane(useColors: false)

        // Act
        let separator = logLane.createSeparator(terminalWidth: 10)

        // Assert
        #expect(separator.count == 10, "Separator should match terminal width")
        #expect(separator.allSatisfy { $0 == "-" }, "Should use dash character when colors disabled")
    }

    @Test("LogLane predefined configurations")
    func logLanePredefinedConfigurations() {
        // Test debug configuration
        let debugConfig = LogLane.Configuration.debug
        #expect(debugConfig.maxDisplayLines == 15, "Debug config should have 15 max lines")
        #expect(debugConfig.timestampFormat == .timeWithMs, "Debug config should use millisecond timestamps")

        // Test minimal configuration
        let minimalConfig = LogLane.Configuration.minimal
        #expect(minimalConfig.maxDisplayLines == 5, "Minimal config should have 5 max lines")
        #expect(minimalConfig.showTimestamps == false, "Minimal config should not show timestamps")

        // Test compact configuration
        let compactConfig = LogLane.Configuration.compact
        #expect(compactConfig.timestampFormat == .relative, "Compact config should use relative timestamps")
    }
}
