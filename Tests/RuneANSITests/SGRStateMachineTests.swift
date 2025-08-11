import Testing
@testable import RuneANSI

struct SGRStateMachineTests {
    @Test("Reset clears all attributes")
    func reset() {
        var state = SGRStateMachine(initial: TextAttributes(
            color: .red,
            backgroundColor: .blue,
            bold: true,
            italic: true,
            underline: true,
            inverse: true,
            strikethrough: true,
            dim: true,
        ))
        let attrs = state.apply([0])
        #expect(attrs.isDefault)
    }

    @Test("Basic style enable/disable and colors")
    func stylesAndColors() {
        var state = SGRStateMachine()
        _ = state.apply([1, 3, 4, 9]) // bold italic underline strike
        _ = state.apply([31, 44]) // red on blue
        var attrs = state.attributes
        #expect(attrs.bold && attrs.italic && attrs.underline && attrs.strikethrough)
        #expect(attrs.color == .red && attrs.backgroundColor == .blue)

        _ = state.apply([22, 23, 24, 29]) // disable bold/italic/underline/strike
        attrs = state.attributes
        #expect(!attrs.bold && !attrs.italic && !attrs.underline && !attrs.strikethrough)

        _ = state.apply([39, 49]) // reset colors
        attrs = state.attributes
        #expect(attrs.color == nil && attrs.backgroundColor == nil)
    }

    @Test("256 and RGB colors")
    func extendedColors() {
        var state = SGRStateMachine()
        _ = state.apply([38, 5, 196])
        #expect(state.attributes.color == .color256(196))
        _ = state.apply([48, 2, 10, 20, 30])
        #expect(state.attributes.backgroundColor == .rgb(10, 20, 30))
    }
}
