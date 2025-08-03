#!/bin/bash

# Development setup and code formatting script for RuneKit
# Installs tools, formats code, and validates setup

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Check if we're on macOS (for brew)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Install development tools if missing
    log_info "Checking development tools..."

    if ! command -v swiftformat &> /dev/null; then
        log_info "Installing SwiftFormat..."
        if command -v brew &> /dev/null; then
            brew install swiftformat
            log_success "SwiftFormat installed"
        else
            log_warning "Homebrew not found. Please install SwiftFormat manually."
        fi
    else
        log_success "SwiftFormat already installed"
    fi

    if ! command -v swiftlint &> /dev/null; then
        log_info "Installing SwiftLint..."
        if command -v brew &> /dev/null; then
            brew install swiftlint
            log_success "SwiftLint installed"
        else
            log_warning "Homebrew not found. Please install SwiftLint manually."
        fi
    else
        log_success "SwiftLint already installed"
    fi
fi

# Format code if tools are available
if command -v swiftformat &> /dev/null; then
    log_info "Formatting code with SwiftFormat..."
    swiftformat .
    log_success "Code formatted"
else
    log_warning "SwiftFormat not available. Applying basic fixes..."
    # Fallback to basic formatting
    find Sources Tests -name "*.swift" -exec sed -i '' 's/[[:space:]]*$//' {} \;
    find Sources Tests -name "*.swift" -exec sh -c 'if [ "$(tail -c1 "$1")" != "" ]; then echo "" >> "$1"; fi' _ {} \;
    log_success "Basic formatting applied"
fi

# Run linting if available
if command -v swiftlint &> /dev/null; then
    log_info "Running SwiftLint..."
    if swiftlint lint --strict; then
        log_success "SwiftLint passed"
    else
        log_warning "SwiftLint found issues. Please fix them."
    fi
else
    log_warning "SwiftLint not available. Install with: brew install swiftlint"
fi

log_success "Development setup complete!"
log_info "Run './scripts/ci-test.sh' to validate your changes before pushing."
