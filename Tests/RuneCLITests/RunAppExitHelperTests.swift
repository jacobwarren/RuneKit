import Foundation
import Testing
import RuneKit
@testable import RuneCLI

@Suite("RuneCLI exit helper")
struct RunAppExitHelperTests {
    struct ExitImmediate: View, ViewIdentifiable {
        var id = UUID().uuidString
        var viewIdentity: String? { id }
        var code: Int32
        var body: some View {
            HooksRuntime.useEffect("exit", deps: []) {
                let app = HooksRuntime.useApp()
                await app.exit(Coded(code: code))
                return nil
            }
            return Text("")
        }
        struct Coded: Error, AppExitCodeProviding { let code: Int32; var exitCode: Int32 { code } }
    }

    @Test("runAppAndReturnExitCode returns the app's exit code")
    func helperReturnsExitCode() async {
        let options = RuneCLI.demoOptions
        let code = await RuneCLI.runAppAndReturnExitCode(ExitImmediate(code: 7), options: options)
        #expect(code == 7)
    }

    @Test("helper returns 0 when app exits with nil error")
    func helperReturnsZeroOnNil() async {
        struct ExitNil: View, ViewIdentifiable {
            var id = UUID().uuidString
            var viewIdentity: String? { id }
            var body: some View {
                HooksRuntime.useEffect("exit", deps: []) {
                    let app = HooksRuntime.useApp()
                    await app.exit(nil)
                    return nil
                }
                return Text("")
            }
        }
        let options = RuneCLI.demoOptions
        let code = await RuneCLI.runAppAndReturnExitCode(ExitNil(), options: options)
        #expect(code == 0)
    }
}

