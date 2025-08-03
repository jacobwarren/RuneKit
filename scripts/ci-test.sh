#!/bin/bash

# CI Test Script for RuneKit
# This script validates the CI pipeline locally before pushing to GitHub

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "Package.swift" ]]; then
    log_error "Package.swift not found. Please run this script from the RuneKit root directory."
    exit 1
fi

log_info "Starting CI validation for RuneKit..."

# Check Swift version
log_info "Checking Swift version..."
SWIFT_VERSION=$(swift --version | head -n1)
log_info "Swift version: $SWIFT_VERSION"

if ! swift --version | grep -q "6\."; then
    log_warning "Expected Swift 6.x, but found: $SWIFT_VERSION"
fi

# Check utf8proc dependency
log_info "Checking utf8proc dependency..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    if brew list utf8proc &> /dev/null; then
        log_success "utf8proc is installed via Homebrew"
    else
        log_error "utf8proc not found. Install with: brew install utf8proc"
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if pkg-config --exists libutf8proc; then
        log_success "utf8proc is installed"
        UTF8PROC_VERSION=$(pkg-config --modversion libutf8proc)
        log_info "utf8proc version: $UTF8PROC_VERSION"
    else
        log_error "utf8proc not found. Install with: sudo apt-get install libutf8proc-dev"
        exit 1
    fi
else
    log_warning "Unknown OS type: $OSTYPE. Cannot verify utf8proc installation."
fi

# Clean build directory
log_info "Cleaning build directory..."
rm -rf .build
log_success "Build directory cleaned"

# Test 1: Package resolution
log_info "Testing package resolution..."
if swift package resolve; then
    log_success "Package resolution successful"
else
    log_error "Package resolution failed"
    exit 1
fi

# Test 2: Package dump
log_info "Testing package dump..."
if swift package dump-package > /dev/null; then
    log_success "Package dump successful"
else
    log_error "Package dump failed"
    exit 1
fi

# Test 3: Debug build
log_info "Testing debug build..."
if swift build -c debug; then
    log_success "Debug build successful"
else
    log_error "Debug build failed"
    exit 1
fi

# Test 4: Release build
log_info "Testing release build..."
if swift build -c release; then
    log_success "Release build successful"
else
    log_error "Release build failed"
    exit 1
fi

# Test 5: Run tests
log_info "Running tests..."
if swift test --enable-code-coverage; then
    log_success "Tests passed"
else
    log_error "Tests failed"
    exit 1
fi

# Test 6: CLI executable
log_info "Testing CLI executable..."
if swift run RuneCLI > /dev/null; then
    log_success "CLI executable works"
else
    log_error "CLI executable failed"
    exit 1
fi

# Test 7: Code formatting (if SwiftFormat is available)
if command -v swiftformat &> /dev/null; then
    log_info "Checking code formatting..."
    if swiftformat --lint .; then
        log_success "Code formatting is correct"
    else
        log_warning "Code formatting issues found. Run 'swiftformat .' to fix."
    fi
else
    log_warning "SwiftFormat not found. Install with: brew install swiftformat"
fi

# Test 8: Linting (if SwiftLint is available)
if command -v swiftlint &> /dev/null; then
    log_info "Running SwiftLint..."
    if swiftlint lint --strict; then
        log_success "SwiftLint passed"
    else
        log_warning "SwiftLint issues found"
    fi
else
    log_warning "SwiftLint not found. Install with: brew install swiftlint"
fi

# Test 9: Sanitizer builds (Linux/macOS specific)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "Testing sanitizer builds (Linux)..."
    
    # Address Sanitizer
    log_info "Testing Address Sanitizer..."
    if swift build -c debug -Xswiftc -sanitize=address; then
        log_success "Address Sanitizer build successful"
        if ASAN_OPTIONS=detect_leaks=1:abort_on_error=1 swift test -c debug -Xswiftc -sanitize=address; then
            log_success "Address Sanitizer tests passed"
        else
            log_warning "Address Sanitizer tests failed"
        fi
    else
        log_warning "Address Sanitizer build failed"
    fi
    
    # Undefined Behavior Sanitizer
    log_info "Testing Undefined Behavior Sanitizer..."
    if swift build -c debug -Xswiftc -sanitize=undefined; then
        log_success "UB Sanitizer build successful"
        if UBSAN_OPTIONS=abort_on_error=1 swift test -c debug -Xswiftc -sanitize=undefined; then
            log_success "UB Sanitizer tests passed"
        else
            log_warning "UB Sanitizer tests failed"
        fi
    else
        log_warning "UB Sanitizer build failed"
    fi
    
    # Thread Sanitizer
    log_info "Testing Thread Sanitizer..."
    if swift build -c debug -Xswiftc -sanitize=thread; then
        log_success "Thread Sanitizer build successful"
        if TSAN_OPTIONS=abort_on_error=1 swift test -c debug -Xswiftc -sanitize=thread; then
            log_success "Thread Sanitizer tests passed"
        else
            log_warning "Thread Sanitizer tests failed"
        fi
    else
        log_warning "Thread Sanitizer build failed"
    fi
else
    log_info "Skipping sanitizer tests (not on Linux)"
fi

# Test 10: Coverage report generation
log_info "Testing coverage report generation..."
if [[ -d ".build/debug/codecov" ]]; then
    log_info "Found coverage data directory"
    
    # Find test binary
    if [[ "$OSTYPE" == "darwin"* ]]; then
        TEST_BINARY=$(find .build/debug -name "*PackageTests.xctest" -type d | head -1)
        if [[ -n "$TEST_BINARY" ]]; then
            TEST_BINARY="$TEST_BINARY/Contents/MacOS/$(basename "$TEST_BINARY" .xctest)"
        fi
    else
        TEST_BINARY=$(find .build/debug -name "*PackageTests.xctest" -type f | head -1)
    fi
    
    if [[ -n "$TEST_BINARY" && -f "$TEST_BINARY" ]]; then
        log_info "Found test binary: $TEST_BINARY"
        PROFDATA_FILE=".build/debug/codecov/default.profdata"
        if [[ -f "$PROFDATA_FILE" ]]; then
            log_info "Generating coverage report..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                if xcrun llvm-cov export "$TEST_BINARY" -instr-profile "$PROFDATA_FILE" -format="lcov" > coverage.lcov; then
                    log_success "Coverage report generated successfully"
                    rm -f coverage.lcov
                else
                    log_warning "Coverage report generation failed"
                fi
            else
                if llvm-cov export "$TEST_BINARY" -instr-profile "$PROFDATA_FILE" -format="lcov" > coverage.lcov; then
                    log_success "Coverage report generated successfully"
                    rm -f coverage.lcov
                else
                    log_warning "Coverage report generation failed"
                fi
            fi
        else
            log_warning "Profile data not found"
        fi
    else
        log_warning "Test binary not found"
    fi
else
    log_warning "Coverage data directory not found"
fi

# Summary
log_info "CI validation completed!"
log_success "All critical tests passed. The CI pipeline should work correctly."

# Cleanup
log_info "Cleaning up..."
rm -f coverage.lcov
log_success "Cleanup completed"

log_info "You can now safely push your changes to trigger the GitHub Actions CI pipeline."
