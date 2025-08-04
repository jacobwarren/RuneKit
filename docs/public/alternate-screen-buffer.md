# Alternate Screen Buffer Support (RUNE-22)

RuneKit provides optional alternate screen buffer support, allowing applications to create full-screen terminal interfaces that preserve and restore the user's previous terminal session when exiting.

## Overview

The alternate screen buffer is a terminal feature that allows applications to temporarily take over the entire terminal display. When the application exits, the previous terminal content is automatically restored. This is the same mechanism used by applications like `vim`, `less`, `htop`, and other full-screen terminal applications.

## Key Features

- **Automatic Management**: Enter and leave alternate screen automatically based on configuration
- **Environment Variable Support**: Configure via `RUNE_ALT_SCREEN` environment variable
- **Graceful Fallback**: Works on terminals that don't support alternate screen
- **Integration**: Seamlessly integrates with RuneKit's rendering system
- **Thread-Safe**: Actor-based implementation ensures safe concurrent access

## Basic Usage

### Enabling Alternate Screen Buffer

```swift
import RuneKit

// Create configuration with alternate screen enabled
let config = RenderConfiguration(useAlternateScreen: true)
let frameBuffer = FrameBuffer(configuration: config)

// Render your application
let frame = TerminalRenderer.Frame(
    lines: ["Welcome to my app!", "Press any key to exit..."],
    width: 20,
    height: 2
)

await frameBuffer.renderFrame(frame)

// When you're done, clear to exit alternate screen
await frameBuffer.clear()
```

### Environment Variable Configuration

Users can control alternate screen behavior without code changes:

```bash
# Enable alternate screen buffer
export RUNE_ALT_SCREEN=true
./my-runekit-app

# Disable alternate screen buffer
export RUNE_ALT_SCREEN=false
./my-runekit-app

# Use numeric values
export RUNE_ALT_SCREEN=1  # Enable
export RUNE_ALT_SCREEN=0  # Disable
```

In your application:

```swift
// Automatically respects RUNE_ALT_SCREEN environment variable
let config = RenderConfiguration.fromEnvironment()
let frameBuffer = FrameBuffer(configuration: config)
```

## ANSI Sequences

RuneKit uses standard ANSI escape sequences for alternate screen buffer control:

- **Enter**: `ESC[?1049h` - Switch to alternate screen buffer
- **Leave**: `ESC[?1049l` - Switch back to main screen buffer

These sequences are widely supported by modern terminal emulators.

## Fallback Behavior

When alternate screen buffer is disabled or not supported:

- **Enter**: No special action (content renders to main buffer)
- **Leave**: Normal screen clearing if needed
- **Compatibility**: Ensures your application works on all terminals

## Integration with FrameBuffer

The alternate screen buffer integrates seamlessly with RuneKit's rendering system:

```swift
let frameBuffer = FrameBuffer(configuration: .init(useAlternateScreen: true))

// First render automatically enters alternate screen
await frameBuffer.renderFrame(firstFrame)

// Subsequent renders stay in alternate screen
await frameBuffer.renderFrame(secondFrame)
await frameBuffer.renderFrame(thirdFrame)

// Clear automatically leaves alternate screen
await frameBuffer.clear()
```

## Best Practices

### 1. Always Clean Up

Ensure you properly exit the alternate screen buffer:

```swift
let frameBuffer = FrameBuffer(configuration: .init(useAlternateScreen: true))

defer {
    Task {
        await frameBuffer.clear()
    }
}

// Your application logic here
await frameBuffer.renderFrame(frame)
```

### 2. Handle Signals

For robust applications, handle termination signals:

```swift
import Foundation

// Set up signal handling
signal(SIGINT) { _ in
    Task {
        await frameBuffer.clear()
        exit(0)
    }
}

signal(SIGTERM) { _ in
    Task {
        await frameBuffer.clear()
        exit(0)
    }
}
```

### 3. Respect User Preferences

Always support the environment variable override:

```swift
// Good: Respects user's RUNE_ALT_SCREEN setting
let config = RenderConfiguration.fromEnvironment()

// Less ideal: Forces alternate screen regardless of user preference
let config = RenderConfiguration(useAlternateScreen: true)
```

## Configuration Options

### RenderConfiguration

```swift
let config = RenderConfiguration(
    optimizationMode: .lineDiff,
    performance: .default,
    enableMetrics: true,
    enableDebugLogging: false,
    hideCursorDuringRender: true,
    useAlternateScreen: true  // Enable alternate screen buffer
)
```

### Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `RUNE_ALT_SCREEN` | `true`, `1` | Enable alternate screen buffer |
| `RUNE_ALT_SCREEN` | `false`, `0` | Disable alternate screen buffer |
| `RUNE_ALT_SCREEN` | (unset) | Use default (disabled) |

## Terminal Compatibility

### Supported Terminals

- **macOS**: Terminal.app, iTerm2, Alacritty, Kitty
- **Linux**: GNOME Terminal, Konsole, xterm, Alacritty, Kitty
- **Windows**: Windows Terminal, ConEmu (with proper ANSI support)

### Legacy Terminals

For terminals that don't support alternate screen buffer:
- Sequences are safely ignored
- Application continues to work normally
- Content renders to main terminal buffer

## Examples

### Simple Full-Screen App

```swift
import RuneKit

@main
struct MyApp {
    static func main() async {
        let config = RenderConfiguration.fromEnvironment()
        let frameBuffer = FrameBuffer(configuration: config)
        
        let frame = TerminalRenderer.Frame(
            lines: [
                "┌─ My Application ─┐",
                "│ Hello, World!    │",
                "│ Press Ctrl+C     │",
                "└──────────────────┘"
            ],
            width: 20,
            height: 4
        )
        
        await frameBuffer.renderFrame(frame)
        
        // Wait for user input (simplified)
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        await frameBuffer.clear()
    }
}
```

### Interactive Application

```swift
import RuneKit

class InteractiveApp {
    private let frameBuffer: FrameBuffer
    
    init() {
        let config = RenderConfiguration(useAlternateScreen: true)
        self.frameBuffer = FrameBuffer(configuration: config)
    }
    
    func run() async {
        await showWelcomeScreen()
        await showMainInterface()
        await cleanup()
    }
    
    private func showWelcomeScreen() async {
        let frame = createWelcomeFrame()
        await frameBuffer.renderFrame(frame)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func showMainInterface() async {
        let frame = createMainFrame()
        await frameBuffer.renderFrame(frame)
        // Handle user interaction...
    }
    
    private func cleanup() async {
        await frameBuffer.clear()
    }
    
    // Frame creation methods...
}
```

## Testing

RuneKit provides comprehensive testing support for alternate screen buffer functionality:

```swift
import Testing
@testable import RuneRenderer

@Test("Alternate screen buffer integration")
func testAlternateScreenBuffer() async {
    let pipe = Pipe()
    let output = pipe.fileHandleForWriting
    let input = pipe.fileHandleForReading
    
    let config = RenderConfiguration(useAlternateScreen: true)
    let frameBuffer = FrameBuffer(output: output, configuration: config)
    
    let frame = TerminalRenderer.Frame(
        lines: ["Test"],
        width: 4,
        height: 1
    )
    
    await frameBuffer.renderFrame(frame)
    await frameBuffer.clear()
    output.closeFile()
    
    let data = input.readDataToEndOfFile()
    let result = String(data: data, encoding: .utf8) ?? ""
    
    #expect(result.contains("\u{001B}[?1049h"), "Should enter alternate screen")
    #expect(result.contains("\u{001B}[?1049l"), "Should leave alternate screen")
    
    input.closeFile()
}
```

## See Also

- [Frame Buffer Documentation](frame-buffer.md)
- [Line Diff Rendering](line-diff-rendering.md)
- [Performance Guide](../dev/performance.md)
