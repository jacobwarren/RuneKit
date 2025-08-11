import Testing
@testable import RuneComponents
@testable import RuneLayout

struct AlignmentWrapMatrixTests {
    private func makeChild(_ label: String, w: Float = 5, h: Float = 1) -> Box {
        Box(width: .points(w), height: .points(h), child: Text(label))
    }

    private func layout(_ box: Box, width: Int = 20, height: Int = 6) -> BoxLayoutResult {
        let container = FlexLayout.Rect(x: 0, y: 0, width: width, height: height)
        return box.calculateLayout(in: container)
    }

    @Test("Parametric matrix: alignItems × justifyContent × flexWrap × direction")
    func parametricMatrix() {
        let aligns: [AlignItems] = [.flexStart, .center, .flexEnd, .stretch, .baseline]
        let justifies: [JustifyContent] = [.flexStart, .center, .flexEnd, .spaceBetween, .spaceAround, .spaceEvenly]
        let wraps: [FlexWrap] = [.noWrap, .wrap]
        let directions: [YogaFlexDirection] = [.row, .column]

        for align in aligns {
            for justify in justifies {
                for wrap in wraps {
                    for dir in directions {
                        let b = Box(
                            flexDirection: dir,
                            justifyContent: justify,
                            alignItems: align,
                            rowGap: 1,
                            columnGap: 2,
                            flexWrap: wrap,
                            children: makeChild("A"), makeChild("B"), makeChild("C"), makeChild("D"),
                        )
                        let result = layout(b, width: 24, height: 8)

                        // Minimal invariants to avoid overfitting:
                        // - All child rects must be within contentRect bounds
                        for r in result.childRects {
                            #expect(r.x >= 0 && r.y >= 0)
                            #expect(r.x + r.width <= result.contentRect.width)
                            #expect(r.y + r.height <= result.contentRect.height)
                        }

                        // - With wrap enabled in row direction at constrained widths, we expect >1 row
                        if wrap != .noWrap, dir == .row {
                            // Heuristic: total desired width of 4 children + gaps exceeds container -> wraps
                            let shouldWrap = (4 * 5 + 3 * 2) > result.contentRect.width
                            if shouldWrap {
                                // Y positions for children should not all be identical
                                let ys = Set(result.childRects.map(\.y))
                                #expect(ys.count > 1)
                            }
                        }

                        // - With justifyContent space-between in row and no wrap, first child at x=0, last aligned to
                        // end
                        if wrap == .noWrap, dir == .row, justify == .spaceBetween {
                            if result.childRects.count >= 2 {
                                #expect(result.childRects.first?.x == 0)
                                let last = result.childRects.last!
                                #expect(last.x + last.width == result.contentRect.width)
                            }
                        }
                    }
                }
            }
        }
    }
}
