import Testing
@testable import RuneComponents
@testable import RuneKit

struct ChildIdentityReconcilerTests {
    private struct StatefulChild: Component, ComponentIdentifiable {
        let id: String
        var componentIdentity: String? { id }
        func render(in rect: FlexLayout.Rect) -> [String] {
            // Read, increment, and persist count in registry using current identity path
            let path = RuntimeStateContext.currentPath
            let current: Int = StateRegistry.shared.get(path: path, key: "count", initial: 0)
            StateRegistry.shared.set(path: path, key: "count", value: current + 1)
            return ["#\(id):\(current + 1)"]
        }
    }

    @Test("Preserve child state across reordering with stable identity")
    func preserveAcrossReorder() {
        // Ensure clean registry state
        StateRegistry.shared.clearAll()

        let container = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 2)
        // First render: A then B
        let a = Identified("A", child: StatefulChild(id: "A"))
        let b = Identified("B", child: StatefulChild(id: "B"))
        var box = Box(children: a, b)
        _ = box.render(in: container)

        // Second render: B then A (reordered)
        let a2 = Identified("A", child: StatefulChild(id: "A"))
        let b2 = Identified("B", child: StatefulChild(id: "B"))
        box = Box(children: b2, a2)
        _ = box.render(in: container)

        // Inspect registry directly for explicit counts using the identity paths we generate
        let pathA = "root/Box/child#A/Identified/A"
        let pathB = "root/Box/child#B/Identified/B"
        let countA: Int = StateRegistry.shared.get(path: pathA, key: "count", initial: -1)
        let countB: Int = StateRegistry.shared.get(path: pathB, key: "count", initial: -1)
        #expect(countA == 2, "A should have been rendered twice across reordering, preserving state")
        #expect(countB == 2, "B should have been rendered twice across reordering, preserving state")
    }
}

