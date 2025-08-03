# RuneKit Development Scripts

This directory contains essential development and CI validation scripts for RuneKit.

## Scripts Overview

### 🔧 `format-code.sh` - Development Setup & Formatting

**Purpose:** Sets up the development environment and formats code consistently.

**What it does:**
- Installs SwiftFormat and SwiftLint (macOS with Homebrew)
- Formats code using SwiftFormat
- Runs SwiftLint validation
- Falls back to basic formatting if tools aren't available

**Usage:**
```bash
./scripts/format-code.sh
```

**When to use:**
- First time setting up the project
- Before committing changes
- When SwiftLint reports formatting issues

### 🧪 `ci-test.sh` - CI Pipeline Validation

**Purpose:** Validates the entire CI pipeline locally before pushing to GitHub.

**What it does:**
- Tests package resolution and structure
- Builds debug and release configurations
- Runs complete test suite with coverage
- Validates CLI executable
- Tests sanitizer builds (Linux)
- Generates coverage reports
- Checks code formatting and linting

**Usage:**
```bash
./scripts/ci-test.sh
```

**When to use:**
- Before pushing changes to GitHub
- When debugging CI failures
- Before creating pull requests
- When setting up a new development environment

**Benefits:**
- Catches issues early (saves CI resources)
- Validates cross-platform compatibility
- Ensures consistent development environment
- Reduces failed GitHub Actions runs

### 📊 `generate_unicode_tables.swift` - Unicode Data Table Generation

**Purpose:** Generates optimized Unicode lookup tables from official Unicode data files.

**What it does:**
- Downloads official Unicode data files from unicode.org
- Parses East Asian Width property data (UAX #11)
- Parses emoji property data (Extended_Pictographic)
- Generates optimized Swift lookup tables
- Creates files in `Sources/RuneUnicode/Generated/`

**Usage:**
```bash
swift Scripts/generate_unicode_tables.swift
```

**Generated Files:**
- `Sources/RuneUnicode/Generated/EastAsianWidthTables.swift`
- `Sources/RuneUnicode/Generated/EmojiTables.swift`

**When to use:**
- When updating to a new Unicode version
- When Unicode property definitions change
- During initial project setup (if generated files are missing)

**Update Process:**
1. Update Unicode version in the script
2. Run the generation script
3. Review generated files for correctness
4. Run tests: `swift test --filter RuneUnicodeTests`
5. Run performance benchmarks
6. Commit the updated tables

## Development Workflow

### New Contributors
```bash
# 1. Set up development environment
./scripts/format-code.sh

# 2. Make your changes
# ... edit code ...

# 3. Validate before pushing
./scripts/ci-test.sh

# 4. Push with confidence
git push
```

### Regular Development
```bash
# Quick format check
./scripts/format-code.sh

# Full validation (recommended before PR)
./scripts/ci-test.sh
```

## Requirements

### macOS
- Xcode with Swift 6.1+
- Homebrew (for automatic tool installation)

### Linux
- Swift 6.1+
- LLVM tools (for coverage and sanitizers)

## Troubleshooting

### "SwiftFormat/SwiftLint not found"
**Solution:** Run `./scripts/format-code.sh` which will install them automatically on macOS.

### "CI test failed"
**Solution:** Check the specific error message. Common issues:
- Swift version mismatch
- Missing dependencies
- Code formatting issues

### "Permission denied"
**Solution:** Make scripts executable:
```bash
chmod +x scripts/*.sh
```

## Script Maintenance

These scripts are maintained as part of the RuneKit project:

- **`format-code.sh`**: Updated when new formatting rules are added
- **`ci-test.sh`**: Updated when CI pipeline changes

Both scripts are essential for maintaining code quality and should be kept in sync with the CI configuration.

## Contributing

When modifying these scripts:

1. Test on both macOS and Linux (if applicable)
2. Update this README if behavior changes
3. Ensure scripts remain idempotent (safe to run multiple times)
4. Follow the existing error handling patterns
5. Update CI documentation if script interfaces change
