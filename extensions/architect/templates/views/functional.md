# Functional View: [SUB_SYSTEM_NAME]

**Sub-System**: [SUB_SYSTEM_NAME]
**ADRs Referenced**: [ADR_IDS]
**Generated**: [DATE]
**Dependencies**: Context View

---

## 3.2 Functional View

**Purpose**: Describe functional elements, their responsibilities, and interactions

### 3.2.1 Functional Elements

| Element | Responsibility | Interfaces Provided | Dependencies |
|---------|----------------|---------------------|--------------|
| [COMPONENT_1] | [e.g., User authentication] | [e.g., REST /auth/*] | [e.g., Database] |
| [COMPONENT_2] | [Responsibility] | [Interfaces] | [Dependencies] |

### 3.2.2 Element Interactions

```mermaid
graph TD
    APIGateway["API Gateway"]
    AuthService["Authentication<br/>Service"]
    BusinessLogic["Business Logic<br/>Layer"]
    DataAccess["Data Access<br/>Layer"]
    
    APIGateway -->|Routes| AuthService
    APIGateway -->|Routes| BusinessLogic
    AuthService -->|Validates| BusinessLogic
    BusinessLogic -->|Queries| DataAccess
    
    classDef serviceNode fill:#4a9eff,stroke:#333,stroke-width:2px,color:#fff
    classDef dataNode fill:#66c2a5,stroke:#333,stroke-width:2px,color:#fff
    
    class APIGateway,AuthService,BusinessLogic serviceNode
    class DataAccess dataNode
```

### 3.2.3 Functional Boundaries

**What this system DOES:**

- [Functionality 1]
- [Functionality 2]

**What this system does NOT do:**

- [Excluded functionality 1]
- [Excluded functionality 2]

---

**ADR Traceability:**

| ADR | Decision | Impact on Functional View |
|-----|----------|---------------------------|
| [ADR-XXX] | [Decision] | [How it affects this view] |
