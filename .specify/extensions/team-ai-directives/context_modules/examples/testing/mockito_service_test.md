---
instruction_type: Generation
priority: Standard
description: Example of advanced Mockito service testing
---

# Example: Advanced Mockito Service Layer Test

**Note**: This example demonstrates advanced Mockito patterns. For basic testing patterns, see `junit5_class_based.md`.

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("CustomerService Tests with Mockito")
class CustomerServiceTest {
    
    @Mock
    private CustomerRepository customerRepository;
    
    @Mock
    private EmailService emailService;
    
    @InjectMocks
    private CustomerService customerService;
    
    @BeforeEach
    void setUp() {
        // Additional setup if needed
    }
    
    @Test
    @DisplayName("Should create customer and send welcome email")
    void shouldCreateCustomerAndSendWelcomeEmail() {
        // Arrange
        Customer customer = new Customer("alex@example.com", "active");
        Customer savedCustomer = new Customer(1L, "alex@example.com", "active");
        when(customerRepository.save(any(Customer.class))).thenReturn(savedCustomer);
        doNothing().when(emailService).sendWelcomeEmail(anyString());
        
        // Act
        Customer result = customerService.createCustomer(customer);
        
        // Assert
        assertNotNull(result);
        assertEquals(1L, result.getId());
        verify(customerRepository, times(1)).save(any(Customer.class));
        verify(emailService, times(1)).sendWelcomeEmail(eq("alex@example.com"));
    }
    
    @Test
    @DisplayName("Should update customer status")
    void shouldUpdateCustomerStatus() {
        // Arrange
        Long customerId = 1L;
        Customer existingCustomer = new Customer(customerId, "alex@example.com", "active");
        when(customerRepository.findById(customerId))
            .thenReturn(Optional.of(existingCustomer));
        when(customerRepository.save(any(Customer.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
        ArgumentCaptor<Customer> customerCaptor = ArgumentCaptor.forClass(Customer.class);
        
        // Act
        Customer updated = customerService.updateCustomerStatus(customerId, "inactive");
        
        // Assert
        assertEquals("inactive", updated.getStatus());
        verify(customerRepository).findById(customerId);
        verify(customerRepository).save(customerCaptor.capture());
        Customer savedCustomer = customerCaptor.getValue();
        assertEquals("inactive", savedCustomer.getStatus());
        assertEquals(customerId, savedCustomer.getId());
    }
    
    @Test
    @DisplayName("Should capture customer arguments for verification")
    void shouldCaptureCustomerArguments() {
        // Arrange
        ArgumentCaptor<Customer> customerCaptor = ArgumentCaptor.forClass(Customer.class);
        Customer customer = new Customer("alex@example.com", "active");
        when(customerRepository.save(any(Customer.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
        
        // Act
        customerService.createCustomer(customer);
        
        // Assert
        verify(customerRepository).save(customerCaptor.capture());
        Customer captured = customerCaptor.getValue();
        assertEquals("alex@example.com", captured.getEmail());
        assertEquals("active", captured.getStatus());
    }
    
    @Test
    @DisplayName("Should throw exception when customer not found")
    void shouldThrowExceptionWhenCustomerNotFound() {
        // Arrange
        Long customerId = 999L;
        when(customerRepository.findById(customerId))
            .thenReturn(Optional.empty());
        
        // Act & Assert
        assertThrows(CustomerNotFoundException.class, 
            () -> customerService.updateCustomerStatus(customerId, "active"));
        verify(customerRepository, never()).save(any());
    }
}
```

**Why it works**

- Uses `@InjectMocks` to automatically inject `@Mock` dependencies into the service under test.
- Demonstrates `ArgumentCaptor` for verifying method arguments when exact matching is complex.
- Shows proper use of `verify()` to check method invocations and interaction patterns.
- Uses `when().thenAnswer()` for dynamic stubbing behavior.
- Follows Arrange-Act-Assert pattern with clear separation of concerns.
- Shows exception testing with `assertThrows()` and verification that certain methods were never called.

