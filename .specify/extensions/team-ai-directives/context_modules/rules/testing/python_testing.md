---
instruction_type: Review
priority: Standard
description: Standards for writing and organizing Python tests with pytest
---

# Rule: Python Testing with Pytest

## Checklist
- Use pytest for all new test suites
- Organize tests with class-based grouping for related test scenarios
- Use fixtures in conftest.py for shared test data
- Apply pytest.mark.parametrize for testing multiple inputs
- Mock external dependencies (databases, APIs, file systems) not code under test
- Follow TDD when appropriate: write failing test, implement to pass, refactor
- Use descriptive test method names following pytest conventions

## Test Organization

### Class-Based Test Organization
```python
class TestCustomerSerializer:
    def test_valid_payload(self, serializer_factory):
        serializer = serializer_factory(
            "CustomerSerializer",
            data={"email": "alex@example.com", "status": "active"},
        )

        assert serializer.is_valid(), serializer.errors
        assert serializer.validated_data["status"] == "active"

    def test_missing_email(self, serializer_factory):
        serializer = serializer_factory("CustomerSerializer", data={"status": "active"})

        assert not serializer.is_valid()
        assert "email" in serializer.errors
```

- Group related tests in classes for organization
- Classes make fixtures and setup methods scoped to related tests
- Use descriptive class and method names (TestCustomerSerializer, test_valid_payload)

### Function-Based Test Organization
```python
def test_create_customer_success(db_session):
    customer = Customer(email="alex@example.com", status="active")
    db_session.add(customer)
    db_session.commit()

    retrieved = db_session.query(Customer).filter_by(email="alex@example.com").first()
    assert retrieved is not None
    assert retrieved.status == "active"

def test_create_customer_missing_email(db_session):
    customer = Customer(status="active")

    with pytest.raises(ValidationError):
        db_session.add(customer)
        db_session.commit()
```

- Use function-based tests for simple, independent test cases
- Group related test functions with descriptive names (test_create_customer_*)

See `examples/testing/pytest_class_based.md` for complete examples.

## Fixtures and Conftest

### conftest.py for Shared Fixtures
```python
# conftest.py
import pytest
from app.models import Customer, db

@pytest.fixture
def db_session():
    session = db.session
    session.begin_nested()
    yield session
    session.rollback()

@pytest.fixture
def serializer_factory():
    def make(class_name, **kwargs):
        module = __import__("app.serializers", fromlist=[class_name])
        serializer_cls = getattr(module, class_name)
        return serializer_cls(**kwargs)
    return make
```

- Define fixtures in conftest.py for automatic discovery
- Fixtures available to all tests in same directory and subdirectories
- Use fixture factories (like serializer_factory) for dynamic test data

### Using Fixtures in Tests
```python
def test_with_fixture(db_session, serializer_factory):
    # Use db_session fixture for database
    customer = Customer(email="test@example.com", status="active")
    db_session.add(customer)
    db_session.commit()

    # Use serializer_factory fixture for serializers
    serializer = serializer_factory("CustomerSerializer", data={"email": "test@example.com"})
    assert serializer.is_valid()
```

- Fixture names in function signature are automatically injected
- Fixtures can depend on other fixtures

## Parametrized Tests

### pytest.mark.parametrize
```python
@pytest.mark.parametrize("email,expected_valid", [
    ("alex@example.com", True),
    ("invalid-email", False),
    ("", False),
])
def test_email_validation(email, expected_valid):
    serializer = CustomerSerializer(data={"email": email})

    is_valid = serializer.is_valid()

    assert is_valid == expected_valid
```

- Test multiple input scenarios with single test function
- Parameter values become test function arguments
- Clear separation of test data from test logic

## Mocking Guidelines

### Mocking External Dependencies
```python
from unittest.mock import Mock, patch
import pytest

def test_send_welcome_email():
    # Mock external email service
    mock_email_service = Mock()
    customer_service = CustomerService(email_service=mock_email_service)

    # Act
    customer_service.create_customer("alex@example.com", "active")

    # Assert
    mock_email_service.send_welcome_email.assert_called_once_with("alex@example.com")
```

- Mock external dependencies (databases, APIs, file systems)
- Do NOT mock the code under test
- Use Mock objects to verify method calls and arguments

### Patching with pytest
```python
import pytest
from unittest.mock import patch

def test_with_patch():
    with patch("app.services.email.EmailService") as mock_email_service:
        mock_email_service.return_value.send_welcome_email.return_value = True

        customer_service = CustomerService()
        customer_service.create_customer("alex@example.com", "active")

        mock_email_service.return_value.send_welcome_email.assert_called_once()
```

- Use patch to replace dependencies during test execution
- Use with context manager for temporary patches

## TDD Principles

### Test-Driven Development Cycle
1. **Red**: Write a failing test for desired behavior
2. **Green**: Write minimal code to make test pass
3. **Refactor**: Improve code while keeping tests green

### TDD Example
```python
# Step 1: Write failing test
def test_calculate_discount_for_vip():
    customer = Customer(email="vip@example.com", is_vip=True, total=100)
    discount = calculate_discount(customer)

    assert discount == 10  # Test fails: calculate_discount not implemented

# Step 2: Write minimal implementation
def calculate_discount(customer):
    if customer.is_vip:
        return customer.total * 0.10
    return 0

# Step 3: Add more tests and refactor
@pytest.mark.parametrize("is_vip,total,expected", [
    (True, 100, 10),
    (False, 100, 0),
    (True, 50, 5),
])
def test_calculate_discount_various_scenarios(is_vip, total, expected):
    customer = Customer(email="test@example.com", is_vip=is_vip, total=total)
    discount = calculate_discount(customer)

    assert discount == expected
```

- Write tests before implementation when possible
- Focus on one test/feature at a time
- Refactor code after making tests pass

## Test Naming Conventions

- Use descriptive test names: `test_calculate_discount_for_vip` not `test_discount`
- Use prefixes: `test_` for test functions, `Test` for test classes
- Name fixtures descriptively: `db_session`, `serializer_factory`, `authenticated_client`
- Use `@pytest.mark.parametrize` for data-driven tests

## Assertions

### Pytest Assertions
```python
def test_assertions():
    # Boolean assertions
    assert customer.is_valid() == True
    assert customer.is_valid() is True

    # Equality assertions
    assert result == expected_value

    # None assertions
    assert customer is not None

    # Exception assertions
    with pytest.raises(CustomerNotFoundError):
        get_customer(999)

    # Collection assertions
    assert len(results) > 0
    assert "expected@email.com" in [c.email for c in results]
```

- Use built-in assert statements (no special imports needed)
- Pytest provides clear error messages on assertion failure
- Use `pytest.raises` for exception testing

## Examples

### Complete Test Suite with Fixtures
```python
# conftest.py
@pytest.fixture
def db_session():
    session = db.session
    session.begin_nested()
    yield session
    session.rollback()

# test_customers.py
class TestCustomerRepository:
    def test_find_by_email(self, db_session):
        customer = Customer(email="alex@example.com", status="active")
        db_session.add(customer)
        db_session.commit()

        result = db_session.query(Customer).filter_by(email="alex@example.com").first()

        assert result is not None
        assert result.email == "alex@example.com"
        assert result.status == "active"

    def test_find_by_email_not_found(self, db_session):
        result = db_session.query(Customer).filter_by(email="nonexistent@example.com").first()

        assert result is None
```

## Rationale

Well-structured tests serve as living documentation and catch regressions early. Following these pytest patterns ensures:
- **Maintainability**: Class-based organization groups related tests logically
- **Reusability**: Fixtures in conftest.py reduce test setup duplication
- **Coverage**: Parametrized tests cover multiple scenarios efficiently
- **Testability**: Proper mocking isolates code under test from external dependencies
- **TDD Benefits**: Writing tests first drives better design and fewer bugs

For style guide, see @rule:style-guides/python_pep8_and_docstrings.md.

## Related Rules
- @rule:style-guides/python_pep8_and_docstrings.md
