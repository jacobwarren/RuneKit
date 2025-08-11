import Foundation
import Testing
@testable import RuneKit

struct AdvancedInputDecodingTests {
    actor Sink { var events: [KeyEvent] = []; func add(_ e: KeyEvent) { events.append(e) } }

    private func manager(raw: Bool = false, paste: Bool = true) -> InputManager {
        let inPipe = Pipe()
        let outPipe = Pipe()
        return InputManager(input: inPipe.fileHandleForReading,
                            controlOut: outPipe.fileHandleForWriting,
                            enableRawMode: raw,
                            enableBracketedPaste: paste,
                            exitOnCtrlC: false)
    }

    @Test("Decodes SS3 arrows and F1-F4")
    func ss3ArrowsAndFKeys() async {
        let m = manager()
        let sink = Sink()
        await m.setEventHandler { await sink.add($0) }

        // ESC O A (Up), ESC O P/Q/R/S (F1..F4)
        await m.process(bytes: [0x1B, 0x4F, 0x41])
        await m.process(bytes: [0x1B, 0x4F, 0x50])
        await m.process(bytes: [0x1B, 0x4F, 0x51])
        await m.process(bytes: [0x1B, 0x4F, 0x52])
        await m.process(bytes: [0x1B, 0x4F, 0x53])

        let events = await sink.events
        #expect(events.contains(.arrowUp))
        #expect(events.contains(.key(kind: .function(1), modifiers: [])))
        #expect(events.contains(.key(kind: .function(2), modifiers: [])))
        #expect(events.contains(.key(kind: .function(3), modifiers: [])))
        #expect(events.contains(.key(kind: .function(4), modifiers: [])))
    }

    @Test("Decodes CSI function keys F5-F12 and PageUp/Down")
    func csiFunctionKeysAndPaging() async {
        let m = manager()
        let sink = Sink()
        await m.setEventHandler { await sink.add($0) }

        func send(_ s: String) async { await m.process(bytes: Array(s.utf8)) }
        // CSI 15~.. CSI 24~ => F5..F12, CSI 5~ => PageUp, CSI 6~ => PageDown
        await send("\u{001B}[15~")
        await send("\u{001B}[24~")
        await send("\u{001B}[5~")
        await send("\u{001B}[6~")

        let evs = await sink.events
        #expect(evs.contains(.key(kind: .function(5), modifiers: [])))
        #expect(evs.contains(.key(kind: .function(12), modifiers: [])))
        #expect(evs.contains(.key(kind: .pageUp, modifiers: [])))
        #expect(evs.contains(.key(kind: .pageDown, modifiers: [])))
    }

    @Test("Decodes modifiers for arrow keys (Ctrl)")
    func csiArrowWithModifiers() async {
        let m = manager()
        let sink = Sink()
        await m.setEventHandler { await sink.add($0) }
        // CSI 1;5A => Ctrl+Up (xterm: 1;5 indicates Ctrl)
        await m.process(bytes: [0x1B, 0x5B] + Array("1;5A".utf8))
        let evs = await sink.events
        #expect(evs.contains(.key(kind: .up, modifiers: [.ctrl])))
    }

    @Test("Chunked ESC sequence is decoded when complete")
    func chunkedEscDecoding() async {
        let m = manager()
        let sink = Sink()
        await m.setEventHandler { await sink.add($0) }

        // Send ESC, then '[', then 'A' separately
        await m.process(bytes: [0x1B])
        await m.process(bytes: [0x5B])
        await m.process(bytes: [0x41])
        let evs = await sink.events
        #expect(evs.contains(.arrowUp))
    }

    @Test("Bracketed paste with UTF-8 payload (emoji)")
    func bracketedPasteUTF8() async {
        let m = manager()
        let sink = Sink()
        await m.setEventHandler { await sink.add($0) }

        let start = "\u{001B}[200~".utf8
        let end   = "\u{001B}[201~".utf8
        let payload = "Hi 👋🏽 世界".utf8
        await m.process(bytes: Array(start))
        await m.process(bytes: Array(payload))
        await m.process(bytes: Array(end))

        let evs = await sink.events
        #expect(evs.contains(.paste("Hi 👋🏽 世界")))
    }
}

