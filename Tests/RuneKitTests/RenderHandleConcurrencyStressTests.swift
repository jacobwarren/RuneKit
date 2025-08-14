import Foundation
import Testing
@testable import RuneKit

@Suite(.enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
struct RenderHandleConcurrencyStressTests {
    @Test("Concurrent clear/rerender/unmount is safe")
    func concurrentClearRerenderUnmountIsSafe() async {
        // Use pipe output to avoid interfering with test runner stdout
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        struct V1: View { let n: Int; var body: some View { Text("V1-\(n)") } }
        await handle.rerender(V1(n: 0))

        // Launch concurrent tasks performing operations in random order
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 10 {
                group.addTask {
                    await handle.rerender(V1(n: i))
                }
            }
            for _ in 0 ..< 5 {
                group.addTask { await handle.clear() }
            }
            for _ in 0 ..< 3 {
                group.addTask { await handle.unmount() }
            }
        }

        // waitUntilExit should resolve quickly and idempotently after unmount
        await handle.waitUntilExit()

        // Cleanup pipes
        output.closeFile()
        input.closeFile()
    }

    @Test("Identity change resets diff state")
    func identityChangeResetsDiffState() async {
        // Use pipe output to avoid interfering with test runner stdout
        let pipe = Pipe()
        let output = pipe.fileHandleForWriting
        let input = pipe.fileHandleForReading

        let config = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let frameBuffer = FrameBuffer(output: output, configuration: config)
        let options = RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, fpsCap: 60)
        let handle = RenderHandle(frameBuffer: frameBuffer, signalHandler: nil, options: options)

        struct ViewA: View,
            ViewIdentifiable { let id: String; var viewIdentity: String? { id }; var body: some View { Text("A") } }
        struct ViewB: View,
            ViewIdentifiable { let id: String; var viewIdentity: String? { id }; var body: some View { Text("B") } }

        await handle.rerender(ViewA(id: "x"))
        // same identity – should not reset
        await handle.rerender(ViewA(id: "x"))
        // different identity – should reset reconciler diff state (no direct observable hook, but it must not crash)
        await handle.rerender(ViewA(id: "y"))
        // switching types also changes computed identity
        await handle.rerender(ViewB(id: "y"))

        await handle.unmount()
        await handle.waitUntilExit()

        // Cleanup pipes
        output.closeFile()
        input.closeFile()
    }
}
