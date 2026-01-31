#!/usr/bin/env bash
# Mermaid diagram generator for architecture views
# Generates Mermaid code for all 7 Rozanski & Woods architectural views

# Generate Context View diagram (system boundary)
generate_context_mermaid() {
    local system_name="${1:-System}"
    
    cat <<'EOF'
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
EOF
}

# Generate Functional View diagram (component interactions)
generate_functional_mermaid() {
    cat <<'EOF'
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
EOF
}

# Generate Information View diagram (data entities and relationships)
generate_information_mermaid() {
    cat <<'EOF'
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
EOF
}

# Generate Concurrency View diagram (process timeline)
generate_concurrency_mermaid() {
    cat <<'EOF'
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
EOF
}

# Generate Development View diagram (module dependencies)
generate_development_mermaid() {
    cat <<'EOF'
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
EOF
}

# Generate Deployment View diagram (infrastructure)
generate_deployment_mermaid() {
    cat <<'EOF'
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
EOF
}

# Generate Operational View diagram (operational workflow)
generate_operational_mermaid() {
    cat <<'EOF'
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
EOF
}

# Main function to generate diagram for a specific view
# Usage: generate_mermaid_diagram "context" "System Name"
generate_mermaid_diagram() {
    local view_type="$1"
    local system_name="${2:-System}"
    
    case "$view_type" in
        context)
            generate_context_mermaid "$system_name"
            ;;
        functional)
            generate_functional_mermaid
            ;;
        information)
            generate_information_mermaid
            ;;
        concurrency)
            generate_concurrency_mermaid
            ;;
        development)
            generate_development_mermaid
            ;;
        deployment)
            generate_deployment_mermaid
            ;;
        operational)
            generate_operational_mermaid
            ;;
        *)
            echo "Error: Unknown view type '$view_type'" >&2
            return 1
            ;;
    esac
}

# Export functions for use in other scripts
export -f generate_context_mermaid
export -f generate_functional_mermaid
export -f generate_information_mermaid
export -f generate_concurrency_mermaid
export -f generate_development_mermaid
export -f generate_deployment_mermaid
export -f generate_operational_mermaid
export -f generate_mermaid_diagram
