import Foundation
import RuneKit

/// Demo for RUNE-25: Render handle control methods
///
/// This demo showcases the new render handle control methods including
/// unmount(), clear(), rerender(), and waitUntilExit() with concurrency safety.
public enum RUNE25Demo {
    /// Run the RUNE-25 demonstration
    public static func run() async {
        print("🎯 RUNE-25 Demo: Render Handle Control Methods")
        print("==============================================")
        print("")

        await demonstrateBasicHandleControl()
        await demonstrateRerenderFunctionality()
        await demonstrateWaitUntilExit()
        await demonstrateConcurrencySafety()

        print("✅ RUNE-25 Demo completed successfully!")
        print("")
    }

    /// Demonstrate basic handle control operations
    private static func demonstrateBasicHandleControl() async {
        print("Demo 1: Basic handle control (unmount, clear)")
        print("---------------------------------------------")

        // Create a render handle
        let welcomeView = Text("Welcome to RUNE-25 Handle Control!")
        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(welcomeView, options: options)
        print("✓ Render handle created")

        // Check initial state
        let isActive = await handle.isActive
        print("✓ Handle active: \(isActive)")

        // Test clear operation
        await handle.clear()
        print("✓ Screen cleared")

        // Test unmount operation
        await handle.unmount()
        let isActiveAfterUnmount = await handle.isActive
        print("✓ Handle unmounted, active: \(isActiveAfterUnmount)")

        // Test idempotent unmount
        await handle.unmount()
        print("✓ Idempotent unmount completed")

        print("")
    }

    /// Demonstrate rerender functionality
    private static func demonstrateRerenderFunctionality() async {
        print("Demo 2: Rerender functionality")
        print("------------------------------")

        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(Text("Initial content"), options: options)
        print("✓ Initial render completed")

        // Rerender with new content
        await handle.rerender(Text("Updated content"))
        print("✓ Rerender with new content")

        // Multiple rapid rerenders
        for i in 1...5 {
            await handle.rerender(Text("Rapid update \(i)"))
        }
        print("✓ Multiple rapid rerenders completed")

        // Clean up
        await handle.unmount()
        print("✓ Handle unmounted")

        print("")
    }

    /// Demonstrate waitUntilExit functionality
    private static func demonstrateWaitUntilExit() async {
        print("Demo 3: waitUntilExit functionality")
        print("-----------------------------------")

        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(Text("Waiting for exit..."), options: options)
        print("✓ Render handle created")

        // Start waiting for exit in background
        let waitTask = Task {
            await handle.waitUntilExit()
            return "Exit resolved!"
        }
        print("✓ Started waiting for exit")

        // Simulate some work
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        print("✓ Simulated work completed")

        // Unmount to trigger exit
        await handle.unmount()
        print("✓ Handle unmounted")

        // Wait for the exit task to complete
        let result = await waitTask.value
        print("✓ \(result)")

        print("")
    }

    /// Demonstrate concurrency safety
    private static func demonstrateConcurrencySafety() async {
        print("Demo 4: Concurrency safety")
        print("--------------------------")

        let options = RenderOptions(
            exitOnCtrlC: false,
            patchConsole: false,
            useAltScreen: false,
            fpsCap: 30.0
        )

        let handle = await render(Text("Concurrency test"), options: options)
        print("✓ Render handle created")

        // Perform multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Multiple rerender operations
            for i in 0..<3 {
                group.addTask {
                    await handle.rerender(Text("Concurrent content \(i)"))
                }
            }

            // Multiple clear operations
            for _ in 0..<2 {
                group.addTask {
                    await handle.clear()
                }
            }

            // Check status operations
            for _ in 0..<2 {
                group.addTask {
                    _ = await handle.isActive
                }
            }
        }
        print("✓ Concurrent operations completed")

        // Test multiple waitUntilExit calls
        let waitTasks = (0..<3).map { _ in
            Task {
                await handle.waitUntilExit()
                return true
            }
        }
        print("✓ Multiple waitUntilExit calls started")

        // Unmount to resolve all waits
        await handle.unmount()
        print("✓ Handle unmounted")

        // Verify all waits resolved
        let results = await withTaskGroup(of: Bool.self) { group in
            for task in waitTasks {
                group.addTask {
                    await task.value
                }
            }

            var allResolved = true
            for await result in group {
                allResolved = allResolved && result
            }
            return allResolved
        }
        print("✓ All waitUntilExit calls resolved: \(results)")

        print("")
    }
}
