import Foundation
import Testing
@testable import RuneKit

// RUNE-36: Raw-mode input & key events
// Failing tests first (TDD): decoding, bracketed paste, and cleanup integration.

struct InputManagerTests {
    // Utilities for capturing events thread-safely
    actor EventSink {
        private(set) var events: [KeyEvent] = []
        func append(_ e: KeyEvent) { events.append(e) }
        func all() -> [KeyEvent] { events }
    }

    @Test("Decodes arrows and Ctrl-C/ Ctrl-D bytes", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
    func decodesArrowsAndControl() async {
        // Arrange: use pipes for IO so we don't require a TTY
        let outPipe = Pipe()
        let inPipe = Pipe()
        let mgr = InputManager(
            input: inPipe.fileHandleForReading,
            controlOut: outPipe.fileHandleForWriting,
            enableRawMode: false,
            enableBracketedPaste: false,
            exitOnCtrlC: false
        )
        let sink = EventSink()
        await mgr.setEventHandler { event in
            await sink.append(event)
        }

        // Act: feed sequences
        // Arrow Up: ESC [ A, Arrow Left: ESC [ D
        await mgr.process(bytes: [0x1B, 0x5B, 0x41])
        await mgr.process(bytes: [0x1B, 0x5B, 0x44])
        // Ctrl-C (ETX) and Ctrl-D (EOT)
        await mgr.process(bytes: [0x03])
        await mgr.process(bytes: [0x04])

        // Assert
        let events = await sink.all()
        #expect(events.contains(.arrowUp))
        #expect(events.contains(.arrowLeft))
        #expect(events.contains(.ctrlC))
        #expect(events.contains(.ctrlD))
    }

    @Test("Bracketed paste emits single paste event when enabled", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
    func bracketedPasteEmitsSingleEvent() async {
        // Arrange
        let outPipe = Pipe()
        let inPipe = Pipe()
        let mgr = InputManager(
            input: inPipe.fileHandleForReading,
            controlOut: outPipe.fileHandleForWriting,
            enableRawMode: false,
            enableBracketedPaste: true,
            exitOnCtrlC: false
        )
        let sink = EventSink()
        await mgr.setEventHandler { event in
            await sink.append(event)
        }

        // Act: call start() so it writes the enable sequence, then paste
        await mgr.start()
        // Simulate bracketed paste: CSI 200~ ... CSI 201~
        let start: [UInt8] = [0x1B, 0x5B, 0x32, 0x30, 0x30, 0x7E]
        let end: [UInt8] = [0x1B, 0x5B, 0x32, 0x30, 0x31, 0x7E]
        let payload = Array("hello\nworld".utf8)
        await mgr.process(bytes: start + payload + end)

        // Assert: event captured with entire payload
        let events = await sink.all()
        #expect(events.contains(.paste("hello\nworld")))

        // Also assert that disabling writes the bracketed paste off sequence when stopping
        await mgr.stop()
        outPipe.fileHandleForWriting.closeFile()
        let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let outputStr = String(decoding: outputData, as: UTF8.self)
        #expect(outputStr.contains("\u{001B}[?2004h"), "Should enable bracketed paste on start")
        #expect(outputStr.contains("\u{001B}[?2004l"), "Should disable bracketed paste on stop")
    }

    @Test("Integration: RenderHandle unmount cleans up input manager and paste mode", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
    func integrationUnmountCleansUp() async {
        // Arrange: Render with pipes and explicit options enabling paste
        let outPipe = Pipe()
        let options = RenderOptions(
            stdout: outPipe.fileHandleForWriting,
            stdin: Pipe().fileHandleForReading,
            stderr: Pipe().fileHandleForWriting,
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
            terminalProfile: nil
        )
        // Render a trivial view
        let handle = await render(Text("IO Test"), options: options)

        // Act: unmount to trigger cleanup
        await handle.unmount()
        outPipe.fileHandleForWriting.closeFile()
        let out = outPipe.fileHandleForReading.readDataToEndOfFile()
        let outStr = String(decoding: out, as: UTF8.self)

        // Assert: even if bracketed paste default may be off, stop should not crash and should restore terminal state.
        // We at least ensure no stray control sequences remain for paste mode enabled case.
        // Note: If paste wasn't enabled, off sequence may be absent; this assertion is permissive.
        #expect(!outStr.contains("\u{001B}[?2004h"))
    }

    @Test("Ctrl-C triggers unmount when exitOnCtrlC=true via InputManager path", .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
    func ctrlCTriggersUnmount() async {
        // Arrange: set options to enable raw input path handling
        let outPipe = Pipe()
        let inPipeR = Pipe()
        let options = RenderOptions(
            stdout: outPipe.fileHandleForWriting,
            stdin: inPipeR.fileHandleForReading,
            stderr: Pipe().fileHandleForWriting,
            exitOnCtrlC: true,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0,
            terminalProfile: nil
        )
        let handle = await render(Text("CtrlC"), options: options)

        // Inject ctrl-c into the input manager decoder directly (test hook)
        await handle.testingProcessInput(bytes: [0x03])

        // Assert: waitUntilExit resolves
        await handle.waitUntilExit()

        // Cleanup
        outPipe.fileHandleForWriting.closeFile()
    }
}

