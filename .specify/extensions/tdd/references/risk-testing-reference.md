# Risk-Based Testing Reference

This document provides guidance on integrating risk-based testing with the TDD extension, following the 12-factors AI-augmented testing methodology.

## Overview

Risk-based testing focuses on validating critical business, security, and performance risks identified during feature planning. Unlike comprehensive TDD (which tests all scenarios), risk-based testing prioritizes tests that validate identified risks are mitigated.

## Risk Register Format

Include a Risk Register section in `spec.md`:

```markdown
## Risk Register

Identify critical business, security, or performance risks:

- RISK: [short name] | Severity: [High/Medium/Low] | Impact: [what goes wrong] | Test: [specific test to validate]
```

### Format Fields

| Field | Description | Required |
|-------|-------------|----------|
| RISK | Short descriptive name | Yes |
| Severity | High/Medium/Low | Yes |
| Impact | What happens if risk occurs | Yes |
| Test | Specific test to validate mitigation | Yes |

### Example Risk Register

```markdown
## Risk Register

### Security Risks
- RISK: Authentication bypass | Severity: High | Impact: Unauthorized access to user data | Test: Verify 403 status when accessing protected endpoint without valid session
- RISK: Data leakage | Severity: High | Impact: PII exposed in logs | Test: Verify sensitive fields are not logged in plain text
- RISK: SQL injection | Severity: Critical | Impact: Database compromise | Test: Verify SQL injection attempts are rejected

### Performance Risks
- RISK: API timeout under load | Severity: Medium | Impact: Service unavailable | Test: Verify API responds < 200ms with 100 concurrent requests
- RISK: Memory leak | Severity: Medium | Impact: Service degradation | Test: Verify memory usage stable after 1000 requests

### Business Risks
- RISK: Payment calculation error | Severity: High | Impact: Incorrect charges | Test: Verify total matches sum of line items
- RISK: Cart item out of stock | Severity: Medium | Impact: Customer frustration | Test: Verify error when purchasing out-of-stock item
```

---

## Risk Severity Levels

### Critical
- **Definition**: Immediate threat to system security, data integrity, or core functionality
- **Examples**: SQL injection, authentication bypass, payment processing bugs
- **Response Time**: Must be tested and fixed immediately
- **TDD Priority**: TDD-R01, TDD-R02...

### High
- **Definition**: Significant impact on business operations or user experience
- **Examples**: Data loss, major feature broken, security vulnerability
- **Response Time**: Should be tested in current sprint
- **TDD Priority**: TDD-R03, TDD-R04...

### Medium
- **Definition**: Moderate impact, workaround available
- **Examples**: Performance degradation, minor security issues
- **Response Time**: Can be addressed in next sprint
- **TDD Priority**: TDD-R05, TDD-R06...

---

## Test Generation Pattern

For each RISK entry in the Risk Register:

1. **Parse** the entry to extract test description
2. **Generate** a task: `[TDD-R## [RISK] [Test description]`
3. **Mark** as HIGH PRIORITY (execute before increment tests)
4. **Format** in tasks.md under each User Story section

### Example Generation

**Input** (Risk Register):
```
- RISK: Authentication bypass | Severity: High | Impact: Unauthorized access | Test: Verify 403 when accessing protected endpoint without valid session
```

**Generated Task**:
```markdown
### Risk-Based Tests (HIGH PRIORITY)
- [ ] TDD-R01 [RISK] Verify 403 when accessing protected endpoint without valid session
```

---

## Risk Categories

### Security Risks

| Risk Type | Common Tests |
|-----------|-------------|
| Authentication bypass | Verify 401/403 without credentials |
| Authorization flaw | Verify users can't access others' resources |
| Data exposure | Verify sensitive data not in logs/responses |
| Injection attacks | Verify SQL/command injection blocked |
| Session hijacking | Verify token expiration, revocation |

### Performance Risks

| Risk Type | Common Tests |
|-----------|-------------|
| Timeout under load | Verify response time under concurrent requests |
| Memory leak | Verify memory stable over extended operation |
| Database deadlock | Verify concurrent transactions don't deadlock |
| Rate limiting | Verify throttling works correctly |

### Business Risks

| Risk Type | Common Tests |
|-----------|-------------|
| Calculation error | Verify math operations are correct |
| Data consistency | Verify related entities stay in sync |
| Workflow violation | Verify business rules enforced |
| Edge case handling | Verify unusual but valid inputs handled |

---

## Integration with TDD

### Hybrid Workflow

1. **First**: Execute risk-based tests (TDD-R##)
   - These validate critical risks are mitigated
   - Business/security focus
   - Higher priority

2. **Second**: Execute increment-based tests (TDD-###)
   - These validate structural coverage
   - Comprehensive edge cases
   - Standard TDD approach

### Example Tasks Output

```markdown
## Phase 3: User Story 1 - User Authentication

### Risk-Based Tests (HIGH PRIORITY)
- [ ] TDD-R01 [RISK] Verify 403 when accessing protected endpoint without valid JWT
- [ ] TDD-R02 [RISK] Verify expired JWT token returns 401
- [ ] TDD-R03 [RISK] Verify SQL injection in login field is blocked

### Increment-Based Tests (Structural Coverage)
- [ ] TDD-001 [ASYNC] Login with valid credentials succeeds
- [ ] TDD-002 [ASYNC] Login with wrong password fails
- [ ] TDD-003 [ASYNC] Login with non-existent user fails
- [ ] TDD-004 [ASYNC] Login with empty credentials fails
- [ ] TDD-005 [ASYNC] JWT token refresh works
```

---

## Best Practices

### 1. Focus on User-Facing Risks

Test what matters to users and business:
- What happens to users if this fails?
- What is the business impact?

### 2. Write Executable Tests

Risk tests should be specific and verifiable:
- **Good**: "Verify 403 when accessing protected endpoint without valid session"
- **Bad**: "Improve security" (not testable)

### 3. One Test Per Risk

Each risk should have one focused test:
- Multiple tests for same risk = unclear priority
- One test per risk = clear validation

### 4. Risk Tests Have Priority

Execute risk tests before increment tests:
- Higher business value
- Validate critical mitigations first

### 5. Keep Risk Register Updated

As risks are validated or new risks identified:
- Mark validated risks as "tested"
- Add new risks to register
- Remove resolved risks

---

## Risk Testing vs. TDD

| Aspect | Risk Testing | TDD (Increment) |
|--------|--------------|-------------------|
| Focus | Critical risks | All scenarios |
| Scope | Targeted | Comprehensive |
| Priority | Business value | Structural coverage |
| When | First | After risks |
| Source | Risk Register | Feature analysis |

---

## Tool Integration

The TDD extension automatically parses Risk Register from `spec.md`:

```bash
# Risk tests generated automatically
./extensions/tdd/scripts/bash/generate-risk-tests.sh spec.md

# Or via PowerShell
./extensions/tdd/scripts/powershell/Generate-RiskTests.ps1 -SpecFile spec.md
```

This generates markdown tasks that are appended to `tasks.md` under each User Story section.

---

## Example: Complete Risk-Based Testing Workflow

1. **Create spec.md** with Risk Register:
   ```markdown
   ## Risk Register
   - RISK: XSS vulnerability | Severity: Critical | Impact: Script injection | Test: Verify script tags in input are escaped in response
   ```

2. **Run tasks generation**:
   ```bash
   /spec.tasks
   ```

3. **TDD extension** parses Risk Register and generates:
   ```markdown
   ### Risk-Based Tests (HIGH PRIORITY)
   - [ ] TDD-R01 [RISK] Verify script tags in input are escaped in response
   ```

4. **Execute RED→GREEN→REFACTOR**:
   ```bash
   /spec.implement
   # First executes TDD-R01 (risk test)
   # Then executes TDD-001, TDD-002... (increment tests)
   ```

5. **Validate quality**:
   ```bash
   /tdd.validate
   ```