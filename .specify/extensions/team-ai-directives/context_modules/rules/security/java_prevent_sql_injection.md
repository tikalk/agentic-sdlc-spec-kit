# Rule: Prevent SQL Injection in Java

## Checklist
- Always use parameterized queries with `PreparedStatement`—never string concatenation or interpolation.
- When using JPA/Hibernate, use named parameters (`:paramName`) or positional parameters (`?1`, `?2`) in `@Query` annotations.
- When using Spring Data JPA, prefer method names or `@Query` with parameters over `@Query` with string interpolation.
- Validate and sanitize inputs at the controller/service boundary layer before database operations.
- Enforce least privilege on database credentials; use read-only connections where possible.
- Use database connection pooling with appropriate security configurations.
- Add regression tests covering malicious payloads (e.g., `' OR 1=1 --`, `'; DROP TABLE users; --`).
- Avoid dynamic query building; if necessary, use query builders (JPA Criteria API, QueryDSL) that handle parameterization.

## Examples

### Good: Parameterized PreparedStatement
```java
String sql = "SELECT * FROM users WHERE email = ? AND status = ?";
try (PreparedStatement stmt = connection.prepareStatement(sql)) {
    stmt.setString(1, email);
    stmt.setString(2, status);
    ResultSet rs = stmt.executeQuery();
    // ...
}
```

### Good: JPA Named Parameters
```java
@Query("SELECT u FROM User u WHERE u.email = :email AND u.status = :status")
Optional<User> findByEmailAndStatus(@Param("email") String email, @Param("status") String status);
```

### Avoid: String Concatenation
```java
// NEVER DO THIS - Vulnerable to SQL injection
String sql = "SELECT * FROM users WHERE email = '" + email + "'";
// If email = "admin' OR '1'='1", this becomes: 
// SELECT * FROM users WHERE email = 'admin' OR '1'='1'
Statement stmt = connection.createStatement();
ResultSet rs = stmt.executeQuery(sql);
```

## Rationale
SQL injection remains a top OWASP risk. Java's `PreparedStatement` and JPA parameter binding ensure queries are safe by construction. Following these patterns prevents injection vulnerabilities in all database interactions.

