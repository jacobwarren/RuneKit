import Foundation

/// Actor-based frame buffer for region-based terminal rendering
///
/// This actor manages the complex task of rendering frames to a terminal
/// using the proven approach from Ink.js: erase previous lines, then write new content.
///
/// Key features:
/// - Ink.js-compatible line-by-line erasing and rewriting
/// - Cursor hide/show management during rendering
/// - Frame dimension tracking for proper cleanup
/// - Error-safe cursor restoration
/// - Thread-safe output serialization
public actor FrameBuffer {

    /// Current frame being displayed
    private var currentFrame: TerminalRenderer.Frame?

    /// Number of lines written in the last frame (for erasing)
    private var lastFrameLineCount: Int = 0

    /// Whether cursor is currently hidden
    private var cursorHidden: Bool = false

    /// Output handle for terminal writes
    private let output: FileHandle
    
    /// Initialize frame buffer with output handle
    /// - Parameter output: File handle for terminal output (defaults to stdout)
    public init(output: FileHandle = .standardOutput) {
        self.output = output
    }
    
    /// Deinitializer ensures cursor is restored on cleanup
    deinit {
        // Note: We can't use async in deinit, so we do synchronous cleanup
        if cursorHidden {
            let showSequence = "\u{001B}[?25h"
            if let data = showSequence.data(using: .utf8) {
                output.write(data)
            }
        }
    }
    
    /// Get the current frame being displayed
    /// - Returns: Current frame or nil if no frame is active
    public func getCurrentFrame() -> TerminalRenderer.Frame? {
        return currentFrame
    }
    
    /// Render a frame to the terminal using Ink.js approach
    /// - Parameter frame: Frame to render
    public func renderFrame(_ frame: TerminalRenderer.Frame) async {
        // Hide cursor before rendering
        await hideCursor()

        // Erase previous frame lines (if any) using Ink.js approach
        if lastFrameLineCount > 0 {
            await eraseLines(count: lastFrameLineCount)
        }

        // Write the new frame content
        await writeFrameContent(frame)

        // Update tracking (count lines including final newline like Ink.js)
        currentFrame = frame
        let output = frame.lines.joined(separator: "\n") + "\n"
        lastFrameLineCount = output.split(separator: "\n", omittingEmptySubsequences: false).count

        // Show cursor after rendering
        await showCursor()
    }
    
    /// Clear the frame buffer and show cursor (for cleanup)
    public func clear() async {
        if lastFrameLineCount > 0 {
            await eraseLines(count: lastFrameLineCount)
            lastFrameLineCount = 0
        }
        currentFrame = nil
        await showCursor()
    }
    
    // MARK: - Private Methods
    
    /// Hide the cursor
    private func hideCursor() async {
        let hideSequence = "\u{001B}[?25l"
        await writeToOutput(hideSequence)
        cursorHidden = true
    }
    
    /// Show the cursor
    private func showCursor() async {
        let showSequence = "\u{001B}[?25h"
        await writeToOutput(showSequence)
        cursorHidden = false
    }
    
    /// Erase lines using Ink.js approach
    /// - Parameter count: Number of lines to erase
    private func eraseLines(count: Int) async {
        guard count > 0 else { return }

        var clearSequence = ""

        // For each line: clear line + move cursor up (except for the last one)
        for i in 0..<count {
            clearSequence += "\u{001B}[2K"  // Clear entire line
            if i < count - 1 {
                clearSequence += "\u{001B}[A"  // Move cursor up
            }
        }

        // Move cursor to beginning of line
        if count > 0 {
            clearSequence += "\u{001B}[G"  // Move cursor to column 1
        }

        await writeToOutput(clearSequence)
    }
    
    /// Write frame content to terminal (Ink.js approach)
    /// - Parameter frame: Frame to write
    private func writeFrameContent(_ frame: TerminalRenderer.Frame) async {
        let content = frame.lines.joined(separator: "\n") + "\n"  // Add final newline like Ink.js
        await writeToOutput(content)
    }
    
    /// Write data to output handle
    /// - Parameter data: String data to write
    private func writeToOutput(_ data: String) async {
        if let utf8Data = data.data(using: .utf8) {
            output.write(utf8Data)
        }
    }
    

}
