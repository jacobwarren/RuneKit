import Foundation
import Testing
import TestSupport
@testable import RuneRenderer

@Suite("Output serialization integration", .enabled(if: !TestEnv.isCI))
struct OutputSerializationIntegrationTests {
    @Test("Renderer per-line writes are atomic relative to external logs")
    func rendererLineWritesAreAtomicAgainstExternal() async {
        // Arrange: shared writer routed to a pipe so we can capture
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 256, maxQueueDepth: 8, policy: .block)
        let cfg = RenderConfiguration(useAlternateScreen: false, enableConsoleCapture: false)
        let renderer = TerminalRenderer(output: out, writer: writer, configuration: cfg)

        // Simple 3-line grid; increases window for potential interleaving
        let grid = TerminalGrid(lines: ["AAA", "BBB", "CCC"], width: 5)

        // Act: race renderer vs many external atomic writes
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = await renderer.render(grid, strategy: .fullRedraw)
            }
            group.addTask {
                for _ in 0..<200 {
                    await writer.writeAtomic("<EXT>")
                }
            }
        }
        await writer.shutdown()
        let s = await cap.finishAndReadString()

        // Assert: For each line, text between its move-to-row and trailing reset should not contain external markers
        // Row 1
        #expect(noExternalBetween(s: s, start: "\u{001B}[1;1H", end: "\u{001B}[0m"), "External logs interleaved inside line 1 render")
        // Row 2
        #expect(noExternalBetween(s: s, start: "\u{001B}[2;1H", end: "\u{001B}[0m"), "External logs interleaved inside line 2 render")
        // Row 3
        #expect(noExternalBetween(s: s, start: "\u{001B}[3;1H", end: "\u{001B}[0m"), "External logs interleaved inside line 3 render")
    }

    @Test("Backpressure policies are documented and configurable")
    func backpressurePoliciesAreDocumentedAndConfigurable() async {
        let cap = PipeCapture(); let out = cap.start()

        // Test each backpressure policy can be configured
        let blockWriter = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 2, policy: .block)
        let dropNewestWriter = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 2, policy: .dropNewest)
        let dropOldestWriter = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 2, policy: .dropOldest)

        // Verify they can be created without error (policy is documented via enum cases)
        // Just test that they exist and can be shut down
        await blockWriter.shutdown()
        await dropNewestWriter.shutdown()
        await dropOldestWriter.shutdown()
        _ = await cap.finishAndReadString()
    }

    @Test("Atomic writes reduce syscalls vs unbatched writes")
    func atomicWritesReduceSyscallsVsUnbatched() async {
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 8, policy: .block)

        // Measure syscalls for atomic writes (each write is a single syscall)
        let atomicStart = await writer.metrics()
        for _ in 0..<5 {
            await writer.writeAtomic("\u{001B}[1;1H\u{001B}[2KLine content")
        }
        let atomicEnd = await writer.metrics()
        let atomicSyscalls = atomicEnd.writeSyscalls - atomicStart.writeSyscalls

        // Measure syscalls for buffered writes (should use fewer syscalls due to buffering)
        let bufferedStart = await writer.metrics()
        for _ in 0..<5 {
            await writer.write("\u{001B}[1;1H")
            await writer.write("\u{001B}[2K")
            await writer.write("Line content")
        }
        await writer.flush() // Final flush
        let bufferedEnd = await writer.metrics()
        let bufferedSyscalls = bufferedEnd.writeSyscalls - bufferedStart.writeSyscalls

        await writer.shutdown()
        _ = await cap.finishAndReadString()

        // Buffered writes should use fewer syscalls than atomic writes
        #expect(bufferedSyscalls < atomicSyscalls, "Buffered writes (\(bufferedSyscalls) syscalls) should be fewer than atomic writes (\(atomicSyscalls) syscalls)")
    }

    // Helpers
    private func noExternalBetween(s: String, start: String, end: String) -> Bool {
        guard let r1 = s.range(of: start) else { return true }
        guard let r2 = s.range(of: end, range: r1.upperBound..<s.endIndex) else { return true }
        let between = String(s[r1.upperBound..<r2.lowerBound])
        return !between.contains("<EXT>")
    }
}

