# Contributing

Thanks for helping improve RuneKit! This guide explains how we plan, branch, commit, review, test, and release code.

## TL;DR (Flow)

1. Create a ticket in the tracker (e.g., **RUNE-123**)
2. Create a branch:
   * Feature → `story/RUNE-123-short-slug`
   * Bugfix → `bug/RUNE-124-short-slug`
   * Chore/infra → `task/RUNE-125-short-slug`
3. Commit using the ticket key: `[RUNE-123] Imperative summary` (+ body)
4. Open a PR into `main` titled: `[RUNE-123] Story: Short summary`
5. Ensure checks pass, request review, address feedback
6. **Squash & merge**, delete the branch
7. (Optional) For releases, open a Release Candidate PR (see below)

---

## Work Item Types

* **Story**: User-facing feature/slice that delivers value
* **Bug**: Defect fix (no scope creep)
* **Task**: Refactors, build/infra, docs, housekeeping

> Use exactly one type per branch/PR. If scope expands, open another ticket.

---

## Branch Naming

```
story/RUNE-14-ansi-tokenizer
bug/RUNE-124-fix-emoji-width
task/RUNE-50-github-actions-ci
```

* Lowercase type prefix: `story/`, `bug/`, `task/`
* Keep the slug short and descriptive
* One ticket per branch. Short-lived; delete after merge

---

## Commit Messages

**Format**

```
[RUNE-123] Imperative summary

Context: Why is this change needed?
Changes: What was done at a high level.
Testing: How you verified it (swift test commands).
Notes: Migration, performance impact, risks (if any).
```

**Rules**

* Prefix every commit with the ticket key
* Small, focused commits preferred
* No drive-by changes; keep diffs scoped to the ticket

**Examples**

```
[RUNE-14] Add ANSI tokenizer with SGR support

Context: Need to parse ANSI escape sequences for proper text wrapping.
Changes: Implemented tokenizer supporting SGR, CSI, OSC sequences.
Testing: swift test --filter ANSITokenizerTests
Notes: Round-trip parsing preserves exact byte sequences.
```

---

## Pull Requests

**Title**

```
[RUNE-14] Story: Implement ANSI tokenizer
[RUNE-124] Bug: Fix emoji width calculation  
[RUNE-50] Task: GitHub Actions CI (macOS + Linux)
```

**PR Body Format**

```markdown
**What**
Brief description of changes implemented.

**Why (Value/Outcome)**
User value or defect being fixed.

**Acceptance Criteria**
- [x] Tests pass for SGR parsing
- [x] Round-trip preserves sequences
- [x] Snapshot tests for complex cases
- [x] API documentation complete

**Out of Scope**
- Full terminal emulation
- Performance optimizations (separate ticket)

**Dependencies**
- RUNE-13 (SwiftPM structure)
```

**Checklist (include in PR body)**

* [ ] Linked ticket: RUNE-XXX
* [ ] Scope matches title/type (Story/Bug/Task)
* [ ] Tests added/updated
* [ ] `swiftformat` + `swiftlint` clean
* [ ] Package.swift unchanged or documented
* [ ] API documentation written
* [ ] Backward compatibility considered

**Process**

* Open PR → CI runs automatically
* Request at least **1 reviewer** (2 for risky changes)
* Address review comments with follow-up commits (don't force-push during review)
* **Squash & merge** (keeps one clean commit per ticket)
* **Delete branch** after merge

---

## Labels & Automation

* Apply one of: `type:story`, `type:bug`, `type:task`
* Target labels: `target:ansi`, `target:unicode`, `target:layout`, `target:renderer`, `target:components`
* Optional: `area:unicode`, `area:terminal`, `perf`, `docs`

**CI routing by branch prefix (example)**

```yaml
# .github/workflows/checks.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps: [ ... ]
  
  integration:
    if: startsWith(github.head_ref, 'story/')
    runs-on: ubuntu-latest
    steps: [ ... ]
  
  sanitizers:
    if: startsWith(github.head_ref, 'bug/')
    runs-on: ubuntu-latest
    steps: [ ... ]
```

---

## Code Style & Tooling

* **Formatter**: `swiftformat` (run before commit)
* **Linter**: `swiftlint` (no new warnings)
* **Build**: SwiftPM; both Debug and Release must build cleanly
* **Sanitizers** (CI): Thread and Address sanitizers in Debug
* **Dependencies**: Prefer SPM system libraries. Document any C dependencies

**Pre-commit (recommended)**

```bash
# Install pre-commit hooks
brew install swiftformat swiftlint

# Before committing
swiftformat .
swiftlint --fix
swift test
```

---

## Local CI Testing

**⚠️ Important**: Always test your changes locally before pushing to ensure CI will pass.

### Quick Start

```bash
# Test your changes exactly like GitHub Actions will
./scripts/docker-ci-test.sh

# For debugging CI failures
./scripts/docker-ci-test.sh --interactive

# Native testing (faster, but may miss Linux-specific issues)
./scripts/ci-test.sh
```

### Docker CI Testing (Recommended)

The `./scripts/docker-ci-test.sh` script runs your code in the **exact same Linux environment** as GitHub Actions:

**What it tests:**
- ✅ Swift 6.1 compatibility
- ✅ Package resolution and structure
- ✅ Debug and Release builds
- ✅ Full test suite
- ✅ CLI executable functionality
- ✅ Linux-specific behavior

**When to use:**
- **Before every push** (prevents CI failures)
- **When adding new dependencies** (tests Linux compatibility)
- **For debugging CI failures** (exact environment reproduction)
- **Before opening PRs** (ensures all checks pass)

### Native CI Testing

For faster iteration during development:

```bash
# Run the full native CI validation
./scripts/ci-test.sh

# Individual commands
swift build -c debug
swift build -c release
swift test --enable-code-coverage
swift run RuneCLI
swiftformat --lint .
swiftlint lint
```

### CI Environment Differences

| Environment | Speed | Accuracy | Use Case |
|-------------|-------|----------|----------|
| **Docker** | Slower | 100% accurate | Before push, debugging CI |
| **Native** | Faster | ~95% accurate | Development iteration |
| **GitHub Actions** | N/A | Reference | Final validation |

### Debugging CI Failures

1. **Reproduce locally first:**
   ```bash
   ./scripts/docker-ci-test.sh --interactive
   ```

2. **Inside the container, run individual steps:**
   ```bash
   swift --version
   swift package resolve
   swift build -c debug
   swift test
   swift run RuneCLI
   ```

3. **Check for Linux-specific issues:**
   - File path differences (`/` vs `\`)
   - Case-sensitive filesystems
   - Different Swift runtime behavior
   - Missing system dependencies

### Pre-Push Checklist

```bash
# 1. Format and lint
swiftformat .
swiftlint --fix

# 2. Test locally (fast)
swift test

# 3. Test in CI environment (thorough)
./scripts/docker-ci-test.sh

# 4. Only then push
git push
```

**Pro tip**: Add this to your git hooks or IDE to run automatically!

---

## Testing Policy

* **Unit tests** for all public APIs (fast, deterministic)
* **Integration tests** for terminal I/O and rendering
* **Snapshot tests** for visual components (Box, borders)
* New code requires tests; bug fixes must include a failing test first
* **Coverage**: Don't regress. Aim ≥ **80%** for core modules
* Document test commands in the PR

**Test Structure**

```swift
// TDD: Write test first
func testEmojiWidth() {
    // Arrange
    let emoji = "👨‍👩‍👧‍👦"
    
    // Act
    let width = Width.displayWidth(of: emoji)
    
    // Assert
    XCTAssertEqual(width, 2)
}
```

---

## Review Standards

* **Correctness**: Implements ticket, handles edge cases (emoji, CJK, terminal quirks)
* **Clarity**: Readable code, comments where intent isn't obvious
* **Architecture**: Respects module boundaries (no circular dependencies)
* **Safety**: Proper optionals, bounds checks, actor isolation for I/O
* **Performance**: No obvious regressions (string allocations, render loops)
* **Docs**: Public APIs documented with examples

---

## Module Architecture

Respect the multi-target structure:

```
RuneANSI      → Tokenization, escape sequences
RuneUnicode   → Width calculations, grapheme handling
RuneLayout    → Flexbox engine (depends on Unicode)
RuneRenderer  → Frame rendering (depends on ANSI, Unicode)
RuneComponents → UI components (depends on Layout, Renderer)
RuneKit       → Main API, runtime (depends on Components)
```

* **No upward dependencies**: RuneANSI cannot import RuneComponents
* **Test in isolation**: Each module has its own test target
* **Clear boundaries**: Parser logic in ANSI, width logic in Unicode

---

## Release Management

* **Release Candidate PRs**: Open `task/RUNE-XXX-release-candidate-N` summarizing changes since last tag
* **Tagging**: Semantic Versioning (`v0.1.0`, `v0.2.0`)
  * **feat**: Minor version bump
  * **fix**: Patch version bump  
  * **breaking**: Major version bump
* **Changelog**: Updated on tag. Group by **Features**, **Fixes**, **Tasks**
* **Hotfixes**: `bug/*` branches may be fast-tracked with minimal review if severity is high

---

## Branch Protection (GitHub settings)

* Require PRs for `main`
* Require status checks:
  * `test (macos-latest)`
  * `test (ubuntu-latest)`
  * `lint`
  * `sanitizers`
* Require 1+ approval; dismiss stale reviews on new commits
* Require linear history; **Squash merge only**
* Delete head branches automatically

---

## Swift-Specific Guidelines

### Performance

* Avoid string concatenation in loops (use `Array<String>` + `joined()`)
* Use `String.UTF8View` for byte operations
* Prefer value types; use `class` only when needed
* Profile with Instruments for render-loop bottlenecks

### Unicode & Terminal Safety

* Always test with:
  * Emoji families: "👨‍👩‍👧‍👦"
  * CJK characters: "你好", "こんにちは"
  * RTL text: "مرحبا"
  * Combining marks: "é" (e + ́)
* Test at terminal boundaries (column 79/80)
* Handle SIGWINCH gracefully

### API Design

```swift
// ✅ GOOD: Clear, documented, testable
public struct ANSITokenizer {
    /// Tokenizes ANSI escape sequences
    /// - Parameter input: Terminal string with ANSI codes
    /// - Returns: Array of tokens preserving semantics
    public func tokenize(_ input: String) -> [Token] { ... }
}

// ❌ BAD: Side effects, poor naming, untestable
class parser {
    func parse() { 
        print(text) // Side effect!
    }
}
```

---

## Questions?

Open a discussion or tag a maintainer in your PR. Thanks for contributing to RuneKit!

---

## Quick Reference

```bash
# Start new feature
git checkout main && git pull
git checkout -b story/RUNE-XXX-description
swift test --filter ModuleNameTests

# Commit
git add .
git commit -m "[RUNE-XXX] Add feature description"

# Before pushing - CRITICAL STEP
swiftformat .
swiftlint
./scripts/docker-ci-test.sh  # Test in CI environment

# Push and create PR
git push -u origin story/RUNE-XXX-description
# Go to GitHub → Create PR with template
```