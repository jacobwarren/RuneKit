import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneLayout
@testable import RuneUnicode

struct WrapEmojiClippingE2ETests {
    @Test("Wrap and clip emoji with borders without exceeding width")
    func wrapAndClipEmojiWithBorders() {
        // Container width forces wrapping/truncation
        let width = 8 // small width to force clipping of a double-width emoji
        let rect = FlexLayout.Rect(x: 0, y: 0, width: width, height: 4)

        // Styled emoji text
        let text = Text("🔥🔥🔥🔥", color: .yellow, bold: true)
        let box = Box(border: .single, width: .points(Float(width)), child: text)

        let lines = box.render(in: rect)
        // Assert that each line is ANSI-safe and does not exceed width columns
        for (i, line) in lines.enumerated() {
            let cols = ANSISafeTruncation.displayWidthIgnoringANSI(line)
            #expect(cols <= width, "Line \(i) exceeds width with display columns: \(cols) > \(width)")
        }
    }
}
