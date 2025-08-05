# Console Capture & Log Lane

RuneKit's console capture system prevents random `print()` statements and stderr output from corrupting your terminal UI while preserving all logs in a dedicated area above your live application region.

## Overview

When building terminal applications, one of the biggest challenges is handling log output that can interfere with your carefully crafted UI. RuneKit solves this by:

- **Capturing stdout/stderr**: Redirects all console output to internal buffers
- **Displaying logs above UI**: Shows captured logs in a dedicated area above your live region
- **Preserving order**: Maintains chronological order of all log messages
- **Source distinction**: Differentiates between stdout and stderr output
- **Optional toggle**: Can be enabled/disabled via configuration

## Key Features

- **Thread-safe capture**: Actor-based implementation ensures safe concurrent access
- **Background processing**: Non-blocking pipe readers with line buffering
- **Automatic formatting**: Timestamps, source indicators, and ANSI color support
- **Buffer management**: Configurable buffer size with automatic trimming
- **Environment control**: Configure via `RUNE_CONSOLE_CAPTURE` environment variable
- **Integration**: Seamlessly works with FrameBuffer and rendering system

## Basic Usage

### Enabling Console Capture

```swift
import RuneKit

// Enable console capture in configuration
let config = RenderConfiguration(enableConsoleCapture: true)
let frameBuffer = FrameBuffer(configuration: config)

// Create your application UI
let appFrame = TerminalRenderer.Frame(
    lines: [
        "┌─ My Application ─┐",
        "│ Status: Running  │",
        "│ Logs above ↑     │",
        "└──────────────────┘"
    ],
    width: 20,
    height: 4
)

// Render the frame - console capture starts automatically
await frameBuffer.renderFrame(appFrame)

// Now all print() calls appear above the live region
print("🔍 Application started")
print("📊 Processing data...")
print("⚠️ Warning: Low memory")

// stderr also appears above (in red if colors enabled)
fputs("❌ Error: Connection failed\n", stderr)

// Update your UI - logs remain above
let updatedFrame = TerminalRenderer.Frame(
    lines: [
        "┌─ My Application ─┐",
        "│ Status: Updated  │",
        "│ Logs above ↑     │",
        "└──────────────────┘"
    ],
    width: 20,
    height: 4
)

await frameBuffer.renderFrame(updatedFrame)

// Clean up when done
await frameBuffer.clear()
```

### Environment Variable Configuration

Users can control console capture without code changes:

```bash
# Enable console capture
export RUNE_CONSOLE_CAPTURE=true
./my-runekit-app

# Disable console capture
export RUNE_CONSOLE_CAPTURE=false
./my-runekit-app

# Use numeric values
export RUNE_CONSOLE_CAPTURE=1  # Enable
export RUNE_CONSOLE_CAPTURE=0  # Disable
```

In your application:

```swift
// Automatically respects RUNE_CONSOLE_CAPTURE environment variable
let config = RenderConfiguration.fromEnvironment()
let frameBuffer = FrameBuffer(configuration: config)
```

## Advanced Usage

### Direct Console Capture

You can use the console capture system independently:

```swift
import RuneRenderer

let capture = ConsoleCapture()
await capture.startCapture()

// All print() calls are now captured
print("This will be captured")
print("So will this")

// Get captured logs
let logs = await capture.getBufferedLogs()
for log in logs {
    print("Captured: \(log.content) from \(log.source) at \(log.timestamp)")
}

await capture.stopCapture()
```

### Custom Log Formatting

Use LogLane for custom log formatting:

```swift
import RuneRenderer

// Create custom log lane configuration
let config = LogLane.Configuration(
    maxDisplayLines: 15,
    showTimestamps: true,
    timestampFormat: .timeWithMs,
    useColors: true
)

let logLane = LogLane(configuration: config)

// Format captured logs
let logs = await capture.getBufferedLogs()
let formattedLines = logLane.formatLogs(logs, terminalWidth: 80)

// Display formatted logs
for line in formattedLines {
    print(line)
}
```

### Predefined Configurations

LogLane provides several predefined configurations:

```swift
// Debug configuration - verbose with millisecond timestamps
let debugLogLane = LogLane(configuration: .debug)

// Minimal configuration - compact for production
let minimalLogLane = LogLane(configuration: .minimal)

// Compact configuration - relative timestamps
let compactLogLane = LogLane(configuration: .compact)
```

## Configuration Options

### RenderConfiguration

```swift
let config = RenderConfiguration(
    enableConsoleCapture: true,     // Enable/disable console capture
    enableDebugLogging: false       // Enable debug logging for capture system
)
```

### ConsoleCapture

```swift
let capture = ConsoleCapture(
    maxBufferSize: 1000,           // Maximum log lines to buffer
    enableDebugLogging: false      // Debug logging for capture system
)
```

### LogLane.Configuration

```swift
let config = LogLane.Configuration(
    maxDisplayLines: 10,           // Maximum lines to display
    showTimestamps: true,          // Show timestamps
    showSourceIndicators: true,    // Show stdout/stderr indicators
    timestampFormat: .time,        // Timestamp format
    stdoutPrefix: "│",            // Prefix for stdout logs
    stderrPrefix: "⚠",            // Prefix for stderr logs
    useColors: true               // Use ANSI colors
)
```

## Timestamp Formats

LogLane supports several timestamp formats:

- `.none` - No timestamps
- `.time` - HH:mm:ss format
- `.timeWithMs` - HH:mm:ss.SSS format
- `.relative` - +1.234s relative to start

## Visual Output

With console capture enabled, your terminal output looks like this:

```
[10:30:15] │ Application started
[10:30:16] │ Processing data...
[10:30:17] ⚠ Warning: Low memory
[10:30:18] ⚠ Error: Connection failed
[10:30:19] │ Recovery successful
────────────────────────────────────────
┌─ My Application ─┐
│ Status: Running  │
│ Logs above ↑     │
└──────────────────┘
```

## Error Handling

Console capture is designed to be robust:

- **Safe start/stop**: Multiple calls to start/stop are safe
- **Automatic cleanup**: Resources are cleaned up on shutdown
- **Error isolation**: Capture errors don't affect your application
- **Fallback behavior**: Gracefully handles unsupported terminals

## Performance Considerations

- **Minimal overhead**: Background readers use efficient buffering
- **Memory management**: Automatic buffer trimming prevents memory leaks
- **Non-blocking**: Capture operations don't block your application
- **Configurable limits**: Adjust buffer size based on your needs

## Integration with Other Features

Console capture works seamlessly with other RuneKit features:

- **Alternate Screen Buffer**: Logs are preserved when entering/leaving alternate screen
- **Line Diff Rendering**: Efficient updates when logs change
- **Performance Metrics**: Capture overhead is tracked in performance metrics
- **Debug Mode**: Enhanced logging when debug mode is enabled

## Troubleshooting

### Console capture not working

1. Verify it's enabled in configuration:
   ```swift
   let config = RenderConfiguration(enableConsoleCapture: true)
   ```

2. Check environment variable:
   ```bash
   echo $RUNE_CONSOLE_CAPTURE
   ```

3. Ensure you're calling `renderFrame()`:
   ```swift
   await frameBuffer.renderFrame(frame)  // This starts capture
   ```

### Logs not appearing

1. Give capture time to initialize:
   ```swift
   await frameBuffer.renderFrame(frame)
   try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
   print("This should appear above")
   ```

2. Check if capture is active:
   ```swift
   let isActive = await frameBuffer.isConsoleCaptureActive()
   print("Capture active: \(isActive)")
   ```

### Performance issues

1. Reduce buffer size:
   ```swift
   let capture = ConsoleCapture(maxBufferSize: 100)
   ```

2. Disable timestamps:
   ```swift
   let logLane = LogLane(showTimestamps: false)
   ```

3. Use minimal configuration:
   ```swift
   let logLane = LogLane(configuration: .minimal)
   ```

## Examples

See `Sources/RuneCLI/RuneCLI.swift` for a complete working example of console capture in action.

The demo shows:
- Basic console capture setup
- Mixed stdout/stderr output
- Live UI updates with logs above
- Environment variable configuration
- Comparison with capture disabled
