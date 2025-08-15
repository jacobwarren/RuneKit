import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

@Suite("Alt-screen ordering boundaries")
struct AltScreenOrderingTests {
    @Test("Strict: No content before enter; none after leave")
    func strictBoundaries() async {
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 128, maxQueueDepth: 4, policy: .block)
        let cfg = RenderConfiguration(useAlternateScreen: true, enableConsoleCapture: false)
        let fb = FrameBuffer(output: out, configuration: cfg)

        let frame = TerminalRenderer.Frame(lines: ["Hello"], width: 10, height: 1)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await fb.renderFrame(frame) }
            group.addTask {
                // Try to create noise concurrently
                for _ in 0..<100 { await writer.writeAtomic("<NOISE>") }
            }
            group.addTask {
                // Race a leave soon after
                try? await Task.sleep(nanoseconds: 100_000)
                await fb.clear() // clear triggers leave if active
            }
        }

        // Shutdown
        await writer.shutdown()
        let s = await cap.finishAndReadString()

        // Assert boundaries
        guard let enter = s.range(of: "\u{001B}[?1049h"), let leave = s.range(of: "\u{001B}[?1049l", range: enter.upperBound..<s.endIndex) else {
            #expect(false, "Missing alt-screen enter/leave sequences"); return
        }

        let beforeEnter = String(s[..<enter.lowerBound])
        let afterLeave = String(s[leave.upperBound...])

        #expect(!beforeEnter.contains("Hello") && !beforeEnter.contains("\u{001B}[1;1H"), "No content before enter")
        #expect(!afterLeave.contains("Hello") && !afterLeave.contains("\u{001B}[1;1H"), "No content after leave")
    }
}

