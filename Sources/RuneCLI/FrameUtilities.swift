import Foundation
import RuneRenderer

/// Frame creation utilities for RuneCLI demos
extension RuneCLI {
    /// Create a system monitor frame that adapts to terminal width
    static func createSystemMonitorFrame(
        terminalWidth: Int,
        cpuUsage: Int,
        ramUsage: Int,
        diskUsage: Int,
        netUsage: Int,
        style: BorderStyle = .single
    ) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60) // Leave some margin
        let contentWidth = max(maxWidth - 4, 20) // Ensure minimum width

        // Create progress bars
        let cpuBar = createProgressBar(value: cpuUsage, width: contentWidth - 12, label: "CPU")
        let ramBar = createProgressBar(value: ramUsage, width: contentWidth - 12, label: "RAM")
        let diskBar = createProgressBar(value: diskUsage, width: contentWidth - 12, label: "DISK")
        let netBar = createProgressBar(value: netUsage, width: contentWidth - 12, label: "NET")

        let borderChars = getBorderChars(style: style)

        let lines = [
            "\(borderChars.topLeft)\(String(repeating: borderChars.horizontal, count: contentWidth + 2))\(borderChars.topRight)",
            "\(borderChars.vertical) System Monitor \(String(repeating: " ", count: contentWidth - 14))\(borderChars.vertical)",
            "\(borderChars.leftTee)\(String(repeating: borderChars.horizontal, count: contentWidth + 2))\(borderChars.rightTee)",
            "\(borderChars.vertical) \(cpuBar) \(borderChars.vertical)",
            "\(borderChars.vertical) \(ramBar) \(borderChars.vertical)",
            "\(borderChars.vertical) \(diskBar) \(borderChars.vertical)",
            "\(borderChars.vertical) \(netBar) \(borderChars.vertical)",
            "\(borderChars.bottomLeft)\(String(repeating: borderChars.horizontal, count: contentWidth + 2))\(borderChars.bottomRight)"
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: contentWidth + 4,
            height: lines.count
        )
    }

    /// Create a simple box frame with content
    static func createBoxFrame(content: String) -> TerminalRenderer.Frame {
        let contentWidth = max(content.count, 10)
        let totalWidth = contentWidth + 4

        let lines = [
            "┌\(String(repeating: "─", count: contentWidth + 2))┐",
            "│ \(content.padding(toLength: contentWidth, withPad: " ", startingAt: 0)) │",
            "└\(String(repeating: "─", count: contentWidth + 2))┘"
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: totalWidth,
            height: 3
        )
    }

    /// Create a multi-line box frame
    static func createMultiLineBoxFrame(contents: [String]) -> TerminalRenderer.Frame {
        let maxContentWidth = contents.map { $0.count }.max() ?? 10
        let contentWidth = max(maxContentWidth, 10)
        let totalWidth = contentWidth + 4

        var lines = ["┌\(String(repeating: "─", count: contentWidth + 2))┐"]

        for content in contents {
            lines.append("│ \(content.padding(toLength: contentWidth, withPad: " ", startingAt: 0)) │")
        }

        lines.append("└\(String(repeating: "─", count: contentWidth + 2))┘")

        return TerminalRenderer.Frame(
            lines: lines,
            width: totalWidth,
            height: lines.count
        )
    }

    /// Create final results frame for performance metrics
    static func createFinalResultsFrame(terminalWidth: Int, metrics: HybridPerformanceMetrics) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)

        // Build lines separately to avoid compiler complexity
        let topBorder = "┌\(String(repeating: "─", count: contentWidth + 2))┐"
        let titleLine = "│ Performance Results \(String(repeating: " ", count: contentWidth - 19))│"
        let separatorLine = "├\(String(repeating: "─", count: contentWidth + 2))┤"
        let totalRendersLine = "│ Total renders: \(String(metrics.totalRenders).padding(toLength: contentWidth - 15, withPad: " ", startingAt: 0))│"
        let efficiencyLine = "│ Avg efficiency: \(String(format: "%.1f%%", metrics.averageEfficiency * 100).padding(toLength: contentWidth - 16, withPad: " ", startingAt: 0))│"
        let droppedFramesLine = "│ Dropped frames: \(String(metrics.droppedFrames).padding(toLength: contentWidth - 16, withPad: " ", startingAt: 0))│"
        let queueDepthLine = "│ Queue depth: \(String(metrics.currentQueueDepth).padding(toLength: contentWidth - 13, withPad: " ", startingAt: 0))│"
        let qualityLine = "│ Quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100).padding(toLength: contentWidth - 9, withPad: " ", startingAt: 0))│"
        let bottomBorder = "└\(String(repeating: "─", count: contentWidth + 2))┘"

        let lines = [
            topBorder,
            titleLine,
            separatorLine,
            totalRendersLine,
            efficiencyLine,
            droppedFramesLine,
            queueDepthLine,
            qualityLine,
            bottomBorder
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: contentWidth + 4,
            height: lines.count
        )
    }

    /// Create alternate screen welcome frame
    static func createAlternateScreenWelcomeFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)

        let lines = [
            "┌\(String(repeating: "─", count: contentWidth + 2))┐",
            "│ Welcome to Alternate Screen! \(String(repeating: " ", count: contentWidth - 29))│",
            "├\(String(repeating: "─", count: contentWidth + 2))┤",
            "│ This is running in the alternate screen buffer. \(String(repeating: " ", count: contentWidth - 48))│",
            "│ When we exit, your previous terminal content \(String(repeating: " ", count: contentWidth - 46))│",
            "│ will be restored automatically. \(String(repeating: " ", count: contentWidth - 32))│",
            "│ \(String(repeating: " ", count: contentWidth))│",
            "│ This is how applications like vim, less, and \(String(repeating: " ", count: contentWidth - 46))│",
            "│ htop work - they don't interfere with your \(String(repeating: " ", count: contentWidth - 44))│",
            "│ terminal history. \(String(repeating: " ", count: contentWidth - 18))│",
            "└\(String(repeating: "─", count: contentWidth + 2))┘"
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: contentWidth + 4,
            height: lines.count
        )
    }

    /// Create alternate screen application frame
    static func createAlternateScreenAppFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)

        let lines = [
            "┌\(String(repeating: "─", count: contentWidth + 2))┐",
            "│ Full-Screen Application \(String(repeating: " ", count: contentWidth - 24))│",
            "├\(String(repeating: "─", count: contentWidth + 2))┤",
            "│ Status: Running \(String(repeating: " ", count: contentWidth - 16))│",
            "│ Mode: Alternate Screen Buffer \(String(repeating: " ", count: contentWidth - 30))│",
            "│ \(String(repeating: " ", count: contentWidth))│",
            "│ [F1] Help    [F2] Settings    [Q] Quit \(String(repeating: " ", count: contentWidth - 39))│",
            "│ \(String(repeating: " ", count: contentWidth))│",
            "│ This simulates a full-screen application \(String(repeating: " ", count: contentWidth - 42))│",
            "│ interface that takes over the entire \(String(repeating: " ", count: contentWidth - 37))│",
            "│ terminal without affecting your history. \(String(repeating: " ", count: contentWidth - 41))│",
            "└\(String(repeating: "─", count: contentWidth + 2))┘"
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: contentWidth + 4,
            height: lines.count
        )
    }

    /// Create fallback demo frame
    static func createFallbackDemoFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 50)
        let contentWidth = max(maxWidth - 4, 25)

        let lines = [
            "┌\(String(repeating: "─", count: contentWidth + 2))┐",
            "│ Normal Mode (No Alt Screen) \(String(repeating: " ", count: contentWidth - 28))│",
            "├\(String(repeating: "─", count: contentWidth + 2))┤",
            "│ This renders normally without \(String(repeating: " ", count: contentWidth - 30))│",
            "│ using the alternate screen. \(String(repeating: " ", count: contentWidth - 28))│",
            "└\(String(repeating: "─", count: contentWidth + 2))┘"
        ]

        return TerminalRenderer.Frame(
            lines: lines,
            width: contentWidth + 4,
            height: lines.count
        )
    }

    // MARK: - Utility Functions

    /// Create a progress bar string
    private static func createProgressBar(value: Int, width: Int, label: String) -> String {
        let barWidth = width - 8 // Account for label and percentage
        let filledWidth = Int(Double(barWidth) * Double(value) / 100.0)
        let emptyWidth = barWidth - filledWidth

        let filled = String(repeating: "█", count: filledWidth)
        let empty = String(repeating: "░", count: emptyWidth)
        let percentage = String(format: "%3d%%", value)

        return "\(label): [\(filled)\(empty)] \(percentage)"
    }

    /// Border style for frames
    enum BorderStyle {
        case single
        case double
    }

    /// Border characters for different styles
    struct BorderChars {
        let topLeft: String
        let topRight: String
        let bottomLeft: String
        let bottomRight: String
        let horizontal: String
        let vertical: String
        let leftTee: String
        let rightTee: String
    }

    /// Get border characters for a style
    private static func getBorderChars(style: BorderStyle) -> BorderChars {
        switch style {
        case .single:
            return BorderChars(
                topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘",
                horizontal: "─", vertical: "│", leftTee: "├", rightTee: "┤"
            )
        case .double:
            return BorderChars(
                topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝",
                horizontal: "═", vertical: "║", leftTee: "╠", rightTee: "╣"
            )
        }
    }
}
