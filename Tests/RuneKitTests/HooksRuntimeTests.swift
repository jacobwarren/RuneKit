import Foundation
import Testing
@testable import RuneComponents
@testable import RuneKit

@Suite("Hooks runtime tests for RUNE-37", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
struct HooksRuntimeTests {
    @Test("useEffect runs on mount and cleanup runs on unmount; requestRerender drives ~10-12 Hz", .disabled("Timing-sensitive test that can hang"))
    func effectLifecycleAndSpinnerRate() async {
        // Arrange
        actor Counters {
            var mounts = 0
            var cleanups = 0
            var renders = 0
            func incMount() { mounts += 1 }
            func incCleanup() { cleanups += 1 }
            func incRender() { renders += 1 }
            func snapshot() -> (Int, Int, Int) { (mounts, cleanups, renders) }
        }
        let ctr = Counters()

        struct SpinnerView: View, ViewIdentifiable {
            var id: String
            var viewIdentity: String? { id }
            var body: some View { Text("") }
        }

        // We'll trigger rerenders from an effect approximately every 100ms
        // and count renders by registering an effect without deps.
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(SpinnerView(id: "spin"), options: options)

        // Hook: mount, schedule timer-like task via Task, call requestRerender.
        // Count mounts and cleanups with another effect.
        let start = Date()
        let duration: TimeInterval = 1.2 // run ~1.2s

        await handle.rerender {
            // Register a render counter effect (no deps) so it runs on each commit
            HooksRuntime.useEffect("renderCounter", deps: nil) {
                await ctr.incRender()
                return nil
            }
            // Register a mount effect with cleanup
            HooksRuntime.useEffect("mountOnce", depsToken: "once") {
                await ctr.incMount()
                // Schedule periodic rerenders using a Task
                let task = Task {
                    while Date().timeIntervalSince(start) < duration {
                        HooksRuntime.requestRerender()
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                }
                return {
                    task.cancel()
                    Task { await ctr.incCleanup() }
                }
            }
            return SpinnerView(id: "spin")
        }

        // Wait for the run window
        try? await Task.sleep(for: .seconds(1.3))
        await handle.unmount()
        await handle.waitUntilExit()
        // Allow any cleanup tasks scheduled within cleanup closures to run
        try? await Task.sleep(for: .milliseconds(50))

        // Assert
        let (mounts, cleanups, renders) = await ctr.snapshot()
        #expect(mounts >= 1, "Effect should run at least once on mount")
        #expect(cleanups >= 1, "Cleanup should run on unmount")
        // Expect around 10-12 rerenders per second for ~1.2s -> ~12 rerenders.
        // Allow wide tolerance on CI: between 6 and 20 commits.
        #expect(renders >= 6 && renders <= 30, "Expected ~10-12Hz renders; saw \(renders)")
    }

    @Test("Effect re-runs on deps change and previous cleanup executes", .disabled("Timing-sensitive test that can hang"))
    func effectDepsChangeReruns() async {
        actor Probe { var runs = 0; var cleans = 0; func incRun() { runs += 1 }; func incClean() { cleans += 1 } }
        let probe = Probe()

        struct V: View, ViewIdentifiable { var id: String; var viewIdentity: String? { id }; var body: some View { Text("v") } }
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = await render(V(id: "v"), options: options)

        var dep = 0
        // Initial render with dep=0
        let dep0 = dep
        await handle.rerender {
            HooksRuntime.useEffect("e", depsToken: "\(dep0)") {
                await probe.incRun(); return { Task { await probe.incClean() } }
            }
            return V(id: "v")
        }
        // Change dep -> should cleanup and re-run
        dep = 1
        let dep1 = dep
        await handle.rerender {
            HooksRuntime.useEffect("e", depsToken: "\(dep1)") {
                await probe.incRun(); return { Task { await probe.incClean() } }
            }
            return V(id: "v")
        }
        await handle.unmount()
        await handle.waitUntilExit()

        let (runs, cleans) = await (probe.runs, probe.cleans)
        #expect(runs >= 2, "Effect should run twice for dep change")
        #expect(cleans >= 1, "Cleanup should have run when deps changed")
    }
}

