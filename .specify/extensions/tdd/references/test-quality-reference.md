# Test Quality Reference

This document provides guidelines for writing high-quality tests and identifies common anti-patterns to avoid.

## Quality Scoring

Tests are scored from 0-100 based on the following criteria:

### Good Practices (+points)

| Practice | Points | Description |
|----------|--------|-------------|
| Tests through public interfaces | +10 | Tests exercise the system through its public API, not internal methods |
| Describes behavior not implementation | +10 | Test names and assertions describe WHAT the system does, not HOW |
| Follows AAA pattern | +5 | Tests use Arrange-Act-Assert structure |
| Descriptive test names | +5 | Test names clearly describe the scenario being tested |
| Refactor-safe | +10 | Tests survive internal refactoring without changes |

### Anti-Patterns (-points)

| Anti-Pattern | Points | Description |
|-------------|--------|-------------|
| Mocks internal collaborators | -10 | Tests mock internal implementation details, not external dependencies |
| Tests implementation details | -15 | Tests check private methods, internal state, or specific implementations |
| Tests data structure shapes | -15 | Tests assert on specific data structures rather than behavior |
| Brittle tests | -10 | Tests break on any refactoring or minor changes |

---

## Good Test Examples

### Example 1: Public Interface Testing ✓

```python
# GOOD: Tests through public interface
def test_login_returns_token_for_valid_credentials():
    """Valid credentials should return an authentication token."""
    # Arrange
    credentials = {"username": "user", "password": "pass"}
    
    # Act
    result = auth_service.login(credentials)
    
    # Assert
    assert result.status_code == 200
    assert "token" in result.body
    assert result.body["token"] is not None
```

### Example 2: Behavior-Focused ✓

```python
# GOOD: Describes behavior
def test_transfer_funds_deducts_from_source_account():
    """Transferring funds should deduct amount from source account."""
    source = Account(balance=100)
    destination = Account(balance=0)
    
    transfer(source, destination, 50)
    
    assert source.balance == 50
    assert destination.balance == 50
```

### Example 3: AAA Pattern ✓

```python
# GOOD: Clear AAA structure
def test_order_submits_successfully():
    # Arrange
    order = Order(items=[{"product": "widget", "qty": 2}])
    
    # Act
    result = order.submit()
    
    # Assert
    assert result.status == "submitted"
    assert len(result.items) == 2
```

---

## Bad Test Examples

### Example 1: Testing Implementation Details ✗

```python
# BAD: Tests implementation details
def test_login_uses_bcrypt_hash():
    """Login should use bcrypt for password hashing."""
    # This tests HOW it's implemented, not WHAT it does
    
    # Bad: Testing internal method
    assert auth_service._hash_password == bcrypt.hash
    
    # Bad: Testing specific algorithm
    assert "bcrypt" in str(auth_service._hash_function)
```

### Example 2: Mocking Internal Collaborators ✗

```python
# BAD: Mocks internal collaborators
def test_calculate_discount():
    # Don't mock internal components
    mock_inventory = Mock()
    mock_inventory.get_stock.return_value = 10
    
    # Don't reach into internal state
    service._inventory = mock_inventory
    
    result = service.calculate_discount("product", 5)
    
    # This will break when internal implementation changes
```

### Example 3: Brittle Test ✗

```python
# BAD: Brittle test with hardcoded values
def test_user_creation():
    # Don't use exact timestamps or IDs
    user = create_user("test", "test@example.com")
    
    # Brittle: Breaks if ID generation changes
    assert user.id == 1
    
    # Brittle: Breaks if timestamp format changes  
    assert user.created_at == "2024-01-15T10:30:00Z"
    
    # Better: Test behavior, not exact values
    assert user.id is not None
    assert user.created_at is not None
```

### Example 4: Testing Data Structure ✗

```python
# BAD: Tests data structure shape
def test_user_object_structure():
    user = get_user(1)
    
    # Bad: Tests HOW, not WHAT
    assert hasattr(user, "id")
    assert hasattr(user, "name")
    assert hasattr(user, "email")
    assert hasattr(user, "_internal_cache")
    
    # Better: Test behavior
    assert user.can_access("/dashboard")
    assert user.has_permission("read")
```

---

## Refactoring Safety

### Tests Should Survive Refactoring

Good tests verify **behavior**, not **implementation**:

| Implementation Change | Should Break Test? | Notes |
|----------------------|-------------------|-------|
| Rename internal method | No | Internal implementation detail |
| Change data structure | No | As long as behavior is same |
| Refactor algorithm | No | Different implementation, same result |
| Add caching layer | No | Performance optimization |
| **API contract change** | **Yes** | Public interface changed |
| **Behavior change** | **Yes** | System does something different |

---

## Test Quality Checklist

Use this checklist when writing or reviewing tests:

- [ ] Does the test verify behavior through public interfaces?
- [ ] Does the test name describe WHAT is being tested?
- [ ] Does the test use AAA pattern (Arrange-Act-Assert)?
- [ ] Does the test avoid mocking internal collaborators?
- [ ] Does the test avoid testing implementation details?
- [ ] Is the test resilient to internal refactoring?
- [ ] Are test assertions checking behavior, not data shapes?
- [ ] Are test names descriptive and clear?
- [ ] Does the test have appropriate setup/teardown?
- [ ] Are edge cases and error conditions tested?

---

## Score Interpretation

| Score | Quality Level | Action Required |
|-------|--------------|----------------|
| 90-100 | Excellent | Maintain quality, continue |
| 70-89 | Good | Minor improvements possible |
| 50-69 | Needs Work | Address high-priority issues |
| 0-49 | Poor | Significant refactoring needed |

---

## Test Quality Anti-Patterns to Avoid

1. **Test Naming**: `test_function_a()`, `test_1()`, `test_case_2()`
   - **Fix**: Use descriptive names like `test_login_fails_with_invalid_credentials()`

2. **Multiple Assertions Without Context**: 
   ```python
   # Bad
   assert user.name == "John"
   assert user.email == "john@example.com"
   assert user.active == True
   ```
   - **Fix**: Group assertions by scenario with descriptive text

3. **No Teardown**:
   - **Fix**: Always clean up test data, especially with databases/files

4. **Shared State Between Tests**:
   - **Fix**: Use setup/teardown or fresh instances per test

5. **Tests That Only Pass Locally**:
   - **Fix**: Ensure tests work in any environment

6. **No Error Handling Tests**:
   - **Fix**: Always test error cases, not just happy paths