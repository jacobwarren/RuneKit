import Foundation
import Testing
@testable import RuneANSI

struct TerminalProfileTests {
    @Test("TrueColor preserves RGB and 256")
    func trueColorPreserves() {
        var gen = SGRParameterGenerator()
        gen.profile = .trueColor
        let rgb = gen.attributesToSGRParameters(TextAttributes(color: .rgb(1, 2, 3)))
        let p256 = gen.attributesToSGRParameters(TextAttributes(color: .color256(196)))
        #expect(rgb.starts(with: [38, 2]))
        #expect(p256.starts(with: [38, 5]))
    }

    @Test("xterm256 maps RGB to 256")
    func xterm256MapsRGB() {
        var gen = SGRParameterGenerator()
        gen.profile = .xterm256
        let rgb = gen.attributesToSGRParameters(TextAttributes(color: .rgb(255, 128, 0)))
        #expect(rgb.starts(with: [38, 5]))
    }

    @Test("basic16 maps RGB and 256 to 16-colors")
    func basic16Maps() {
        var gen = SGRParameterGenerator()
        gen.profile = .basic16
        let rgbParams = gen.attributesToSGRParameters(TextAttributes(color: .rgb(255, 0, 0)))
        #expect(rgbParams == [31]) // red
        let idxParams = gen.attributesToSGRParameters(TextAttributes(color: .color256(21)))
        #expect(!idxParams.isEmpty)
        #expect(idxParams[0] >= 30 && idxParams[0] <= 37)
    }

    @Test("noColor strips all color but keeps effects")
    func noColorStrips() {
        var gen = SGRParameterGenerator()
        gen.profile = .noColor
        let params = gen.attributesToSGRParameters(TextAttributes(color: .red, bold: true))
        #expect(params == [1]) // only bold remains
    }
}
