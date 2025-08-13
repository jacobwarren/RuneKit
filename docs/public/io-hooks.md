# RuneKit I/O Hooks (RUNE-40)

RuneKit exposes hooks to access the configured I/O streams and basic metadata from within your components and effects.

- HooksRuntime.useStdin() -> (handle, isTTY, isRawMode)
- HooksRuntime.useStdout() -> (handle, isTTY)
- HooksRuntime.useStderr() -> (handle, isTTY)

These values respect the streams passed via render(options). If you supply custom FileHandles for stdin/stdout/stderr, the hooks will surface those exact handles.

Metadata:
- isTTY is computed using isatty(fd)
- isRawMode is true when RenderOptions.enableRawMode is enabled and stdin is a TTY

Example:

```swift
struct IOExample: View {
    var body: some View {
        HooksRuntime.useEffect("log-io", deps: []) {
            let stdinInfo = HooksRuntime.useStdin()
            let stdoutInfo = HooksRuntime.useStdout()
            let stderrInfo = HooksRuntime.useStderr()
            // You can inspect and optionally write to these handles if needed
            // e.g., write a message directly to stderr
            let msg = "Using TTY? \(stdoutInfo.isTTY)\n"
            if let data = msg.data(using: .utf8) {
                stderrInfo.handle.write(data)
            }
            return nil
        }
        return Text("I/O hooks demo")
    }
}

// Configure custom streams
let outPipe = Pipe()
let options = RenderOptions(stdout: outPipe.fileHandleForWriting,
                            exitOnCtrlC: false, patchConsole: false,
                            useAltScreen: false, fpsCap: 30.0)
let handle = await render(IOExample(), options: options)
```

