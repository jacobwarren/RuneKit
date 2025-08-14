import Foundation
import Testing
import RuneKit

@Suite("RUNE-39: useApp() context", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
struct AppContextHookTests {
    struct ExitOnMountView: View, ViewIdentifiable {
        var id: String = UUID().uuidString
        var viewIdentity: String? { id }
        var body: some View {
            // On mount, request app exit
            HooksRuntime.useEffect("exit-on-mount", deps: []) {
                let app = HooksRuntime.useApp()
                await app.exit(nil)
                return nil
            }
            return Text("")
        }
    }

    struct ClearOnMountView: View, ViewIdentifiable {
        var id: String = UUID().uuidString
        var viewIdentity: String? { id }
        var body: some View {
            HooksRuntime.useEffect("clear-on-mount", deps: []) {
                let app = HooksRuntime.useApp()
                await app.clear()
                return nil
            }
            return Text("")
        }
    }

    @Test("useApp().exit() triggers unmount and resolves waitUntilExit")
    func useAppExitResolvesWaitUntilExit() async {
        // Arrange: use pipes to avoid touching real TTY; disable raw mode
        let outPipe = Pipe()
        let inPipe = Pipe()
        let options = RenderOptions(
            stdout: outPipe.fileHandleForWriting,
            stdin: inPipe.fileHandleForReading,
            stderr: outPipe.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 60.0,
            terminalProfile: .xterm256
        )

        // Act: render a view that exits on mount
        let handle = await render(ExitOnMountView(), options: options)

        // Assert: waitUntilExit should resolve immediately
        await handle.waitUntilExit()
        let active = await handle.isActive
        #expect(!active, "Handle should be inactive after app.exit()")

        // Cleanup
        outPipe.fileHandleForWriting.closeFile()
        inPipe.fileHandleForReading.closeFile()
    }

    @Test("useApp().clear() stops console capture but keeps handle active")
    func useAppClearStopsCaptureKeepsActive() async {
        // Arrange: enable console capture; disable raw mode
        let outPipe = Pipe()
        let inPipe = Pipe()
        let options = RenderOptions(
            stdout: outPipe.fileHandleForWriting,
            stdin: inPipe.fileHandleForReading,
            stderr: outPipe.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: true,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 60.0,
            terminalProfile: .xterm256
        )

        // Act: render a view that clears on mount
        let handle = await render(ClearOnMountView(), options: options)

        // Assert: console capture should have been stopped by clear(), handle remains active
        let captureActive = await handle.hasConsoleCapture()
        let active = await handle.isActive
        #expect(!captureActive, "Console capture should be stopped after app.clear()")
        #expect(active, "Handle should remain active after app.clear()")

        // Cleanup: unmount to resolve any pending state
        await handle.unmount()
        outPipe.fileHandleForWriting.closeFile()
        inPipe.fileHandleForReading.closeFile()
    }
}

