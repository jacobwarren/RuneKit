import RuneANSI
import RuneUnicode
import Foundation

/// Actor-based terminal renderer for thread-safe output
/// 
/// This renderer handles the complex task of updating terminal content
/// efficiently while managing cursor position, screen clearing, and
/// ANSI escape sequence generation.
public actor TerminalRenderer {
    
    /// Represents a frame of terminal content
    public struct Frame {
        public let lines: [String]
        public let width: Int
        public let height: Int
        
        public init(lines: [String], width: Int, height: Int) {
            self.lines = lines
            self.width = width
            self.height = height
        }
    }
    
    private var currentFrame: Frame?
    private let output: FileHandle
    
    public init(output: FileHandle = .standardOutput) {
        self.output = output
    }
    
    /// Render a new frame to the terminal
    /// - Parameter frame: The frame content to display
    public func render(_ frame: Frame) async {
        // TODO: Implement efficient frame rendering with diff
        // For now, just clear and write all lines
        
        let content = frame.lines.joined(separator: "\n")
        if let data = content.data(using: .utf8) {
            output.write(data)
        }
    }
    
    /// Clear the terminal screen
    public func clear() async {
        // ANSI escape sequence to clear screen and move cursor to top-left
        let clearSequence = "\u{001B}[2J\u{001B}[H"
        if let data = clearSequence.data(using: .utf8) {
            output.write(data)
        }
    }
    
    /// Move cursor to specific position
    /// - Parameters:
    ///   - row: Row position (1-based)
    ///   - column: Column position (1-based)
    public func moveCursor(to row: Int, column: Int) async {
        let moveSequence = "\u{001B}[\(row);\(column)H"
        if let data = moveSequence.data(using: .utf8) {
            output.write(data)
        }
    }
    
    /// Hide the cursor
    public func hideCursor() async {
        let hideSequence = "\u{001B}[?25l"
        if let data = hideSequence.data(using: .utf8) {
            output.write(data)
        }
    }
    
    /// Show the cursor
    public func showCursor() async {
        let showSequence = "\u{001B}[?25h"
        if let data = showSequence.data(using: .utf8) {
            output.write(data)
        }
    }
}
