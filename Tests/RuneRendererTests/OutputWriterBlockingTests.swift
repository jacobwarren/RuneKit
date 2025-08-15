import Foundation
import Testing
@testable import RuneRenderer
@testable import TestSupport

@Suite("Output writer blocking behavior", .enabled(if: !TestEnv.isCI))
struct OutputWriterBlockingTests {
    @Test("Block policy flushes immediately and clears buffer for oversized data")
    func blockPolicyFlushesAndClearsForOversizedData() async {
        let cap = PipeCapture(); let out = cap.start()
        // Tiny buffers to force backpressure
        let writer = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 1, policy: .block)

        // Prepare a moderate payload that won't bypass buffer (smaller than maxBufferedBytes)
        let chunk = String(repeating: "x", count: 40)
        let iterations = 200

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    for _ in 0..<iterations {
                        await writer.write(chunk)
                    }
                }
            }
        }

        // Flush remaining bytes and shutdown
        await writer.flush()
        await writer.shutdown()
        let result = await cap.finishAndReadString()

        // No drops expected under .block policy (it flushes and clears buffer instead)
        let m = await writer.metrics()
        #expect(m.droppedMessages == 0, "No messages should be dropped under .block policy")

        // All data should be present (block policy preserves data by flushing/clearing)
        #expect(result.utf8.count == 4 * iterations * chunk.utf8.count, "All bytes should be present after flush/clear")
    }
}

