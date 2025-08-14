import Foundation
import Testing
import TestSupport
@testable import RuneKit
@testable import RuneComponents

@Suite("Hooks deps equality edge cases", .enabled(if: !TestEnv.isCI))
struct HooksDepsEdgeCasesTests {
    struct V: View, ViewIdentifiable { var id: String; var viewIdentity: String? { id }; var body: some View { Text("v") } }

    @Test("Double.nan encodes to a stable deps token across commits")
    func nanIsStableAcrossCommits() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "nan"), options: options)

        let runs = HooksRuntime.Ref(0)
        let cleans = HooksRuntime.Ref(0)

        // 1) Initial: deps=[nan] -> runs once
        await handle.rerender {
            HooksRuntime.useEffect("nan", deps: [Double.nan]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "nan")
        }
        // 2) Same deps [nan] again -> should NOT rerun
        await handle.rerender {
            HooksRuntime.useEffect("nan", deps: [Double.nan]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "nan")
        }
        // 3) Change to [1.0] -> should rerun and cleanup previous
        await handle.rerender {
            HooksRuntime.useEffect("nan", deps: [1.0]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "nan")
        }
        // 4) Back to [nan] -> should rerun and cleanup previous
        await handle.rerender {
            HooksRuntime.useEffect("nan", deps: [Double.nan]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "nan")
        }

        await handle.unmount(); await handle.waitUntilExit()

        // Expect exactly 3 runs: initial, change to 1.0, change back to nan
        #expect(runs.current == 3, "Expected 3 runs; got \(runs.current)")
        // At least two cleanups due to two deps changes (plus possibly unmount cleanup)
        #expect(cleans.current >= 2, "Expected at least 2 cleanups; got \(cleans.current)")
    }

    @Test("Signed zeroes: 0.0 and -0.0 are distinct and trigger reruns")
    func signedZeroesTriggerRerun() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "zeros"), options: options)

        let runs = HooksRuntime.Ref(0)
        let cleans = HooksRuntime.Ref(0)

        await handle.rerender {
            HooksRuntime.useEffect("z", deps: [0.0]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "zeros")
        }
        await handle.rerender {
            HooksRuntime.useEffect("z", deps: [-0.0]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "zeros")
        }
        await handle.unmount(); await handle.waitUntilExit()
        #expect(runs.current == 2, "Expected rerun when changing 0.0 to -0.0; got \(runs.current)")
        #expect(cleans.current >= 1)
    }

    struct Weird: Hashable, CustomStringConvertible {
        let id: Int
        nonisolated(unsafe) static var mode: Int = 0
        var description: String { "Weird(\(id))-mode-\(Weird.mode)" }
        // Equality/Hash depend only on id
    }

    @Test("Custom Hashable with changing description triggers deps change")
    func customHashableChangingDescriptionTriggersRerun() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "weird"), options: options)

        let runs = HooksRuntime.Ref(0)
        let cleans = HooksRuntime.Ref(0)
        let value = Weird(id: 42)

        // Mode 0
        Weird.mode = 0
        await handle.rerender {
            HooksRuntime.useEffect("weird", deps: [AnyHashable(value)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "weird")
        }
        // Same mode -> description same -> should NOT rerun
        Weird.mode = 0
        await handle.rerender {
            HooksRuntime.useEffect("weird", deps: [AnyHashable(value)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "weird")
        }
        // Change mode -> description changes while equality/hash stay same -> should rerun
        Weird.mode = 1
        await handle.rerender {
            HooksRuntime.useEffect("weird", deps: [AnyHashable(value)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "weird")
        }

        await handle.unmount(); await handle.waitUntilExit()

        #expect(runs.current == 2, "Expected exactly 2 runs (initial + desc change); got \(runs.current)")
        #expect(cleans.current >= 1, "Expected at least 1 cleanup due to deps change; got \(cleans.current)")
    }

    @Test("Identity wrapper opts into object-identity dep semantics")
    func identityWrapperControlsReruns() async {
        final class Obj: @unchecked Sendable {}
        let o1 = Obj(); let o2 = Obj()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "ident"), options: options)
        let runs = HooksRuntime.Ref(0)
        let cleans = HooksRuntime.Ref(0)

        // Initial with o1
        await handle.rerender {
            HooksRuntime.useEffect("ident", deps: [Identity(o1)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "ident")
        }
        // Same object identity: no rerun
        await handle.rerender {
            HooksRuntime.useEffect("ident", deps: [Identity(o1)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "ident")
        }
        // Different object identity: rerun
        await handle.rerender {
            HooksRuntime.useEffect("ident", deps: [Identity(o2)]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "ident")
        }

        await handle.unmount(); await handle.waitUntilExit()

        #expect(runs.current == 2, "Expected exactly 2 runs (initial + identity change); got \(runs.current)")
        #expect(cleans.current >= 1)
    }
}

