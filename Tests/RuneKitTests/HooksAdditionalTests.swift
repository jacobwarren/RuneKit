import Foundation
import Testing
import TestSupport
@testable import RuneKit
@testable import RuneComponents

@Suite("Hooks additional tests: deps sugar, useRef, useMemo", .enabled(if: !TestEnv.isCI))
struct HooksAdditionalTests {

    init() {
        // Clean up shared state before each test to prevent interference between tests
        StateRegistry.shared.clearAll()
        StateObjectStore.shared.clearAll()
    }
    struct V: View, ViewIdentifiable { var id: String; var viewIdentity: String? { id }; var body: some View { Text("v") } }

    // Helper that calls useMemo at a single call site to keep the key stable across rerenders
    @inline(never)
    static func memoHelper(_ dep: Int, counter: HooksRuntime.Ref<Int>) -> Int {
        HooksRuntime.useMemo({ counter.current += 1; return dep * 2 }, deps: [dep])
    }

    // Helper that calls useRef at a single call site to keep its key stable
    @inline(never)
    static func refHelper(_ initial: Int = 0) -> HooksRuntime.Ref<Int> {
        // Use explicit key to avoid platform-specific inlining/call-site differences
        HooksRuntime.useRef(key: "HooksAdditionalTests.refHelper", initial)
    }

    @Test("useEffect deps sugar: nil runs every commit, [] mount-only, values trigger rerun")
    func useEffectDepsSugarSemantics() async {
        let runs = HooksRuntime.Ref(0)
        let cleans = HooksRuntime.Ref(0)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "v"), options: options)

        // nil deps: run every commit
        await handle.rerender {
            HooksRuntime.useEffect("nilDeps", deps: nil) { runs.current += 1; return nil }
            return V(id: "v")
        }
        await handle.rerender {
            HooksRuntime.useEffect("nilDeps", deps: nil) { runs.current += 1; return nil }
            return V(id: "v")
        }

        // [] deps: mount-only
        await handle.rerender {
            HooksRuntime.useEffect("emptyDeps", deps: []) { runs.current += 1; return { cleans.current += 1 }
            }
            return V(id: "v")
        }
        await handle.rerender { V(id: "v") }

        // [values] deps: rerun on change
        var dep = 0
        let dep0 = dep
        await handle.rerender {
            HooksRuntime.useEffect("arr", deps: [dep0]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "v")
        }
        dep = 1
        let dep1 = dep
        await handle.rerender {
            HooksRuntime.useEffect("arr", deps: [dep1]) { runs.current += 1; return { cleans.current += 1 } }
            return V(id: "v")
        }

        await handle.unmount()
        await handle.waitUntilExit()

        #expect(runs.current >= 4, "Expected runs for nil twice + empty once + array twice: got \(runs.current)")
        #expect(cleans.current >= 2, "Expected at least two cleanups for emptyDeps unmount + arr deps change")
    }

    @Test("useRef identity persists across rerenders and does not trigger rerender on mutation")
    func useRefIdentity() async {
        actor Probe { var renders = 0; func inc() { renders += 1 } }
        actor Holder { var id1: ObjectIdentifier?; var id2: ObjectIdentifier?; func set1(_ id: ObjectIdentifier) { id1 = id }; func set2(_ id: ObjectIdentifier) { id2 = id }; func get() -> (ObjectIdentifier?, ObjectIdentifier?) { (id1, id2) } }
        let p = Probe()
        let holder = Holder()
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "v"), options: options)

        // Ensure a clean key space for this test path to avoid interference
        StateRegistry.shared.reset(path: "V#v")

        await handle.rerender {
            let r = HooksAdditionalTests.refHelper(0)
            Task { await holder.set1(ObjectIdentifier(r)) }
            HooksRuntime.useEffect("renderCounter", deps: nil) { await p.inc(); return nil }
            return V(id: "v")
        }
        await handle.rerender {
            let r = HooksAdditionalTests.refHelper(0)
            r.current += 1 // mutate should not force rerender by itself
            Task { await holder.set2(ObjectIdentifier(r)) }
            HooksRuntime.useEffect("renderCounter", deps: nil) { await p.inc(); return nil }
            return V(id: "v")
        }

        await handle.unmount(); await handle.waitUntilExit()

        let (id1, id2) = await holder.get()
        #expect(id1 != nil && id2 != nil)
        #expect(id1 == id2)
        let renders = await p.renders
        #expect(renders >= 2)
    }

    @Test("useMemo recomputes only when deps change")
    func useMemoRecompute() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "v"), options: options)

        var dep = 0
        let counter = HooksRuntime.Ref(0)
        let d0 = dep
        await handle.rerender { [d0] in
            let _ = HooksAdditionalTests.memoHelper(d0, counter: counter)
            return V(id: "v")
        }
        // Same deps: no recompute
        await handle.rerender { [d0] in
            let _ = HooksAdditionalTests.memoHelper(d0, counter: counter)
            return V(id: "v")
        }
        // Change dep: recompute
        dep = 1
        let d1 = dep
        await handle.rerender { [d1] in
            let _ = HooksAdditionalTests.memoHelper(d1, counter: counter)
            return V(id: "v")
        }

        await handle.unmount(); await handle.waitUntilExit()
        #expect(counter.current == 2, "Expected exactly 2 computes: first mount + deps change, got \(counter.current)")
    }
}

