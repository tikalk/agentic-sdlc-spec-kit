# Rule: Spring Boot Application Patterns

## Checklist
- Use constructor injection for all @Service, @Controller, @RestController classes
- Define repositories with Spring Data JPA interfaces and derived query methods
- Use @Query with named parameters (:paramName) for custom queries
- Create @Configuration classes with @Bean methods for beans
- Use @Profile for environment-specific configuration
- Test with @DataJpaTest for repository layer, @SpringBootTest for integration tests
- Handle exceptions with @ControllerAdvice and @ExceptionHandler

## Component Layering

### @Service Layer
- Annotate service classes with @Service
- Business logic and orchestration belongs in service layer
- Use constructor injection to inject dependencies (repositories, other services)
- Keep services focused on business logic, not HTTP or database specifics

### @Repository Layer
- Extend JpaRepository, CrudRepository, or PagingAndSortingRepository
- Use derived query methods for simple queries: findByEmail(), findByStatusAndEmail()
- For custom queries, use @Query with named parameters (see Spring Data JPA section)
- Return Optional<T> for methods that may return no results

### @Controller Layer
- Use @RestController for API endpoints returning JSON/XML
- Use @Controller for view-based (HTML) endpoints
- Use @RequestMapping, @GetMapping, @PostMapping, etc. for URL mapping
- Inject services via constructor injection
- Return ResponseEntity<T> for status codes and response body control

## Dependency Injection

### Constructor Injection (Primary)
```java
@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final EmailService emailService;

    public CustomerService(CustomerRepository customerRepository, EmailService emailService) {
        this.customerRepository = customerRepository;
        this.emailService = emailService;
    }
}
```

- Use final fields for injected dependencies
- Constructor injection makes dependencies explicit and enables immutability
- Avoid @Autowired field injection (harder to test, less explicit)

## Spring Data JPA

### Derived Query Methods
```java
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    Optional<Customer> findByEmail(String email);
    List<Customer> findByStatus(String status);
    Optional<Customer> findByEmailAndStatus(String email, String status);
}
```

- Spring derives queries from method names automatically
- Returns Optional for single-result methods (good for null safety)
- Supports AND, OR, Like, Between, etc. in method names

### @Query with Named Parameters
```java
@Query("SELECT c FROM Customer c WHERE c.email = :email AND c.status = :status")
Optional<Customer> findByEmailAndStatus(@Param("email") String email,
                                       @Param("status") String status);
```

- Use @Param("name") for named parameters (secure, readable)
- Never concatenate or interpolate strings in @Query (SQL injection risk)
- See @rule:security/java_prevent_sql_injection.md for security patterns

## Configuration

### @Configuration and @Bean
```java
@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    @Profile("test")
    public DataSource testDataSource() {
        // Test-specific data source
    }
}
```

- Use @Configuration for classes that define beans
- Use @Bean to create and configure Spring-managed objects
- Use @Profile to limit beans to specific environments (dev, test, prod)

### Profiles
```java
@Profile("production")
@Service
public class ProductionEmailService implements EmailService {
    // Production implementation
}

@Profile("test")
@Service
public class TestEmailService implements EmailService {
    // Mock implementation for tests
}
```

- Use @ActiveProfiles("test") in tests to load test configuration
- Define interface-based services for environment-specific implementations

## Testing

### @DataJpaTest for Repository Layer
```java
@DataJpaTest
@ActiveProfiles("test")
@DisplayName("CustomerRepository Integration Tests")
class CustomerRepositoryIntegrationTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private CustomerRepository customerRepository;

    @Test
    @DisplayName("Should find customer by email")
    void shouldFindCustomerByEmail() {
        Customer customer = new Customer("alex@example.com", "active");
        savedCustomer = entityManager.persistAndFlush(customer);

        var result = customerRepository.findByEmail("alex@example.com");

        assertTrue(result.isPresent());
    }
}
```

- Uses in-memory database (H2) for fast, isolated tests
- Tests JPA repository behavior without full application context
- See `examples/testing/spring_boot_integration_test.md` for complete example

### @SpringBootTest for Integration Tests
```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("CustomerController Integration Tests")
class CustomerControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Should return customer by email")
    void shouldReturnCustomerByEmail() throws Exception {
        mockMvc.perform(get("/api/customers/alex@example.com"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("alex@example.com"));
    }
}
```

- Loads full application context for end-to-end testing
- Use @AutoConfigureMockMvc for web layer testing without real server
- Use @MockBean for external dependencies (email services, external APIs)

## Exception Handling

### @ControllerAdvice
```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(CustomerNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCustomerNotFound(CustomerNotFoundException ex) {
        ErrorResponse error = new ErrorResponse("NOT_FOUND", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.toList());
        ErrorResponse error = new ErrorResponse("VALIDATION_ERROR", errors);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
}
```

- Centralize exception handling with @ControllerAdvice
- Return appropriate HTTP status codes (404 for not found, 400 for validation)
- Use structured error responses for API consumers

## Examples

### Complete Service Layer
```java
@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final EmailService emailService;

    public CustomerService(CustomerRepository customerRepository, EmailService emailService) {
        this.customerRepository = customerRepository;
        this.emailService = emailService;
    }

    public Customer createCustomer(Customer customer) {
        Customer saved = customerRepository.save(customer);
        emailService.sendWelcomeEmail(customer.getEmail());
        return saved;
    }

    public Optional<Customer> findByEmail(String email) {
        return customerRepository.findByEmail(email);
    }
}
```

## Rationale

Spring Boot provides a comprehensive framework for building production-ready applications. Following these patterns ensures:
- **Testability**: Constructor injection and clear layering make testing straightforward
- **Maintainability**: Separation of concerns (Service, Repository, Controller) keeps code organized
- **Security**: Named parameters in @Query prevent SQL injection vulnerabilities
- **Flexibility**: Profiles and configuration beans enable environment-specific setups
- **Consistency**: Standard annotations and testing patterns provide predictable structure across the codebase

For testing specifics, see @rule:testing/java_junit5_best_practices.md.
For security patterns (SQL injection), see @rule:security/java_prevent_sql_injection.md.
For dependency injection patterns, see @rule:style-guides/dependency_injection.md.
