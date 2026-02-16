# Pentagon2/Truvify - Architecture Description

## System Overview

Pentagon2 (Truvify) is a **legal background check and due diligence platform** built as an Israeli-focused SaaS application. It aggregates data from multiple public and private sources to generate comprehensive trust reports on individuals and companies, including court cases, financial sanctions, professional licenses, terror/criminal watchlists, and more.

## Architecture Style

**Modular Monolith** - Single Next.js application with clear internal module boundaries following the **UI -> API -> Service -> Model** layered pattern. All code deploys as a single Docker container behind an Nginx reverse proxy.

## Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Runtime** | Node.js | 20.x (.nvmrc) | Server runtime |
| **Framework** | Next.js | 16.1.5 | Full-stack React framework (App Router) |
| **Language** | TypeScript | 5.9.2 | Primary language |
| **ORM** | Prisma | 6.14.0 | Database access and migrations |
| **Database** | PostgreSQL | 15 | Primary data store |
| **UI Framework** | React | 18.3.1 | Component library |
| **UI Components** | MUI (Material-UI) | 5.18.0 | Design system |
| **CSS** | Tailwind CSS | 3.4.19 | Utility-first CSS |
| **State Management** | Zustand | 5.0.8 | Client-side state |
| **Authentication** | NextAuth.js | 5.0.0-beta.30 | Auth (Google OAuth + Credentials) |
| **Validation** | Zod | 3.25.76 | Schema validation |
| **Forms** | React Hook Form | 7.62.0 | Form management |
| **Logging** | Winston + Logtail | 3.17.0 | Structured logging with cloud transport |
| **AI/LLM** | Google Vertex AI / Gemini | 1.10.0 / 1.34.0 | Document classification & extraction |
| **Web Scraping** | Puppeteer | 24.34.0 | Browser automation (Interpol, lawyers) |
| **PDF** | PDFKit + react-pdf + pdf-parse | Various | PDF generation and parsing |
| **Cloud** | AWS (S3, SES, SNS, SQS) | SDK v3 | Storage, email, notifications, queues |
| **Process Manager** | PM2 | Runtime | Production process management |
| **Reverse Proxy** | Nginx | Latest | TLS termination, security headers |
| **Infrastructure** | Terraform | Latest | AWS EC2 provisioning (il-central-1) |
| **CI/CD** | GitHub Actions | N/A | Build, test, deploy pipeline |
| **Testing** | Jest + React Testing Library | 29.7.0 | Unit and component testing |
| **Linting** | ESLint + Prettier | 9.x / 3.6.x | Code quality |
| **API Docs** | Swagger (swagger-jsdoc) | 6.2.8 | OpenAPI documentation |
| **Bot** | Telegraf | 4.16.3 | Telegram bot (dev utility) |
| **Concurrency** | async-mutex + bottleneck | 0.5.0 / 2.19.5 | Rate limiting and mutual exclusion |

## System Topology

```
[Browser] --> [Nginx (TLS/Headers)] --> [Next.js App (PM2)] --> [PostgreSQL]
                                              |
                                              |--> [AWS S3] (document storage)
                                              |--> [AWS SES] (email)
                                              |--> [AWS SNS] (notifications)
                                              |--> [AWS SQS] (message queues)
                                              |--> [Google Vertex AI] (LLM)
                                              |--> [External APIs] (Israeli gov, courts, registries)
                                              |--> [CRM Webhooks] (inbound/outbound)
```

### Deployment Architecture

- **Region**: AWS il-central-1 (Israel)
- **Compute**: EC2 instance (Ubuntu 24.04) provisioned via Terraform
- **Containers**: Docker (App + Nginx), connected via `pentagon-network`
- **Registry**: AWS ECR (separate images per environment)
- **Environments**: staging (`develop` branch), production (`main` branch)
- **SSL**: Certificates stored in AWS Secrets Manager, injected at deploy time
- **Secrets**: AWS Secrets Manager (`pentagon/staging`, `pentagon/production`)
- **CDN**: CloudFront (`d18zaexen4dp1s.cloudfront.net`) for image assets
- **Domains**: `app.truvify.com` (production), `staging.truvify.com` (staging)

## Directory Structure

```
pentagon2/
  app/                    # Next.js App Router
    api/                  # API routes (REST)
      auth/               # Authentication endpoints
      v1/                 # Versioned API (admin, cases, documents, user, webhook)
    admin/                # Admin pages (associates, billing, organizations, users)
    auth/                 # Auth pages (signin, forgot-password, reset-password, verify-token)
    user/                 # User pages (home, profile, new-search, search-results)
    trust-report/         # Trust report pages (edit, preview, preview/en)
    docs/                 # Swagger API documentation page
  aws/                    # AWS service wrappers (s3.ts, ses.ts, sqs.ts)
  components/             # React components
    admin/                # Admin-specific components
    cases/                # Case display components
    common/               # Shared UI components
    quota/                # Quota/billing UI
    trust-report-edit/    # Trust report editing
    trust-report-preview/ # Trust report preview (Hebrew)
    trust-report-preview-english/ # Trust report preview (English)
    trust-reports/        # Trust report listing
    trial/                # Trial mode components
    ui/                   # Generic UI components
    user/                 # User-specific components
  config/                 # Configuration constants
  filters/                # Case/result filtering logic
  hooks/                  # React custom hooks
  interpol_scraping/      # Puppeteer-based Interpol scraper
  lib/                    # Shared library code
  llm/                    # LLM integration
    prompts/              # Prompt templates (civil, criminal, bankruptcy, enforcement)
    utils/                # PDF helper, JSON cleaner
  logs/                   # Local log files
  models/                 # Prisma model wrappers (database access layer)
  nginx/                  # Nginx configs + Dockerfiles per environment
  prisma/                 # Prisma schema and migrations
  public/                 # Static assets
  scripts/                # Utility scripts (prisma-guard, swagger, backfill, etc.)
  searches/               # External search API integrations
  services/               # Business logic layer
  store/                  # Zustand stores
  terraform/              # AWS infrastructure as code
  types/                  # TypeScript type definitions
  utils/                  # Utility functions
    scripts/              # Data migration and maintenance scripts
  __tests__/              # Test files (mirrors source structure)
  __mocks__/              # Test mocks
```

## Key Architectural Patterns

### 1. Layered Architecture (UI -> API -> Service -> Model)
- **UI (components/)**: Presentation only, no business logic. All client-rendered (`'use client'`)
- **API (app/api/)**: HTTP handling, request validation, calls services. Next.js App Router route handlers
- **Service (services/)**: Business logic orchestration, external integrations
- **Model (models/)**: Thin Prisma wrappers for database CRUD operations

### 2. Client-Side Rendering Only
No SSR or server components. All frontend-backend communication via HTTP calls to API routes. `SessionProvider` wraps the app for auth state.

### 3. Multi-Source Search Pipeline
The search system aggregates data from 15+ sources in parallel:
- Israeli court case databases
- Government registries (constructors, medical, accountants, HR)
- Financial sanctions databases
- Criminal/terror watchlists (local + Interpol)
- Company registries
- ME (identity verification)
- Google Places
- News articles (Posta)

### 4. Confidence Engine
A scoring system that evaluates search results with certainty levels, considering name matching, location, age, and document classification data.

### 5. Trust Report Generation
End-to-end pipeline: Search -> Classify Documents (LLM) -> Score Results -> Generate PDF Report (Hebrew + English)

### 6. Role-Based Access Control
Three roles enforced in `proxy.ts` (Next.js 16 replacement for middleware):
- **admin**: Full access to all routes
- **manager**: Organization billing + user-level features
- **user**: Search and report access only

### 7. Dual Authentication
- **Google OAuth**: Restricted to `@truvify.com` domain (internal/admin)
- **Credentials**: Email/password with MFA token verification (external users)

### 8. API Token Authentication
Bearer token system for programmatic API access with per-token permissions, cached with 5-minute TTL.

### 9. CRM Integration
- **Inbound webhooks**: `/api/v1/webhook/crm/user` and `/api/v1/webhook/crm/tx` for user provisioning and credit transactions
- **Outbound notifications**: Credit exhaustion alerts sent to CRM

### 10. Quota/Billing System
Two-tier credit system:
- **Organization-level quotas** (`usage` table)
- **User-level quotas** (`user_usage` table)
- Package-based credit allocation via CRM webhooks
- Trial mode with configurable limits

## Database Schema Highlights

### Core Entities
- **personal_info**: Central entity linking all search results for a person
- **cases**: Court cases with scrape status tracking
- **person_cases**: Many-to-many linking persons to cases with certainty levels
- **trust_report**: Scored findings for report generation

### Supporting Entities
- **searches**: Search history tracking per user/organization
- **doc_classification**: LLM-classified court documents
- **person_entities**: Named entities extracted from documents
- **associates**: Person-to-person associations discovered in cases

### Professional/Registry Data
- accountant, bank_israel, constructor, human_resource, medical_profession, financial_sanctions, company, person_company

### System Entities
- organization, user, user_usage, usage, billing, audit, api_token, mfa_token, package_mapping

### Key Database Features
- UUID primary keys (uuid_generate_v4())
- pg_trgm extension for trigram-based fuzzy text search on case parties
- Extensive indexing on frequently queried columns
- Cascading deletes from personal_info

## Security Architecture

### Network Layer (Nginx)
- TLS 1.2/1.3 with strong cipher suites
- Security headers: X-Frame-Options DENY, CSP, HSTS, X-Content-Type-Options
- HTTP -> HTTPS redirect (308)
- Server version hidden, X-Powered-By stripped

### Application Layer
- Route-based access control in proxy.ts
- MFA via email token (configurable via feature flag)
- Password hashing with salt, password history tracking
- Account lockout after failed login attempts
- CORS restricted to environment-specific origins
- API routes: no-cache, no-store

### Data Layer
- Encrypted EBS volumes
- Secrets in AWS Secrets Manager
- PII logging prohibited (anonymized IDs only)
- Prisma guard script prevents accidental production database operations

## CI/CD Pipeline

```
PR/Push -> GitHub Actions:
  1. Install dependencies
  2. Lint (ESLint)
  3. Prisma validation + migration check (against test PostgreSQL)
  4. Build (prisma generate -> swagger generate -> next build)
  5. Test (Jest)
  6. Deploy (only on push to main/develop):
     a. Build Docker images (app + nginx)
     b. Push to ECR
     c. SSH to EC2, pull images, restart containers
     d. Run database migrations
```

## External Integrations

| Integration | Protocol | Purpose |
|-------------|----------|---------|
| Israeli Court System | HTTP/Scraping | Case data retrieval |
| Government Registries | HTTP APIs | Professional license verification |
| Interpol | Puppeteer scraping | International criminal database |
| Google Vertex AI / Gemini | Google Cloud SDK | Document classification, entity extraction |
| AWS S3 | SDK | Court document storage (2 buckets: cases, decisions) |
| AWS SES | SDK | Transactional emails (trial, billing) |
| AWS SNS | SDK | Push notifications |
| AWS SQS | SDK | Message queuing |
| Google Places | HTTP API | Location/business verification |
| CRM System | Webhooks (inbound/outbound) | User provisioning, credit management |
| Logtail | Winston transport | Centralized log aggregation |
| Telegram | Telegraf bot | Development notifications |
| CloudFront CDN | HTTPS | Image asset delivery |
