# Feature Hierarchy: [PRODUCT_NAME]

> **Generated**: [DATE] from PRD.md Section 7 (Functional Requirements)  
> **Last Updated**: [DATE]  
> **Auto-refresh**: Run `/product.implement --refresh-diagrams` to update  
> 
> This diagram shows the hierarchical structure of product features.  
> For dependencies between features, see [feature-deps.md](feature-deps.md).

---

## Feature Structure

```mermaid
flowchart TD
    subgraph "Product: [PRODUCT_NAME]"
        direction TB
        
        subgraph "Core Platform"
            Auth["🔐 Authentication"]
            Users["👤 User Management"]  
            Settings["⚙️ Settings"]
        end
        
        subgraph "Business Layer"
            Billing["💳 Billing"]
            Subscriptions["📊 Subscriptions"]
            Invoices["📄 Invoicing"]
        end
        
        subgraph "Growth Features"
            Analytics["📈 Analytics"]
            API["🔌 API Access"]
            Integrations["🔗 Integrations"]
        end
    end
    
    Auth --> Users
    Users --> Settings
    Users --> Billing
    Billing --> Subscriptions
    Billing --> Invoices
    Users --> Analytics
    API --> Integrations
    
    %% Styling
    classDef core fill:#4a9eff,stroke:#333,stroke-width:2px,color:#fff
    classDef business fill:#66c2a5,stroke:#333,stroke-width:2px,color:#fff
    classDef growth fill:#f47721,stroke:#333,stroke-width:2px,color:#fff
    
    class Auth,Users,Settings core
    class Billing,Subscriptions,Invoices business
    class Analytics,API,Integrations growth
```

---

## Feature Breakdown by Area

| Area | Features | Status | Completion |
|------|----------|--------|------------|
| **Core** | Auth, Users, Settings | [STATUS] | [%] |
| **Business** | Billing, Subscriptions, Invoices | [STATUS] | [%] |
| **Growth** | Analytics, API, Integrations | [STATUS] | [%] |

## Legend

- 🔐 **Authentication**: User identity and access management
- 👤 **User Management**: Profiles, preferences, accounts
- ⚙️ **Settings**: Configuration and customization
- 💳 **Billing**: Payment processing and transactions
- 📊 **Subscriptions**: Plan management and renewals
- 📄 **Invoicing**: Bill generation and delivery
- 📈 **Analytics**: Reporting and insights
- 🔌 **API Access**: Developer interfaces
- 🔗 **Integrations**: Third-party connections

---

## Navigation

- [← Back to PRD](../PRD.md)
- [Feature Dependencies →](feature-deps.md)
- [Cross-Feature-Area Map →](cross-area-map.md)
