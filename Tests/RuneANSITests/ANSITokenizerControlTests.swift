import Testing
@testable import RuneANSI

/// Tests for cursor movement, erase sequences, and OSC handling
struct ANSITokenizerControlTests {
    // MARK: - Cursor Movement (CSI)

    @Test("Cursor up by 3 (CSI A)")
    func cursorUpByThree() {
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[3A"
        let tokens = tokenizer.tokenize(input)
        #expect(tokens == [.cursor(3, "A")])
        // Round-trip
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == input)
    }

    @Test("Cursor right default 1 (CSI C with no param)")
    func cursorRightDefault() {
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[C" // default 1
        let tokens = tokenizer.tokenize(input)
        #expect(tokens == [.cursor(1, "C")])
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == input)
    }

    // MARK: - Erase sequences (CSI J/K)

    @Test("Erase display all (CSI 2J)")
    func eraseDisplayAll() {
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[2J"
        let tokens = tokenizer.tokenize(input)
        #expect(tokens == [.erase(2, "J")])
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == input)
    }

    @Test("Erase line to end (CSI K with default)")
    func eraseLineToEnd() {
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}[K" // default 0
        let tokens = tokenizer.tokenize(input)
        #expect(tokens == [.erase(0, "K")])
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == input)
    }

    // MARK: - OSC (Operating System Command)

    @Test("OSC window title with BEL terminator round-trips identically")
    func oscWithBELRoundTrip() {
        let tokenizer = ANSITokenizer()
        let input = "\u{001B}]0;My Window Title\u{0007}"
        let tokens = tokenizer.tokenize(input)
        #expect(tokens == [.oscExt("0", "My Window Title", .bel)])
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == input, "BEL-terminated OSC should be byte-identical on round-trip")
    }

    @Test("OSC window title with ST terminator parses and canonicalizes to BEL on encode")
    func oscWithSTCanonicalizes() {
        let tokenizer = ANSITokenizer()
        // ESC ] 2;Title ESC \
        let inputST = "\u{001B}]2;Title\u{001B}\\"
        let tokens = tokenizer.tokenize(inputST)
        // Parsed tokens are semantic: command '2' and data 'Title' with preserved terminator
        #expect(tokens == [.oscExt("2", "Title", .st)])
        // Encoding preserves ST terminator now
        let encoded = tokenizer.encode(tokens)
        #expect(encoded == inputST)
    }

    @Test("Unterminated OSC is treated as plain text (no .osc token)")
    func unterminatedOSCTreatedAsText() {
        let tokenizer = ANSITokenizer()
        let input = "Prelude \u{001B}]0;Title" // no BEL/ST terminator
        let tokens = tokenizer.tokenize(input)
        // Should not contain any .osc token
        let hasOSC = tokens.contains { token in
            if case .osc = token { return true } else { return false }
        }
        #expect(!hasOSC, "Unterminated OSC should not produce .osc token")
        // Reconstruct concatenated text content equals original input
        let reconstructed = tokens.map { token -> String in
            switch token {
            case let .text(s): return s
            case let .sgr(params): return ANSITokenizer().encode([.sgr(params)])
            case let .cursor(n, dir): return ANSITokenizer().encode([.cursor(n, dir)])
            case let .erase(mode, type): return ANSITokenizer().encode([.erase(mode, type)])
            case let .osc(cmd, data): return ANSITokenizer().encode([.osc(cmd, data)])
            case let .oscExt(cmd, data, term): return ANSITokenizer().encode([.oscExt(cmd, data, term)])
            case let .control(seq): return seq
            }
        }.joined()
        #expect(reconstructed == input)
    }
}

