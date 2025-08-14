import Foundation
import Testing
import RuneKit

@Suite("RUNE-41: useFocusManager hook", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
struct UseFocusManagerHookTests {
    actor Sink {
        private(set) var events: [KeyEvent] = []
        func add(_ e: KeyEvent) { events.append(e) }
        func all() -> [KeyEvent] { events }
        func clear() { events.removeAll() }
    }

    struct FocusableView: View, ViewIdentifiable {
        var id: String
        var sink: Sink
        var viewIdentity: String? { id }
        var body: some View {
            let isFocused = HooksRuntime.useFocus()
            HooksRuntime.useInput({ event in await sink.add(event) }, isActive: true)
            return Text(isFocused ? "[\(id)]" : id)
        }
    }

    @Test("Programmatic next/previous cycles focus and gates input")
    func programmaticCycling() async {
        let sinkA = Sink(); let sinkB = Sink(); let sinkC = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            FocusableView(id: "A", sink: sinkA),
            FocusableView(id: "B", sink: sinkB),
            FocusableView(id: "C", sink: sinkC)
        ), options: options)

        // Initially A focused. Send Up; only A receives.
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkA.all().contains(.arrowUp))
        #expect(await sinkB.all().isEmpty)
        #expect(await sinkC.all().isEmpty)
        await sinkA.clear(); await sinkB.clear(); await sinkC.clear()

        // Programmatically move to next (B)
        await handle.focusNext()
        try? await Task.sleep(for: .milliseconds(20))
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x42]) // Down
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkB.all().contains(.arrowDown))
        #expect(await sinkA.all().isEmpty)
        #expect(await sinkC.all().isEmpty)

        // Move previous back to A
        await handle.focusPrevious()
        try? await Task.sleep(for: .milliseconds(20))
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x43]) // Right
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkA.all().contains(.arrowRight))

        await handle.unmount()
        await handle.waitUntilExit()
    }

    @Test("Direct focus by id/path works")
    func directFocusByIdAndPath() async {
        let sinkA = Sink(); let sinkB = Sink(); let sinkC = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            FocusableView(id: "A", sink: sinkA),
            FocusableView(id: "B", sink: sinkB),
            FocusableView(id: "C", sink: sinkC)
        ), options: options)

        // Sanity: initial focused path should be A
        if let fp = await handle.currentFocusedPath() {
            #expect(fp.hasSuffix("/A"))
        } else {
            #expect(Bool(false), "Expected a focused path initially")
        }

        // Focus by id("C")
        let ok1 = await handle.focus(id: "C")
        #expect(ok1 == true)
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x44]) // Left
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkC.all().contains(.arrowLeft))
        await sinkA.clear(); await sinkB.clear(); await sinkC.clear()

        // Focus by an existing path substring that should match C's identity path
        if let path = await handle.currentFocusedPath() {
            let ok2 = await handle.focus(path: path)
            #expect(ok2 == true)
            await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41]) // Up
            try? await Task.sleep(for: .milliseconds(30))
            #expect(await sinkC.all().contains(.arrowUp))
        } else {
            #expect(Bool(false), "Expected a focused path to be available")
        }

        await handle.unmount()
        await handle.waitUntilExit()
    }

    @Test("No-focusables broadcast remains unaffected by manager")
    func noFocusablesBroadcastUnaffected() async {
        let s1 = Sink(); let s2 = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            // These do not call useFocus(); no focusables will be registered
            Text("X"),
            Text("Y")
        ), options: options)

        let mgr = HooksRuntime.useFocusManager()
        // Manager operations should be no-ops; ensure broadcast still happens
        await mgr.next()
        let ok = await mgr.focus(id: "anything")
        #expect(ok == false)

        // Register two global listeners that do not require focus
        struct Global: View, ViewIdentifiable { var id: String; var viewIdentity: String? { id }; var body: some View { HooksRuntime.useInput({ _ in }, isActive: true, requiresFocus: false); return Text(id) } }
        await handle.rerender(Box(children: Global(id: "g1"), Global(id: "g2")))
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41])
        // Not asserting delivery here; covered by FocusRegistryTests no-focusables test. We just check no crash.

        await handle.unmount()
        await handle.waitUntilExit()
    }
}

