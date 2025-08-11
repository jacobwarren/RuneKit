import Foundation
import Testing
@testable import RuneANSI
@testable import RuneComponents

struct TextStyleTypeTests {
    @Test("Overlay last-wins and conversion to attributes")
    func overlayAndAttributes() {
        let base = TextStyle(foreground: .red, effects: [.bold])
        let accent = TextStyle(foreground: .blue, background: .yellow, effects: [.italic, .underline])
        let merged = base.overlay(accent)
        let attrs = merged.attributes
        #expect(attrs.color == .blue)
        #expect(attrs.backgroundColor == .yellow)
        #expect(attrs.bold)
        #expect(attrs.italic)
        #expect(attrs.underline)
        #expect(!attrs.inverse)
        #expect(!attrs.strikethrough)
    }

    @Test("Text init with style renders correctly")
    func initWithStyleRenders() {
        let style = TextStyle(foreground: .green, effects: [.bold])
        let text = Text("Hi", style: style)
        let out = text.render(in: FlexLayout.Rect(x: 0, y: 0, width: 10, height: 1))[0]
        #expect(out.contains("\u{001B}["))
        #expect(out.contains("32"))
        #expect(out.contains("1"))
    }
}
