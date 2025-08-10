import Testing
import Foundation
@testable import RuneRenderer
@testable import RuneUnicode
@testable import RuneANSI

struct LogLaneANSIWIdeWrapTests {
    @Test("Wraps colored emoji/CJK by display columns and preserves right edge")
    func wrapsByDisplayColumns() {
        let lane = LogLane(showTimestamps: false, useColors: true)
        // 1 emoji (2 cols), 1 CJK char (2 cols), and color around them
        let content = "\u{001B}[31m😀中\u{001B}[0m-end"
        let line = ConsoleCapture.LogLine(content: content, timestamp: Date(), source: .stdout)
        let wrapped = lane.formatLogLine(line, terminalWidth: 6)
        // Expect multiple lines
        #expect(wrapped.count >= 2)
        // Each line must not exceed width in display columns (ignore ANSI)
        for w in wrapped {
            #expect(ANSISafeTruncation.displayWidthIgnoringANSI(w) <= 6)
        }
        // Combined visible text should contain suffix "-end"
        let visible = wrapped.joined()
        #expect(visible.contains("-end"))
    }
}

