#!/bin/bash

# Docker CI Testing Script for RuneKit
# This script tests the CI pipeline using Docker to simulate the Linux environment

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

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    log_info "Please install Docker Desktop or Docker Engine"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    log_info "Please start Docker Desktop or the Docker daemon"
    exit 1
fi

log_info "Starting Docker CI pipeline test for RuneKit..."

# Build the Docker image
log_info "Building Docker image..."
if docker build -f Dockerfile.test -t runekit-ci-test .; then
    log_success "Docker image built successfully"
else
    log_error "Docker image build failed"
    exit 1
fi

# Run the CI pipeline in Docker
log_info "Running CI pipeline in Docker container..."
if docker run --rm runekit-ci-test; then
    log_success "Docker CI pipeline completed successfully"
else
    log_error "Docker CI pipeline failed"
    exit 1
fi

# Optional: Run interactive mode for debugging
if [[ "${1:-}" == "--interactive" || "${1:-}" == "-i" ]]; then
    log_info "Starting interactive Docker session for debugging..."
    log_info "You can run commands like: swift build, swift test, swift run RuneCLI"
    docker run --rm -it runekit-ci-test bash
fi

# Optional: Clean up Docker image
if [[ "${1:-}" == "--cleanup" || "${1:-}" == "-c" ]]; then
    log_info "Cleaning up Docker image..."
    if docker rmi runekit-ci-test; then
        log_success "Docker image cleaned up"
    else
        log_warning "Failed to clean up Docker image"
    fi
fi

log_success "Docker CI test completed successfully!"
log_info "Your code should work correctly in the GitHub Actions Linux environment."
