# Language-Specific TDD Configurations

This document provides language and framework-specific configuration for TDD extension.

## Python (pytest)

### Detection
Files checked: `pyproject.toml`, `requirements.txt`, `setup.py`

### Configuration
| Setting | Value |
|---------|-------|
| Language | python |
| Framework | pytest |
| Test Directory | `tests/` |
| File Pattern | `test_*.py`, `*_test.py` |
| Binary | `pytest` |
| Flags | `-xvs` |
| Stop on First Failure | `-x` |

### Test File Example
```python
# tests/test_auth.py
import pytest

def test_valid_login_succeeds():
    """Test that valid credentials return success."""
    # Arrange
    credentials = {"username": "user", "password": "pass"}
    
    # Act
    result = login(credentials)
    
    # Assert
    assert result.status_code == 200
    assert result.token is not None

def test_invalid_credentials_fail():
    """Test that invalid credentials are rejected."""
    # Arrange
    credentials = {"username": "bad", "password": "wrong"}
    
    # Act & Assert
    with pytest.raises(AuthenticationError):
        login(credentials)
```

### Run Command
```bash
pytest -xvs tests/
```

---

## TypeScript (vitest)

### Detection
Files checked: `package.json`

### Configuration
| Setting | Value |
|---------|-------|
| Language | typescript |
| Framework | vitest |
| Test Directory | `__tests__/` or `tests/` |
| File Pattern | `*.test.ts`, `*.spec.ts` |
| Binary | `vitest` |
| Flags | `run` |
| Stop on First Failure | Default |

### Test File Example
```typescript
// __tests__/auth.test.ts
import { describe, it, expect, beforeEach } from 'vitest'

describe('Authentication', () => {
  let auth: AuthService
  
  beforeEach(() => {
    auth = new AuthService()
  })
  
  it('should return token on valid credentials', () => {
    const result = auth.login('user', 'pass')
    expect(result.status).toBe(200)
    expect(result.token).toBeDefined()
  })
  
  it('should throw on invalid credentials', () => {
    expect(() => auth.login('bad', 'wrong'))
      .toThrow('Invalid credentials')
  })
})
```

### Run Command
```bash
vitest run
```

---

## TypeScript (jest)

### Detection
Files checked: `package.json`

### Configuration
| Setting | Value |
|---------|-------|
| Language | typescript |
| Framework | jest |
| Test Directory | `__tests__/` or `tests/` |
| File Pattern | `*.test.ts`, `*.spec.ts` |
| Binary | `npx jest` |
| Flags | `--passWithNoTests` |

### Run Command
```bash
npx jest --passWithNoTests
```

---

## Go (testing)

### Detection
Files checked: `go.mod`

### Configuration
| Setting | Value |
|---------|-------|
| Language | go |
| Framework | testing (standard library) |
| Test Directory | Same as source (`*_test.go`) |
| File Pattern | `*_test.go` |
| Binary | `go test` |
| Flags | `-v` |
| Stop on First Failure | `-failfast` |

### Test File Example
```go
// auth_test.go
package auth

import (
    "testing"
)

func TestLogin_Success(t *testing.T) {
    // Arrange
    creds := Credentials{Username: "user", Password: "pass"}
    
    // Act
    result, err := Login(creds)
    
    // Assert
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if result.Token == "" {
        t.Error("expected token to be set")
    }
}

func TestLogin_InvalidCredentials(t *testing.T) {
    // Arrange
    creds := Credentials{Username: "bad", Password: "wrong"}
    
    // Act
    _, err := Login(creds)
    
    // Assert
    if err == nil {
        t.Error("expected error for invalid credentials")
    }
}
```

### Run Command
```bash
go test -v -failfast ./...
```

---

## Rust (cargo)

### Detection
Files checked: `Cargo.toml`

### Configuration
| Setting | Value |
|---------|-------|
| Language | rust |
| Framework | cargo |
| Test Directory | Same as source (`#[cfg(test)]`) |
| File Pattern | `*_test.rs` or inline `#[test]` |
| Binary | `cargo test` |
| Flags | (none) |
| Stop on First Failure | `--test-threads=1 --nocapture` |

### Test File Example
```rust
// src/auth.rs

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_valid_login_succeeds() {
        let result = login("user", "pass");
        assert!(result.is_ok());
    }
    
    #[test]
    fn test_invalid_credentials_fail() {
        let result = login("bad", "wrong");
        assert!(result.is_err());
    }
}
```

### Run Command
```bash
cargo test -- --test-threads=1 --nocapture
```

---

## Java (JUnit)

### Detection
Files checked: `pom.xml`, `build.gradle`

### Configuration
| Setting | Value |
|---------|-------|
| Language | java |
| Framework | junit |
| Test Directory | `src/test/java/` |
| File Pattern | `*Test.java` |
| Binary | `mvn test` or `./gradlew test` |
| Flags | (none) |

### Run Command
```bash
# Maven
mvn test

# Gradle
./gradlew test
```

---

## C# (.NET)

### Detection
Files checked: `*.csproj`, `*.sln`

### Configuration
| Setting | Value |
|---------|-------|
| Language | csharp |
| Framework | xunit / nunit |
| Test Directory | `Tests/` |
| File Pattern | `*Test.cs` |
| Binary | `dotnet test` |
| Flags | (none) |

### Run Command
```bash
dotnet test
```

---

## Framework Comparison

| Language | Framework | Binary | Key Flag |
|----------|-----------|--------|----------|
| Python | pytest | pytest | -x |
| TS/JS | vitest | vitest | run |
| TS/JS | jest | npx jest | --passWithNoTests |
| Go | testing | go test | -v -failfast |
| Rust | cargo | cargo test | --test-threads=1 |
| Java | junit | mvn/gradlew | (none) |
| C# | xunit | dotnet | (none) |