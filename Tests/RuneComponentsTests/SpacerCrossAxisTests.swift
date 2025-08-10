import Testing
@testable import RuneComponents
@testable import RuneLayout
@testable import RuneUnicode

struct SpacerCrossAxisTests {
    @Test("Spacer remains minimal on cross-axis under alignItems: .stretch")
    func spacerMinimalCrossAxis() {
        let spacer = Spacer()
        let box = Box(
            border: .none,
            flexDirection: .row,
            alignItems: .stretch,
            width: .points(20), height: .points(5),
            children: spacer
        )
        let layout = box.calculateLayout(in: FlexLayout.Rect(x: 0, y: 0, width: 20, height: 5))
        #expect(layout.childRects.count == 1)
        let r = layout.childRects[0]
        // Spacer should have intrinsic minimal height (1) when not explicitly sized
        #expect(r.height == 1)
    }
}

