# Architectural Decision Records (ADRs)

> **Generated**: 2026-02-10
> **Method**: Reverse-engineered from codebase analysis
> **Project**: Pentagon2 / Truvify

---

## ADR-001: System Architecture Style - Next.js Monolith

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The system needed a web application serving both a user-facing UI and a REST API for a compliance/background-check SaaS platform. The team needed to move fast with a small engineering team (~1.5 engineers), minimizing operational complexity while delivering a full-stack product.

**Evidence Found**:
- Single `package.json` at root with both React frontend and API dependencies
- `app/` directory contains both UI pages (`app/auth/`, `app/admin/`, `app/user/`) and API routes (`app/api/v1/`)
- Single Dockerfile builds the entire application
- Single deployment pipeline in `.github/workflows/deploy.yml`
- No service discovery, message brokers between services, or separate deployment units

### Decision
Use Next.js as a full-stack monolith, combining the React frontend and Node.js API backend in a single deployable unit using the App Router pattern.

### Consequences

#### Positive (Observed)
- Single deployment simplifies ops for a small team
- Shared TypeScript types between frontend and backend
- Fast iteration without cross-service coordination
- Simple debugging - one process, one log stream

#### Negative (Potential)
- Frontend and backend scale together (can't scale API independently)
- Large codebase in a single repo may become unwieldy
- No isolation between concerns at deployment level

#### Risks
- Performance bottlenecks in one area affect the whole app
- Long build times as codebase grows

### Alternatives (Available at Decision Time)
- **Separate frontend/backend**: React SPA + Express API - more operational overhead
- **Microservices**: Overkill for team size and early-stage product
- **Serverless (Lambda)**: Would fragment the scraping/LLM workloads poorly

### Confidence Level
**HIGH** - Single package.json, single Dockerfile, unified deployment pipeline clearly indicate monolithic architecture.

---

## ADR-002: Client-Side Rendering Only - No SSR

### Status
Discovered (Inferred from codebase + CLAUDE.md)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
Despite using Next.js (which supports SSR and Server Components), the team needed to decide on a rendering strategy. The application is a SaaS dashboard behind authentication - SEO is irrelevant, and data fetching requires user context.

**Evidence Found**:
- CLAUDE.md explicitly states: "Use client-side rendering only - NO SSR or server components"
- CLAUDE.md: "All frontend-backend communication must be via HTTP calls to API routes"
- CLAUDE.md: "Use 'use client' for all components that need interactivity or state"
- Components directory shows React functional components with client-side patterns
- No `getServerSideProps`, `getStaticProps`, or Server Component patterns found

### Decision
Use client-side rendering exclusively. All components are client components that fetch data via HTTP calls to API routes. No SSR, no Server Components.

### Consequences

#### Positive (Observed)
- Simpler mental model - clear separation between UI and API
- No hydration mismatches or SSR-specific bugs
- Easier to reason about authentication state
- API routes are a clean boundary

#### Negative (Potential)
- Initial page load shows loading states (no pre-rendered content)
- Cannot leverage React Server Components for data fetching optimization
- Not using Next.js to its full potential

#### Risks
- Perceived performance impact on initial load (mitigated by auth-gated app)

### Alternatives (Available at Decision Time)
- **SSR with Next.js**: Better initial load but complex auth handling
- **Server Components**: Newer pattern, but adds complexity for a small team
- **Static Generation**: Not applicable for dynamic dashboard data

### Confidence Level
**HIGH** - Explicitly documented in CLAUDE.md as a project standard.

---

## ADR-003: PostgreSQL as Primary Database

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform stores court cases, person records, company registrations, financial sanctions, and other structured compliance data. The data model is highly relational with complex queries including full-text search.

**Evidence Found**:
- `prisma/schema.prisma` declares `provider = "postgresql"`
- PostgreSQL extensions used: `pg_trgm` (trigram search), `uuid-ossp` (UUID generation)
- 40 Prisma models with extensive foreign key relationships
- GIN trigram indexes on `cases.appellants` and `cases.appellees` for fuzzy name matching
- 129 migration files showing active schema evolution
- CI/CD pipeline uses `postgres:15` service container for testing
- `DATABASE_URL` environment variable for connection

### Decision
Use PostgreSQL as the sole database, with Prisma ORM for schema management and query building.

### Consequences

#### Positive (Observed)
- Strong relational model fits the compliance domain perfectly
- pg_trgm extension enables fuzzy Hebrew name matching
- Mature ecosystem with excellent indexing capabilities
- Prisma provides type-safe queries and migration management

#### Negative (Potential)
- Single database for all workloads (OLTP + search + analytics)
- Large tables (`cases`, `doc_classification`, `person_entities`) require careful query optimization
- No read replicas evident for scaling reads

#### Risks
- Performance degradation on large tables without proper indexing strategy
- Schema migrations on massive tables can cause downtime

### Alternatives (Available at Decision Time)
- **MongoDB**: Flexible schema but poor for relational compliance data
- **PostgreSQL + Elasticsearch**: Better search but more operational complexity
- **MySQL**: Weaker full-text search and extension ecosystem

### Confidence Level
**HIGH** - Unambiguous from Prisma schema, CI config, and extensive migration history.

---

## ADR-004: Prisma ORM for Database Access

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needed a database access layer that provides type safety, migration management, and a clean API for the TypeScript codebase.

**Evidence Found**:
- `@prisma/client` v6.14.0 in dependencies, `prisma` v6.14.0 in devDependencies
- `prisma/schema.prisma` with 40 models and 691 lines
- 129 migration files in `prisma/migrations/`
- Build script runs `prisma generate` before Next.js build
- 37 model files in `models/` directory wrapping Prisma operations
- Custom `prisma-guard.ts` script preventing accidental production DB operations

### Decision
Use Prisma as the ORM with a dedicated model layer wrapping Prisma client calls, following the Service -> Model architecture pattern.

### Consequences

#### Positive (Observed)
- Type-safe database queries throughout the codebase
- Schema-as-code with migration history
- `prisma-guard.ts` adds safety against destructive operations
- Model layer provides abstraction over raw Prisma calls

#### Negative (Potential)
- Prisma's query capabilities are limited vs raw SQL for complex analytics
- Generated client can be large
- N+1 query patterns if not careful with includes

#### Risks
- Lock-in to Prisma's migration format
- Raw SQL (`$queryRaw`) needed for complex operations, bypassing type safety

### Alternatives (Available at Decision Time)
- **TypeORM**: More features but less type safety
- **Drizzle ORM**: Lighter, SQL-first approach
- **Raw pg client**: Maximum control but no migration management

### Confidence Level
**HIGH** - Prisma is deeply integrated throughout the stack.

---

## ADR-005: Layered Architecture - UI -> API -> Service -> Model

### Status
Discovered (Inferred from codebase + CLAUDE.md)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The team needed a code organization pattern that separates concerns clearly while remaining simple enough for a small team to maintain.

**Evidence Found**:
- CLAUDE.md explicitly documents: "Architecture: UI -> API -> Service -> Model"
- CLAUDE.md: "UI: Presentation only, no business logic"
- CLAUDE.md: "API: HTTP handling, call services"
- CLAUDE.md: "Service: Business logic"
- CLAUDE.md: "Model: Prisma database operations"
- Directory structure reflects this: `components/` (UI), `app/api/` (API), `services/` (44 files), `models/` (37 files)
- Services contain business logic (searchService.ts at 561 lines, confidenceEngine.ts at 796 lines)
- Models wrap Prisma operations

### Decision
Follow a strict 4-layer architecture: UI components -> API route handlers -> Service functions -> Model functions (Prisma).

### Consequences

#### Positive (Observed)
- Clear separation of concerns
- Services are testable independently of HTTP layer
- Models isolate database operations
- Easy to understand for new developers

#### Negative (Potential)
- Can lead to "pass-through" layers for simple CRUD operations
- No domain model layer - business logic lives in service functions

#### Risks
- Services growing too large (searchService.ts already at 561 lines)
- Temptation to bypass layers (UI calling models directly)

### Alternatives (Available at Decision Time)
- **Clean Architecture**: More layers, more abstraction, more boilerplate
- **Feature-based modules**: Group by domain instead of layer
- **CQRS**: Separate read/write paths - overkill for current scale

### Confidence Level
**HIGH** - Explicitly documented and consistently followed in codebase structure.

---

## ADR-006: NextAuth for Authentication

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needs secure authentication supporting both internal (Google SSO) and external (CRM/API) users with role-based access control.

**Evidence Found**:
- `next-auth` v5.0.0-beta.30 in dependencies
- `auth.ts` configures NextAuth with Google OAuth + Credentials providers
- JWT session strategy with role injection
- MFA support via separate token generation flow
- `proxy.ts` implements middleware with both NextAuth session and Bearer token validation
- Role-based routing: User, Manager, Admin with distinct endpoint permissions
- API token system with granular permissions (`api_token_permission` table)
- Password history tracking, account lockout, password reset tokens

### Decision
Use NextAuth (v5 beta) for session management with dual authentication: Google OAuth for internal users (restricted to @truvify.com) and Credentials provider for external users. Supplement with a custom API token system for service-to-service authentication.

### Consequences

#### Positive (Observed)
- Google SSO for internal team - zero password management
- External users get traditional email/password auth
- API tokens enable CRM webhook integration
- Fine-grained permissions per API token
- MFA adds security layer

#### Negative (Potential)
- Using beta version (v5.0.0-beta.30) of NextAuth - stability risks
- Dual auth systems (session + token) add complexity
- Custom MFA implementation alongside NextAuth

#### Risks
- Beta version may have breaking changes
- Token cache in `proxy.ts` (5-minute TTL) could serve stale permissions
- Password security relies on custom implementation (salt, history)

### Alternatives (Available at Decision Time)
- **Auth0/Clerk**: Managed auth - less code but vendor dependency
- **Passport.js**: More mature but less Next.js integration
- **Custom JWT**: Full control but more security surface area

### Confidence Level
**HIGH** - Auth implementation is well-evidenced across auth.ts, proxy.ts, and database schema.

---

## ADR-007: Next.js 16 Proxy Pattern (Replacing Middleware)

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
Next.js 16 replaced `middleware.ts` with `proxy.ts` for request interception. The application needed to authenticate requests, enforce RBAC, and inject user context headers.

**Evidence Found**:
- CLAUDE.md notes: "Next.js 16 with App Router (note: in version 16 middleware.ts was replaced with proxy.ts!)"
- `proxy.ts` at root (314 lines) implementing full auth middleware
- Token cache with 5-minute TTL and automatic cleanup
- Route protection matrix with public/user/manager/admin tiers
- Headers injection: `x-user-email`, `x-user-role`

### Decision
Implement authentication and authorization in Next.js 16's `proxy.ts` pattern, combining session validation, API token validation, and role-based route protection in a single middleware layer.

### Consequences

#### Positive (Observed)
- Centralized auth logic at the edge
- Token caching reduces database lookups
- Clear route permission matrix

#### Negative (Potential)
- 314-line proxy is getting complex
- Token cache could serve stale data for up to 5 minutes

#### Risks
- Next.js 16 proxy pattern is new - limited community knowledge
- Single point of failure for all authentication

### Confidence Level
**HIGH** - Direct evidence in proxy.ts and CLAUDE.md documentation.

---

## ADR-008: AWS Cloud Infrastructure

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needed cloud infrastructure for file storage, email, async processing, and compute.

**Evidence Found**:
- AWS SDK dependencies: `@aws-sdk/client-s3`, `@aws-sdk/client-ses`, `@aws-sdk/client-sns`, `@aws-sdk/client-sqs`
- `aws/` directory with `s3.ts`, `ses.ts`, `sqs.ts` integration modules
- Terraform in `terraform/` for infrastructure-as-code
- Deployment to EC2 via SSH (GitHub Actions workflow)
- AWS Secrets Manager for environment configuration
- Amazon ECR for Docker image registry
- S3 for document storage with presigned URLs
- SES for transactional email
- SQS for async job processing

### Decision
Use AWS as the sole cloud provider with EC2 for compute, S3 for storage, SES for email, SQS for messaging, ECR for container registry, and Secrets Manager for configuration.

### Consequences

#### Positive (Observed)
- Single cloud provider reduces operational complexity
- Terraform provides reproducible infrastructure
- Managed services (SES, SQS, S3) reduce ops burden

#### Negative (Potential)
- EC2 deployment (not ECS/Fargate) requires manual server management
- No auto-scaling configuration evident
- Single EC2 instance per environment (no load balancer evident)

#### Risks
- Single point of failure without auto-scaling or load balancing
- Manual SSH deployment is fragile
- No evident disaster recovery strategy

### Alternatives (Available at Decision Time)
- **AWS ECS/Fargate**: Container orchestration with auto-scaling
- **GCP/Azure**: Alternative cloud providers
- **Vercel**: Native Next.js hosting but limited for custom infrastructure needs

### Confidence Level
**HIGH** - Extensive AWS SDK usage, Terraform configs, and deployment pipeline confirm AWS-centric infrastructure.

---

## ADR-009: Docker Containerization with Nginx Reverse Proxy

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needed a deployment strategy supporting staging and production environments with TLS termination and security headers.

**Evidence Found**:
- Multi-stage `Dockerfile` with builder and runtime stages
- `Dockerfile.base` for cached base image (Node 20.19.2)
- Nginx Dockerfiles per environment: `Dockerfile.production`, `Dockerfile.staging`
- Nginx configs with TLS 1.2/1.3, security headers (HSTS, CSP, X-Frame-Options)
- Docker network `pentagon-network` connecting app and nginx containers
- PM2 as process manager inside container
- Google Chrome installed for Puppeteer scraping

### Decision
Deploy as Docker containers with a two-container architecture: Next.js app (PM2 managed) and Nginx reverse proxy (TLS termination, security headers). Use environment-specific Docker images and nginx configs.

### Consequences

#### Positive (Observed)
- Consistent environments across staging/production
- Nginx handles TLS and security headers properly
- Multi-stage builds reduce image size
- Base image caching speeds up builds

#### Negative (Potential)
- Chrome in Docker for Puppeteer adds significant image size
- PM2 inside Docker is somewhat redundant (Docker already manages process lifecycle)
- Manual container orchestration via SSH (no ECS/K8s)

#### Risks
- No container orchestration - manual restarts on failure
- SSL certificate management via Secrets Manager adds deployment complexity

### Confidence Level
**HIGH** - Multiple Dockerfiles, nginx configs, and deployment scripts clearly document this pattern.

---

## ADR-010: Multi-Source Search Pipeline Architecture

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The core product performs comprehensive background checks by aggregating data from 15+ sources including court records, professional registries, sanctions lists, and news articles.

**Evidence Found**:
- `searchService.ts` (561 lines) orchestrating multi-source searches
- `confidenceEngine.ts` (796 lines) calculating trust scores
- `searches/` directory with 15+ search implementations
- `entitySearchService.ts` for cross-database entity matching
- `filters/` directory with filtering logic for search results
- CLAUDE.md documents "Search Pipeline Reliability" patterns including state flags and multi-stage process design
- Data sources: court cases, Bank of Israel, accountants, medical professionals, constructors, HR records, jobs, known criminals, Interpol, financial sanctions, terror lists, company registries, news articles (Posta), crypto wallets

### Decision
Implement a multi-source search pipeline where `searchService` orchestrates parallel searches across 15+ data sources, `entitySearchService` handles cross-database matching, and `confidenceEngine` calculates a trust/risk score from aggregated results.

### Consequences

#### Positive (Observed)
- Comprehensive coverage across multiple data sources
- Confidence scoring provides quantified risk assessment
- Filtering pipeline handles deduplication and relevance
- CLAUDE.md documents critical lessons about pipeline reliability

#### Negative (Potential)
- Complex pipeline with many potential failure points
- All-or-nothing approach can be slow if any source is slow
- confidenceEngine at 796 lines is the most complex single file

#### Risks
- Early return patterns can bypass critical search stages (documented in CLAUDE.md)
- Race conditions in sequential processing (documented lesson)
- Performance depends on slowest data source

### Confidence Level
**HIGH** - Core business logic with extensive evidence across services, searches, filters, and documented patterns.

---

## ADR-011: LLM Integration for Document Classification

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform processes court documents and needs to extract structured data from unstructured legal text, classify document types, and identify entities.

**Evidence Found**:
- `llm/` directory with structured prompt system
- `llmCall.ts` for AI API interaction
- Prompts for: general case extraction, case type classification, criminal/civil/bankruptcy/enforcement proceedings
- `@google-cloud/vertexai` and `@google/genai` dependencies (Google AI)
- `llmService.ts` (169 lines) in services
- `doc_classification` and `person_entities` database tables for storing extraction results
- `llm-cases-classifier` script for batch classification
- JSON cleaner utility for parsing LLM responses

### Decision
Use LLM (Google Vertex AI / Gemini) with specialized prompts for document classification and entity extraction. Organize prompts by legal domain (criminal, civil, bankruptcy, enforcement) with structured input/output schemas.

### Consequences

#### Positive (Observed)
- Automated extraction from unstructured legal documents
- Domain-specific prompts improve accuracy
- Structured output via JSON schemas
- Batch processing capability via CLI scripts

#### Negative (Potential)
- LLM costs scale with document volume
- Response parsing requires JSON cleaning (unreliable LLM output)
- Model changes can affect extraction quality

#### Risks
- LLM hallucination in legal context could produce incorrect classifications
- Dependency on external AI provider availability
- Prompt maintenance burden as legal categories evolve

### Alternatives (Available at Decision Time)
- **Rule-based extraction**: More predictable but limited to known patterns
- **Custom ML models**: Better accuracy but higher development cost
- **OpenAI/Anthropic**: Alternative LLM providers

### Confidence Level
**HIGH** - Well-structured LLM directory with domain-specific prompts and supporting infrastructure.

---

## ADR-012: Puppeteer for Web Scraping

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needs to scrape court case documents and other public records from various Israeli government websites.

**Evidence Found**:
- `puppeteer` v24.34.0 in dependencies
- Chrome installed in Docker container (`PUPPETEER_EXECUTABLE_PATH=/opt/google/chrome/chrome`)
- `interpol_scraping/scraper.ts` for Interpol data
- `scrape-lawyers.ts` script
- `cases` table has `scrape_status` enum tracking scraping progress
- `doc_classification` table stores scraped document analysis results
- Bottleneck rate limiter for managing scraping throughput
- `requestService.ts` (189 lines) for external HTTP requests with retry logic

### Decision
Use Puppeteer with headless Chrome for web scraping, running inside Docker containers with rate limiting via Bottleneck.

### Consequences

#### Positive (Observed)
- Full browser rendering handles JavaScript-heavy government sites
- Rate limiting prevents IP blocking
- Scrape status tracking enables resumable scraping jobs
- Docker ensures consistent Chrome environment

#### Negative (Potential)
- Chrome in Docker is resource-heavy
- Scraping is fragile - site changes break scrapers
- Significant Docker image size increase

#### Risks
- Legal compliance with scraping terms of service
- Government site changes requiring scraper maintenance
- Resource consumption of headless Chrome instances

### Confidence Level
**HIGH** - Puppeteer deeply integrated with Docker configuration, scraping scripts, and database schema.

---

## ADR-013: Winston + Logtail for Logging

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needed structured logging with cloud aggregation for debugging and compliance.

**Evidence Found**:
- `winston` v3.17.0 and `@logtail/winston` v0.5.5 in dependencies
- `logger.ts` configures Winston with console + Logtail transports
- CLAUDE.md defines strict logging standards: `{ data: { ... } }` format
- CLAUDE.md prohibits PII in logs
- Container ID included in log format for multi-instance tracking
- Global logger mock in tests (`__mocks__/logger.ts`)

### Decision
Use Winston as the logging framework with Logtail as the cloud log aggregation service. Enforce structured logging format with a `data` field and strict PII prohibition.

### Consequences

#### Positive (Observed)
- Structured logs enable searching and filtering
- Cloud aggregation via Logtail for production monitoring
- PII prohibition protects user privacy
- Consistent format enforced via CLAUDE.md standards

#### Negative (Potential)
- Logtail dependency for production log viewing
- Strict format rules can slow development

#### Risks
- PII leaks through error objects if not properly sanitized
- Log volume costs with Logtail

### Confidence Level
**HIGH** - Logger configuration, CLAUDE.md standards, and mock setup clearly document this choice.

---

## ADR-014: MUI (Material UI) Component Library

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The frontend needed a comprehensive component library for building a professional SaaS dashboard with minimal custom CSS.

**Evidence Found**:
- `@mui/material` v5.18.0 and `@mui/icons-material` v5.18.0 in dependencies
- `@emotion/react` and `@emotion/styled` (MUI's styling engine)
- Components use MUI patterns throughout the codebase
- Also uses: `lucide-react` for additional icons, `react-select` for dropdowns
- Tailwind CSS in devDependencies (v3.4.19) - possibly for supplementary styling
- `@base-ui-components/react` v1.0.0-beta.2 - MUI's unstyled component library

### Decision
Use Material UI (MUI) v5 as the primary component library with Emotion for styling. Supplement with Tailwind CSS for utility classes and lucide-react for additional icons.

### Consequences

#### Positive (Observed)
- Comprehensive component set reduces custom UI work
- Consistent design language across the application
- MUI v5 is battle-tested and well-documented

#### Negative (Potential)
- MUI bundle size is significant
- Mixed styling approaches (MUI/Emotion + Tailwind) can create inconsistency
- MUI theming is complex for heavy customization

#### Risks
- Two styling paradigms (Emotion + Tailwind) may confuse developers

### Confidence Level
**MEDIUM** - MUI dependencies are clear, but the relationship between MUI, Tailwind, and Base UI components needs clarification.

---

## ADR-015: Multi-Tenant Organization Model

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needed to support multiple customer organizations, each with their own users, search quotas, and billing.

**Evidence Found**:
- `organization` table with subscription tiers and quota management
- `user` table with `organization_id` foreign key
- `usage` table tracking per-organization search quotas
- `user_usage` table for per-user quota tracking
- `billing` table with both `user_id` and `organization_id`
- `package_mapping` for subscription tier definitions
- Trial mode support with configurable quota sizes
- CRM webhook integration for automated user provisioning
- `api_token_permission` for per-token access control

### Decision
Implement shared-database multi-tenancy where organizations share the same database but data is scoped by `organization_id`. Each organization has its own users, quotas, and billing.

### Consequences

#### Positive (Observed)
- Simple to implement - no separate databases per tenant
- Flexible quota and billing at both org and user level
- CRM integration automates user onboarding
- Trial mode enables self-service signup

#### Negative (Potential)
- No data isolation between tenants at database level
- All tenants share the same compute resources
- Complex quota logic (org-level + user-level)

#### Risks
- Data leakage between organizations if queries aren't properly scoped
- Noisy neighbor problem without resource isolation
- Query performance impacted by all tenants sharing tables

### Confidence Level
**HIGH** - Database schema, billing tables, and CRM integration clearly show multi-tenant design.

---

## ADR-016: GitHub Actions CI/CD with EC2 Deployment

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The team needed automated testing, building, and deployment for staging and production environments.

**Evidence Found**:
- `.github/workflows/deploy.yml` with test + deploy jobs
- Branch-based deployment: `develop` -> staging, `main` -> production
- PostgreSQL 15 service container in CI for integration tests
- Full test suite: lint -> prisma validate -> build -> test
- Docker build with ECR push
- SSH-based deployment to EC2
- AWS Secrets Manager for environment configuration
- Concurrency control with in-progress cancellation
- CODEOWNERS requires @alfasin and @yaelal review

### Decision
Use GitHub Actions for CI/CD with a two-job pipeline (test, deploy). Deploy via Docker images pushed to ECR, then pulled and run on EC2 via SSH.

### Consequences

#### Positive (Observed)
- Automated testing prevents broken deployments
- Branch-based environments (staging/production)
- Concurrency control prevents conflicting deployments
- Full integration testing with real PostgreSQL

#### Negative (Potential)
- SSH-based deployment is fragile and hard to audit
- No blue-green or canary deployment strategy
- EC2 deployment lacks auto-recovery

#### Risks
- Single EC2 instance - no high availability
- SSH key management in GitHub secrets
- No rollback mechanism beyond redeploying previous commit

### Alternatives (Available at Decision Time)
- **AWS ECS**: Container orchestration with health checks
- **AWS CodePipeline**: Native AWS CI/CD
- **Kubernetes**: Full orchestration - overkill for team size

### Confidence Level
**HIGH** - Complete CI/CD workflow with deployment scripts clearly documented.

---

## ADR-017: Zod for Runtime Validation

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needs runtime validation of API inputs, webhook payloads, and form data beyond TypeScript's compile-time type checking.

**Evidence Found**:
- `zod` v3.25.76 in dependencies
- Used alongside TypeScript for runtime schema validation
- `react-hook-form` v7.62.0 for form validation (likely with Zod resolver)
- API routes need input validation before passing to services

### Decision
Use Zod for runtime schema validation, complementing TypeScript's compile-time type checking.

### Consequences

#### Positive (Observed)
- Runtime type safety at API boundaries
- Schema-first validation with TypeScript inference
- Integrates with react-hook-form for frontend validation

#### Negative (Potential)
- Additional runtime overhead for validation
- Schema duplication with Prisma types

### Confidence Level
**MEDIUM** - Zod is in dependencies and is the standard choice with TypeScript, but specific usage patterns would need code-level verification.

---

## ADR-018: Zustand for Client-Side State Management

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The frontend needed lightweight state management for cross-component state like admin search filters and pagination.

**Evidence Found**:
- `zustand` v5.0.8 in dependencies
- Single store: `store/adminStore.ts` with localStorage persistence
- Manages search query and pagination state
- No Redux, MobX, or other state management libraries

### Decision
Use Zustand for minimal client-side state management with localStorage persistence, keeping most state in component-local React state and URL parameters.

### Consequences

#### Positive (Observed)
- Minimal boilerplate compared to Redux
- Persistence across page navigations
- Small bundle size

#### Negative (Potential)
- Single store suggests limited global state needs
- May need more stores as features grow

### Confidence Level
**HIGH** - Zustand dependency confirmed with single store implementation.

---

## ADR-019: PDF Generation with Dual Libraries

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform generates trust reports as PDFs for download, and also needs to parse incoming PDF documents from court records.

**Evidence Found**:
- `@react-pdf/renderer` v4.3.0 for React-based PDF generation
- `pdfkit` v0.17.1 for server-side PDF generation
- `pdf-parse` v1.1.1 for PDF text extraction
- `pdfGenerationService.ts` (211 lines) in services
- `trust-report-preview/` and `trust-report-preview-english/` components for Hebrew/English reports
- `generate-pdf` API endpoint
- `sharp` v0.34.3 for image processing

### Decision
Use @react-pdf/renderer for React-component-based PDF generation (trust reports) and pdfkit for server-side PDF operations. Use pdf-parse for extracting text from incoming PDFs.

### Consequences

#### Positive (Observed)
- React-PDF allows reusing React components for PDF layout
- Hebrew and English report templates
- Server-side generation doesn't block the UI

#### Negative (Potential)
- Two PDF generation libraries adds complexity
- React-PDF has limited styling compared to CSS

### Confidence Level
**MEDIUM** - Dependencies confirm dual-library approach but exact usage split needs verification.

---

## ADR-020: Functional Programming Over OOP

### Status
Discovered (Inferred from codebase + CLAUDE.md)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The team needed to establish coding patterns for the TypeScript codebase.

**Evidence Found**:
- CLAUDE.md: "Use functional programming patterns - avoid classes, prefer standalone functions"
- CLAUDE.md: "Use functions, not arrow functions"
- Services are standalone exported functions, not class methods
- No class-based patterns in services or models
- React functional components (no class components)

### Decision
Use functional programming patterns exclusively. All services, models, and utilities are standalone exported functions. No classes, no OOP patterns.

### Consequences

#### Positive (Observed)
- Simpler testing (pure functions)
- No `this` context issues
- Consistent pattern across codebase

#### Negative (Potential)
- No encapsulation via class instances
- Shared state must be passed explicitly

### Confidence Level
**HIGH** - Explicitly documented in CLAUDE.md and consistently observed.

---

## ADR-021: Swagger/OpenAPI for API Documentation

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The API needed documentation for both internal team and external API consumers (CRM integrations).

**Evidence Found**:
- `swagger-jsdoc` and `swagger-ui-react` in dependencies
- `scripts/generate-swagger.ts` generates OpenAPI spec during build
- `lib/swagger.ts` configuration
- `/api/docs` endpoint serves Swagger UI
- Build script includes `npm run generate:swagger`
- Security schemes: BearerAuth (JWT), SystemToken (service-to-service)

### Decision
Use Swagger/OpenAPI with auto-generated specs from JSDoc annotations, served via swagger-ui-react at `/api/docs`.

### Consequences

#### Positive (Observed)
- Interactive API documentation
- Security scheme documentation
- Generated during build - stays in sync

#### Negative (Potential)
- JSDoc annotations must be maintained alongside code
- Swagger UI adds bundle size

### Confidence Level
**HIGH** - Dependencies, build script, and API endpoint confirm Swagger integration.

---

## ADR-022: Telegram Bot (Development Utility Only)

### Status
Discovered (Verified - dev-only utility)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The team needed a development utility for message logging/debugging.

**Evidence Found**:
- `telegraf` v4.16.3 in dependencies (Telegram bot framework)
- `utils/scripts/bot.ts` - simple message logger without business logic
- Not referenced by any production service or API route
- Not included in Docker container or deployment pipeline

### Decision
Telegraf is included as a development utility script for message logging. It is NOT a production notification channel.

### Consequences

#### Positive (Observed)
- Useful for development/debugging

#### Negative (Potential)
- Unused dependency in production bundle

### Confidence Level
**HIGH** - Verified: `bot.ts` is a standalone script in `utils/scripts/`, not integrated into production code. Production notifications use AWS SES email.

---

## ADR-023: CRM Webhook Integration (Bizsense)

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needed automated user provisioning and credit management through the sales CRM system (Bizsense, BIZ_ID: 9545) to reduce manual onboarding.

**Evidence Found**:
- `services/crmWebhookService.ts` - core CRM webhook processing logic
- `services/crmOutboundService.ts` - outbound notifications to CRM on credit exhaustion
- `app/api/v1/webhook/crm/user/route.ts` - user provisioning webhook endpoint
- `app/api/v1/webhook/crm/tx/route.ts` - transaction status webhook endpoint
- Bearer token authentication with granular permissions (`create_user`, `modify_user`, `add_credits`, `fail_tx`, `success_tx`)
- Snake_case to camelCase conversion at API boundary (CRM uses snake_case)

### Decision
Integrate with Bizsense CRM via inbound webhooks for user provisioning and credit management. Two webhook endpoints handle user lifecycle (creation, package assignment) and transaction callbacks (payment success/failure). Outbound notifications alert CRM when users exhaust auto-renewable package credits.

### Consequences

#### Positive (Observed)
- Automated user onboarding from CRM reduces manual work
- Credit management tied to package purchases
- Organization-aware: credits routed to org or user based on membership
- Transaction status callbacks enable billing failure handling

#### Negative (Potential)
- Tight coupling to Bizsense CRM API contract
- Snake_case/camelCase translation layer adds fragility
- No webhook signature verification (relies on bearer token only)

#### Risks
- CRM contract changes could break user provisioning
- Failed webhooks could leave users without credits
- No retry/dead-letter queue for failed webhook processing

### Alternatives (Available at Decision Time)
- **API polling**: Less real-time but more resilient
- **Message queue integration**: Decoupled but more infrastructure
- **Manual provisioning**: No automation

### Confidence Level
**HIGH** - Two dedicated webhook endpoints, dedicated service files, and extensive test coverage confirm this pattern.

---

## ADR-024: External API Integration Catalog

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform aggregates data from multiple external sources for background checks, requiring diverse API integration patterns.

**Evidence Found**:
- `searches/searchCompany.ts` - D&B (Dun & Bradstreet) SOAP/XML integration for company data
- `searches/searchME.ts` - ME mobile provider for phone lookups (custom protocol)
- `searches/searchBankIsrael.ts` - Bank of Israel financial data (web scraping)
- `searches/searchPashar.ts` - Tax authority data (web scraping)
- `searches/searchPosta.ts` - Posta news article search (REST API)
- `llm/llmCall.ts` - Google Vertex AI / Gemini (REST/gRPC) with fallback cascade
- `aws/ses.ts`, `aws/s3.ts`, `aws/sqs.ts` - AWS services (SDK)
- `services/crmWebhookService.ts` - Bizsense CRM (inbound webhooks)
- `services/crmOutboundService.ts` - Bizsense CRM (outbound HTTP)

### Decision
Integrate with 11+ external services using heterogeneous protocols: REST APIs, SOAP/XML, web scraping, AWS SDK, and webhook patterns. Each integration is isolated in its own search or service module.

### Consequences

#### Positive (Observed)
- Comprehensive data coverage from diverse sources
- Each integration isolated in its own module
- Rate limiting via Bottleneck prevents abuse
- LLM integration includes fallback cascade (5 Gemini models) and exponential backoff

#### Negative (Potential)
- SOAP/XML integration (D&B) is legacy and complex
- No unified error handling across different API protocols
- Each integration has different auth mechanisms

#### Risks
- External API availability directly impacts search quality
- No circuit breaker pattern for cascading failures
- SOAP integration particularly fragile to schema changes

### Confidence Level
**HIGH** - Search directory, service files, and AWS wrappers clearly document all integrations.

---

## ADR-025: Environment-Based Configuration

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needed to manage configuration across local, staging, and production environments with multiple external service credentials.

**Evidence Found**:
- Single `.env` file at project root with `dotenv` v16.6.1
- `dotenv-cli` v7.4.4 for CLI scripts
- `process.env.*` access throughout codebase (no config wrapper)
- Feature toggles: `LOGIN_TOKEN_FLAG`, `ENABLE_EMAIL_SENDING`, `DISABLE_DOCUMENT_INTELLIGENCE_CASES`
- AWS Secrets Manager pulls env vars into EC2 at deploy time
- `prisma-guard.ts` checks `DATABASE_URL` to prevent production destructive operations
- Commented database URLs in `.env` for environment switching

### Decision
Use simple `.env` file with `dotenv` for local development and AWS Secrets Manager for deployed environments. No configuration framework or structured config module - direct `process.env.*` access throughout.

### Consequences

#### Positive (Observed)
- Simple, zero-overhead configuration
- AWS Secrets Manager secures production credentials
- `prisma-guard.ts` adds safety for database operations

#### Negative (Potential)
- No type-safe config layer - typos in env var names fail silently
- No validation of required env vars at startup
- Feature flags are scattered as raw env var checks

#### Risks
- Missing env vars cause runtime errors, not startup failures
- No centralized documentation of required env vars
- Environment switching via commenting `.env` lines is error-prone

### Alternatives (Available at Decision Time)
- **convict/envalid**: Validated config with defaults and typing
- **dotenv-safe**: Validates against `.env.example`
- **Custom config module**: Centralized typed access

### Confidence Level
**HIGH** - `.env` file, `dotenv` dependency, and `process.env` usage patterns confirmed throughout.

---

## ADR-026: In-Memory Caching Strategy

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The application needed caching for frequently accessed data to reduce database lookups, particularly for authentication tokens and organization data.

**Evidence Found**:
- `proxy.ts` - API token cache using `Map` with 5-minute TTL, cleanup every 60 seconds
- `services/organizationService.ts` - Organization cache with 60-minute TTL
- No Redis, Memcached, or other external cache dependencies
- Cache invalidation functions exposed for testing

### Decision
Use simple in-memory `Map`-based caching with TTL expiration. No external cache infrastructure.

### Consequences

#### Positive (Observed)
- Zero additional infrastructure cost
- Sub-millisecond cache reads
- Simple implementation, easy to reason about

#### Negative (Potential)
- Cache lost on process restart (PM2 restart, deployment)
- Cache not shared across Node.js instances (if horizontal scaling)
- Memory usage grows with cached data volume

#### Risks
- Stale data served for up to TTL duration (5-60 minutes)
- Token permission changes not reflected until cache expires
- No cache warming strategy after deployment

### Alternatives (Available at Decision Time)
- **Redis**: Distributed, persistent cache - more infrastructure
- **Node-cache**: More features (events, stats) but still in-process
- **No cache**: Simpler but higher database load

### Confidence Level
**HIGH** - Cache implementations confirmed in proxy.ts and organizationService.ts with clear TTL patterns.

---

## ADR-027: AWS SES Email Notification System

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform needed transactional email for authentication flows, trial management, and billing notifications in both Hebrew and English.

**Evidence Found**:
- `services/emailService.ts` - centralized email service
- `aws/ses.ts` - AWS SES client wrapper
- `ENABLE_EMAIL_SENDING` env toggle (disabled in dev/test)
- Hebrew RTL email templates using `dir="rtl"` HTML attribute
- Email types: password reset, MFA tokens, trial approval/dismissal, billing failure alerts
- Sales team BCC on customer-facing emails

### Decision
Use AWS SES as the sole email delivery service with an `emailService` abstraction layer. Emails are HTML-formatted with inline Hebrew RTL support. Email sending is toggleable via environment variable.

### Consequences

#### Positive (Observed)
- Managed email delivery - no SMTP server maintenance
- Hebrew RTL support for Israeli users
- Environment toggle prevents accidental emails in development
- Sales team visibility via BCC

#### Negative (Potential)
- HTML email templates are inline strings, not template files
- No email templating engine (Handlebars, MJML)
- No email preview/testing framework

#### Risks
- Template changes require code changes and deployments
- No bounce/complaint handling evident
- Inline HTML templates hard to maintain

### Confidence Level
**HIGH** - Email service, SES client, and multiple email types confirmed with environment toggle.

---

## ADR-028: Ad-Hoc Bilingual Support (Hebrew/English)

### Status
Discovered (Inferred from codebase)

### Date
2026-02-10

### Owner
Legacy/Inferred

### Context
The platform serves Israeli users who need Hebrew support, while also supporting English for international users and trust reports.

**Evidence Found**:
- No i18n framework (no react-intl, i18next, or similar)
- Hebrew text hardcoded in email templates with `dir="rtl"` HTML
- `components/trust-report-preview/` (Hebrew) and `components/trust-report-preview-english/` (English) - separate components per language
- UI primarily in English
- Legal document processing handles Hebrew text natively (pg_trgm for Hebrew fuzzy matching)

### Decision
Support Hebrew and English through ad-hoc implementation: duplicate components for different languages, inline Hebrew strings in emails, and English as the default UI language. No internationalization framework.

### Consequences

#### Positive (Observed)
- Simple, no framework overhead
- Hebrew report is a dedicated component with full control over RTL layout
- English UI reduces localization burden for development

#### Negative (Potential)
- Duplicate components for each language (trust reports)
- No string externalization for future language additions
- Inconsistent localization approach across the app

#### Risks
- Adding a third language would require significant refactoring
- Hebrew strings scattered across email templates and components
- No translation management process

### Alternatives (Available at Decision Time)
- **react-intl / i18next**: Standard React i18n with string externalization
- **next-intl**: Next.js-native i18n with routing support
- **ICU MessageFormat**: Industry standard for pluralization and formatting

### Confidence Level
**HIGH** - Confirmed: no i18n dependencies, duplicate language-specific components, inline Hebrew strings.

---

# Architecture Discovery Report

## Technologies Detected

| Category | Technology | Version | Confidence | Evidence |
|----------|------------|---------|------------|----------|
| Framework | Next.js | 16.1.5 | HIGH | package.json, app router structure |
| Language | TypeScript | 5.9.2 | HIGH | tsconfig.json, all source files |
| Database | PostgreSQL | 15 | HIGH | Prisma schema, CI config |
| ORM | Prisma | 6.14.0 | HIGH | schema, migrations, models |
| Auth | NextAuth | 5.0.0-beta.30 | HIGH | auth.ts, proxy.ts |
| UI Library | MUI | 5.18.0 | HIGH | package.json, components |
| State | Zustand | 5.0.8 | HIGH | store/adminStore.ts |
| Styling | Emotion + Tailwind | 11.14.0 / 3.4.19 | MEDIUM | package.json |
| AI/LLM | Google Vertex AI / Gemini | 1.10.0 / 1.34.0 | HIGH | llm/ directory |
| Storage | AWS S3 | 3.981.0 | HIGH | aws/s3.ts |
| Email | AWS SES | 3.981.0 | HIGH | aws/ses.ts |
| Queue | AWS SQS | 3.981.0 | HIGH | aws/sqs.ts |
| Scraping | Puppeteer | 24.34.0 | HIGH | Dockerfile, scripts |
| Logging | Winston + Logtail | 3.17.0 / 0.5.5 | HIGH | logger.ts |
| Testing | Jest + RTL | 29.7.0 / 16.3.0 | HIGH | jest.config.mjs, 188 tests |
| Validation | Zod | 3.25.76 | MEDIUM | package.json |
| PDF | React-PDF + PDFKit | 4.3.0 / 0.17.1 | HIGH | services, components |
| Container | Docker | - | HIGH | Dockerfile, nginx configs |
| Proxy | Nginx | 1.28.0 | HIGH | nginx/ directory |
| IaC | Terraform | - | HIGH | terraform/ directory |
| CI/CD | GitHub Actions | - | HIGH | .github/workflows/ |
| Process Mgr | PM2 | - | HIGH | Dockerfile CMD |
| API Docs | Swagger/OpenAPI | 3.0.0 | HIGH | swagger config, /api/docs |

## ADRs Generated Summary

| ID | Decision | Confidence |
|----|----------|------------|
| ADR-001 | Next.js Monolith | HIGH |
| ADR-002 | Client-Side Rendering Only | HIGH |
| ADR-003 | PostgreSQL Database | HIGH |
| ADR-004 | Prisma ORM | HIGH |
| ADR-005 | UI -> API -> Service -> Model Layers | HIGH |
| ADR-006 | NextAuth Authentication | HIGH |
| ADR-007 | Next.js 16 Proxy Pattern | HIGH |
| ADR-008 | AWS Cloud Infrastructure | HIGH |
| ADR-009 | Docker + Nginx Deployment | HIGH |
| ADR-010 | Multi-Source Search Pipeline | HIGH |
| ADR-011 | LLM Document Classification | HIGH |
| ADR-012 | Puppeteer Web Scraping | HIGH |
| ADR-013 | Winston + Logtail Logging | HIGH |
| ADR-014 | MUI Component Library | MEDIUM |
| ADR-015 | Multi-Tenant Organization Model | HIGH |
| ADR-016 | GitHub Actions CI/CD | HIGH |
| ADR-017 | Zod Runtime Validation | MEDIUM |
| ADR-018 | Zustand State Management | HIGH |
| ADR-019 | Dual PDF Libraries | MEDIUM |
| ADR-020 | Functional Programming | HIGH |
| ADR-021 | Swagger API Documentation | HIGH |
| ADR-022 | Telegram Bot (Dev-Only Utility) | HIGH |
| ADR-023 | CRM Webhook Integration (Bizsense) | HIGH |
| ADR-024 | External API Integration Catalog | HIGH |
| ADR-025 | Environment-Based Configuration | HIGH |
| ADR-026 | In-Memory Caching Strategy | HIGH |
| ADR-027 | AWS SES Email Notification System | HIGH |
| ADR-028 | Ad-Hoc Bilingual Support (Hebrew/English) | HIGH |

## Unclear Areas (Need Human Input)

| Area | Question | Status |
|------|----------|--------|
| Styling Strategy | MUI + Tailwind + Emotion - what's the intended split? | OPEN |
| Auto-Scaling | No load balancer or auto-scaling config found | OPEN - Is single-instance intentional? |
| Backup Strategy | No database backup configuration found | OPEN - Verify RDS automated backups |
| Monitoring | Only logging (Logtail) found - no APM/metrics | OPEN - Consider Sentry |
| API Rate Limiting | Bottleneck for scraping, but no API rate limiting | OPEN - External consumers unprotected |
| ~~Telegram Usage~~ | ~~What does the Telegraf bot do?~~ | RESOLVED - Dev-only script (ADR-022) |
| ~~Caching~~ | ~~Token cache but no distributed cache~~ | RESOLVED - Intentional in-memory (ADR-026) |
| ~~CRM Integration~~ | ~~Webhook patterns unclear~~ | RESOLVED - Bizsense webhooks (ADR-023) |
| ~~i18n~~ | ~~Hebrew/English approach~~ | RESOLVED - Ad-hoc, no framework (ADR-028) |

## Recommended Next Steps

1. **Run `/architect.clarify`** to refine MEDIUM confidence ADRs (014, 017, 019) with team input
2. **Run `/architect.implement`** to generate full Rozanski & Woods Architecture Description
3. **Address open areas** - especially scaling, backup, monitoring, and API rate limiting
4. **Review ADR-006** - NextAuth beta version (v5.0.0-beta.30) risk assessment
5. **Consider additional ADRs** for: error handling strategy, data retention policy, audit logging
