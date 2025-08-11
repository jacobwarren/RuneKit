import Foundation
import Testing
@testable import RuneANSI
@testable import RuneRenderer
@testable import RuneUnicode

#if os(Linux)
struct LinuxANSISnapshotTests {
    @Test("Linux snapshot: SGR inside content keeps right border visible")
    func linuxSnapshotBorderVisibility() {
        let left = "│"
        let right = "│"
        let boldStart = "\u{001B}[1m"
        let reset = "\u{001B}[0m"
        // Construct a line with ANSI SGR that should visually be 8 columns: │ Bold │
        let line = left + " " + boldStart + "Bold" + reset + " " + right
        let width = 8

        // Build grid from the line
        let grid = TerminalGrid(lines: [line], width: width)
        if let row = grid.getRow(0) {
            #expect(row.count == width)
            #expect(row[width - 1].content == right)
        } else {
            #expect(false, "row 0 should exist")
        }
    }

    @Test("Linux snapshot: StyledText RGB encode exact sequence")
    func linuxSnapshotStyledTextRGBEncode() {
        let converter = ANSISpanConverter()
        let tokenizer = ANSITokenizer()
        let spans = [TextSpan(text: "RGB Orange", attributes: TextAttributes(color: .rgb(255, 128, 0)))]
        let tokens = converter.styledTextToTokens(StyledText(spans: spans))
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == "\u{001B}[38;2;255;128;0mRGB Orange\u{001B}[0m")
    }

    @Test("Linux snapshot: Family emoji width is 2")
    func linuxSnapshotFamilyEmojiWidth() {
        let family = "👨‍👩‍👧‍👦"
        #expect(Width.displayWidth(of: family) == 2)
    }
}
#endif
