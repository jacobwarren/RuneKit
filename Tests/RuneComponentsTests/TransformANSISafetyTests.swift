import Testing
import Foundation
@testable import RuneComponents
@testable import RuneANSI

struct TransformANSISafetyTests {
    @Test("Plain text uppercase is applied directly")
    func plainTextUppercase() {
        let input = "hello world"
        let output = TransformANSISafety.applySafely(to: input) { $0.uppercased() }
        #expect(output == "HELLO WORLD")
    }

    @Test("ANSI-styled text preserves SGR and uppercases text")
    func ansiStyledUppercase() {
        // \u{001B}[1;31mError:\u{001B}[0m \u{001B}[33mwarning\u{001B}[0m
        let input = "\u{001B}[1;31mError:\u{001B}[0m \u{001B}[33mwarning\u{001B}[0m"
        let output = TransformANSISafety.applySafely(to: input) { $0.uppercased() }
        let tokens = ANSITokenizer().tokenize(output)
        let expected: [ANSIToken] = [
            .sgr([1,31]),
            .text("ERROR:"),
            .sgr([0]),
            .text(" "),
            .sgr([33]),
            .text("WARNING"),
            .sgr([0])
        ]
        #expect(tokens == expected)
    }

    @Test("Time-based transform on plain text uses provided time")
    func timeBasedPlain() {
        let input = "spin"
        let time: TimeInterval = 123.0
        let output = TransformANSISafety.applySafely(to: input, time: time) { s, t in
            return "T\(Int(t)):" + s
        }
        #expect(output == "T123:spin")
    }

    @Test("Time-based transform on single ANSI span applies to text and preserves SGR")
    func timeBasedANSI() {
        // Single styled span to keep one text token between SGRs
        let input = "\u{001B}[32mgo\u{001B}[0m"
        let time: TimeInterval = 42.0
        let output = TransformANSISafety.applySafely(to: input, time: time) { s, t in
            return "T\(Int(t))_" + s.uppercased()
        }
        let tokens = ANSITokenizer().tokenize(output)
        let expected: [ANSIToken] = [
            .sgr([32]),
            .text("T42_GO"),
            .sgr([0])
        ]
        #expect(tokens == expected)
    }
}

