#!/usr/bin/env pwsh
# ASCII diagram generator for architecture views
# Generates ASCII art for all 7 Rozanski & Woods architectural views

# Generate Context View diagram (system boundary)
function New-ContextAscii {
    param(
        [string]$SystemName = "System"
    )
    
    return @'
┌─────────────────────────────────────────────────────────────┐
│                     Context View Diagram                     │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │    Users     │
                    └──────┬───────┘
                           │
                           ▼
       ┌───────────────────────────────────────┐
       │                                       │
       │           System (Main App)           │
       │                                       │
       └───┬───────────┬───────────┬───────┬───┘
           │           │           │       │
           ▼           ▼           ▼       ▼
    ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌──────────┐
    │ Database │ │ External │ │   Cloud    │ │  Other   │
    │          │ │   APIs   │ │  Services  │ │ Systems  │
    └──────────┘ └──────────┘ └────────────┘ └──────────┘
'@
}

# Generate Functional View diagram (component interactions)
function New-FunctionalAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                   Functional View Diagram                    │
└─────────────────────────────────────────────────────────────┘

          User Request
               │
               ▼
    ┌──────────────────────┐
    │    API Gateway       │
    └──────────┬───────────┘
               │
        ┏──────┴──────┓
        ▼             ▼
┌───────────────┐  ┌───────────────┐
│ Authentication│  │   Business    │
│    Service    │  │     Logic     │
└───────┬───────┘  └───────┬───────┘
        │                  │
        └──────────┬───────┘
                   ▼
        ┌──────────────────────┐
        │   Data Access Layer  │
        └──────────┬───────────┘
                   │
            ┏──────┴──────┓
            ▼             ▼
    ┌─────────────┐  ┌─────────────┐
    │  Database   │  │    Cache    │
    └─────────────┘  └─────────────┘
'@
}

# Generate Information View diagram (data entities)
function New-InformationAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                  Information View Diagram                    │
└─────────────────────────────────────────────────────────────┘

┌──────────┐         ┌──────────┐         ┌──────────┐
│   User   │1      n │  Order   │1      n │OrderItem │
├──────────┤◄────────├──────────┤◄────────├──────────┤
│ id (PK)  │         │ id (PK)  │         │ id (PK)  │
│ email    │         │ user_id  │         │ order_id │
│ name     │         │ status   │         │product_id│
│created_at│         │ total    │         │ quantity │
└──────────┘         │created_at│         │ price    │
                     └──────────┘         └────┬─────┘
                                               │
                                               │n
                                               ▼
                                         ┌──────────┐
                                         │ Product  │
                                         ├──────────┤
                                         │ id (PK)  │
                                         │ name     │
                                         │ price    │
                                         │ sku      │
                                         └──────────┘

Key: PK = Primary Key, FK = Foreign Key
     1 = One, n = Many, ◄──── = Relationship
'@
}

# Generate Concurrency View diagram (process timeline)
function New-ConcurrencyAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                  Concurrency View Diagram                    │
└─────────────────────────────────────────────────────────────┘

User    WebServer   AppServer    Worker    Database
  │         │           │           │          │
  │─Request─>│           │           │          │
  │         │           │           │          │
  │         │─Process──>│           │          │
  │         │           │           │          │
  │         │           │──Query───────────────>│
  │         │           │           │          │
  │         │           │<──Results─────────────│
  │         │           │           │          │
  │         │           │─Queue Job─>│          │
  │         │           │           │          │
  │         │           │           │──Update──>│
  │         │<─Response─│           │          │
  │         │           │           │<─Done────│
  │<─Result─│           │           │          │
  │         │           │           │          │

Processes run concurrently:
- Main Request/Response Flow (vertical)
- Background Worker Processing (parallel)
'@
}

# Generate Development View diagram (module dependencies)
function New-DevelopmentAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                  Development View Diagram                    │
└─────────────────────────────────────────────────────────────┘

Directory Structure:

project-root/
├── src/
│   ├── api/              ◄─── API Layer (Controllers)
│   │   └── routes/           │
│   │                          │ depends on
│   ├── services/         ◄───┘
│   │   └── business/      ◄─── Services Layer
│   │                          │
│   ├── repositories/          │ depends on
│   │   └── data/          ◄───┘
│   │                       ◄─── Data Access Layer
│   ├── models/                │
│   │   └── entities/      ◄───┘ depends on
│   │                       ◄─── Models (Shared)
│   └── utils/
│       └── helpers/       ◄─── Utilities (Shared)
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── docs/

Dependency Rules:
- API → Services → Repositories → Models
- No circular dependencies
- Utilities shared across layers
'@
}

# Generate Deployment View diagram (infrastructure)
function New-DeploymentAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                  Deployment View Diagram                     │
└─────────────────────────────────────────────────────────────┘

                        Internet
                            │
                            ▼
                   ┌────────────────┐
                   │ Load Balancer  │
                   │   (ALB/Nginx)  │
                   └────────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  Web Server 1 │  │  Web Server 2 │  │  Web Server 3 │
│   (Public)    │  │   (Public)    │  │   (Public)    │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │   App Tier     │
                   │   (Private)    │
                   └────────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   Database    │  │  Redis Cache  │  │    Object     │
│   (Primary)   │  │               │  │   Storage     │
│   (Private)   │  │   (Private)   │  │   (S3/Blob)   │
└───────┬───────┘  └───────────────┘  └───────────────┘
        │
        ▼
┌───────────────┐
│   Database    │
│   (Replica)   │
│   (Private)   │
└───────────────┘
'@
}

# Generate Operational View diagram (operational workflow)
function New-OperationalAscii {
    return @'
┌─────────────────────────────────────────────────────────────┐
│                 Operational View Diagram                     │
└─────────────────────────────────────────────────────────────┘

Deployment Workflow:

    START
      │
      ▼
┌──────────────┐
│  Run Tests   │──┐
│  & Build     │  │ Fail
└──────┬───────┘  │
       │ Pass     │
       ▼          │
┌──────────────┐  │
│  Deploy to   │  │
│   Staging    │  │
└──────┬───────┘  │
       │          │
       ▼          │
┌──────────────┐  │
│Run Staging   │──┤ Fail
│    Tests     │  │
└──────┬───────┘  │
       │ Pass     │
       ▼          │
┌──────────────┐  │
│   Manual     │──┤ Reject
│  Approval?   │  │
└──────┬───────┘  │
       │ Approve  │
       ▼          │
┌──────────────┐  │
│  Deploy to   │  │
│ Production   │  │
└──────┬───────┘  │
       │          │
       ▼          │
┌──────────────┐  │
│   Monitor    │  │
│   Health     │  │
└──────┬───────┘  │
       │          │
   ┌───┴───┐      │
   │Healthy│      │
   ▼       ▼      │
  YES      NO     │
   │        │     │
   │   ┌────────┐│
   │   │Rollback││
   │   └────┬───┘│
   │        │    │
   ▼        ▼    ▼
  END    Alert Team

Monitoring: Continuous
Backups: Daily automated
On-call: 24/7 rotation
'@
}

# Main function to generate diagram for a specific view
# Usage: New-AsciiDiagram -ViewType "context" -SystemName "System Name"
function New-AsciiDiagram {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('context','functional','information','concurrency','development','deployment','operational')]
        [string]$ViewType,
        
        [string]$SystemName = "System"
    )
    
    switch ($ViewType) {
        'context' { return New-ContextAscii -SystemName $SystemName }
        'functional' { return New-FunctionalAscii }
        'information' { return New-InformationAscii }
        'concurrency' { return New-ConcurrencyAscii }
        'development' { return New-DevelopmentAscii }
        'deployment' { return New-DeploymentAscii }
        'operational' { return New-OperationalAscii }
        default {
            Write-Error "Unknown view type: $ViewType"
            return $null
        }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'New-ContextAscii',
    'New-FunctionalAscii',
    'New-InformationAscii',
    'New-ConcurrencyAscii',
    'New-DevelopmentAscii',
    'New-DeploymentAscii',
    'New-OperationalAscii',
    'New-AsciiDiagram'
)
