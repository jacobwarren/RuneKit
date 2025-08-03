# UTF8PROC Integration in RuneKit

This document describes the integration of utf8proc in RuneKit for accurate Unicode character categorization, combining mark detection, and text normalization.

## Overview

RuneKit integrates the [utf8proc](https://github.com/JuliaStrings/utf8proc) C library to provide:

- **Unicode category detection** using the latest Unicode standard
- **Combining mark identification** for proper text rendering
- **Emoji scalar detection** using Extended_Pictographic property
- **Unicode normalization** (NFC, NFD, NFKC, NFKD)
- **High performance** with C library backend

## Unicode Version

The current integration supports **Unicode 16.0.0** (as of the latest utf8proc version). You can check the exact version at runtime:

```swift
let version = UnicodeCategories.unicodeVersion()
print("Unicode version: \(version)") // "16.0.0"
```

## Installation Requirements

### macOS
```bash
brew install utf8proc
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install libutf8proc-dev
```

### Linux (RHEL/CentOS)
```bash
sudo yum install utf8proc-devel
```

## API Reference

### Unicode Categories

```swift
// Get Unicode category for any character
let category = UnicodeCategories.category(of: Unicode.Scalar("A")!)
// Returns: .uppercaseLetter

// Check if character is a combining mark
let isCombining = UnicodeCategories.isCombining(Unicode.Scalar(0x0301)!)
// Returns: true (combining acute accent)

// Detect emoji scalars
let isEmoji = UnicodeCategories.isEmojiScalar(Unicode.Scalar("👍")!)
// Returns: true
```

### Unicode Normalization

```swift
// Normalize text to different forms
let text = "é" // precomposed
let nfd = UnicodeNormalization.normalize(text, form: .nfd)
// Returns: "e\u{0301}" (decomposed)

// Decompose compatibility characters
let ligature = "ﬁ"
let nfkd = UnicodeNormalization.normalize(ligature, form: .nfkd)
// Returns: "fi"

// Check if text is already normalized
let isNormalized = UnicodeNormalization.isNormalized(text, form: .nfc)
```

## Supported Unicode Categories

The API supports all Unicode General Categories:

### Letters
- `uppercaseLetter` (Lu) - A, B, C
- `lowercaseLetter` (Ll) - a, b, c
- `titlecaseLetter` (Lt) - Dž, Lj, Nj
- `modifierLetter` (Lm) - ʰ, ʲ, ʷ
- `otherLetter` (Lo) - 世, あ, א

### Marks
- `nonspacingMark` (Mn) - ́, ̀, ̂ (combining marks)
- `spacingMark` (Mc) - ं, ः
- `enclosingMark` (Me) - ⃝, ⃞

### Numbers
- `decimalNumber` (Nd) - 0, 1, 2
- `letterNumber` (Nl) - Ⅰ, Ⅱ, Ⅲ
- `otherNumber` (No) - ½, ¼, ¾

### Punctuation
- `connectorPunctuation` (Pc) - _, ‿
- `dashPunctuation` (Pd) - -, –, —
- `openPunctuation` (Ps) - (, [, {
- `closePunctuation` (Pe) - ), ], }
- `initialPunctuation` (Pi) - «, "
- `finalPunctuation` (Pf) - », "
- `otherPunctuation` (Po) - !, ?, .

### Symbols
- `mathSymbol` (Sm) - +, =, ∞
- `currencySymbol` (Sc) - $, €, ¥
- `modifierSymbol` (Sk) - ^, `, ¨
- `otherSymbol` (So) - ©, ®, ™

### Separators
- `spaceSeparator` (Zs) - space, non-breaking space
- `lineSeparator` (Zl) - line separator
- `paragraphSeparator` (Zp) - paragraph separator

### Other
- `control` (Cc) - \t, \n, \r
- `format` (Cf) - soft hyphen, zero-width space
- `surrogate` (Cs) - high/low surrogates
- `privateUse` (Co) - private use area
- `unassigned` (Cn) - unassigned code points

## Performance Characteristics

All functions are optimized for high-frequency usage:

- **Category detection**: O(1) constant time lookup
- **Combining mark detection**: O(1) constant time lookup  
- **Emoji detection**: O(1) constant time lookup
- **Normalization**: O(n) linear in string length

Performance benchmarks show excellent characteristics:
- 60,000 category operations in < 20ms
- 7,000 width calculations in < 65ms

## Thread Safety

All utf8proc functions are thread-safe and can be called concurrently from multiple threads without synchronization.

## Error Handling

The API is designed to be robust:
- Invalid Unicode scalars return sensible defaults
- Normalization failures return the original string
- All functions are non-throwing for reliability

## Integration Details

### Package.swift Configuration

```swift
.systemLibrary(
    name: "Cutf8proc",
    pkgConfig: "libutf8proc",
    providers: [
        .brew(["utf8proc"]),
        .apt(["libutf8proc-dev"])
    ]
)
```

### Module Map

```c
module Cutf8proc {
    header "shim.h"
    link "utf8proc"
    export *
}
```

## Testing

Comprehensive test suite covers:
- All Unicode categories
- Combining mark detection
- Emoji scalar identification
- All normalization forms
- Performance benchmarks
- Edge cases and error conditions

Run tests with:
```bash
swift test --filter UnicodeCategoriesTests
```

## Future Updates

To update to a newer Unicode version:

1. Update utf8proc via package manager
2. Verify compatibility with existing tests
3. Update documentation if new categories are added
4. Test on all supported platforms

The utf8proc library is actively maintained and regularly updated with new Unicode releases.
