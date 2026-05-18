# Feature Dependencies: [PRODUCT_NAME]

> **Generated**: [DATE] from PRD.md Section 7  
> **Last Updated**: [DATE]  
> **Auto-refresh**: Run `/product.implement --refresh-diagrams` to update

---

## Dependency Graph

```mermaid
graph LR
    %% Define nodes with status indicators
    Auth["✅ Authentication<br/>Complete"]
    Profile["🟡 User Profile<br/>In Progress"]
    Billing["⬜ Billing<br/>Not Started"]
    API["🔴 API Access<br/>Blocked"]
    Analytics["⬜ Analytics<br/>Not Started"]
    
    %% Dependencies
    Auth -->|"requires"| Profile
    Profile -->|"enables"| Billing
    Auth -->|"prerequisite"| API
    Billing -->|"depends on"| API
    Profile -->|"provides data"| Analytics
    API -->|"feeds"| Analytics
    
    %% Legend
    subgraph "Legend"
        direction LR
        Done["✅ Complete"]
        Progress["🟡 In Progress"]
        Blocked["🔴 Blocked"]
        NotStarted["⬜ Not Started"]
    end
    
    %% Styling
    classDef done fill:#4a9eff,stroke:#333,color:#fff
    classDef progress fill:#f47721,stroke:#333,color:#fff
    classDef blocked fill:#e74c3c,stroke:#333,color:#fff
    classDef notstarted fill:#95a5a6,stroke:#333,color:#fff
    
    class Auth done
    class Profile progress
    class API blocked
    class Billing,Analytics notstarted
```

---

## Dependency Matrix

| Feature | Depends On | Blocks | Status | Risk Level |
|---------|-----------|--------|--------|------------|
| User Profile | Authentication | Billing, API | In Progress | Medium |
| Billing | User Profile, API | - | Not Started | High (API blocked) |
| API | Authentication | Billing, Analytics | Blocked | **Critical** |
| Analytics | User Profile, API | - | Not Started | Medium |

## Critical Path

**Path 1**: Authentication → User Profile → Billing  
**Path 2**: Authentication → API → Billing  

*Critical path length: 3 features*  
*Current blocker: API Access*

## Blockers

| Blocked Feature | Blocked By | Impact | Resolution Needed |
|-----------------|------------|--------|-------------------|
| Billing | API Access | **High** - Revenue feature | Unblock API first |
| Analytics | API Access | Medium - Growth feature | Can use mock data temporarily |

## Navigation

- [← Back to PRD](../PRD.md)
- [Feature Hierarchy ←](feature-hierarchy.md)
- [Cross-Feature-Area Map →](cross-area-map.md)
