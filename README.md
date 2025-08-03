# RuneKit

A Swift library for terminal user interfaces inspired by Ink (React for CLIs).

## Overview

RuneKit provides a declarative way to build terminal-based user interfaces using Swift. It combines the power of Swift's type system with efficient terminal rendering to create production-quality CLI applications.

## Architecture

RuneKit is built on four core subsystems:

### 1. Text Engine (`RuneANSI` + `RuneUnicode`)
- **RuneANSI**: ANSI escape sequence parsing and tokenization
- **RuneUnicode**: Accurate Unicode width calculations for emoji, CJK, and complex scripts
- Foundation for text wrapping and alignment

### 2. Layout Engine (`RuneLayout`)
- Flexbox-inspired layout system optimized for terminals
- Constraint-based sizing and positioning
- Support for complex nested layouts

### 3. Renderer (`RuneRenderer`)
- Efficient terminal frame rendering with ANSI escape sequences
- Actor-based thread-safe output management
- Cursor position management and screen clearing

### 4. Components (`RuneComponents`)
- Reusable UI building blocks (Text, Box, etc.)
- Layout-aware rendering within provided rectangles
- Foundation for complex UI composition

## Package Structure

```
RuneKit/
├── Sources/
│   ├── RuneANSI/        # ANSI escape codes & tokenization
│   ├── RuneUnicode/     # Width calculations, emoji/CJK
│   ├── RuneLayout/      # Flexbox engine
│   ├── RuneRenderer/    # Terminal frame rendering
│   ├── RuneComponents/  # Box, Text, Static components
│   ├── RuneKit/         # Main API, runtime, hooks
│   └── RuneCLI/         # Demo executable
└── Tests/
    ├── RuneANSITests/
    ├── RuneUnicodeTests/
    └── ...
```

## Products

- **RuneKit**: Main library (umbrella module)
- **RuneCLI**: Example executable demonstrating functionality
- Individual modules available as separate products for advanced use cases

## Quick Start

### Building

```bash
swift build
```

### Running the Demo

```bash
swift run RuneCLI
```

### Running Tests

```bash
swift test
```

### Development Scripts

```bash
# Set up development environment and format code
./scripts/format-code.sh

# Validate CI pipeline locally before pushing
./scripts/ci-test.sh
```

See `scripts/README.md` for detailed documentation.

## Usage Example

```swift
import RuneKit

// Basic text rendering
let text = Text("Hello, RuneKit!")
let rect = FlexLayout.Rect(x: 0, y: 0, width: 20, height: 1)
let lines = text.render(in: rect)

// ANSI tokenization
let tokenizer = ANSITokenizer()
let tokens = tokenizer.tokenize("\u{001B}[31mRed Text\u{001B}[0m")

// Unicode width calculation
let width = Width.displayWidth(of: "👨‍👩‍👧‍👦") // Returns 2
```

## Platform Support

- macOS 13.0+
- iOS 16.0+
- tvOS 16.0+
- watchOS 9.0+
- visionOS 1.0+
- Linux (Swift 6.1+)

## Development Status

This is the initial package structure implementation. Core functionality is minimal and will be expanded following TDD principles.

## License

See LICENSE file for details.
