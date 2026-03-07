# TDD Extension - Quick Start Guide

Get started with Test-Driven Development in 5 minutes.

## Prerequisites

- Agentic SDLC Spec Kit CLI (`specify` command)
- Python, TypeScript, or Go project
- Basic knowledge of TDD concepts

## Installation

```bash
# TDD extension is preinstalled by default
specify extension list
# Verify tdd appears in the list
```

## 5-Minute Tutorial

### Step 1: Create Your Feature Spec

```bash
# Initialize project if needed
specify init my-project --ai claude

# Create a feature specification
specify create "Calculator with addition and division"
```

This creates `specs/feature/spec.md` with user stories.

### Step 2: Add Risk Register

Edit `specs/feature/spec.md` to include:

```markdown
## Risk Register

- RISK: Division by zero crashes | Severity: High | Impact: Program crashes | Test: Verify divide(5, 0) returns error
- RISK: Invalid input handling | Severity: Medium | Impact: TypeError crashes | Test: Verify add("two", 3) raises TypeError
```

### Step 3: Run Planning (Optional but Recommended)

```bash
/tdd.plan
```

Answer 5 questions about your interface, behaviors, and design.

### Step 4: Generate Tasks

```bash
/spec.tasks
```

This automatically triggers `tdd.tasks` hook which:
- Detects your language (Python, TypeScript, Go, etc.)
- Generates risk tests from Risk Register
- Creates increment tests (Degenerate → Happy → Edge → Errors)

### Step 5: Implement with TDD

```bash
/spec.implement
```

Follow the RED→GREEN→REFACTOR workflow:

```
🔴 RED Phase:
1. Write ONE failing test
2. Run and confirm FAIL

🟢 GREEN Phase:
3. Write MINIMAL code to pass
4. Run and confirm PASS

🔵 REFACTOR Phase (optional):
5. Improve code
6. Run and confirm PASS
```

### Step 6: Validate Test Quality

```bash
/tdd.validate tests/
```

Check your score:
- 90-100: Excellent TDD quality
- 70-89: Good quality
- 50-69: Acceptable
- 0-49: Needs improvement

## Common Workflows

### New Feature Workflow (Recommended)

```bash
specify create "Add new feature"
/tdd.plan                             # Plan phase (optional)
/spec.tasks                            # Generate TDD tests → auto-installs
/spec.implement                        # Execute RED→GREEN→REFACTOR
/tdd.validate tests/                    # Validate quality
```

### Resume Workflow

If you中断 the TDD cycle, resume anytime:

```bash
/spec.implement                       # Continue where you left off
# Reads increment-state.json to resume
```

### Update Existing Tests

```bash
# Validate current test quality
/tdd.validate tests/

# Regenerate tests (replaces old)
/spec.tasks

# Continue new implementations
/spec.implement
```

## Key Principles

### 1. Vertical Slicing

Write ONE test → implement ONE behavior → repeat

Don't:
- ❌ Write all tests first, then implement
- ❌ Write 10 tests at once

Do:
- ✅ Test → Implement → Test → Implement → ...

### 2. Public Interface Testing

Test WHAT (behavior) through public interfaces, not HOW (implementation)

Don't:
- ❌ Test private methods
- ❌ Mock internal collaborators
- ❌ Verify call counts
- ❌ Query DB directly

Do:
- ✅ Test through public API
- ✅ Verify returned results
- ✅ Test edge cases

### 3. Test What, Not How

Tests should read like user-facing specifications

Good:
```python
test("user can checkout with valid cart", ...)
```

Bad:
```python
test("checkout calls paymentService.process", ...)
```

### 4. One Behavior Per Test

Don't:
```python
def test_full_checkout():
    # Creates user
    # Adds item
    # Checks out
    # Verifies payment
    # Verifies email sent
    # (5+ behaviors)
```

Do:
```python
def test_checkout_with_valid_cart():
    # Single behavior

def test_checkout_sends_email():
    # Single behavior
```

## Troubleshooting

### Hooks Not Triggering

Check `.specify/extensions.yml`:

```yaml
hooks:
  after_tasks:
    - extension: tdd
      command: tdd.tasks
      enabled: true
```

### Language Detection Fails

Ensure project has:
- Python: `pyproject.toml` with pytest
- TypeScript: `package.json` with vitest/jest
- Go: `go.mod`
- Rust: `Cargo.toml`

### Test Quality Score Low

Check for:
- Excessive mocking (tests imagined behavior)
- Implementation detail tests (breaks on refactors)
- DB queries (bypasses interface)
- Call count verification (tests HOW not WHAT)

## Next Steps

Read the full [README.md](README.md) for:
- Detailed configuration options
- Advanced patterns (CRUD, State Machine, Transform)
- Risk-based testing methodology
- State persistence details

## Help

```bash
# List all TDD commands
specify extension info tdd

# Check installed extensions
specify extension list

# View extension hooks
cat .specify/extensions.yml
```