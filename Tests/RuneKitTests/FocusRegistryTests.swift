import Foundation
import Testing
import RuneKit

@Suite("RUNE-41: Focus registry + useFocus/useFocusManager", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
struct FocusRegistryTests {
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
            // Mark this component as focusable and render an indicator when focused
            let isFocused = HooksRuntime.useFocus()
            HooksRuntime.useInput({ event in
                await sink.add(event)
            }, isActive: true)
            return Text(isFocused ? "[\(id)]" : id)
        }
    }

    @Test("Tab cycles focus among focusable elements and gates input to focused one")
    func tabCyclesFocusAndGatesInput() async {
        let sinkA = Sink(); let sinkB = Sink(); let sinkC = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            FocusableView(id: "A", sink: sinkA),
            FocusableView(id: "B", sink: sinkB),
            FocusableView(id: "C", sink: sinkC)
        ), options: options)

        // After initial mount, focus should default to first focusable (A).
        // Send an arrow key; only A should receive initially.
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41]) // Up
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkA.all().contains(.arrowUp))
        #expect(await sinkB.all().isEmpty)
        #expect(await sinkC.all().isEmpty)

        // Press Tab (0x09) -> focus moves to B
        await handle.testingProcessInput(bytes: [0x09])
        // Send Down; only B should receive now
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x42])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkB.all().contains(.arrowDown))
        #expect(await sinkA.all().count == 1) // still just the first event
        #expect(await sinkC.all().isEmpty)

        // Shift+Tab (often ESC [ Z) -> focus moves back to A
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x5A])
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x43]) // Right
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sinkA.all().contains(.arrowRight))
        #expect(await sinkC.all().isEmpty)

        await handle.unmount()
        await handle.waitUntilExit()
    }

    struct GlobalListenerView: View, ViewIdentifiable {
        var id: String
        var sink: Sink
        var viewIdentity: String? { id }
        var body: some View {
            // Do NOT mark focusable; register global input listener (opt-out of focus gating)
            HooksRuntime.useInput({ event in await sink.add(event) }, isActive: true, requiresFocus: false)
            return Text(id)
        }
    }

    @Test("Global input handlers receive events regardless of focus; others are gated")
    func globalOptOutReceivesRegardlessOfFocus() async {
        let sf = Sink(); let sg = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            FocusableView(id: "F", sink: sf),
            GlobalListenerView(id: "G", sink: sg)
        ), options: options)

        // Initially focus on F; send Up. Both F (focused) and G (global) should receive.
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sf.all().contains(.arrowUp))
        #expect(await sg.all().contains(.arrowUp))

        // Shift+Tab to cycle (with only one focusable, it should stay on F). Send Right.
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x5A])
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x43])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sf.all().contains(.arrowRight))
        #expect(await sg.all().contains(.arrowRight))

        await handle.unmount()
        await handle.waitUntilExit()
    }

    struct PlainInputView: View, ViewIdentifiable {
        var id: String
        var sink: Sink
        var viewIdentity: String? { id }
        var body: some View {
            // No focusable elements registered anywhere in the tree
            HooksRuntime.useInput({ event in await sink.add(event) }, isActive: true)
            return Text(id)
        }
    }

    @Test("When no focusables are registered, useInput remains broadcast to all active handlers (back-compat)")
    func noFocusablesBackCompatBroadcast() async {
        let s1 = Sink(); let s2 = Sink()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(Box(children:
            PlainInputView(id: "P1", sink: s1),
            PlainInputView(id: "P2", sink: s2)
        ), options: options)

        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x41])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await s1.all().contains(.arrowUp))
        #expect(await s2.all().contains(.arrowUp))

        await handle.unmount()
        await handle.waitUntilExit()
    }
}

