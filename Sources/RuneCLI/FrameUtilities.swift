import Foundation
import RuneRenderer
import RuneComponents
import RuneLayout
import RuneUnicode

/// Frame creation utilities for RuneCLI demos
extension RuneCLI {
    /// Create a system monitor frame that adapts to terminal width using Box component
    static func createSystemMonitorFrame(
        terminalWidth: Int,
        cpuUsage: Int,
        ramUsage: Int,
        diskUsage: Int,
        netUsage: Int,
        style: BorderStyle = .single
    ) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60) // Leave some margin
        let contentWidth = max(maxWidth - 4, 30) // Ensure minimum width for progress bars
        let totalWidth = contentWidth + 4

        // Create progress bars - ensure minimum width for meaningful progress bars
        let progressBarWidth = max(contentWidth - 12, 16) // Minimum 16 chars for progress bar
        let cpuBar = createProgressBar(value: cpuUsage, width: progressBarWidth, label: "CPU")
        let ramBar = createProgressBar(value: ramUsage, width: progressBarWidth, label: "RAM")
        let diskBar = createProgressBar(value: diskUsage, width: progressBarWidth, label: "DISK")
        let netBar = createProgressBar(value: netUsage, width: progressBarWidth, label: "NET")

        // Convert BorderStyle to Box.BorderStyle
        let boxBorderStyle: Box.BorderStyle = (style == .double) ? .double : .single

        let box = Box(
            border: boxBorderStyle,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("System Monitor"),
                     Text(cpuBar),
                     Text(ramBar),
                     Text(diskBar),
                     Text(netBar)
        )

        return boxToFrame(box, width: totalWidth, height: 8)
    }

    /// Create a simple box frame with content using Box component
    static func createBoxFrame(content: String) -> TerminalRenderer.Frame {
        let contentDisplayWidth = max(Width.displayWidth(of: content), 10)
        let totalWidth = contentDisplayWidth + 4

        let box = Box(
            border: .single,
            paddingRight: 1,
            paddingLeft: 1,
            child: Text(content)
        )

        return boxToFrame(box, width: totalWidth, height: 3)
    }

    /// Create a box frame using Transform component (RUNE-34)
    static func createBoxFrameWithTransform(transform: Transform) -> TerminalRenderer.Frame {
        let box = Box(
            border: .single,
            paddingRight: 1,
            paddingLeft: 1,
            child: transform
        )

        // Use a fixed width for consistent animation frames
        return boxToFrame(box, width: 20, height: 3)
    }

    /// Create a multi-line box frame using Box component
    static func createMultiLineBoxFrame(contents: [String]) -> TerminalRenderer.Frame {
        let maxContentDisplayWidth = contents.map { Width.displayWidth(of: $0) }.max() ?? 10
        let contentWidth = max(maxContentDisplayWidth, 10)
        let totalWidth = contentWidth + 4
        let totalHeight = contents.count + 2 // +2 for top and bottom borders

        // Create Box with individual Text components
        let box: Box
        switch contents.count {
        case 0:
            box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1)
        case 1:
            box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1, children: Text(contents[0]))
        case 2:
            box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1, children: Text(contents[0]), Text(contents[1]))
        case 3:
            box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1, children: Text(contents[0]), Text(contents[1]), Text(contents[2]))
        default:
            // For more than 3 items, just use the first 3 for now
            box = Box(border: .single, flexDirection: .column, paddingRight: 1, paddingLeft: 1, children: Text(contents[0]), Text(contents[1]), Text(contents[2]))
        }

        return boxToFrame(box, width: totalWidth, height: totalHeight)
    }

    /// Create final results frame for performance metrics using Box component
    static func createFinalResultsFrame(terminalWidth: Int, metrics: HybridPerformanceMetrics) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)
        let totalWidth = contentWidth + 4

        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Performance Results"),
                     Text("Total renders: \(metrics.totalRenders)"),
                     Text("Avg efficiency: \(String(format: "%.1f%%", metrics.averageEfficiency * 100))"),
                     Text("Dropped frames: \(metrics.droppedFrames)"),
                     Text("Queue depth: \(metrics.currentQueueDepth)"),
                     Text("Quality: \(String(format: "%.1f%%", metrics.adaptiveQuality * 100))")
        )

        return boxToFrame(box, width: totalWidth, height: 9)
    }

    /// Create alternate screen welcome frame using Box component
    static func createAlternateScreenWelcomeFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)
        let totalWidth = contentWidth + 4

        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Welcome to Alternate Screen!"),
                     Text("This is running in the alternate screen buffer."),
                     Text("When we exit, your previous terminal content"),
                     Text("will be restored automatically."),
                     Newline(count: 1),
                     Text("This is how applications like vim, less, and"),
                     Text("htop work - they don't interfere with your"),
                     Text("terminal history.")
        )

        return boxToFrame(box, width: totalWidth, height: 11)
    }

    /// Create alternate screen application frame using Box component
    static func createAlternateScreenAppFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 60)
        let contentWidth = max(maxWidth - 4, 30)
        let totalWidth = contentWidth + 4

        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Full-Screen Application"),
                     Text("Status: Running"),
                     Text("Mode: Alternate Screen Buffer"),
                     Newline(count: 1),
                     Text("[F1] Help    [F2] Settings    [Q] Quit"),
                     Newline(count: 1),
                     Text("This simulates a full-screen application"),
                     Text("interface that takes over the entire"),
                     Text("terminal without affecting your history.")
        )

        return boxToFrame(box, width: totalWidth, height: 12)
    }

    /// Create fallback demo frame using Box component
    static func createFallbackDemoFrame(terminalWidth: Int) -> TerminalRenderer.Frame {
        let maxWidth = min(terminalWidth - 4, 50)
        let contentWidth = max(maxWidth - 4, 25)
        let totalWidth = contentWidth + 4

        let box = Box(
            border: .single,
            flexDirection: .column,
            paddingRight: 1,
            paddingLeft: 1,
            children: Text("Normal Mode (No Alt Screen)"),
                     Text("This renders normally without"),
                     Text("using the alternate screen.")
        )

        return boxToFrame(box, width: totalWidth, height: 6)
    }

    // MARK: - Utility Functions

    /// Convert a Box component to a TerminalRenderer.Frame
    /// - Parameters:
    ///   - box: The Box component to render
    ///   - width: The desired frame width
    ///   - height: The desired frame height
    /// - Returns: A TerminalRenderer.Frame containing the rendered box
    static func boxToFrame(_ box: Box, width: Int, height: Int) -> TerminalRenderer.Frame {
        let rect = FlexLayout.Rect(x: 0, y: 0, width: width, height: height)
        let lines = box.render(in: rect)

        // Use display width for ANSI-safe width calculation
        // For lines with ANSI codes, character count != display width
        // We need to use display width to get the correct visual width
        let actualWidth = lines.map { Width.displayWidth(of: $0) }.max() ?? width

        return TerminalRenderer.Frame(
            lines: lines,
            width: actualWidth,
            height: lines.count
        )
    }

    /// Create a progress bar string
    private static func createProgressBar(value: Int, width: Int, label: String) -> String {
        // Use Transform component for dynamic progress bar generation
        let transform = createProgressBarTransform(value: value, width: width, label: label)
        let rect = FlexLayout.Rect(x: 0, y: 0, width: width, height: 1)
        let lines = transform.render(in: rect)
        return lines.first ?? ""
    }

    /// Create a Transform component for progress bar generation (RUNE-34)
    private static func createProgressBarTransform(value: Int, width: Int, label: String) -> Transform {
        return Transform(transform: { template in
            let barWidth = width - 8 // Account for label and percentage
            let filledWidth = Int(Double(barWidth) * Double(value) / 100.0)
            let emptyWidth = barWidth - filledWidth

            let filled = String(repeating: "█", count: filledWidth)
            let empty = String(repeating: "░", count: emptyWidth)
            let percentage = String(format: "%3d%%", value)

            return template
                .replacingOccurrences(of: "LABEL", with: label)
                .replacingOccurrences(of: "FILLED", with: filled)
                .replacingOccurrences(of: "EMPTY", with: empty)
                .replacingOccurrences(of: "PERCENT", with: percentage)
        }) {
            Text("LABEL: [FILLEDEMPTY] PERCENT")
        }
    }

    /// Border style for frames (legacy compatibility)
    enum BorderStyle {
        case single
        case double
    }
}
