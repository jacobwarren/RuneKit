# RuneKit

A Swift library for terminal user interfaces inspired by Ink (React for CLIs).

## Overview

RuneKit provides a declarative way to build terminal-based user interfaces using Swift. It combines the power of Swift's type system with efficient terminal rendering to create production-quality CLI applications.

## Architecture

RuneKit is built on four core subsystems:

### 1. Text Engine (`RuneANSI` + `RuneUnicode`)
- **RuneANSI**: ANSI escape sequence parsing and tokenization
- **RuneUnicode**: Accurate Unicode width calculations, character categorization, and text normalization
  - Unicode category detection using utf8proc (Unicode 16.0.0)
  - Combining mark identification for proper text rendering
  - Emoji scalar detection using Extended_Pictographic property
  - Unicode normalization (NFC, NFD, NFKC, NFKD)
- Foundation for text wrapping and alignment

### 2. Layout Engine (`RuneLayout`)
- Flexbox-inspired layout system optimized for terminals
- Constraint-based sizing and positioning
- Support for complex nested layouts

### 3. Renderer (`RuneRenderer`)
- Efficient terminal frame rendering with ANSI escape sequences
- Actor-based thread-safe output management
- Cursor position management and screen clearing
- **Alternate screen buffer support** for full-screen applications (like vim, less)

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

### Prerequisites

RuneKit requires utf8proc for Unicode processing:

**macOS:**
```bash
brew install utf8proc
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install libutf8proc-dev
```

**Linux (RHEL/CentOS):**
```bash
sudo yum install utf8proc-devel
```

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

## Key Features

### Alternate Screen Buffer Support
RuneKit supports the alternate screen buffer for creating full-screen terminal applications:

```swift
// Enable alternate screen buffer (like vim, less, htop)
let config = RenderConfiguration(useAlternateScreen: true)
let frameBuffer = FrameBuffer(configuration: config)

// Or use environment variable: RUNE_ALT_SCREEN=true
let config = RenderConfiguration.fromEnvironment()
```

### Advanced Text Processing
- **ANSI-aware text operations**: Wrap, slice, and measure text while preserving styling
- **Unicode-compliant width calculation**: Accurate display width for emoji, CJK, and combining characters
- **Comprehensive character categorization**: Using Unicode 16.0.0 properties via utf8proc

### High-Performance Rendering
- **Hybrid reconciler**: Automatically chooses optimal rendering strategy (full redraw vs. line diff)
- **Actor-based concurrency**: Thread-safe terminal output with backpressure handling
- **Adaptive optimization**: Performance tuning based on terminal characteristics

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

// Unicode category detection
let category = UnicodeCategories.category(of: Unicode.Scalar("A")!)
// Returns: .uppercaseLetter

// Combining mark detection
let isCombining = UnicodeCategories.isCombining(Unicode.Scalar(0x0301)!)
// Returns: true (combining acute accent)

// Emoji detection
let isEmoji = UnicodeCategories.isEmojiScalar(Unicode.Scalar("👍")!)
// Returns: true

// Unicode normalization
let normalized = UnicodeNormalization.normalize("é", form: .nfd)
// Returns: "e\u{0301}" (decomposed form)
```

## Platform Support

- macOS 13.0+
- iOS 16.0+
- tvOS 16.0+
- watchOS 9.0+
- visionOS 1.0+
- Linux (Swift 6.1+)

## Features

### Unicode Processing (NEW!)
- **Character categorization** using Unicode 16.0.0 standard
- **Combining mark detection** for proper text rendering
- **Emoji identification** using Extended_Pictographic property
- **Text normalization** (NFC, NFD, NFKC, NFKD) for consistent text processing
- **High performance** with utf8proc C library backend

### ANSI Processing
- Complete ANSI escape sequence parsing and tokenization
- Styled text spans for rich terminal output
- Lossless round-trip encoding support

### Layout Engine
- Flexbox-inspired layout system optimized for terminals
- Constraint-based sizing and positioning

### Terminal Rendering
- Efficient frame rendering with ANSI escape sequences
- Actor-based thread-safe output management

## Development Status

Core functionality is implemented following strict TDD principles. The library provides production-ready Unicode processing, ANSI handling, and foundational layout capabilities.

## License

See LICENSE file for details.
