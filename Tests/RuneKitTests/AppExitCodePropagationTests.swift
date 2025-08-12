import Foundation
import Testing
import RuneKit

@Suite("RUNE-39+: App exit code propagation via useApp().exit(error:)")
struct AppExitCodePropagationTests {
    // Protocol is in library; define custom errors for tests
    struct CustomExitError: Error, AppExitCodeProviding { let exitCode: Int32 }
    enum PlainError: Error { case oops }

    struct ExitWithCustomCodeView: View, ViewIdentifiable {
        var id: String = UUID().uuidString
        var viewIdentity: String? { id }
        var code: Int32
        var body: some View {
            HooksRuntime.useEffect("exit-code", deps: []) {
                let app = HooksRuntime.useApp()
                await app.exit(CustomExitError(exitCode: code))
                return nil
            }
            return Text("")
        }
    }

    struct ExitWithPlainErrorView: View, ViewIdentifiable {
        var id: String = UUID().uuidString
        var viewIdentity: String? { id }
        var body: some View {
            HooksRuntime.useEffect("exit-plain", deps: []) {
                let app = HooksRuntime.useApp()
                await app.exit(PlainError.oops)
                return nil
            }
            return Text("")
        }
    }

    struct ExitWithNilErrorView: View, ViewIdentifiable {
        var id: String = UUID().uuidString
        var viewIdentity: String? { id }
        var body: some View {
            HooksRuntime.useEffect("exit-nil", deps: []) {
                let app = HooksRuntime.useApp()
                await app.exit(nil)
                return nil
            }
            return Text("")
        }
    }



    @Test("exit(error:) uses provided custom exit code when error conforms")
    func exitWithCustomCode() async {
        let pipeOut = Pipe(); let pipeIn = Pipe()
        let options = RenderOptions(
            stdout: pipeOut.fileHandleForWriting,
            stdin: pipeIn.fileHandleForReading,
            stderr: pipeOut.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 60.0,
            terminalProfile: .xterm256
        )
        let handle = await render(ExitWithCustomCodeView(code: 42), options: options)
        await handle.waitUntilExit()
        let status = await handle.getExitStatus()
        #expect(status?.code == 42, "Expected exit code 42 from custom error")
    }

    @Test("exit(error:) uses default code 1 for plain errors")
    func exitWithPlainErrorDefaultsToOne() async {
        let pipeOut = Pipe(); let pipeIn = Pipe()
        let options = RenderOptions(
            stdout: pipeOut.fileHandleForWriting,
            stdin: pipeIn.fileHandleForReading,
            stderr: pipeOut.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 60.0,
            terminalProfile: .xterm256
        )
        let handle = await render(ExitWithPlainErrorView(), options: options)
        await handle.waitUntilExit()
        let status = await handle.getExitStatus()
        #expect(status?.code == 1, "Expected default exit code 1 for non-conforming error")
    }

    @Test("exit(nil) yields code 0 (success)")
    func exitWithNilIsSuccessZero() async {
        let pipeOut = Pipe(); let pipeIn = Pipe()
        let options = RenderOptions(
            stdout: pipeOut.fileHandleForWriting,
            stdin: pipeIn.fileHandleForReading,
            stderr: pipeOut.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            enableRawMode: false,
            enableBracketedPaste: false,
            fpsCap: 60.0,
            terminalProfile: .xterm256
        )
        let handle = await render(ExitWithNilErrorView(), options: options)
        await handle.waitUntilExit()
        let status = await handle.getExitStatus()
        #expect(status?.code == 0, "Expected exit code 0 for nil error")
    }
}

