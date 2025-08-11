import Foundation
import Testing
@testable import RuneRenderer

struct PerformanceTimingExposureTests {
    @Test("HybridReconciler exposes timing consistent with fpsCap")
    func reconcilerTimingReflectsFpsCap() async {
        // Arrange: two configurations with different fps caps
        let pipe1 = Pipe()
        let pipe2 = Pipe()
        let cfg60 = RenderConfiguration(
            performance: RenderConfiguration.PerformanceTuning(maxFrameRate: 60.0),
        )
        let cfg30 = RenderConfiguration(
            performance: RenderConfiguration.PerformanceTuning(maxFrameRate: 30.0),
        )

        let fb60 = FrameBuffer(output: pipe1.fileHandleForWriting, configuration: cfg60)
        let fb30 = FrameBuffer(output: pipe2.fileHandleForWriting, configuration: cfg30)

        // Act
        let m60 = await fb60.getPerformanceMetrics()
        let m30 = await fb30.getPerformanceMetrics()

        // Assert: maxUpdateRate and coalescingWindow should differ appropriately
        #expect(m60.maxUpdateRate < m30.maxUpdateRate, "Higher FPS should allow smaller update interval")
        #expect(m60.coalescingWindow < m30.coalescingWindow, "Higher FPS should use smaller coalescing window")

        // Cleanup
        pipe1.fileHandleForWriting.closeFile()
        pipe2.fileHandleForWriting.closeFile()
    }
}
