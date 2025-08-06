import RuneLayout

/// A flexible space component that consumes remaining space along the main axis
///
/// Spacer is designed to push other components apart by consuming all available
/// space along the main axis of a flex container. It's particularly useful for:
/// - Creating space between components
/// - Pushing components to opposite ends of a container
/// - Distributing space evenly when multiple spacers are used
///
/// ## Usage
///
/// ```swift
/// // Push components to opposite ends
/// Box(flexDirection: .row, children: [
///     Text("Left"),
///     Spacer(),
///     Text("Right")
/// ])
///
/// // Center a component
/// Box(flexDirection: .column, children: [
///     Spacer(),
///     Text("Centered"),
///     Spacer()
/// ])
/// ```
///
/// ## Behavior
///
/// - **Main axis**: Spacer grows to fill available space (flexGrow = 1)
/// - **Cross axis**: Spacer takes minimal space (intrinsic size)
/// - **Multiple spacers**: Divide remaining space equally
/// - **No space**: Spacer collapses to zero size gracefully
/// - **Rendering**: Produces empty content (transparent)
///
/// ## Integration with Yoga
///
/// Spacer leverages Yoga's flexGrow property to consume remaining space:
/// - `flexGrow: 1.0` - Takes all available space
/// - `flexShrink: 1.0` - Can shrink when space is constrained
/// - `flexBasis: .auto` - Uses intrinsic size as starting point
public struct Spacer: Component {
    
    /// Initialize a new Spacer component
    public init() {
        // Spacer has no configuration - it's purely behavioral
    }
    
    /// Render the spacer within the given rectangle
    /// - Parameter rect: The layout rectangle to render within
    /// - Returns: Array of empty strings (spacer is transparent)
    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0 else {
            return []
        }
        
        // Spacer renders as empty lines - it's purely for layout
        return Array(repeating: "", count: rect.height)
    }
}

// MARK: - Spacer Layout Integration

extension Spacer {
    /// Calculate intrinsic size for layout purposes
    /// Spacer has minimal intrinsic size but grows via flexGrow
    internal var intrinsicSize: (width: Float, height: Float) {
        // Minimal intrinsic size - Spacer grows via flex properties
        // Use 1x1 as minimal size to ensure it's visible in cross-axis
        return (width: 1.0, height: 1.0)
    }
    
    /// Flex properties for Yoga layout integration
    internal var flexProperties: (grow: Float, shrink: Float, basis: Dimension) {
        return (
            grow: 1.0,      // Consume all available space
            shrink: 1.0,    // Can shrink when constrained
            basis: .auto    // Use intrinsic size as basis
        )
    }
}
