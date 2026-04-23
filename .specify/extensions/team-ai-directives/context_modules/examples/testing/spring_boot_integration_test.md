---
instruction_type: Generation
priority: Standard
description: Example of Spring Boot integration testing
---

# Example: Spring Boot Integration Test

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
@ActiveProfiles("test")
@DisplayName("CustomerRepository Integration Tests")
class CustomerRepositoryIntegrationTest {
    
    @Autowired
    private TestEntityManager entityManager;
    
    @Autowired
    private CustomerRepository customerRepository;
    
    private Customer savedCustomer;
    
    @BeforeEach
    void setUp() {
        Customer customer = new Customer("alex@example.com", "active");
        savedCustomer = entityManager.persistAndFlush(customer);
    }
    
    @Test
    @DisplayName("Should find customer by email")
    void shouldFindCustomerByEmail() {
        var result = customerRepository.findByEmail("alex@example.com");
        
        assertTrue(result.isPresent());
        Customer found = result.get();
        assertEquals(savedCustomer.getId(), found.getId());
        assertEquals("alex@example.com", found.getEmail());
    }
    
    @Test
    @DisplayName("Should return empty when customer not found")
    void shouldReturnEmptyWhenCustomerNotFound() {
        var result = customerRepository.findByEmail("nonexistent@example.com");
        
        assertTrue(result.isEmpty());
    }
    
    @Test
    @DisplayName("Should save and retrieve customer")
    void shouldSaveAndRetrieveCustomer() {
        Customer newCustomer = new Customer("new@example.com", "pending");
        Customer saved = customerRepository.save(newCustomer);
        entityManager.flush();
        entityManager.clear();
        
        var result = customerRepository.findById(saved.getId());
        
        assertTrue(result.isPresent());
        Customer retrieved = result.get();
        assertEquals("new@example.com", retrieved.getEmail());
        assertEquals("pending", retrieved.getStatus());
    }
}
```

**Why it works**

- Uses `@DataJpaTest` to test JPA repositories with an in-memory database (H2 by default).
- Leverages `TestEntityManager` for fine-grained control over test data persistence.
- Demonstrates integration testing patterns that verify database interactions work correctly.
- Uses `@ActiveProfiles("test")` to ensure test-specific configuration is loaded.
- Shows proper use of `Optional` for nullable repository methods.
- Follows Arrange-Act-Assert pattern with setup in `@BeforeEach`.

