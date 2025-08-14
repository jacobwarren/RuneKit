import Foundation
import Testing
@testable import RuneRenderer
@testable import TestSupport

struct OutputWriterTests {
    @Test("Serializes concurrent writes without interleaving (atomic)")
    func serializesConcurrentAtomicWrites() async {
        let cap = PipeCapture()
        let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 256, maxQueueDepth: 4, policy: .dropNewest)
        let n = 20
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<n {
                group.addTask {
                    await writer.writeAtomic("<B\(i)>" + String(repeating: "x", count: 50) + "</E\(i)>\n")
                }
            }
        }
        await writer.shutdown()
        let s = await cap.finishAndReadString()
        // Validate atomicity without assuming global ordering: each pair appears intact with no nested begin tags inside.
        for i in 0..<n {
            let begin = "<B\(i)>"
            let endTag = "</E\(i)>"
            guard let r1 = s.range(of: begin) else {
                Issue.record("Missing begin tag for index \(i)"); continue
            }
            guard let r2 = s.range(of: endTag, range: r1.upperBound..<s.endIndex) else {
                Issue.record("Missing matching end tag for index \(i)"); continue
            }
            let between = String(s[r1.upperBound..<r2.lowerBound])
            // Ensure no other begin tag occurs between r1 and r2 (no interleaving)
            #expect(!between.contains("<B"), "Interleaving detected inside message for index \(i)")
        }
    }

    @Test("Backpressure dropNewest drops when buffer is full")
    func backpressureDropNewest() async {
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 64, maxQueueDepth: 1, policy: .dropNewest)
        // Push many large non-atomic writes to overflow internal buffer
        for _ in 0..<200 {
            await writer.write(String(repeating: "a", count: 200))
        }
        await writer.shutdown()
        _ = await cap.finishAndReadString()
        let m = await writer.metrics()
        #expect(m.droppedMessages > 0, "Expected some messages to be dropped under backpressure")
    }

    @Test("Batched writes reduce syscalls vs unbatched")
    func batchedWritesReduceSyscalls() async {
        let cap = PipeCapture(); let out = cap.start()
        let writer = OutputWriter(handle: out, bufferSize: 1024, maxQueueDepth: 8, policy: .block)
        for _ in 0..<100 { await writer.write("0123456789") } // 1000 bytes total
        await writer.flush()
        await writer.shutdown()
        _ = await cap.finishAndReadString()
        let m = await writer.metrics()
        #expect(m.writeSyscalls < 100, "Syscalls should be batched (\(m.writeSyscalls))")
        #expect(m.bytesWritten >= 1000, "All bytes should be written")
    }
}

