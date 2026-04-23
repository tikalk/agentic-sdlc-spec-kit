# Rule: JUnit 5 Testing Best Practices

## Checklist
- Use JUnit 5 (`junit-jupiter`) instead of JUnit 4 for all new tests.
- Structure tests using `@Nested` classes to group related test scenarios logically.
- Use `@DisplayName` annotations for human-readable test descriptions.
- Follow Arrange-Act-Assert (AAA) pattern: set up test data, execute the method under test, verify results.
- Use `@BeforeEach` for test setup, avoid `@BeforeAll` unless truly necessary for expensive initialization.
- Prefer `assertThrows()` for exception testing over try-catch blocks.
- Use `assertAll()` to group multiple assertions and see all failures at once.
- Leverage parameterized tests (`@ParameterizedTest`) for testing multiple inputs.
- Use `@Mock` with `MockitoExtension` for dependency injection in tests.
- Keep test methods focused on a single behavior or scenario.
- Use descriptive test method names: `shouldReturnCustomerWhenFound()` not `testFindCustomer()`.
- Avoid test interdependencies; each test should be independent and runnable in isolation.

## Test Organization
- Group related tests in `@Nested` classes with descriptive `@DisplayName`.
- Use test fixtures and builders to reduce test setup code duplication.
- Extract common test setup to `@BeforeEach` methods or test base classes when appropriate.
- Keep test classes focused on testing a single class or component.

## Mocking Guidelines
- Mock external dependencies (databases, APIs, file systems) but avoid mocking the class under test.
- Use `@Mock` annotation with `MockitoExtension` for clean dependency injection.
- Prefer `when().thenReturn()` for stubbing, use `verify()` sparingly (focus on behavior, not implementation).
- Use `ArgumentMatchers` (e.g., `any()`, `eq()`) appropriately but avoid over-mocking.

## Assertions
- Use JUnit 5 assertions (`assertEquals`, `assertNotNull`, `assertTrue`, etc.).
- Use `assertThrows()` with lambda expressions for exception testing.
- Use `assertAll()` to group related assertions and see all failures.
- Prefer specific assertions over generic ones (e.g., `assertEquals(expected, actual)` over `assertTrue(expected.equals(actual))`).

## Rationale
Well-structured tests serve as living documentation and catch regressions early. Following these patterns ensures tests are maintainable, readable, and provide clear feedback when they fail.

