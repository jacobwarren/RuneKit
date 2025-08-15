import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

@Suite("Pluggable IO ordering tests")
struct PluggableIOOrderingTests {
    @Test("Default: Renderer and external atomic writes do not interleave")
    func defaultNoInterleavingWithSharedWriter() async {
        // Arrange
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 256, maxQueueDepth: 8, policy: .block)
        let cfg = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let renderer = TerminalRenderer(output: out, writer: writer, configuration: cfg)

        let grid = TerminalGrid(lines: ["AAA", "BBB", "CCC"], width: 5)

        // Act: render concurrently with many external atomic writes
        await withTaskGroup(of: Void.self) { group in
            group.addTask { _ = await renderer.render(grid, strategy: .fullRedraw) }
            group.addTask {
                for _ in 0..<200 { await writer.writeAtomic("<EXT>") }
            }
        }
        await writer.shutdown()
        let s = await cap.finishAndReadString()

        // Assert: No external markers appear inside each line's absolute segment
        #expect(noExternalBetween(s: s, start: "\u{001B}[1;1H", end: "\u{001B}[0m"))
        #expect(noExternalBetween(s: s, start: "\u{001B}[2;1H", end: "\u{001B}[0m"))
        #expect(noExternalBetween(s: s, start: "\u{001B}[3;1H", end: "\u{001B}[0m"))
    }

    @Test("Opt-out: Without shared writer, ordering between lines is not guaranteed", .enabled(if: !TestEnv.isCI))
    func optOutExternalMayAppearBetweenLines() async {
        // Arrange: pluggable path using encoder for renderer, no shared writer
        let cap = PipeCapture(); let out = cap.start()
        let cfg = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let encoder = FileHandleOutputEncoder(handle: out)
        let cursor = ANSICursorManager(out: encoder)
        let renderer = TerminalRenderer(output: out, encoder: encoder, cursor: cursor, configuration: cfg)

        let grid = TerminalGrid(lines: ["AAA", "BBB", "CCC"], width: 5)

        // Act: Concurrent renderer and external writes directly to FileHandle
        await withTaskGroup(of: Void.self) { group in
            group.addTask { _ = await renderer.render(grid, strategy: .fullRedraw) }
            group.addTask {
                // External writes via FileHandle can land between renderer's per-line atomic writes
                for _ in 0..<300 { try? out.write(contentsOf: Data("<E>".utf8)) }
            }
        }
        try? out.close()
        let s = await cap.finishAndReadString()

        // Expectation: No <E> inside per-line segments (renderer writes a line atomically),
        // but <E> may appear between lines (outside those segments).
        let l1 = rangeBetween(s: s, start: "\u{001B}[1;1H", end: "\u{001B}[0m")
        let l2 = rangeBetween(s: s, start: "\u{001B}[2;1H", end: "\u{001B}[0m")
        let l3 = rangeBetween(s: s, start: "\u{001B}[3;1H", end: "\u{001B}[0m")
        if let r1 = l1 { #expect(!s[r1].contains("<E>") , "No external markers inside line 1") }
        if let r2 = l2 { #expect(!s[r2].contains("<E>") , "No external markers inside line 2") }
        if let r3 = l3 { #expect(!s[r3].contains("<E>") , "No external markers inside line 3") }

        // Check for at least one external marker between line segments
        let between12 = (l1 != nil && l2 != nil) ? s[l1!.upperBound..<l2!.lowerBound] : s[...]
        let between23 = (l2 != nil && l3 != nil) ? s[l2!.upperBound..<l3!.lowerBound] : s[...]
        let foundBetween = between12.contains("<E>") || between23.contains("<E>")
        #expect(foundBetween, "External markers should be able to appear between lines without shared writer")
    }

    // Helpers
    private func noExternalBetween(s: String, start: String, end: String) -> Bool {
        guard let r1 = s.range(of: start) else { return true }
        guard let r2 = s.range(of: end, range: r1.upperBound..<s.endIndex) else { return true }
        let between = String(s[r1.upperBound..<r2.lowerBound])
        return !between.contains("<EXT>")
    }

    private func rangeBetween(s: String, start: String, end: String) -> Range<String.Index>? {
        guard let r1 = s.range(of: start) else { return nil }
        guard let r2 = s.range(of: end, range: r1.upperBound..<s.endIndex) else { return nil }
        return r1.upperBound..<r2.lowerBound
    }
}

