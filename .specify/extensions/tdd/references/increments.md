# TDD Increment Patterns

This document provides increment patterns for different feature types in Test-Driven Development.

## Overview

TDD increments follow a structured approach:
1. **Degenerate Cases** - Empty, null, zero, missing
2. **Happy Path** - Valid inputs, successful operations
3. **Variations** - Multiple items, custom fields, alternative valid inputs
4. **Edge Cases** - Boundary values, non-existent entities, concurrent access
5. **Error Cases** - Invalid inputs, constraint violations, permission errors

---

## CRUD Operations

### Pattern: Create, Read, Update, Delete

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Create with empty input |
| TDD-002 | Degenerate | Create with null input |
| TDD-003 | Degenerate | Create with missing required fields |
| TDD-004 | Happy | Create valid entity |
| TDD-005 | Happy | Read existing entity |
| TDD-006 | Happy | Update with valid changes |
| TDD-007 | Happy | Delete existing entity |
| TDD-008 | Edge | Read non-existent entity |
| TDD-009 | Edge | Update non-existent entity |
| TDD-010 | Edge | Delete non-existent entity |
| TDD-011 | Edge | Create duplicate entity |
| TDD-012 | Error | Create with invalid data types |
| TDD-013 | Error | Create with constraint violations |

### Example Test Sequence

```python
# 1. Degenerate - Empty
def test_create_with_empty_payload():
    with pytest.raises(ValidationError):
        create({})

# 2. Degenerate - Missing required
def test_create_with_missing_required():
    with pytest.raises(ValidationError):
        create({"name": "test"})  # missing email

# 3. Happy - Valid
def test_create_valid_entity():
    result = create({"name": "test", "email": "test@example.com"})
    assert result.id is not None
    assert result.status == "created"

# 4. Edge - Read not found
def test_read_nonexistent():
    with pytest.raises(NotFoundError):
        read("nonexistent-id")
```

---

## Data Transform

### Pattern: Input → Transformation → Output

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Transform empty input |
| TDD-002 | Degenerate | Transform null input |
| TDD-003 | Degenerate | Transform NaN/invalid numbers |
| TDD-004 | Happy | Transform valid single item |
| TDD-005 | Happy | Transform valid multiple items |
| TDD-006 | Happy | Transform nested structures |
| TDD-007 | Edge | Transform boundary values |
| TDD-008 | Edge | Transform maximum values |
| TDD-009 | Edge | Transform minimum values |
| TDD-010 | Error | Transform malformed input |
| TDD-011 | Error | Handle missing required fields |

---

## State Machine

### Pattern: State → Transition → New State

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Initialize with invalid state |
| TDD-002 | Happy | Valid state transition |
| TDD-003 | Happy | Complete transition sequence |
| TDD-004 | Happy | Transition to terminal state |
| TDD-005 | Edge | Invalid transition attempt |
| TDD-006 | Edge | Transition from terminal state |
| TDD-007 | Edge | Concurrent state changes |
| TDD-008 | Error | Handle invalid state input |

### Example Test Sequence

```python
# 1. Degenerate - Invalid initial
def test_invalid_initial_state():
    with pytest.raises(InvalidStateError):
        Order("invalid_status")

# 2. Happy - Valid transition
def test_submit_pending_to_processing():
    order = Order("pending")
    order.submit()
    assert order.status == "processing"

# 3. Edge - Invalid transition
def test_cannot_cancel_completed():
    order = Order("completed")
    with pytest.raises(InvalidTransitionError):
        order.cancel()
```

---

## API/Integration

### Pattern: Client → Request → Response Handling

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Handle connection error |
| TDD-002 | Degenerate | Handle timeout |
| TDD-003 | Degenerate | Handle DNS resolution failure |
| TDD-004 | Happy | Handle 200 OK response |
| TDD-005 | Happy | Handle 201 Created response |
| TDD-006 | Happy | Handle 204 No Content response |
| TDD-007 | Edge | Handle 400 Bad Request |
| TDD-008 | Edge | Handle 401 Unauthorized |
| TDD-009 | Edge | Handle 403 Forbidden |
| TDD-010 | Edge | Handle 404 Not Found |
| TDD-011 | Error | Handle 500 Internal Server Error |
| TDD-012 | Error | Handle 502 Bad Gateway |
| TDD-013 | Error | Handle 503 Service Unavailable |
| TDD-014 | Error | Handle malformed JSON response |

---

## Authentication

### Pattern: Auth flows and security

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Authenticate with empty credentials |
| TDD-002 | Degenerate | Authenticate with null token |
| TDD-003 | Happy | Valid authentication succeeds |
| TDD-004 | Happy | Valid token accepted |
| TDD-005 | Happy | Refresh token works |
| TDD-006 | Edge | Expired token rejected |
| TDD-007 | Edge | Malformed token rejected |
| TDD-008 | Edge | Revoked token rejected |
| TDD-009 | Error | Invalid credentials rejected |
| TDD-010 | Error | Missing credentials rejected |
| TDD-011 | Error | SQL injection attempts blocked |

---

## Database Operations

### Pattern: CRUD with persistence

| Increment | Type | Description |
|----------|------|-------------|
| TDD-001 | Degenerate | Query with empty result set |
| TDD-002 | Degenerate | Insert with null values |
| TDD-003 | Happy | Successful CRUD operations |
| TDD-004 | Happy | Transaction commit works |
| TDD-005 | Happy | Query returns correct results |
| TDD-006 | Edge | Handle large datasets |
| TDD-007 | Edge | Handle concurrent transactions |
| TDD-008 | Edge | Handle connection pool exhaustion |
| TDD-009 | Error | Handle constraint violations |
| TDD-010 | Error | Handle deadlocks |
| TDD-011 | Error | Handle query timeouts |

---

## Feature Type Selection Guide

Use this guide to determine which pattern to use:

| Feature Type | Pattern to Use |
|--------------|----------------|
| User management (CRUD) | CRUD Operations |
| Data import/export | Data Transform |
| Workflow engine | State Machine |
| External API calls | API/Integration |
| Login, sessions, tokens | Authentication |
| Data persistence | Database Operations |
| File processing | Data Transform |
| Event handling | State Machine |

---

## Increment Order Priority

For each feature, tests should be written in this priority order:

1. **Risk-Based Tests** (from Risk Register) - HIGHEST PRIORITY
   - Security vulnerabilities
   - Data breaches
   - Critical business logic

2. **Degenerate Cases** - Catch empty/null/missing early
   - Prevents null pointer exceptions
   - Validates error handling

3. **Happy Path** - Core functionality works
   - Validates main use case

4. **Edge Cases** - Boundary conditions
   - Maximum/minimum values
   - Non-existent entities
   - Concurrent access

5. **Error Cases** - Failure handling
   - Invalid inputs
   - Constraint violations
   - Permission errors

6. **Variations** - Alternative valid inputs
   - Multiple formats
   - Custom configurations