import Foundation
import Testing
@testable import RuneComponents
@testable import RuneKit

struct ChildIdentityReconcilerTests {

    init() {
        // Clean up shared state before each test to prevent interference between tests
        StateRegistry.shared.clearAll()
        StateObjectStore.shared.clearAll()
    }
    // Shared state tracker that's not affected by StateRegistry.clearAll()
    nonisolated(unsafe) private static var renderCounts: [String: Int] = [:]
    private static let renderCountsQueue = DispatchQueue(label: "renderCounts")

    private struct StatefulChild: Component, ComponentIdentifiable {
        let id: String
        var componentIdentity: String? { id }
        func render(in _: FlexLayout.Rect) -> [String] {
            // Use our own state tracking that's not affected by StateRegistry.clearAll()
            let path = RuntimeStateContext.currentPath
            let count = ChildIdentityReconcilerTests.renderCountsQueue.sync {
                let current = ChildIdentityReconcilerTests.renderCounts[path, default: 0]
                let newCount = current + 1
                ChildIdentityReconcilerTests.renderCounts[path] = newCount
                return newCount
            }
            return ["#\(id):\(count)"]
        }
    }

    @Test("Preserve child state across reordering with stable identity")
    func preserveAcrossReorder() {
        // Clear our custom state tracker for this test
        Self.renderCountsQueue.sync {
            Self.renderCounts.removeAll()
        }

        // Use a unique root path for this test to avoid interference
        let testRoot = "test-\(UUID().uuidString)"

        let container = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 2)
        let tree = ComponentTreeReconciler()

        // First render: A then B
        let a = Identified("A", child: StatefulChild(id: "A"))
        let b = Identified("B", child: StatefulChild(id: "B"))
        var box = Box(children: a, b)

        // Render with proper ComponentTreeBinding context using the same tree
        ComponentTreeBinding.bindDuringRender(tree: tree) {
            RuntimeStateContext.$currentPath.withValue(testRoot) {
                _ = box.render(in: container)
            }
        }

        // Capture state immediately after first render
        let pathA = "\(testRoot)/Box/child#A/Identified/A"
        let pathB = "\(testRoot)/Box/child#B/Identified/B"
        let countA1 = Self.renderCountsQueue.sync { Self.renderCounts[pathA, default: -1] }
        let countB1 = Self.renderCountsQueue.sync { Self.renderCounts[pathB, default: -1] }

        // Second render: B then A (reordered)
        let a2 = Identified("A", child: StatefulChild(id: "A"))
        let b2 = Identified("B", child: StatefulChild(id: "B"))
        box = Box(children: b2, a2)

        // Render again with the SAME tree to preserve state
        ComponentTreeBinding.bindDuringRender(tree: tree) {
            RuntimeStateContext.$currentPath.withValue(testRoot) {
                _ = box.render(in: container)
            }
        }

        // Capture state immediately after second render
        let countA2 = Self.renderCountsQueue.sync { Self.renderCounts[pathA, default: -1] }
        let countB2 = Self.renderCountsQueue.sync { Self.renderCounts[pathB, default: -1] }

        // Verify that both components were rendered in first render
        #expect(countA1 == 1, "A should have been rendered once in first render")
        #expect(countB1 == 1, "B should have been rendered once in first render")

        // Verify that both components were rendered again in second render, preserving state
        #expect(countA2 == 2, "A should have been rendered twice across reordering, preserving state")
        #expect(countB2 == 2, "B should have been rendered twice across reordering, preserving state")
    }
}
