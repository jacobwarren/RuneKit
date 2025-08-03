# RuneKit CI/CD Pipeline

This directory contains the GitHub Actions workflows for RuneKit's continuous integration and deployment pipeline.

## Workflows

### 1. Main CI Pipeline (`ci.yml`)

The primary CI workflow that runs on every push and pull request:

**Jobs:**
- **build-and-test**: Matrix build across macOS and Linux
  - Builds debug and release configurations
  - Runs comprehensive test suite with coverage
  - Generates and uploads coverage reports to Codecov
  - Caches Swift Package Manager dependencies

- **code-quality**: Code style and quality checks
  - SwiftFormat linting for consistent formatting
  - SwiftLint analysis for code quality and conventions
  - Runs on macOS with latest tools

- **sanitizer-tests**: Memory safety validation
  - Address Sanitizer (detects memory leaks and corruption)
  - Undefined Behavior Sanitizer (catches UB issues)
  - Thread Sanitizer (detects race conditions)
  - Matrix across all sanitizer types

- **release-build**: Production build verification
  - Builds optimized release configuration
  - Tests CLI executable functionality

- **all-checks**: Aggregation job
  - Ensures all previous jobs pass
  - Required for branch protection

### 2. PR Checks (`pr-checks.yml`)

Enhanced validation for pull requests:

**Jobs:**
- **quick-check**: Fast validation for draft PRs
- **comprehensive-checks**: Reuses main CI pipeline
- **pr-analysis**: Analyzes PR size and complexity
- **security-scan**: Semgrep security analysis
- **docs-check**: Documentation coverage validation
- **pr-ready**: Final aggregation for merge readiness

### 3. Performance Benchmarks (`performance.yml`)

Performance monitoring and regression detection:

**Jobs:**
- **benchmark**: Runs performance tests on main branch
- **performance-comparison**: Compares PR performance vs base

## Configuration Files

### SwiftFormat (`.swiftformat`)
- Enforces consistent code formatting
- 120 character line limit
- 4-space indentation
- Modern Swift conventions

### SwiftLint (`.swiftlint.yml`)
- Code quality and style enforcement
- Custom rules for ANSI sequences
- Documentation requirements for public APIs
- Performance and maintainability guidelines

### Git Ignore (`.gitignore`)
- Comprehensive coverage of CI-generated files
- Coverage reports (*.lcov, *.profdata)
- Performance benchmark artifacts
- Temporary test files and logs
- Code quality tool caches

## Local Development

### Prerequisites
```bash
# Install code quality tools
brew install swiftformat swiftlint

# Optional: Install Semgrep for security scanning
pip install semgrep
```

### Running CI Locally
```bash
# Set up development environment and format code
./scripts/format-code.sh

# Run the full CI validation suite
./scripts/ci-test.sh

# Manual formatting and linting (if tools installed)
swiftformat .
swiftlint lint --strict
```

### Coverage Reports
Coverage is automatically collected during test runs and uploaded to Codecov. Local coverage reports can be generated using:

```bash
swift test --enable-code-coverage
# Coverage data will be in .build/debug/codecov/
```

## Branch Protection

The following checks are required for merging to `main`:
- ✅ All CI jobs must pass
- ✅ Code quality checks must pass
- ✅ Security scan must pass
- ✅ Documentation checks must pass
- ✅ At least one approving review

## Secrets Configuration

The following secrets need to be configured in the repository:

- `CODECOV_TOKEN`: Token for uploading coverage reports
- `SEMGREP_APP_TOKEN`: Token for Semgrep security scanning (optional)

## Performance Targets

The CI pipeline enforces these performance benchmarks:
- Tokenize 1MB of ANSI text: <10ms
- Calculate width of 10k strings: <5ms
- Render 100-component tree: <16ms (60fps)
- Frame diff 1000 lines: <1ms

## Troubleshooting

### Common Issues

1. **SwiftFormat/SwiftLint not found**
   - Install tools locally: `brew install swiftformat swiftlint`
   - Or run `./scripts/format-code.sh` for basic fixes

2. **Coverage generation fails**
   - Ensure tests are run with `--enable-code-coverage`
   - Check that test binaries are built correctly

3. **Sanitizer tests fail**
   - Review memory usage patterns
   - Check for potential race conditions
   - Ensure proper cleanup in tests

4. **Performance regression**
   - Profile the specific failing benchmark
   - Compare with baseline performance
   - Optimize critical paths

### Getting Help

- Check the Actions tab for detailed logs
- Review the specific job that failed
- Look for error messages in the CI output
- Ensure all required secrets are configured

## Contributing

When contributing to RuneKit:

1. Run `./scripts/ci-test.sh` before pushing
2. Ensure all tests pass locally
3. Follow the code style guidelines
4. Add tests for new functionality
5. Update documentation as needed

The CI pipeline will automatically validate your changes and provide feedback on any issues.
