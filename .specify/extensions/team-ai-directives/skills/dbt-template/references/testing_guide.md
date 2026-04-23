# Testing Guidelines Reference

See @rule:testing/java_junit5_best_practices.md for testing best practices.

## Data Quality Testing for dbt Projects

### Basic Testing Patterns
- Test for null values in critical columns
- Validate data uniqueness constraints
- Check data freshness and timeliness
- Test referential integrity between models

### Test Organization
- Place tests in `tests/` directory
- Use descriptive test names
- Group related tests together
- Document test assumptions and success criteria

### Integration with Team Testing Standards
- Follow team testing guidelines for test structure
- Include appropriate test coverage metrics
- Document test data and fixtures
- Align with team's testing tools and frameworks