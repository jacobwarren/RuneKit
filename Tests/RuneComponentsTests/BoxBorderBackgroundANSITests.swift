import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents
@testable import RuneKit
@testable import RuneUnicode

struct BoxBorderBackgroundANSITests {

    init() {
        // Clean up shared state before each test to prevent interference between tests
        StateRegistry.shared.clearAll()
        StateObjectStore.shared.clearAll()
    }
    @Test("Borders get colored and background fills content area without bleed")
    func borderAndBackgroundColoring() {
        let child = Text("A🙂B", color: .yellow)
        let box = Box(
            border: .single,
            borderColor: .brightBlue,
            backgroundColor: .brightBlack,
            width: .points(8),
            height: .points(3),
            child: child,
        )
        let lines = box.render(in: FlexLayout.Rect(x: 0, y: 0, width: 8, height: 3))
        #expect(lines.count == 3)
        // Top and bottom lines should include blue SGR and reset
        #expect(lines[0].contains("\u{001B}[94m"))
        #expect(lines[0].contains("\u{001B}[0m"))
        #expect(lines[2].contains("\u{001B}[94m"))
        #expect(lines[2].contains("\u{001B}[0m"))
        // Middle line should have left/right borders colored and content area wrapped in background SGR
        #expect(lines[1].contains("\u{001B}[94m│\u{001B}[0m\u{001B}[100m"))
        // Ensure the right edge is: end background, then blue right border, then reset, and nothing after
        #expect(lines[1].hasSuffix("\u{001B}[0m\u{001B}[94m│\u{001B}[0m"))
        // Stripped of ANSI, line should end with the border character and have correct width
        let stripped = lines[1].replacingOccurrences(of: "\u{001B}[^m]*m", with: "", options: .regularExpression)
        #expect(stripped.hasPrefix("│"))
        #expect(stripped.hasSuffix("│"))
        #expect(Width.displayWidth(of: stripped) == 8)
    }

    @Test("Multi-children ANSI/emoji placement uses display columns and no overlap")
    func multiChildrenPlacement() {
        let c1 = Text("😀", color: .red)
        let c2 = Text("X", color: .green)
        let c3 = Text("Y", color: .blue)
        let box = Box(
            border: .single,
            borderColor: .yellow,
            flexDirection: .row,
            width: .points(10), height: .points(3),
            children: c1, c2, c3,
        )
        let lines = box.render(in: FlexLayout.Rect(x: 0, y: 0, width: 10, height: 3))
        // Slice interior columns ANSI-safely (drop 1 col from left and right borders)
        let totalCols = ANSISafeTruncation.displayWidthIgnoringANSI(lines[1])
        let st = ANSISpanConverter().tokensToStyledText(ANSITokenizer().tokenize(lines[1]))
        let interior = st.sliceByDisplayColumns(from: 1, to: max(1, totalCols - 1))
        let interiorRaw = ANSITokenizer().encode(ANSISpanConverter().styledTextToTokens(interior))
        let visibleWidth = ANSISafeTruncation.displayWidthIgnoringANSI(interiorRaw)
        #expect(visibleWidth == 8)
        #expect(interiorRaw.contains("😀"))
        #expect(interiorRaw.contains("X"))
        #expect(interiorRaw.contains("Y"))
    }
}
