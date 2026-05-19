# TDD Extension

Strict RED→GREEN→REFACTOR vertical slicing Test-Driven Development methodology.

## Overview

The TDD extension provides comprehensive Test-Driven Development workflow:
1. Language/framework auto-detection (after planning phase)
2. Increment-based test decomposition (Degenerate → Happy → Variations → Edge → Errors)
3. Risk-based testing integration (identifies critical business/security/performance risks)
4. RED→GREEN→REFACTOR execution with state persistence
5. Test quality validation with scoring and recommendations

## Commands

| Command | Purpose | Hook Trigger |
|---------|---------|---------------|
| `tdd.plan` | Planning phase - design before coding | `after_plan` (optional) |
| `tdd.tasks` | Detect language/framework + generate hybrid tests | `after_tasks` |
| `tdd.implement` | Execute RED→GREEN→REFACTOR | `before_implement` |
| `tdd.validate` | Validate test quality | `after_implement` (optional) |

## Quick Start

### Option A: Full Spec Workflow (with artifacts)

```bash
# Create feature spec with Risk Register
specify create "Add JWT authentication"

# Generate tasks (TDD hooks trigger automatically)
/spec.tasks

# Implement (TDD cycle runs before code)
/spec.implement
```

### Option B: Quick Workflow (session-only, no artifacts)

```bash
# Quick session with automatic TDD
/quick.implement "Add JWT authentication"
```

TDD runs entirely in-session:
- Condensed planning (3 questions)
- Language auto-detection
- Test increment generation
- RED→GREEN→REFACTOR cycles
- No files created

### Step 1: Create Feature Specification (Full Workflow)

```bash
# Create feature spec with Risk Register
specify create "Add JWT authentication"
```

### Step 2: Plan Tests

```bash
# Run planning phase before writing tests
/tdd.plan
```

This prompts you with 5 key questions:
1. What interface changes are needed?
2. Which behaviors matter most?
3. Design for deep modules?
4. Design for testability?
5. Vertical slicing constraint

### Step 3: Generate Tasks

```bash
# Generate tasks (TDD hooks trigger automatically)
/spec.tasks
```

Output:
```
Detected: python / pytest
Test directory: tests/
Test command: pytest -xvs

### Risk-Based Tests (HIGH PRIORITY)
- [ ] TDD-R01 [RISK] Verify 403 on protected endpoints
- [ ] TDD-R02 [RISK] Verify token expiration handling

### Increment-Based Tests
**Degenerate Cases**
- [ ] TDD-001 Create valid JWT token with empty claims
...
```

### Step 4: Implement with TDD

```bash
# Execute RED→GREEN→REFACTOR for each test
/spec.implement
```

 workflow:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 RED PHASE: Write failing test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task: Write a test that verify 403 on protected endpoint
The test should FAIL initially (red).

⚠️  IMPORTANT: Follow TDD principles
1. Test PUBLIC interface (not internal methods)
2. Test OBSERVABLE behavior (not mock internals)
3. Return values preferred over side effects
4. Avoid: DB queries, file checks, call verification

Enter test file path (default: tests/test_auth.py): 
```

### Step 5: Validate Quality

```bash
# Test quality validation
/tdd.validate tests/
```

Output:
```
Analyzing test quality in: tests/
Based on TDD best practices:
- Vertical slicing: ONE test → ONE implementation
- Public interface testing, not implementation details
- Test WHAT (behavior), not HOW (implementation)

Found test files:
- tests/test_auth.py

Score: 85/100
==========================================
Overall Test Quality Score
==========================================

Files analyzed: 1
Overall score: 85/100

Good test quality
```

## Context Detection

`tdd.implement` automatically detects which workflow mode to use:

### Spec Mode (File-Based)

Triggered when spec workflow artifacts exist:
- `tasks.md` with TDD increments
- `increment-state.json`
- `.specify/extensions/tdd/language-detected.json`

Uses file-based state persistence. Resume anytime by running commands.

### Quick Mode (In-Session)

Triggered when **no artifacts exist** (e.g., from `/quick.implement`):
- State tracked in conversation only
- Condensed planning (3 questions)
- No files created
- Progress lost if session ends (but git commits preserve code changes)

**Benefits**: Seamless TDD integration without breaking Quick's philosophy.

## Detailed Workflow

### Full Spec Workflow

```
/spec.specify "Add feature"
         ↓
 /spec.plan         ← Run planning phase
         ↓
    [after_plan hook] → tdd.plan (optional)
         ↓
 /spec.tasks
         ↓
    [after_tasks hook] → tdd.tasks
         ↓ Auto-detect language (Python/pytest, TS/vitest, Go/test)
         ↓ Generate hybrid tests: [RISK] + [TDD] increment tests
         ↓
 /spec.implement
         ├─ [before_implement hook] → tdd.implement
         │    ↓ Execute RED→GREEN→REFACTOR for each test
         │
         └─ [after_implement hook] → tdd.validate (optional)
              ↓ Quality validation + recommendations
```

### Quick Workflow (Session-Only)

```
/quick.implement "Add feature"
         ↓
 Mission Brief (3 questions)
         ↓
 Task Breakdown
         ↓
    [before_implement hook] → tdd.implement
         ↓ Context Detection: No artifacts → Quick Mode
         ↓
         ├─ In-session language detection
         ├─ Condensed planning (3 questions)
         ├─ Test increment generation
         └─ RED→GREEN→REFACTOR (all in-session)
         ↓
 Execution (quick tasks with auto-commits)
         ↓
    [after_implement hook] → tdd.validate (optional)
         ↓
 Summary
```
/s specify "Add feature"
         ↓
 /spec.plan         ← Run planning phase
         ↓
 /spec.tasks
         ↓
    [after_tasks hook] → tdd.tasks
         ↓ Auto-detect language (Python/pytest, TS/vitest, Go/test)
         ↓ Generate hybrid tests: [RISK] + [TDD] increment tests
         ↓
 /spec.implement
         ├─ [before_implement hook] → tdd.implement
         │    ↓ Execute RED→GREEN→REFACTOR for each test
         │
         └─ [after_implement hook] → tdd.validate (optional)
              ↓ Quality validation + recommendations
```

## Configuration

### Enable/Disable TDD Hooks

**In `.specify/extensions.yml`:**

```yaml
hooks:
  after_plan:
    - extension: tdd
      command: tdd.plan
      enabled: true  # true (default) or false
      optional: true
      
  after_tasks:
    - extension: tdd
      command: tdd.tasks
      enabled: true  # true (default) or false
      optional: false
      
  before_implement:
    - extension: tdd
      command: tdd.implement
      enabled: true  # true (default) or false
      optional: false
      
  after_implement:
    - extension: tdd
      command: tdd.validate
      enabled: true  # true (default) or false
      optional: true
```

When `enabled: false`, all TDD extension hooks are automatically skipped downstream.

### Extension Config (Optional)

**In `.specify/extensions/tdd/tdd-config.yml`:**

```yaml
strategy: hybrid  # increment-only, risk-only, hybrid
increments: all  # all, minimal, critical
test_analysis:
  enabled: true
  threshold: 70
persist_state: true
```

## Test Generation Patterns

### CRUD Operations
1. Create valid entity
2. Create invalid entity (duplicate, missing required)
3. Read existing entity
4. Read non-existent entity
5. Update valid change
6. Update invalid change
7. Delete existing entity
8. Delete non-existent entity

### Data Transform
1. Empty input
2. Single item
3. Multiple items
4. Quoted/special characters
5. Missing fields
6. Malformed input

### State Machine
1. Initial state
2. Valid transition
3. Invalid transition
4. Terminal state

### Integration
1. Success response (200)
2. Client error (400-499)
3. Server error (500-599)
4. Connection error
5. Timeout
6. Malformed response

## Risk-Based Testing

**Risk Register** in spec.md:

```markdown
## Risk Register

- RISK: Authentication bypass | Severity: High | Impact: Unauthorized access | Test: Verify 403 on protected endpoints
- RISK: Data leakage | Severity: Medium | Impact: PII exposure | Test: Verify encryption for sensitive fields
```

**Test Generation:**
- Parse RISK entries from spec.md
- Generate [TDD-R## tasks with HIGH PRIORITY
- Execute before increment tests
- Focused on business/security/performance critical risks

## Test Quality Scoring

The `tdd.validate` command scores test quality (0-100):

**Good Practices (+points)**:
- ✓ Tests through public interfaces (+10)
- ✓ Describes behavior not implementation (+10)
- ✓ Test isolation (no dependencies between tests) (+10)
- ✓ Edge case testing (+10)
- ✓ One behavior per test (+10)
- ✓ AAA pattern (Arrange/Act/Assert) (+5)
- ✓ Error/happy path coverage (+5)

**Anti-Patterns (-points)**:
- ✗ Excessive mocking (tests imagined behavior, not real) (-15)
- ✗ Tests implementation details (breaks on refactors) (-15)
- ✗ DB query tests (bypass interface) (-15)
- ✗ Call count verification (tests HOW not WHAT) (-15)
- ✗ File system checks (bypass interface) (-15)
- ✗ Brittle tests with hardcoded values (-10)
- ✗ Test does too much (multiple behaviors) (-10)
- ✗ Missing assertions (-10)

**Recommendations:**
- Score < 50: Needs improvement
- Score 50-70: Acceptable
- Score 70-89: Good
- Score 90-100: Excellent

## Usage Examples

### Example 1: Calculator Feature

```bash
# 1. Create spec with Risk Register
specify create "Simple CLI calculator"
```

`spec.md` should include:

```markdown
## Risk Register

- RISK: Division by zero crashes | Severity: High | Impact: Program crashes | Test: Verify divide(5, 0) returns error
```

```bash
# 2. Generate tasks
/spec.tasks
```

Output:
```
Detected: python / pytest
Test directory: tests/

### Risk-Based Tests (HIGH PRIORITY)
- [ ] TDD-R01 [RISK] Verify divide(5, 0) returns error

### Increment-Based Tests (Degenerate → Happy → Edge)
**Degenerate Cases**
- [ ] TDD-001 [ASYNC] Handle empty input
- [ ] TDD-002 [ASYNC] Handle negative to positive
**Happy Path**
- [ ] TDD-003 [P] [ASYNC] Add two numbers
- [ ] TDD-004 [P] [ASYNC] Divide two numbers
**Edge Cases**
- [ ] TDD-005 [ASYNC] Divide by zero
```

```bash
# 3. Implement with TDD
/spec.implement
```

Workflow guides you through each increment:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 RED PHASE: Write failing test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: Write a test that divide(5, 0) returns error

⚠️  IMPORTANT: Follow TDD principles
1. Test PUBLIC interface (not internal methods)
2. Test OBSERVABLE behavior (not mock internals)
3. Return values preferred over side effects
4. Avoid: DB queries, file checks, call verification

Enter test file path: tests/test_calculator.py
Enter test function name: test_divide_by_zero

... [Write your test now]

Run: pytest -xvs tests/test_calculator.py::test_divide_by_zero
Did the test FAIL as expected? (yes/no): yes

✅ RED phase complete - test fails as expected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 GREEN PHASE: Write minimal implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: Write minimal code to make the test pass.
Focus on the simplest solution that works.

⚠️  IMPORTANT: Write ONLY what the test requires
1. No speculative code
2. No extra features
3. Test behavior, not implementation

Enter implementation file path: calculator.py
Enter implementation function/class: divide

... [Write minimal implementation now]

Run: pytest -xvs
Did ALL tests PASS? (yes/no): yes

✅ GREEN phase complete - tests pass

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔵 REFACTOR PHASE (optional)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Are there improvements to make? (yes/no): no

Skipping refactor phase
```

```bash
# 4. Validate quality
/tdd.validate tests/
```

Output:
```
Analyzing test quality in: tests/
Based on TDD best practices:
- Vertical slicing: ONE test → ONE implementation
- Public interface testing, not implementation details
- Test WHAT (behavior), not HOW (implementation)

Found test files:
- tests/test_calculator.py

Score: 60/100
==========================================
Overall Test Quality Score
==========================================

Files analyzed: 1
Overall score: 60/100

Acceptable test quality
```

## State Persistence

TDD workflow persists increment state at feature level:

```json
{
  "current_increment": 3,
  "increments": [
    {
      "id": "TDD-R01",
      "type": "risk",
      "description": "Verify divide(5, 0) returns error",
      "status": "complete"
    },
    {
      "id": "TDD-001",
      "type": "increment",
      "description": "Handle empty input",
      "status": "pending"
    }
  ]
}
```

Resume workflow anytime by running `/spec.implement`.

## Troubleshooting

### Line数量检测问题

**Issue**: grep pattern not working correctly
**Solution**: Use head -1 to get first line after grep -c

### Score calculation errors

**Issue**: Variable unbound errors in bash scripts
**Solution**: Ensure all variables are properly initialized with `${var:-0}` pattern

### TDD Plan command output

**Issue**: No output shown after planning phase
**Solution**: Add `echo` statements to display planning checklist

### Language detection fails

**Issue**: Language shows as "unknown"
**Solution**: Check if pyproject.toml, package.json, go.mod exists. For Python, ensure pytest is listed in dependencies.

### Hooks not triggering

**Issue**: TDD hooks don't fire after `/spec.tasks` or `/spec.implement`
**Solution**: 
1. Check `.specify/extensions.yml` has correct hook definitions
2. Verify `enabled: true` for each hook
3. Check extension is installed: `specify extension list`

### Validation script errors

**Issue**: "unbound variable" or "syntax error" messages
**Solution**: Ensure all variables are initialized before use, use `[[ ]]` for string comparisons

### Test quality score always low

**Issue**: Score shows < 50 despite good tests
**Solution**: Check test file for:
- Excessive mocking
- Implementation detail testing
- DB queries that bypass interface
- Focus testing WHAT not HOW

## Breaking Changes

### No more `--tdd` CLI flag

The `--tdd` CLI flag has been removed. TDD is now an opt-in extension that integrates via extension hooks.

**Migration:**
1. Install TDD extension (preinstalled by default)
2. Configure `.specify/extensions.yml` if needed
3. Extension auto-executes via hooks after tasks/implement commands

## License

MIT

## Acknowledgments

Inspired by best practices from:
- AIHero TDD: https://www.aihero.dev/skill-test-driven-development-claude-code
- mfranzon/tdd: https://github.com/mfranzon/tdd