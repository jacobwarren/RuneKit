import Foundation
import Testing
import RuneKit

@Suite("RUNE-38: useInput matrix")
struct UseInputHookMatrixTests {
    actor Sink { var events: [KeyEvent] = []; func add(_ e: KeyEvent) { events.append(e) } }

    struct V: View, ViewIdentifiable {
        var id: String
        var sink: Sink
        var viewIdentity: String? { id }
        var body: some View {
            HooksRuntime.useInput({ event in await sink.add(event) }, isActive: true)
            return Text("")
        }
    }

    @Test("F1-F4 (SS3), F6-F12 (CSI), Home/End/Page with modifiers, Shift+Ctrl")
    func matrix() async {
        let sink = Sink()
        let h = await render(V(id: "mx", sink: sink), options: RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60))

        // SS3 F1..F4
        await h.testingProcessInput(bytes: [0x1B, 0x4F, 0x50]) // F1
        await h.testingProcessInput(bytes: [0x1B, 0x4F, 0x51]) // F2
        await h.testingProcessInput(bytes: [0x1B, 0x4F, 0x52]) // F3
        await h.testingProcessInput(bytes: [0x1B, 0x4F, 0x53]) // F4

        // CSI F6..F12 via ~ family (F5 is tested elsewhere)
        for code in [17,18,19,20,21,23,24] { // maps to F6..F12 (per InputManager.mapTildeFamily)
            await h.testingProcessInput(bytes: [0x1B, 0x5B] + Array("\(code)~".utf8))
        }

        // Home/End with modifiers: H/F finals with ;6 (Shift+Ctrl)
        await h.testingProcessInput(bytes: [0x1B, 0x5B] + Array("1;6H".utf8))
        await h.testingProcessInput(bytes: [0x1B, 0x5B] + Array("1;6F".utf8))

        // PageUp/PageDown with modifiers ;6 via ~ family (5~, 6~)
        await h.testingProcessInput(bytes: [0x1B, 0x5B] + Array("5;6~".utf8))
        await h.testingProcessInput(bytes: [0x1B, 0x5B] + Array("6;6~".utf8))

        try? await Task.sleep(for: .milliseconds(50))
        let evs = await sink.events

        // Assertions for presence
        #expect(evs.contains(.key(kind: .function(1), modifiers: [])))
        #expect(evs.contains(.key(kind: .function(2), modifiers: [])))
        #expect(evs.contains(.key(kind: .function(3), modifiers: [])))
        #expect(evs.contains(.key(kind: .function(4), modifiers: [])))
        #expect(evs.contains(.key(kind: .function(12), modifiers: [])))
        #expect(evs.contains(.key(kind: .home, modifiers: [.shift, .ctrl])))
        #expect(evs.contains(.key(kind: .end, modifiers: [.shift, .ctrl])))
        #expect(evs.contains(.key(kind: .pageUp, modifiers: [.shift, .ctrl])))
        #expect(evs.contains(.key(kind: .pageDown, modifiers: [.shift, .ctrl])))

        await h.unmount()
        await h.waitUntilExit()
    }
}

