# Reconciler Developer Guide

## Overview

The `HybridReconciler` is the core intelligence behind RuneKit's line-diff rendering system. It implements sophisticated strategy selection, update coalescing, and adaptive performance optimization to minimize terminal I/O while maintaining visual fidelity.

## Architecture

### Core Responsibilities

1. **Strategy Selection** - Choose optimal rendering approach based on frame characteristics
2. **Update Coalescing** - Batch rapid updates to prevent flicker and reduce overhead
3. **Performance Adaptation** - Adjust behavior based on real-time performance metrics
4. **Backpressure Handling** - Gracefully handle terminal output limitations

### Key Components

```swift
public actor HybridReconciler {
    private let renderer: TerminalRenderer
    private let configuration: RenderConfiguration
    private var currentGrid: TerminalGrid?
    private var pendingUpdate: TerminalGrid?
    private var updateTask: Task<Void, Never>?
    
    // Performance tracking
    private var framesSinceFullRedraw: Int = 0
    private var lastFullRedrawTime: Date = .distantPast
    private var adaptiveQuality: Double = 1.0
    private var adaptiveThresholds: AdaptiveThresholds
}
```

## Strategy Selection Algorithm

### Decision Tree

```
┌─ forceFullRedraw? ──────────────────────────────────────────────────────────┐
│  ├─ YES → .fullRedraw                                                       │
│  └─ NO                                                                      │
│     ├─ currentGrid == nil? ─────────────────────────────────────────────────┤
│     │  ├─ YES → .fullRedraw                                                 │
│     │  └─ NO                                                                │
│     │     ├─ configuration.optimizationMode                                 │
│     │     │  ├─ .fullRedraw → .fullRedraw                                   │
│     │     │  ├─ .lineDiff → .deltaUpdate (if possible)                      │
│     │     │  └─ .automatic                                                  │
│     │     │     ├─ dimensions changed? ─────────────────────────────────────┤
│     │     │     │  ├─ YES → .fullRedraw                                     │
│     │     │     │  └─ NO                                                    │
│     │     │     │     ├─ changePercentage > 70%? ───────────────────────────┤
│     │     │     │     │  ├─ YES → .fullRedraw                               │
│     │     │     │     │  └─ NO                                              │
│     │     │     │     │     ├─ bytesSaved < threshold? ─────────────────────┤
│     │     │     │     │     │  ├─ YES → .fullRedraw                         │
│     │     │     │     │     │  └─ NO                                        │
│     │     │     │     │     │     ├─ scroll pattern detected? ──────────────┤
│     │     │     │     │     │     │  ├─ YES → .scrollOptimized              │
│     │     │     │     │     │     │  └─ NO → .deltaUpdate                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
private func determineOptimalStrategy(
    newGrid: TerminalGrid,
    currentGrid: TerminalGrid?,
    forceFullRedraw: Bool
) async -> RenderingStrategy {
    // Early exits
    if forceFullRedraw || currentGrid == nil {
        return .fullRedraw
    }
    
    // Respect explicit configuration
    switch configuration.optimizationMode {
    case .fullRedraw:
        return .fullRedraw
    case .lineDiff:
        return .deltaUpdate  // Force line-diff when possible
    case .automatic:
        break  // Continue with hybrid logic
    }
    
    guard let current = currentGrid else { return .fullRedraw }
    
    // Dimension changes require full redraw
    if newGrid.width != current.width || newGrid.height != current.height {
        return .fullRedraw
    }
    
    // Calculate change metrics
    let changedLines = newGrid.changedLines(comparedTo: current)
    let changePercentage = Double(changedLines.count) / Double(newGrid.height)
    
    // Estimate bytes for different strategies
    let fullRedrawBytes = estimateFullRedrawBytes(grid: newGrid)
    let deltaBytes = estimateDeltaBytes(changedLines: changedLines, grid: newGrid)
    let bytesSaved = Double(fullRedrawBytes - deltaBytes) / Double(fullRedrawBytes)
    
    // Decision logic
    if changePercentage > 0.7 {
        return .fullRedraw  // Too many changes
    }
    
    if bytesSaved < adaptiveThresholds.deltaThreshold {
        return .fullRedraw  // Not enough savings
    }
    
    // Check for scroll patterns
    if await detectScrollPattern(newGrid: newGrid, currentGrid: current) {
        return .scrollOptimized
    }
    
    return .deltaUpdate
}
```

## Update Coalescing

### Coalescing Window

The reconciler uses a 16ms coalescing window (60 FPS) to batch rapid updates:

```swift
private var coalescingWindow: TimeInterval = 0.016  // 16ms batching window

public func render(_ grid: TerminalGrid) async {
    pendingUpdate = grid
    
    // Cancel any pending update task
    updateTask?.cancel()
    
    // Schedule the actual update with coalescing window
    updateTask = Task {
        try? await Task.sleep(nanoseconds: UInt64(coalescingWindow * 1_000_000_000))
        await performCoalescedUpdate()
    }
}
```

### Rate Limiting

Additional rate limiting prevents terminal overload:

```swift
private func performCoalescedUpdate() async {
    let now = Date()
    let timeSinceLastRender = now.timeIntervalSince(lastRenderTime)
    let minInterval = 1.0 / configuration.performance.maxFrameRate
    
    if timeSinceLastRender < minInterval {
        let delay = minInterval - timeSinceLastRender
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    await performRender(pendingUpdate)
}
```

## Adaptive Performance

### Quality Metrics

The reconciler tracks rendering quality and adapts behavior:

```swift
private struct AdaptiveThresholds {
    var deltaThreshold: Double = 0.3      // Min bytes saved for delta
    var qualityThreshold: Double = 0.7    // Min quality for optimization
    var adaptationRate: Double = 0.1      // How quickly to adapt
}

private func updateAdaptiveQuality(from stats: RenderStats) {
    let currentQuality = calculateQuality(from: stats)
    
    // Exponential moving average
    adaptiveQuality = adaptiveQuality * (1 - adaptiveThresholds.adaptationRate) +
                     currentQuality * adaptiveThresholds.adaptationRate
    
    // Adjust thresholds based on quality
    if adaptiveQuality < 0.7 {
        adaptiveThresholds.deltaThreshold += 0.05  // Be more conservative
    } else if adaptiveQuality > 0.9 {
        adaptiveThresholds.deltaThreshold -= 0.02  // Be more aggressive
    }
}
```

### Forced Full Redraws

Periodic full redraws ensure visual consistency:

```swift
private let maxFramesBetweenFullRedraws = 100
private let maxTimeBetweenFullRedraws: TimeInterval = 30.0

private func shouldForceFullRedraw() -> Bool {
    let timeSinceLastFullRedraw = Date().timeIntervalSince(lastFullRedrawTime)
    
    return framesSinceFullRedraw >= maxFramesBetweenFullRedraws ||
           timeSinceLastFullRedraw >= maxTimeBetweenFullRedraws ||
           adaptiveQuality < 0.7
}
```

## Performance Estimation

### Byte Estimation

The reconciler estimates bytes for different strategies:

```swift
private func estimateFullRedrawBytes(grid: TerminalGrid) -> Int {
    // Rough estimate: each cell is ~1-3 bytes on average
    // Plus ANSI sequences for cursor management and clearing
    let contentBytes = grid.width * grid.height * 2
    let ansiOverhead = 50  // Cursor hide/show, clear screen, etc.
    return contentBytes + ansiOverhead
}

private func estimateDeltaBytes(changedLines: [Int], grid: TerminalGrid) -> Int {
    var totalBytes = 0
    
    for lineIndex in changedLines {
        // Cursor positioning: ESC[row;colH (average 8 bytes)
        totalBytes += 8
        
        // Line clear: ESC[2K (4 bytes)
        totalBytes += 4
        
        // Line content (estimate based on grid width)
        totalBytes += grid.width * 2
    }
    
    return totalBytes
}
```

### Scroll Detection

Basic scroll pattern detection for future optimization:

```swift
private func detectScrollPattern(
    newGrid: TerminalGrid,
    currentGrid: TerminalGrid
) async -> Bool {
    // Simplified scroll detection
    // TODO: Implement sophisticated scroll pattern recognition
    
    // Check if lines have shifted vertically
    let changedLines = newGrid.changedLines(comparedTo: currentGrid)
    
    // If most lines changed but content is similar, might be a scroll
    if changedLines.count > newGrid.height / 2 {
        // More sophisticated analysis would go here
        return false  // Disabled for now
    }
    
    return false
}
```

## Error Handling and Resilience

### Graceful Degradation

The reconciler handles errors gracefully:

```swift
private func performRender(_ grid: TerminalGrid?) async {
    guard let grid = grid else { return }
    
    do {
        let stats = await renderer.render(grid, strategy: strategy, previousGrid: currentGrid)
        await recordPerformance(stats)
        
        // Update state on success
        currentGrid = grid
        lastRenderTime = Date()
        
        if strategy == .fullRedraw {
            framesSinceFullRedraw = 0
            lastFullRedrawTime = Date()
        } else {
            framesSinceFullRedraw += 1
        }
        
    } catch {
        // On error, fall back to full redraw
        let fallbackStats = await renderer.render(grid, forceFullRedraw: true)
        await recordPerformance(fallbackStats)
        
        // Reset state
        currentGrid = grid
        framesSinceFullRedraw = 0
        lastFullRedrawTime = Date()
    }
}
```

### Backpressure Handling

When the terminal can't keep up, the reconciler drops frames:

```swift
private func handleBackpressure() async {
    // If we're falling behind, drop intermediate frames
    if let metrics = await performanceMetrics.getCurrentCounters(),
       metrics.renderDuration > coalescingWindow * 2 {
        
        // Drop this frame and wait for the next one
        await performanceMetrics.recordDroppedFrame()
        return
    }
}
```

## Testing Considerations

### Deterministic Testing

For testing, use immediate rendering to avoid timing issues:

```swift
public func renderFrameImmediate(_ frame: TerminalRenderer.Frame) async {
    let grid = frame.toGrid()
    await performRender(grid)
}
```

### Performance Testing

Test different scenarios to validate strategy selection:

```swift
// Test small changes (should use delta)
let smallChange = modifyLines(originalFrame, lines: [0, 1])
// Verify strategy == .deltaUpdate

// Test large changes (should use full redraw)
let largeChange = modifyLines(originalFrame, lines: Array(0..<50))
// Verify strategy == .fullRedraw

// Test dimension changes (should use full redraw)
let resizedFrame = resizeFrame(originalFrame, newWidth: 120)
// Verify strategy == .fullRedraw
```

## Configuration Tuning

### Performance Profiles

Different use cases require different tuning:

```swift
// High-frequency updates (games, animations)
let gameConfig = RenderConfiguration(
    optimizationMode: .lineDiff,
    performance: PerformanceTuning(
        maxLinesForDiff: 2000,
        minEfficiencyThreshold: 0.2,  // More aggressive
        maxFrameRate: 120.0
    )
)

// Text editors (moderate updates)
let editorConfig = RenderConfiguration(
    optimizationMode: .automatic,
    performance: PerformanceTuning(
        maxLinesForDiff: 1000,
        minEfficiencyThreshold: 0.4,
        maxFrameRate: 60.0
    )
)

// Status displays (infrequent updates)
let statusConfig = RenderConfiguration(
    optimizationMode: .lineDiff,
    performance: PerformanceTuning(
        maxLinesForDiff: 500,
        minEfficiencyThreshold: 0.6,  // More conservative
        maxFrameRate: 30.0
    )
)
```

## Future Enhancements

### Scroll Optimization

Planned enhancements for scroll pattern detection:

1. **Line similarity analysis** - Compare line content for shifts
2. **Scroll region detection** - Identify scrollable areas
3. **ANSI scroll sequences** - Use terminal scroll commands

### Character-Level Diffs

Potential for sub-line optimization:

1. **Horizontal diffing** - Find changed regions within lines
2. **Cursor positioning** - Move to specific columns
3. **Partial line updates** - Update only changed portions

### Predictive Optimization

Machine learning for strategy selection:

1. **Pattern recognition** - Learn from usage patterns
2. **Predictive modeling** - Anticipate optimal strategies
3. **Dynamic adaptation** - Adjust to terminal characteristics

## Debugging

### Debug Logging

Enable detailed logging for troubleshooting:

```swift
let config = RenderConfiguration(enableDebugLogging: true)
```

### Performance Analysis

Monitor strategy effectiveness:

```swift
let summary = await reconciler.getPerformanceSummary()
print("Strategy distribution:")
for (strategy, count) in summary.strategyDistribution {
    print("  \(strategy): \(count) frames")
}
```

### Visual Debugging

Compare strategies visually:

```swift
// Force different strategies for comparison
await reconciler.renderFrameImmediate(frame)  // Uses optimal strategy
await reconciler.forceFullRedraw()           // Forces full redraw
```
