# FrameBuffer API Reference

## Overview

`FrameBuffer` is the primary interface for efficient terminal rendering in RuneKit. It provides line-diff optimization, update coalescing, and performance monitoring for responsive terminal UIs.

## Class Definition

```swift
public final class FrameBuffer: Sendable
```

## Initialization

### `init(output:configuration:)`

Creates a new frame buffer with the specified output and configuration.

```swift
public init(
    output: FileHandle,
    configuration: RenderConfiguration = .default
)
```

**Parameters:**
- `output`: File handle for terminal output (typically `FileHandle.standardOutput`)
- `configuration`: Rendering configuration (defaults to line-diff optimization)

**Example:**
```swift
let frameBuffer = FrameBuffer(
    output: FileHandle.standardOutput,
    configuration: .highPerformance
)
```

## Core Rendering Methods

### `renderFrame(_:)`

Renders a frame with automatic optimization and update coalescing.

```swift
public func renderFrame(_ frame: TerminalRenderer.Frame) async
```

**Parameters:**
- `frame`: The frame to render

**Behavior:**
- Automatically chooses optimal rendering strategy
- Coalesces rapid updates (16ms window)
- Applies rate limiting and backpressure handling

**Example:**
```swift
let frame = TerminalRenderer.Frame(
    lines: ["Hello", "World"],
    width: 10,
    height: 2
)
await frameBuffer.renderFrame(frame)
```

### `renderFrameImmediate(_:)`

Renders a frame immediately, bypassing coalescing and rate limiting.

```swift
public func renderFrameImmediate(_ frame: TerminalRenderer.Frame) async
```

**Parameters:**
- `frame`: The frame to render immediately

**Use Cases:**
- Time-critical updates
- Final frame before application exit
- Testing and debugging

**Example:**
```swift
// Render immediately without coalescing
await frameBuffer.renderFrameImmediate(criticalFrame)
```

## Control Methods

### `clear()`

Clears the terminal and resets the frame buffer state.

```swift
public func clear() async
```

**Behavior:**
- Clears terminal screen
- Resets cursor to home position
- Shows cursor if hidden
- Resets internal state

**Example:**
```swift
await frameBuffer.clear()
```

### `forceFullRedraw()`

Forces a full redraw of the current frame, bypassing line-diff optimization.

```swift
public func forceFullRedraw() async
```

**Use Cases:**
- Terminal corruption recovery
- Debugging rendering issues
- Performance testing

**Example:**
```swift
// Force full redraw after terminal resize
await frameBuffer.forceFullRedraw()
```

### `restoreCursor()`

Restores cursor visibility without clearing the screen.

```swift
public func restoreCursor() async
```

**Example:**
```swift
// Ensure cursor is visible before exit
await frameBuffer.restoreCursor()
```

## Performance and Monitoring

### `getMetrics()`

Returns current performance metrics for the rendering session.

```swift
public func getMetrics() async -> PerformanceMetrics.Counters
```

**Returns:** Current performance counters including:
- `bytesWritten`: Total bytes written to terminal
- `linesChanged`: Number of lines rewritten
- `totalLines`: Total lines in current frame
- `framesDropped`: Frames dropped due to backpressure
- `renderMode`: Current rendering strategy
- `renderDuration`: Time spent rendering

**Example:**
```swift
let metrics = await frameBuffer.getMetrics()
print("Efficiency: \(metrics.efficiency)%")
print("Bytes written: \(metrics.bytesWritten)")
```

### `getPerformanceSummary()`

Returns aggregated performance metrics over recent frames.

```swift
public func getPerformanceSummary() async -> PerformanceMetrics.Summary
```

**Returns:** Performance summary including:
- Average metrics over recent frames
- Strategy distribution
- Performance trends

**Example:**
```swift
let summary = await frameBuffer.getPerformanceSummary()
print("Average render time: \(summary.averageRenderTime)ms")
print("Line-diff usage: \(summary.lineDiffPercentage)%")
```

### `waitForPendingUpdates()`

Waits for all pending coalesced updates to complete.

```swift
public func waitForPendingUpdates() async
```

**Use Cases:**
- Testing and verification
- Ensuring updates complete before exit
- Synchronization points

**Example:**
```swift
await frameBuffer.renderFrame(frame)
await frameBuffer.waitForPendingUpdates()
// All updates are now complete
```

## Configuration

### RenderConfiguration

Controls frame buffer behavior and optimization settings.

```swift
public struct RenderConfiguration: Sendable {
    public enum OptimizationMode: String, CaseIterable {
        case fullRedraw = "full_redraw"    // Always full redraw
        case lineDiff = "line_diff"        // Always line-diff
        case automatic = "automatic"       // Intelligent selection
    }
    
    public let optimizationMode: OptimizationMode
    public let performance: PerformanceTuning
    public let enableMetrics: Bool
    public let enableDebugLogging: Bool
    public let hideCursorDuringRender: Bool
    public let useAlternateScreen: Bool
}
```

### Predefined Configurations

```swift
// Balanced performance (default)
let config = RenderConfiguration.default

// Maximum performance
let config = RenderConfiguration.highPerformance

// Conservative settings
let config = RenderConfiguration.conservative

// Environment-based configuration
let config = RenderConfiguration.fromEnvironment()
```

### Performance Tuning

```swift
public struct PerformanceTuning: Sendable {
    public let maxLinesForDiff: Int           // Max lines for line-diff
    public let minEfficiencyThreshold: Double // Min efficiency threshold
    public let maxFrameRate: Double           // Rate limiting
    public let writeBufferSize: Int           // Output buffer size
}
```

## Performance Metrics

### Counters

```swift
public struct Counters: Sendable {
    public let bytesWritten: Int
    public let linesChanged: Int
    public let totalLines: Int
    public let framesDropped: Int
    public let renderMode: RenderMode
    public let renderDuration: TimeInterval
    public let timestamp: Date
    
    // Computed properties
    public var efficiency: Double           // Percentage of lines unchanged
    public var bytesPerLine: Double        // Average bytes per line
    public var linesPerSecond: Double      // Rendering throughput
}
```

### Summary

```swift
public struct Summary: Sendable {
    public let averageMetrics: Counters
    public let totalFrames: Int
    public let timespan: TimeInterval
    public let strategyDistribution: [RenderMode: Int]
    
    // Computed properties
    public var averageRenderTime: Double   // Average render duration
    public var lineDiffPercentage: Double  // Percentage using line-diff
    public var throughput: Double          // Frames per second
}
```

## Error Handling

Frame buffer operations are designed to be resilient:

- **Write errors**: Silently handled to prevent crashes
- **Invalid frames**: Gracefully handled with fallbacks
- **Resource exhaustion**: Automatic backpressure and frame dropping

## Thread Safety

All `FrameBuffer` methods are thread-safe and can be called from any async context:

```swift
// Safe to call from multiple tasks
Task {
    await frameBuffer.renderFrame(frame1)
}

Task {
    await frameBuffer.renderFrame(frame2)
}
```

## Memory Management

Frame buffer automatically manages memory:

- **Bounded history**: Keeps last 100 frames of metrics
- **Automatic cleanup**: Releases resources on deinitialization
- **Grid reuse**: Efficiently reuses terminal grid structures

## Best Practices

### Initialization

```swift
// Use appropriate configuration for your use case
let config = myApp.isDebugMode ? .conservative : .highPerformance
let frameBuffer = FrameBuffer(output: FileHandle.standardOutput, configuration: config)
```

### Rendering

```swift
// Use regular rendering for most updates
await frameBuffer.renderFrame(frame)

// Use immediate rendering sparingly
if isTimeCritical {
    await frameBuffer.renderFrameImmediate(frame)
}
```

### Cleanup

```swift
// Always clean up before exit
defer {
    Task {
        await frameBuffer.clear()
        await frameBuffer.restoreCursor()
    }
}
```

### Performance Monitoring

```swift
// Monitor performance periodically
if frameCount % 100 == 0 {
    let metrics = await frameBuffer.getMetrics()
    if metrics.efficiency < 0.5 {
        // Consider adjusting configuration
    }
}
```

## Environment Variables

Configure frame buffer behavior via environment variables:

- `RUNE_RENDER_MODE`: Set optimization mode (`full_redraw`, `line_diff`, `automatic`)
- `RUNE_MAX_FRAME_RATE`: Set maximum frame rate (default: 60)
- `RUNE_ENABLE_METRICS`: Enable performance metrics (`true`/`false`)
- `RUNE_DEBUG_LOGGING`: Enable debug logging (`true`/`false`)

## Examples

### Basic Usage

```swift
import RuneRenderer

let frameBuffer = FrameBuffer(output: FileHandle.standardOutput)

let frame = TerminalRenderer.Frame(
    lines: ["┌─────────┐", "│ Hello! │", "└─────────┘"],
    width: 11,
    height: 3
)

await frameBuffer.renderFrame(frame)
await frameBuffer.clear()
```

### Performance Monitoring

```swift
let frameBuffer = FrameBuffer(
    output: FileHandle.standardOutput,
    configuration: RenderConfiguration(enableMetrics: true)
)

// Render some frames...
for i in 0..<100 {
    await frameBuffer.renderFrame(generateFrame(i))
}

// Check performance
let summary = await frameBuffer.getPerformanceSummary()
print("Average efficiency: \(summary.averageMetrics.efficiency)%")
print("Line-diff usage: \(summary.lineDiffPercentage)%")
```

### Custom Configuration

```swift
let config = RenderConfiguration(
    optimizationMode: .lineDiff,
    performance: PerformanceTuning(
        maxLinesForDiff: 1000,
        minEfficiencyThreshold: 0.4,
        maxFrameRate: 120.0
    ),
    enableMetrics: true,
    enableDebugLogging: false
)

let frameBuffer = FrameBuffer(output: FileHandle.standardOutput, configuration: config)
```
