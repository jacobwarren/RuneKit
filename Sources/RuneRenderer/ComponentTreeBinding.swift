import Foundation

/// Bind a per-task recorder closure that forwards identity-path visits to the reconciler
public enum ComponentTreeBinding {
    @discardableResult
    public static func bindDuringRender<T>(tree: ComponentTreeReconciler, perform: () -> T) -> T {
        RuntimeStateContext.$recorder.withValue({ path in
            Task {
                await tree.visitNode(path: path)
            }
        }, operation: {
            perform()
        })
    }
}
