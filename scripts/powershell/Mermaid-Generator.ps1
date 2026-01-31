#!/usr/bin/env pwsh
# Mermaid diagram generator for architecture views
# Generates Mermaid code for all 7 Rozanski & Woods architectural views

# Generate Context View diagram (system boundary)
function New-ContextMermaid {
    param(
        [string]$SystemName = "System"
    )
    
    return @'
graph TD
    Users["👥 Users"]
    System["🏢 System<br/>(Main Application)"]
    Database["🗄️ Database"]
    ExternalAPI["🌐 External APIs"]
    CloudServices["☁️ Cloud Services"]
    
    Users -->|Requests| System
    System -->|Queries| Database
    System -->|Integrates| ExternalAPI
    System -->|Deploys to| CloudServices
    
    classDef systemNode fill:#f47721,stroke:#333,stroke-width:2px,color:#fff
    classDef externalNode fill:#e0e0e0,stroke:#333,stroke-width:1px
    
    class System systemNode
    class Users,Database,ExternalAPI,CloudServices externalNode
'@
}

# Generate Functional View diagram (component interactions)
function New-FunctionalMermaid {
    return @'
graph TD
    APIGateway["API Gateway"]
    AuthService["Authentication<br/>Service"]
    BusinessLogic["Business Logic<br/>Layer"]
    DataAccess["Data Access<br/>Layer"]
    Cache["Cache Layer"]
    
    APIGateway -->|Routes| AuthService
    APIGateway -->|Routes| BusinessLogic
    AuthService -->|Validates| BusinessLogic
    BusinessLogic -->|Queries| DataAccess
    BusinessLogic -->|Caches| Cache
    DataAccess -->|Reads/Writes| Cache
    
    classDef serviceNode fill:#4a9eff,stroke:#333,stroke-width:2px,color:#fff
    classDef dataNode fill:#66c2a5,stroke:#333,stroke-width:2px,color:#fff
    
    class APIGateway,AuthService,BusinessLogic serviceNode
    class DataAccess,Cache dataNode
'@
}

# Generate Information View diagram (data entities and relationships)
function New-InformationMermaid {
    return @'
erDiagram
    User ||--o{ Session : has
    User ||--o{ Order : places
    Order ||--|{ OrderItem : contains
    OrderItem }o--|| Product : references
    Product ||--o{ Inventory : tracked_in
    User ||--o{ Address : has
    Order }o--|| Address : ships_to
    
    User {
        int id PK
        string email
        string name
        timestamp created_at
    }
    
    Order {
        int id PK
        int user_id FK
        string status
        decimal total
        timestamp created_at
    }
    
    Product {
        int id PK
        string name
        decimal price
        string sku
    }
'@
}

# Generate Concurrency View diagram (process timeline)
function New-ConcurrencyMermaid {
    return @'
sequenceDiagram
    participant User
    participant WebServer
    participant AppServer
    participant Worker
    participant Database
    
    User->>WebServer: HTTP Request
    WebServer->>AppServer: Process Request
    AppServer->>Database: Query Data
    Database-->>AppServer: Return Results
    
    par Background Processing
        AppServer->>Worker: Queue Background Job
        Worker->>Database: Update Records
    end
    
    AppServer-->>WebServer: Response
    WebServer-->>User: HTTP Response
'@
}

# Generate Development View diagram (module dependencies)
function New-DevelopmentMermaid {
    return @'
graph LR
    API["🔌 API Layer"]
    Services["⚙️ Services Layer"]
    Repositories["💾 Repositories"]
    Models["📦 Models"]
    Utils["🛠️ Utilities"]
    
    API -->|depends on| Services
    Services -->|depends on| Repositories
    Repositories -->|depends on| Models
    Services -->|uses| Utils
    API -->|uses| Utils
    
    classDef layerNode fill:#9b59b6,stroke:#333,stroke-width:2px,color:#fff
    classDef supportNode fill:#95a5a6,stroke:#333,stroke-width:1px,color:#fff
    
    class API,Services,Repositories layerNode
    class Models,Utils supportNode
'@
}

# Generate Deployment View diagram (infrastructure)
function New-DeploymentMermaid {
    return @'
graph TB
    subgraph "Production Environment"
        LB["⚖️ Load Balancer"]
        
        subgraph "Application Tier"
            Web1["Web Server 1"]
            Web2["Web Server 2"]
            Web3["Web Server 3"]
        end
        
        subgraph "Data Tier"
            DB_Primary["🗄️ Database<br/>Primary"]
            DB_Replica["🗄️ Database<br/>Replica"]
            Cache["💾 Redis Cache"]
        end
        
        subgraph "Storage Tier"
            S3["☁️ Object Storage"]
        end
    end
    
    Internet["🌐 Internet"] -->|HTTPS| LB
    LB -->|Distributes| Web1
    LB -->|Distributes| Web2
    LB -->|Distributes| Web3
    
    Web1 -->|Reads/Writes| DB_Primary
    Web2 -->|Reads/Writes| DB_Primary
    Web3 -->|Reads/Writes| DB_Primary
    
    DB_Primary -->|Replicates to| DB_Replica
    
    Web1 -->|Caches| Cache
    Web2 -->|Caches| Cache
    Web3 -->|Caches| Cache
    
    Web1 -->|Stores files| S3
    Web2 -->|Stores files| S3
    Web3 -->|Stores files| S3
    
    classDef infraNode fill:#e74c3c,stroke:#333,stroke-width:2px,color:#fff
    classDef dataNode fill:#3498db,stroke:#333,stroke-width:2px,color:#fff
    
    class LB,Web1,Web2,Web3 infraNode
    class DB_Primary,DB_Replica,Cache,S3 dataNode
'@
}

# Generate Operational View diagram (operational workflow)
function New-OperationalMermaid {
    return @'
flowchart TD
    Start([🚀 Deployment Initiated])
    BuildTests{Run Tests<br/>& Build}
    BuildSuccess[✅ Build Success]
    BuildFail[❌ Build Failed]
    
    Deploy[📦 Deploy to Staging]
    StagingTests{Staging Tests<br/>Pass?}
    
    ManualApproval{Manual<br/>Approval?}
    ProdDeploy[🎯 Deploy to Production]
    
    Monitor[📊 Monitor Health]
    HealthCheck{System<br/>Healthy?}
    
    Rollback[⏪ Rollback]
    Alert[🚨 Alert Team]
    Complete([✅ Deployment Complete])
    
    Start --> BuildTests
    BuildTests -->|Pass| BuildSuccess
    BuildTests -->|Fail| BuildFail
    
    BuildSuccess --> Deploy
    BuildFail --> Alert
    
    Deploy --> StagingTests
    StagingTests -->|Pass| ManualApproval
    StagingTests -->|Fail| Alert
    
    ManualApproval -->|Approved| ProdDeploy
    ManualApproval -->|Rejected| Alert
    
    ProdDeploy --> Monitor
    Monitor --> HealthCheck
    
    HealthCheck -->|Healthy| Complete
    HealthCheck -->|Issues| Rollback
    
    Rollback --> Alert
    
    classDef successNode fill:#27ae60,stroke:#333,stroke-width:2px,color:#fff
    classDef errorNode fill:#e74c3c,stroke:#333,stroke-width:2px,color:#fff
    classDef processNode fill:#3498db,stroke:#333,stroke-width:2px,color:#fff
    
    class BuildSuccess,Complete successNode
    class BuildFail,Alert,Rollback errorNode
    class Deploy,ProdDeploy,Monitor processNode
'@
}

# Main function to generate diagram for a specific view
# Usage: New-MermaidDiagram -ViewType "context" -SystemName "System Name"
function New-MermaidDiagram {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('context','functional','information','concurrency','development','deployment','operational')]
        [string]$ViewType,
        
        [string]$SystemName = "System"
    )
    
    switch ($ViewType) {
        'context' { return New-ContextMermaid -SystemName $SystemName }
        'functional' { return New-FunctionalMermaid }
        'information' { return New-InformationMermaid }
        'concurrency' { return New-ConcurrencyMermaid }
        'development' { return New-DevelopmentMermaid }
        'deployment' { return New-DeploymentMermaid }
        'operational' { return New-OperationalMermaid }
        default {
            Write-Error "Unknown view type: $ViewType"
            return $null
        }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'New-ContextMermaid',
    'New-FunctionalMermaid',
    'New-InformationMermaid',
    'New-ConcurrencyMermaid',
    'New-DevelopmentMermaid',
    'New-DeploymentMermaid',
    'New-OperationalMermaid',
    'New-MermaidDiagram'
)
