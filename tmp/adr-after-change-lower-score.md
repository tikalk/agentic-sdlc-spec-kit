# Pentagon2/Truvify - Architectural Decision Records

## ADR Summary

| ID | Decision | Status | Confidence |
|----|----------|--------|------------|
| ADR-001 | Modular Monolith with Next.js | Discovered | HIGH |
| ADR-002 | PostgreSQL as Primary Database | Discovered | HIGH |
| ADR-003 | REST API with Next.js App Router | Discovered | HIGH |
| ADR-004 | React with Client-Side Rendering Only | Discovered | HIGH |
| ADR-005 | AWS EC2 Single-Instance Deployment | Discovered | HIGH |
| ADR-006 | GitHub Actions CI/CD with Docker | Discovered | HIGH |
| ADR-007 | Prisma ORM for Database Access | Discovered | HIGH |
| ADR-008 | NextAuth.js with Dual Authentication | Discovered | HIGH |
| ADR-009 | Google Vertex AI / Gemini for Document Classification | Discovered | HIGH |
| ADR-010 | Puppeteer for Web Scraping | Discovered | HIGH |
| ADR-011 | Winston + Logtail for Logging | Discovered | HIGH |
| ADR-012 | Zustand for Client-Side State Management | Discovered | HIGH |
| ADR-013 | Nginx as Reverse Proxy with TLS Termination | Discovered | HIGH |
| ADR-014 | Multi-Source Search Pipeline Architecture | Discovered | HIGH |
| ADR-015 | Role-Based Access Control via Proxy | Discovered | HIGH |
| ADR-016 | Two-Tier Quota/Billing System | Discovered | HIGH |
| ADR-017 | CRM Webhook Integration Pattern | Discovered | HIGH |
| ADR-018 | AWS Services for Cloud Infrastructure | Discovered | HIGH |
| ADR-019 | Terraform for Infrastructure Provisioning | Discovered | MEDIUM |
| ADR-020 | Trust Report PDF Generation (Hebrew + English) | Discovered | HIGH |
| ADR-021 | LLM Prompt Engineering for Legal Document Analysis | Discovered | HIGH |
| ADR-022 | Telegram Bot for Development Notifications | Discovered | MEDIUM |
| ADR-023 | Swagger/OpenAPI for API Documentation | Discovered | HIGH |
| ADR-024 | Jest + React Testing Library for Testing | Discovered | HIGH |
| ADR-025 | MUI + Tailwind CSS for UI Styling | Discovered | MEDIUM |
| ADR-026 | Zod for Runtime Schema Validation | Discovered | MEDIUM |
| ADR-027 | UUID Primary Keys with PostgreSQL Extensions | Discovered | HIGH |
| ADR-028 | Gitflow Branching Strategy | Discovered | HIGH |

### Resolved Areas
- System architecture style (monolith)
- Database choice and ORM
- Authentication strategy
- Deployment model
- CI/CD pipeline
- LLM provider
- Logging infrastructure
- State management
- API style and routing
- Security headers and TLS

### Areas Needing Clarification
- Horizontal scaling strategy (currently single EC2)
- Disaster recovery / backup strategy
- Database connection pooling configuration
- Rate limiting strategy beyond bottleneck
- Feature flag management (only MFA flag observed)
- Monitoring and alerting (beyond Logtail)
- Data retention policies

---

## ADR-001: Modular Monolith with Next.js

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The platform needed a full-stack framework that could handle both the frontend UI and backend API logic while maintaining clear separation of concerns for a complex domain (legal background checks).

**Evidence Found**:
- Single `package.json` with both frontend (React, MUI) and backend (Prisma, AWS SDK) dependencies
- `app/` directory containing both pages and API routes
- Clear module boundaries: `services/`, `models/`, `searches/`, `filters/`, `components/`
- Single `Dockerfile` producing one deployable container
- `proxy.ts` handling routing and auth for the entire application

### Decision
Build as a Next.js modular monolith following the UI -> API -> Service -> Model layered pattern. All functionality lives in a single deployable unit with clear internal module boundaries.

### Consequences

#### Positive (Observed)
- Simple deployment model (single container)
- Shared types between frontend and backend
- Easy code navigation across layers
- Fast development iteration with collocated code

#### Negative (Potential)
- Horizontal scaling requires scaling the entire application
- Cannot independently deploy or scale individual services
- Risk of layer boundary violations without strict enforcement

#### Risks
- As the codebase grows, the monolith may become harder to maintain
- Single point of failure in deployment

### Alternatives (Available at Decision Time)
- **Microservices**: Would add complexity for a small team
- **Separate Frontend/Backend**: Would lose type sharing and require API contracts
- **Serverless (Lambda)**: Would complicate the scraping/LLM workloads

### Confidence Level
HIGH - Clear evidence from project structure, single Dockerfile, and unified deployment

---

## ADR-002: PostgreSQL as Primary Database

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application stores structured relational data with complex relationships between people, cases, organizations, and search results. Fuzzy text search on Hebrew names is a core requirement.

**Evidence Found**:
- `prisma/schema.prisma`: `provider = "postgresql"` with 30+ models
- PostgreSQL extensions: `pg_trgm` (trigram fuzzy search), `uuid_ossp` (UUID generation)
- GIN indexes on `appellants` and `appellees` columns for trigram search
- CI workflow uses `postgres:15` Docker image for testing
- Complex relational model with foreign keys and cascading deletes

### Decision
Use PostgreSQL as the sole database, leveraging its advanced features for fuzzy text search (pg_trgm), UUID generation, and JSONB storage.

### Consequences

#### Positive (Observed)
- Excellent support for Hebrew text search via trigram indexes
- Strong relational integrity with foreign keys
- Mature ecosystem with Prisma ORM support
- ACID compliance for financial/billing transactions

#### Negative (Potential)
- Single database for all workloads (OLTP + search)
- May need read replicas as data grows

#### Risks
- Large tables noted in CLAUDE.md: `cases`, `doc_classification`, `person_entities` have massive data
- No caching layer observed (Redis or similar)

### Alternatives (Available at Decision Time)
- **MongoDB**: Less suitable for relational data model
- **PostgreSQL + Elasticsearch**: Would improve search but add operational complexity
- **MySQL**: Lacks pg_trgm equivalent for Hebrew text

### Confidence Level
HIGH - Explicit in Prisma schema, CI configuration, and database extensions

---

## ADR-003: REST API with Next.js App Router

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs a structured API for client-server communication and external integrations (CRM webhooks, API token access).

**Evidence Found**:
- `app/api/v1/` directory with versioned REST endpoints
- Route handlers using `route.ts` files with HTTP verb exports
- `swagger-jsdoc` for OpenAPI documentation
- API token authentication for programmatic access
- CORS headers configured per environment

### Decision
Use Next.js App Router route handlers as a REST API with v1 versioning prefix, documented via Swagger/OpenAPI.

### Consequences

#### Positive (Observed)
- Collocated with frontend code
- Type-safe request/response handling
- Automatic API documentation via Swagger
- Clean versioning (`/api/v1/`)

#### Negative (Potential)
- No GraphQL flexibility for complex queries
- Next.js route handler limitations vs. Express

#### Risks
- API versioning strategy unclear for breaking changes

### Alternatives (Available at Decision Time)
- **GraphQL**: More flexible queries but added complexity
- **Separate Express API**: Would decouple backend but lose collocation benefits
- **tRPC**: Type-safe but less suitable for external API consumers

### Confidence Level
HIGH - Clear REST patterns in route structure, Swagger integration

---

## ADR-004: React with Client-Side Rendering Only

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application is a B2B SaaS tool behind authentication, where SEO is not a concern. All users must be logged in.

**Evidence Found**:
- CLAUDE.md explicitly states: "Use client-side rendering only - NO SSR or server components"
- `app/providers.tsx` wraps app with `SessionProvider` (client component)
- Components use `'use client'` directive
- All data fetching via `fetch()` calls to API routes from client components

### Decision
Use exclusively client-side rendering. No SSR or React Server Components. All data flows through API routes.

### Consequences

#### Positive (Observed)
- Simpler mental model (no hydration issues)
- Clear client/server boundary
- Easier caching strategy (API responses only)

#### Negative (Potential)
- Slower initial page loads (no pre-rendered content)
- Cannot leverage React Server Component optimizations

#### Risks
- May need SSR in future if public-facing features are added

### Alternatives (Available at Decision Time)
- **SSR**: Would improve initial load but add complexity
- **Server Components**: Next.js 16 default, but adds complexity for authenticated apps
- **Hybrid**: Mix of CSR and SSR per route

### Confidence Level
HIGH - Explicit rule in CLAUDE.md, consistent pattern across all components

---

## ADR-005: AWS EC2 Single-Instance Deployment

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs to run in a specific AWS region (Israel) with control over the runtime environment, including Chrome for web scraping.

**Evidence Found**:
- `terraform/main.tf`: Single EC2 instance (`ami-0d43c7c6c8fb4ee5c`, Ubuntu 24.04) in `il-central-1b`
- `terraform/provider.tf`: AWS region `il-central-1`
- Deploy workflow SSHs directly into a single EC2 host
- Docker containers run directly on EC2 (no orchestrator)
- 50GB encrypted EBS volume

### Decision
Deploy to a single AWS EC2 instance in Israel (il-central-1) running Docker containers directly, managed via SSH deployment.

### Consequences

#### Positive (Observed)
- Simple deployment model
- Full control over runtime (Chrome installation for Puppeteer)
- Data residency compliance (Israel region)
- Low operational overhead

#### Negative (Potential)
- Single point of failure (no auto-scaling, no load balancing)
- Manual scaling (instance type change)
- Zero-downtime deployment not evident

#### Risks
- No high availability setup observed
- EC2 instance failure = service outage

### Alternatives (Available at Decision Time)
- **ECS/Fargate**: Container orchestration without managing EC2
- **Kubernetes (EKS)**: Full orchestration but high operational cost
- **AWS App Runner**: Simpler container deployment
- **Lambda**: Not suitable for long-running scraping tasks

### Confidence Level
HIGH - Terraform configuration and deployment workflow clearly show single EC2 model

---

## ADR-006: GitHub Actions CI/CD with Docker

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The team needs automated testing, building, and deployment with environment-specific configurations.

**Evidence Found**:
- `.github/workflows/deploy.yml`: Full CI/CD pipeline
- Triggers on push to `main` (production) and `develop` (staging)
- Multi-step: lint -> prisma validate -> build -> test -> Docker build -> ECR push -> SSH deploy
- AWS ECR for Docker image registry
- AWS Secrets Manager for environment configuration
- SSL certificates retrieved from Secrets Manager at deploy time

### Decision
Use GitHub Actions for CI/CD with Docker-based builds, pushing to AWS ECR and deploying via SSH to EC2.

### Consequences

#### Positive (Observed)
- Integrated with GitHub (no separate CI tool)
- Environment-specific deploys (staging/production)
- Docker layer caching for faster builds
- Prisma migration verification in CI

#### Negative (Potential)
- SSH-based deployment is fragile
- No blue-green or canary deployment capability
- No rollback mechanism visible

#### Risks
- Deployment downtime during container restart
- Failed deployment may leave system in inconsistent state

### Alternatives (Available at Decision Time)
- **AWS CodePipeline**: Native AWS integration
- **GitLab CI**: Would require repository migration
- **ArgoCD**: GitOps but requires Kubernetes

### Confidence Level
HIGH - Workflow files clearly define the entire pipeline

---

## ADR-007: Prisma ORM for Database Access

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs type-safe database access with migration support for a complex PostgreSQL schema.

**Evidence Found**:
- `prisma/schema.prisma`: 30+ models with relations, enums, and indexes
- `models/` directory: Thin wrappers around Prisma client calls
- Preview features: `driverAdapters`, `postgresqlExtensions`, `views`
- `npm run migrate` and `prisma-guard.ts` script for safe migration execution
- `$queryRaw` used for performance-critical queries

### Decision
Use Prisma as the ORM with a thin model layer wrapping Prisma client operations. Raw SQL used selectively for performance-critical paths.

### Consequences

#### Positive (Observed)
- Type-safe database queries generated from schema
- Declarative migration system
- Schema-first design with clear model definitions

#### Negative (Potential)
- N+1 query risks with relation loading
- Raw SQL needed for complex aggregations
- Migration conflicts with team development

#### Risks
- Prisma 6.x is relatively new; preview features may change

### Alternatives (Available at Decision Time)
- **TypeORM**: More mature but less type-safe
- **Drizzle**: Lighter weight, SQL-like API
- **Knex**: Query builder without ORM overhead
- **Raw SQL**: Maximum control but no type safety

### Confidence Level
HIGH - Central to the application's data layer

---

## ADR-008: NextAuth.js with Dual Authentication

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application serves two user types: internal Truvify staff (admin) and external customers. Each requires different authentication flows.

**Evidence Found**:
- `auth.ts`: Two providers configured - Google OAuth and Credentials
- Google OAuth restricted to `@truvify.com` domain (internal users)
- Credentials provider with email/password + MFA token verification
- `proxy.ts`: Role-based route protection (admin, manager, user)
- `mfa_token` model for email-based MFA
- `password_history` model for password reuse prevention
- Account lockout (`failed_login_attempts`, `locked_at`)
- API token system for programmatic access

### Decision
Use NextAuth.js v5 (beta) with dual authentication: Google OAuth for internal staff, Credentials with MFA for external users. Separate API token system for programmatic access.

### Consequences

#### Positive (Observed)
- Clean separation of internal vs external auth flows
- MFA adds security for external users handling sensitive data
- API tokens enable system integrations
- Password security (history, lockout)

#### Negative (Potential)
- NextAuth v5 beta may have stability concerns
- MFA via email is less secure than TOTP/hardware keys
- Two auth flows increase maintenance surface

#### Risks
- Beta dependency for auth is a critical path risk

### Alternatives (Available at Decision Time)
- **Auth0/Clerk**: Managed auth (adds cost, external dependency)
- **Custom JWT**: Full control but more implementation work
- **Passport.js**: More established but less Next.js integrated

### Confidence Level
HIGH - Explicit in auth.ts, proxy.ts, and database schema

---

## ADR-009: Google Vertex AI / Gemini for Document Classification

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
Court documents (PDFs) need to be classified by type and have entities extracted (names, IDs, dates) to build comprehensive background reports.

**Evidence Found**:
- `@google-cloud/vertexai` and `@google/genai` dependencies
- `llm/` directory with structured prompt templates for legal domains:
  - Civil decisions, criminal cases, bankruptcy, enforcement proceedings
  - Case type classification, entity extraction, ID number validation
- `llm/llmCall.ts`: Both PDF buffer and text-based classification
- `services/llmService.ts`: Retry logic, JSON parsing with fallback cleaning
- `doc_classification` and `person_entities` tables for storing results

### Decision
Use Google Vertex AI / Gemini models for document classification and entity extraction from legal PDFs, with domain-specific prompt templates per case type.

### Consequences

#### Positive (Observed)
- Strong multilingual support (Hebrew legal documents)
- PDF-native processing (send buffer directly to model)
- Structured output with confidence scores
- Fallback: PDF buffer -> text extraction -> retry

#### Negative (Potential)
- Vendor lock-in to Google Cloud AI
- LLM costs scale with document volume
- Non-deterministic output requires robust parsing

#### Risks
- Model changes could affect classification accuracy
- Rate limits on API calls during bulk processing

### Alternatives (Available at Decision Time)
- **OpenAI GPT-4**: Strong alternative but less integrated with Google Cloud
- **Custom ML models**: More predictable but requires training data
- **Rule-based classification**: Deterministic but inflexible

### Confidence Level
HIGH - Extensive prompt engineering and LLM integration code

---

## ADR-010: Puppeteer for Web Scraping

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
Some data sources (Interpol, lawyer directories) require browser-based scraping because they don't provide APIs or use JavaScript-heavy rendering.

**Evidence Found**:
- `puppeteer` v24.34.0 in dependencies
- `interpol_scraping/scraper.ts`: Browser automation with retry logic
- `Dockerfile`: Installs Google Chrome, configures `PUPPETEER_EXECUTABLE_PATH`
- `scripts/scrape-lawyers.ts`: Additional scraping script
- Multi-stage Docker build to include Chrome in runtime

### Decision
Use Puppeteer with headless Chrome for web scraping tasks that require full browser rendering, installed at the Docker image level.

### Consequences

#### Positive (Observed)
- Full browser rendering handles JavaScript-heavy sites
- Retry logic with exponential backoff
- System Chrome shared across scraping tasks

#### Negative (Potential)
- Heavy Docker image (Chrome adds ~500MB+)
- Memory-intensive (each browser instance)
- Scraping is fragile to site changes

#### Risks
- Sites may block automated access
- Chrome version updates may break scraping logic

### Alternatives (Available at Decision Time)
- **Playwright**: Similar capability, multi-browser support
- **Cheerio/Axios**: Lighter but no JS rendering
- **Selenium**: Older, more overhead

### Confidence Level
HIGH - Dockerfile Chrome installation and scraper code clearly show this pattern

---

## ADR-011: Winston + Logtail for Logging

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs structured logging for debugging, monitoring, and audit trails, with centralized log aggregation.

**Evidence Found**:
- `logger.ts`: Winston with custom format, Logtail transport
- Container ID injection for multi-instance tracing
- Structured data logging: `logger.info('message ', { data: { ... } })`
- CLAUDE.md: Strict PII logging prohibition, data formatting rules
- `__mocks__/logger.ts`: Logger mocked in tests

### Decision
Use Winston for structured logging with Logtail as the cloud aggregation transport. Console output for local development, Logtail for production monitoring.

### Consequences

#### Positive (Observed)
- Structured logging with context data
- Centralized log aggregation via Logtail
- Container ID tracing for debugging

#### Negative (Potential)
- Logtail is a third-party dependency
- No log level configuration per module

#### Risks
- Logtail outage = loss of production log visibility

### Alternatives (Available at Decision Time)
- **Pino**: Faster but less plugin ecosystem
- **AWS CloudWatch Logs**: Native AWS but vendor lock-in
- **Datadog**: More features but higher cost

### Confidence Level
HIGH - Single logger.ts configuration, consistent usage across services

---

## ADR-012: Zustand for Client-Side State Management

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The frontend needs lightweight state management for UI state like search queries, pagination, and admin filters.

**Evidence Found**:
- `zustand` v5.0.8 in dependencies
- `store/adminStore.ts`: Zustand store with `persist` middleware
- Uses `create()` with interface-typed state
- LocalStorage persistence for navigation state

### Decision
Use Zustand for client-side state management with persistence middleware for navigation-related state.

### Consequences

#### Positive (Observed)
- Minimal boilerplate compared to Redux
- Built-in persistence to localStorage
- TypeScript-friendly API

#### Negative (Potential)
- Limited DevTools compared to Redux
- No built-in async action patterns

#### Risks
- Low risk - Zustand is well-maintained and lightweight

### Alternatives (Available at Decision Time)
- **Redux Toolkit**: More structured but heavier
- **React Context**: Built-in but doesn't scale well
- **Jotai/Recoil**: Atomic state but less conventional

### Confidence Level
HIGH - Explicit usage in store directory

---

## ADR-013: Nginx as Reverse Proxy with TLS Termination

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs TLS termination, security header enforcement, and reverse proxy capabilities in front of the Next.js application.

**Evidence Found**:
- `nginx/` directory with per-environment configs and Dockerfiles
- `nginx.conf`: TLS 1.2/1.3, SSL certificates, security headers (CSP, HSTS, X-Frame-Options)
- Separate Dockerfiles: `Dockerfile.production`, `Dockerfile.staging`, `Dockerfile.testing`
- Proxy to `pentagon-app.{env}:3000` via Docker network
- HTTP->HTTPS redirect (308)
- TRACE method blocked

### Decision
Use Nginx as a reverse proxy in a separate Docker container for TLS termination and security header enforcement, with per-environment configurations.

### Consequences

#### Positive (Observed)
- Clean separation of concerns (security at edge, app logic in Next.js)
- Strong security posture with comprehensive headers
- Environment-specific configs
- WebSocket support via proxy_set_header Upgrade

#### Negative (Potential)
- Additional container to manage
- Configuration duplication across environments

#### Risks
- SSL certificate management (currently manual via Secrets Manager)

### Alternatives (Available at Decision Time)
- **AWS ALB**: Managed load balancer with TLS
- **Caddy**: Automatic TLS with simpler config
- **Traefik**: Docker-native reverse proxy

### Confidence Level
HIGH - Full Nginx configuration and Dockerfiles present

---

## ADR-014: Multi-Source Search Pipeline Architecture

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The core product feature requires aggregating person/company data from 15+ heterogeneous sources with different APIs, response formats, and reliability characteristics.

**Evidence Found**:
- `searches/` directory: 10+ search integrations (constructors, medical, accountant, company, corporations, ME, Google Places, Bank Israel, HR, Interpol)
- `services/searchService.ts`: Orchestrates multiple search types in parallel
- `services/entitySearchService.ts`: Entity-based search coordination
- `services/confidenceEngine.ts`: Scoring engine for result certainty
- `filters/`: Post-search filtering logic (name, location, age, appeal)
- `models/job.ts`: Job tracking with status enum (CREATED, STARTED, SUCCESS, FAILED)
- `bottleneck` for rate limiting, `async-mutex` for concurrency control

### Decision
Build a multi-source search pipeline that orchestrates parallel searches across 15+ data sources, with confidence scoring, result filtering, and job status tracking.

### Consequences

#### Positive (Observed)
- Comprehensive due diligence coverage
- Parallel execution for performance
- Confidence scoring adds value to raw data
- Rate limiting protects against API abuse

#### Negative (Potential)
- Complex error handling across multiple sources
- Individual source failures can affect overall results
- Maintenance burden with each data source having different APIs

#### Risks
- External API changes can break searches silently
- Rate limit changes by providers

### Alternatives (Available at Decision Time)
- **Sequential pipeline**: Simpler but much slower
- **Message queue-based**: More resilient but adds infrastructure
- **External search aggregator**: Would remove control over data sources

### Confidence Level
HIGH - Core product feature with extensive code evidence

---

## ADR-015: Role-Based Access Control via Proxy

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application serves three user types (admin, manager, user) with different access levels to pages and API routes. Next.js 16 replaced middleware.ts with proxy.ts.

**Evidence Found**:
- `proxy.ts`: Route definitions for public, auth, user, and manager routes
- Separate `allowed` and `allowedApi` lists per role
- Token cache for API token validation (5-minute TTL)
- Admin gets unrestricted access, other roles get allowlisted routes
- `user.role` field in database schema

### Decision
Implement role-based access control in `proxy.ts` (Next.js 16 proxy layer) with per-role allowlists for both pages and API routes.

### Consequences

#### Positive (Observed)
- Centralized access control in a single file
- Clear visibility of which roles can access which routes
- API token support for programmatic access

#### Negative (Potential)
- Allowlist approach requires updating for every new route
- No fine-grained permissions (action-level)

#### Risks
- Missing a route in the allowlist = security gap or broken access

### Alternatives (Available at Decision Time)
- **Permission-based RBAC**: More granular but complex
- **ABAC (Attribute-Based)**: More flexible but harder to reason about
- **External auth service**: Adds latency

### Confidence Level
HIGH - Explicit route definitions in proxy.ts

---

## ADR-016: Two-Tier Quota/Billing System

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The SaaS model requires tracking search credits at both the organization level and individual user level, with support for packages and trial mode.

**Evidence Found**:
- `usage` model: Organization-level quotas
- `user_usage` model: User-level quotas
- `billing` model: Transaction records
- `package_mapping` model: Credit package definitions
- `services/quotaService.ts`: Quota checking, deduction, trial mode
- `services/crmWebhookService.ts`: Credit allocation via CRM
- `config/trialConstants.ts`: Trial mode configuration

### Decision
Implement a two-tier quota system with organization-level and user-level credit pools, managed through CRM webhook-based package allocation.

### Consequences

#### Positive (Observed)
- Flexible credit allocation (org-wide or per-user)
- Package-based purchasing model
- Trial mode for onboarding
- Audit trail via billing records

#### Negative (Potential)
- Two-tier complexity in quota checking logic
- Race conditions possible during concurrent searches

#### Risks
- Inconsistency between org and user quotas if not properly synced

### Alternatives (Available at Decision Time)
- **Stripe integration**: Would handle billing externally
- **Single-tier quotas**: Simpler but less flexible
- **Usage-based billing**: Pay-per-use without pre-purchased credits

### Confidence Level
HIGH - Multiple models and services dedicated to quota management

---

## ADR-017: CRM Webhook Integration Pattern

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
User provisioning and credit management is handled by an external CRM system. The application needs to receive events from the CRM and send notifications back.

**Evidence Found**:
- `app/api/v1/webhook/crm/user/route.ts`: User creation/update webhook
- `app/api/v1/webhook/crm/tx/route.ts`: Transaction webhook
- `services/crmWebhookService.ts`: Webhook processing logic
- `services/crmOutboundService.ts`: Outbound notifications to CRM
- `types/crmTypes.ts`: CRM-specific type definitions
- Bearer token auth for webhook endpoints (in proxy.ts public routes)

### Decision
Use inbound webhooks for CRM -> application communication (user provisioning, credit transactions) and outbound HTTP calls for application -> CRM notifications (credit exhaustion).

### Consequences

#### Positive (Observed)
- Loose coupling between CRM and application
- Real-time user provisioning
- Automatic credit allocation on purchase

#### Negative (Potential)
- Webhook delivery not guaranteed (no retry mechanism visible)
- Debugging webhook issues requires CRM access

#### Risks
- CRM webhook format changes can break provisioning
- Missing webhook = user without credits

### Alternatives (Available at Decision Time)
- **Polling-based sync**: Simpler but higher latency
- **Message queue**: More reliable delivery
- **Direct API integration**: Tighter coupling

### Confidence Level
HIGH - Clear webhook endpoints and processing services

---

## ADR-018: AWS Services for Cloud Infrastructure

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs cloud storage for court documents, email delivery, and message passing capabilities.

**Evidence Found**:
- `aws/s3.ts`: S3 client with two buckets (`truvify-cases`, `decisions-s3`), presigned URLs
- `aws/ses.ts`: Email sending with BCC support
- `aws/sqs.ts`: Message queue client
- All using AWS SDK v3 (`@aws-sdk/client-*`)
- S3 migration scripts (old path format -> UUID paths)
- AWS Secrets Manager for configuration

### Decision
Use AWS S3 for document storage, SES for transactional emails, SQS for message queuing, and SNS for notifications. All using SDK v3 with explicit credentials.

### Consequences

#### Positive (Observed)
- Mature, reliable AWS services
- Israel region availability (il-central-1)
- SDK v3 with modular imports
- Presigned URLs for secure document access

#### Negative (Potential)
- AWS vendor lock-in
- Cost scales with storage and email volume

#### Risks
- Credential management (currently explicit keys, not IAM roles)

### Alternatives (Available at Decision Time)
- **MinIO (self-hosted S3)**: Avoids vendor lock-in
- **SendGrid/Mailgun**: Better email deliverability features
- **RabbitMQ**: Self-hosted message queue

### Confidence Level
HIGH - AWS wrappers and deployment configuration clearly show AWS-centric architecture

---

## ADR-019: Terraform for Infrastructure Provisioning

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The AWS infrastructure (EC2, security groups) needs to be managed as code for reproducibility and version control.

**Evidence Found**:
- `terraform/` directory with `main.tf`, `provider.tf`, `variables.tf`, `security_groups.tf`
- `install.sh` user data script
- State files present (`.tfstate`, `.tfstate.backup`)
- AWS provider configured for `il-central-1`

### Decision
Use Terraform for provisioning AWS EC2 infrastructure, with state stored locally.

### Consequences

#### Positive (Observed)
- Infrastructure as code for reproducibility
- Version controlled alongside application code

#### Negative (Potential)
- Local state files (not using remote backend)
- Limited infrastructure managed (only EC2/SG)

#### Risks
- State file loss could cause infrastructure drift
- State files contain sensitive data (should not be committed)

### Alternatives (Available at Decision Time)
- **AWS CloudFormation**: Native AWS IaC
- **Pulumi**: TypeScript-based IaC
- **CDK**: AWS native with familiar languages

### Confidence Level
MEDIUM - Terraform files exist but state management appears basic (local state files in repo)

---

## ADR-020: Trust Report PDF Generation (Hebrew + English)

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The platform needs to generate professional PDF reports in both Hebrew and English summarizing background check findings.

**Evidence Found**:
- `@react-pdf/renderer` for React-based PDF generation
- `pdfkit` for server-side PDF creation
- `components/trust-report-preview/`: Hebrew report template components
- `components/trust-report-preview-english/`: English report template components
- `services/pdfGenerationService.ts` and `services/trustReportService.ts`
- `utils/generate-pdf-server.ts`: Server-side PDF generation utility
- `app/trust-report/`: Edit and preview pages

### Decision
Generate trust report PDFs using React-PDF for template rendering, with separate component trees for Hebrew (RTL) and English (LTR) layouts.

### Consequences

#### Positive (Observed)
- React-based templates reuse existing component knowledge
- Separate language templates for proper RTL/LTR handling
- Preview before PDF generation

#### Negative (Potential)
- Dual maintenance for Hebrew and English templates
- React-PDF has limitations compared to native PDF tools

#### Risks
- Complex layout requirements for legal documents

### Alternatives (Available at Decision Time)
- **Puppeteer HTML-to-PDF**: Would leverage existing Chrome installation
- **WeasyPrint**: Python-based but excellent CSS support
- **LaTeX**: Professional typesetting but steep learning curve

### Confidence Level
HIGH - Extensive component structure for both languages

---

## ADR-021: LLM Prompt Engineering for Legal Document Analysis

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
Court documents need to be classified by legal domain and have structured data extracted for background reports.

**Evidence Found**:
- `llm/prompts/`: Domain-specific prompt templates organized by legal category:
  - Criminal: arrest, verdict/sentence, release orders
  - Civil: decisions
  - Bankruptcy: decisions, verdicts
  - Enforcement proceedings
  - General: case type classification, entity extraction, ID validation (Luhn algorithm)
  - Receiving orders, discharge orders
- `llm/utils/jsonCleaner.ts`: Robust JSON parsing for LLM output
- `llm/utils/pdfHelper.ts`: PDF text extraction
- Dual approach: PDF buffer -> LLM, text extraction -> LLM fallback

### Decision
Create domain-specific prompt templates per Israeli legal case type, with structured output parsing and robust fallback mechanisms.

### Consequences

#### Positive (Observed)
- Domain expertise encoded in prompts
- Structured output for database storage
- Fallback chain (PDF -> text -> retry)
- JSON cleaning handles LLM output quirks (Hebrew quotes, etc.)

#### Negative (Potential)
- Prompt maintenance as models evolve
- Hebrew-specific edge cases in JSON parsing

#### Risks
- Model version changes may degrade extraction quality

### Alternatives (Available at Decision Time)
- **Fine-tuned models**: Better accuracy but high training cost
- **Rule-based extraction**: Deterministic but inflexible
- **OCR + NER pipeline**: More traditional but less capable

### Confidence Level
HIGH - Extensive prompt template library with clear domain organization

---

## ADR-022: Telegram Bot for Development Notifications

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The development team needs real-time notifications for certain events during development and testing.

**Evidence Found**:
- `telegraf` v4.16.3 in dependencies
- `utils/scripts/bot.ts`: Telegram bot implementation
- Used as a development utility, not a production feature

### Decision
Use a Telegram bot (via Telegraf library) for development-time notifications and monitoring.

### Consequences

#### Positive (Observed)
- Real-time notifications to mobile
- Simple setup for small teams

#### Negative (Potential)
- Not a production-grade notification system
- Telegram dependency

### Alternatives (Available at Decision Time)
- **Slack integration**: More common for dev teams
- **Discord**: Similar to Telegram but web-native
- **Email**: Already available via SES

### Confidence Level
MEDIUM - Present in codebase but usage scope is limited to development utility

---

## ADR-023: Swagger/OpenAPI for API Documentation

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The API needs documentation for external consumers (CRM integration, API token users) and internal development.

**Evidence Found**:
- `swagger-jsdoc` and `swagger-ui-react` in dependencies
- `app/api/docs/route.ts`: Documentation endpoint
- `app/docs/page.tsx`: Documentation page
- `scripts/generate-swagger.ts`: Swagger spec generation script
- Build process includes `npm run generate:swagger`

### Decision
Use Swagger/OpenAPI with JSDoc annotations for API documentation, generated at build time and served via a dedicated docs page.

### Consequences

#### Positive (Observed)
- Interactive API documentation
- Generated from code annotations (single source of truth)
- Build-time generation ensures freshness

#### Negative (Potential)
- JSDoc annotations add verbosity to route files

### Alternatives (Available at Decision Time)
- **Postman collections**: Manual but team-shareable
- **TypeDoc**: TypeScript-native but not API-focused
- **Redoc**: Alternative OpenAPI renderer

### Confidence Level
HIGH - Build process, routes, and dependencies all confirm this

---

## ADR-024: Jest + React Testing Library for Testing

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs unit and component testing with good TypeScript support and React integration.

**Evidence Found**:
- `jest.config.mjs`: Jest configuration with TypeScript support
- `@testing-library/react` and `@testing-library/jest-dom` in devDependencies
- `__tests__/` directory with 90+ test files mirroring source structure
- Test categories: models, services, API routes, components, hooks, filters, LLM, utils, pages
- `__mocks__/`: Mock setup for logger, HTTP responses
- CI runs tests with `npm test` (jest --silent)
- CLAUDE.md: "MANDATORY: Add tests for new features and bug fixes"

### Decision
Use Jest for unit testing and React Testing Library for component testing, with comprehensive mocking of external dependencies.

### Consequences

#### Positive (Observed)
- Extensive test coverage across all layers
- Consistent testing patterns
- CI integration ensures tests pass before deploy
- Mandatory testing rule enforced via CLAUDE.md

#### Negative (Potential)
- No integration or E2E tests observed
- Jest can be slow with large test suites

### Alternatives (Available at Decision Time)
- **Vitest**: Faster, Vite-native
- **Cypress/Playwright**: E2E testing (complementary)
- **Mocha**: Flexible but more setup required

### Confidence Level
HIGH - Extensive test suite and CI integration

---

## ADR-025: MUI + Tailwind CSS for UI Styling

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs a comprehensive UI component library for a data-heavy B2B application with tables, dialogs, and forms.

**Evidence Found**:
- `@mui/material` v5.18.0 and `@mui/icons-material` in dependencies
- `tailwindcss` v3.4.19 in devDependencies
- `@base-ui-components/react` (beta) in dependencies
- `app/global.css` and CSS modules in various components
- `react-select` for enhanced dropdowns
- `lucide-react` for icons (alongside MUI icons)

### Decision
Use Material-UI (MUI) as the primary component library with Tailwind CSS for utility styling. Multiple icon libraries (MUI Icons, Lucide) available.

### Consequences

#### Positive (Observed)
- Rich component library for data-heavy UI (tables, dialogs, forms)
- Tailwind for quick layout adjustments
- Consistent design language

#### Negative (Potential)
- Two styling paradigms (MUI's styled/sx + Tailwind utilities) may cause confusion
- MUI + Tailwind can have CSS specificity conflicts
- Multiple icon libraries add bundle size

### Alternatives (Available at Decision Time)
- **Tailwind-only + Headless UI**: Lighter but more custom work
- **Ant Design**: Alternative component library
- **Chakra UI**: Similar to MUI but different design language

### Confidence Level
MEDIUM - Both libraries are present but the exact usage patterns and styling conventions are not fully clear from dependency analysis alone

---

## ADR-026: Zod for Runtime Schema Validation

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
API requests and external data (CRM webhooks, search results) need runtime validation beyond TypeScript's compile-time type checking.

**Evidence Found**:
- `zod` v3.25.76 in dependencies
- Used for request validation and data shape verification
- Complements TypeScript types with runtime checks

### Decision
Use Zod for runtime schema validation of API inputs and external data, complementing TypeScript's static typing.

### Consequences

#### Positive (Observed)
- Runtime type safety for external inputs
- TypeScript type inference from schemas
- Composable validation rules

#### Negative (Potential)
- Additional validation layer to maintain alongside TypeScript types

### Alternatives (Available at Decision Time)
- **Joi**: Older, no TypeScript inference
- **Yup**: Similar but less TypeScript-friendly
- **io-ts**: Functional approach, steeper learning curve

### Confidence Level
MEDIUM - Dependency is present; exact usage patterns require deeper code inspection

---

## ADR-027: UUID Primary Keys with PostgreSQL Extensions

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The application needs globally unique identifiers for entities that may be referenced across systems (CRM, external APIs).

**Evidence Found**:
- All Prisma models use `@id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid`
- PostgreSQL `uuid-ossp` extension enabled in schema
- S3 path migration from case-number-based to UUID-based paths
- CRM integration uses UUIDs (`client_id` on user)

### Decision
Use database-generated UUID v4 as primary keys for all entities, leveraging PostgreSQL's uuid-ossp extension.

### Consequences

#### Positive (Observed)
- Globally unique across systems
- No sequential ID enumeration risk
- Safe for external exposure (CRM, API tokens)

#### Negative (Potential)
- Larger index size vs auto-increment integers
- Less human-readable in debugging

### Alternatives (Available at Decision Time)
- **Auto-increment integers**: Simpler, smaller, but sequential
- **ULID/CUID**: Sortable UUIDs
- **Application-generated UUIDs**: Less database coupling

### Confidence Level
HIGH - Universally applied across all 30+ models

---

## ADR-028: Gitflow Branching Strategy

### Status
Discovered (Inferred from codebase)

### Date
2026-02-11

### Owner
Legacy/Inferred

### Context
The team needs a clear branching strategy for managing releases across staging and production environments.

**Evidence Found**:
- CLAUDE.md: "We use gitflow: always branch out from develop and submit a PR back to develop"
- `develop` is the main branch for development (protected)
- `main` branch for production releases
- CI/CD: `develop` -> staging, `main` -> production
- PR-based workflow with branch protection

### Decision
Use Gitflow branching strategy with `develop` as the integration branch (deploying to staging) and `main` as the production release branch.

### Consequences

#### Positive (Observed)
- Clear separation of development and production code
- Staging environment for pre-release testing
- PR-based code review enforcement

#### Negative (Potential)
- More complex than trunk-based development
- Merge conflicts between long-lived branches

### Alternatives (Available at Decision Time)
- **Trunk-based development**: Simpler but requires feature flags
- **GitHub Flow**: Single main branch with deployments per merge
- **Release branches**: Additional layer for versioned releases

### Confidence Level
HIGH - Explicit in CLAUDE.md and CI/CD configuration
