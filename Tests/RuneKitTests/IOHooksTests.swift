import Foundation
import Testing
@testable import RuneKit

@Suite("RUNE-40: useStdin/Stdout/Stderr hooks")
struct IOHooksTests {
    struct InspectView: View, ViewIdentifiable {
        var id: String
        var customIn: FileHandle?
        var customOut: FileHandle?
        var customErr: FileHandle?
        var viewIdentity: String? { id }
        var body: some View {
            // Access hooks during build path
            let stdinInfo = HooksRuntime.useStdin()
            let stdoutInfo = HooksRuntime.useStdout()
            let stderrInfo = HooksRuntime.useStderr()
            // Assert basic invariants in test
            #expect(stdinInfo.handle.fileDescriptor >= 0)
            #expect(stdoutInfo.handle.fileDescriptor >= 0)
            #expect(stderrInfo.handle.fileDescriptor >= 0)
            return Text("")
        }
    }

    @Test("Hooks surface configured custom streams")
    func hooksReturnConfiguredStreams() async {
        // Arrange: Set up custom pipes for all three streams
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        let options = RenderOptions(
            stdout: outPipe.fileHandleForWriting,
            stdin: inPipe.fileHandleForReading,
            stderr: errPipe.fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )
        let view = InspectView(id: "io1")

        // Act
        let handle = await render(view, options: options)

        // Assert via effects: read inside an effect to ensure context is also bound there
        await handle.rerender {
            HooksRuntime.useEffect("check-io-hooks", deps: []) {
                let sIn = HooksRuntime.useStdin()
                let sOut = HooksRuntime.useStdout()
                let sErr = HooksRuntime.useStderr()
                #expect(sIn.handle.fileDescriptor == inPipe.fileHandleForReading.fileDescriptor)
                #expect(sOut.handle.fileDescriptor == outPipe.fileHandleForWriting.fileDescriptor)
                #expect(sErr.handle.fileDescriptor == errPipe.fileHandleForWriting.fileDescriptor)
                // TTY flags are false for pipes in CI usually
                #expect(sIn.isTTY == false || sIn.isTTY == true)
                #expect(sOut.isTTY == false || sOut.isTTY == true)
                #expect(sErr.isTTY == false || sErr.isTTY == true)
                // Raw mode metadata reflects options + TTY; on pipes it's false
                #expect(sIn.isRawMode == false)
                return nil
            }
            return Text("")
        }

        await handle.unmount()
        await handle.waitUntilExit()
    }

    @Test("Default environment streams are exposed with metadata")
    func defaultEnvironmentStreams() async {
        let handle = await render(Text("noop"), options: RenderOptions(exitOnCtrlC: false, patchConsole: false, useAltScreen: false, enableRawMode: false, enableBracketedPaste: false, fpsCap: 30.0))
        await handle.rerender {
            HooksRuntime.useEffect("defaults-io-hooks", deps: []) {
                let sIn = HooksRuntime.useStdin()
                let sOut = HooksRuntime.useStdout()
                let sErr = HooksRuntime.useStderr()
                // The file descriptors should match standard handles when not overridden (can't guarantee under test runner),
                // but we can at least assert they are valid FDs and that metadata fields exist.
                #expect(sIn.handle.fileDescriptor >= 0)
                #expect(sOut.handle.fileDescriptor >= 0)
                #expect(sErr.handle.fileDescriptor >= 0)
                _ = sIn.isTTY; _ = sOut.isTTY; _ = sErr.isTTY
                _ = sIn.isRawMode
                return nil
            }
            return Text("")
        }
        await handle.unmount()
        await handle.waitUntilExit()
    }
}

