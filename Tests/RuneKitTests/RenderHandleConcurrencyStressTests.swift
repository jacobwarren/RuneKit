import XCTest
@testable import RuneKit

final class RenderHandleConcurrencyStressTests: XCTestCase {
    func testConcurrentClearRerenderUnmountIsSafe() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        struct V1: View { let n: Int; var body: some View { Text("V1-\(n)") } }
        let handle = await render(V1(n: 0), options: options)

        // Launch concurrent tasks performing operations in random order
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await handle.rerender(V1(n: i))
                }
            }
            for _ in 0..<5 {
                group.addTask { await handle.clear() }
            }
            for _ in 0..<3 {
                group.addTask { await handle.unmount() }
            }
        }

        // waitUntilExit should resolve quickly and idempotently after unmount
        await handle.waitUntilExit()
    }

    func testIdentityChangeResetsDiffState() async {
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)

        struct ViewA: View, ViewIdentifiable { let id: String; var viewIdentity: String? { id }; var body: some View { Text("A") } }
        struct ViewB: View, ViewIdentifiable { let id: String; var viewIdentity: String? { id }; var body: some View { Text("B") } }

        let handle = await render(ViewA(id: "x"), options: options)
        // same identity – should not reset
        await handle.rerender(ViewA(id: "x"))
        // different identity – should reset reconciler diff state (no direct observable hook, but it must not crash)
        await handle.rerender(ViewA(id: "y"))
        // switching types also changes computed identity
        await handle.rerender(ViewB(id: "y"))

        await handle.unmount()
        await handle.waitUntilExit()
    }
}

