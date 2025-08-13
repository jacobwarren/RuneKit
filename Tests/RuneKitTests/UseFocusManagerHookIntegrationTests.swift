import Foundation
import Testing
import RuneKit

@Suite("RUNE-41: useFocusManager hook integration")
struct UseFocusManagerHookIntegrationTests {
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
            let mgr = HooksRuntime.useFocusManager()
            HooksRuntime.useInput({ event in
                // On Tab, move focus forward programmatically using the hook
                if event == .tabKey { await mgr.next() }
                await sink.add(event)
            }, isActive: true)
            return Text(isFocused ? "[\(id)]" : id)
        }
    }

    @Test("Tab advances focus via useFocusManager hook")
    func tabAdvancesFocus() async {
        let sA = Sink(); let sB = Sink(); let sC = Sink()
        let handle = await render(Box(children:
            FocusableView(id: "A", sink: sA),
            FocusableView(id: "B", sink: sB),
            FocusableView(id: "C", sink: sC)
        ))

        // Initially A focused; send Tab to trigger mgr.next() from inside handler
        await handle.testingProcessInput(bytes: [0x09]) // Tab
        try? await Task.sleep(for: .milliseconds(30))

        // Now B should receive the next event
        await handle.testingProcessInput(bytes: [0x1B, 0x5B, 0x42]) // Down
        try? await Task.sleep(for: .milliseconds(30))
        #expect(await sB.all().contains(.arrowDown))

        await handle.unmount()
        await handle.waitUntilExit()
    }
}

