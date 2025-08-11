import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents

struct TextErgonomicsTests {
    @Test("Hex color helpers parse and apply when valid, ignore when invalid")
    func hexHelpers() {
        let t1 = Text("Hi").color(hex: "#FF0000")
        #expect(t1.attributes.color == .rgb(255, 0, 0))
        let t2 = Text("Hi").color(hex: "GGGGGG")
        #expect(t2.attributes.color == nil)
        let t3 = Text("Hi").bg(hex: "00FF00")
        #expect(t3.attributes.backgroundColor == .rgb(0, 255, 0))
    }

    @Test("Conditional helpers apply only when condition is true")
    func conditionalHelpers() {
        let t = Text("Hi").color(.red, when: true).bg(.blue, when: false)
        #expect(t.attributes.color == .red)
        #expect(t.attributes.backgroundColor == nil)
    }
}
