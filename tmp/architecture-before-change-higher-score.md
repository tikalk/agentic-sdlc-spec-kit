# Architecture Description - Pentagon2 / Truvify

> **Generated**: 2026-02-10 (Updated: 2026-02-10)
> **Method**: Reverse-engineered from codebase analysis (28 ADRs)
> **ADR Reference**: See `.specify/memory/adr.md` for detailed decision records

---

## 1. System Overview

**Pentagon2** (product name: **Truvify**) is a compliance and background-check SaaS platform that aggregates data from 15+ Israeli public record sources, applies AI-powered document classification, and generates trust/risk reports for organizations.

### Core Capabilities
- **Multi-source background checks**: Court records, professional registries, financial sanctions, criminal databases, news articles
- **AI document classification**: LLM-powered extraction from legal documents (criminal, civil, bankruptcy, enforcement)
- **Trust scoring**: Confidence engine calculating risk scores from aggregated data
- **Trust report generation**: PDF reports in Hebrew and English
- **Multi-tenant SaaS**: Organizations with quotas, billing, and role-based access

### Key Metrics (Codebase)
| Metric | Count |
|--------|-------|
| Service files | 45 (~9,400 LOC) |
| API endpoints | 38 |
| Database models | 40 |
| React components | 84 |
| Test files | 188 |
| Prisma migrations | 129 |

---

## 2. Technology Stack

### Runtime
| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Next.js (App Router) | 16.1.5 |
| Language | TypeScript | 5.9.2 |
| Runtime | Node.js | 20.19.2 |
| Database | PostgreSQL | 15 |
| ORM | Prisma | 6.14.0 |

### Frontend
| Purpose | Technology | Version |
|---------|-----------|---------|
| UI Library | React | 18.3.1 |
| Component Library | MUI (Material UI) | 5.18.0 |
| Styling | Emotion + Tailwind CSS | 11.14.0 / 3.4.19 |
| State Management | Zustand | 5.0.8 |
| Forms | react-hook-form | 7.62.0 |
| Icons | MUI Icons + lucide-react | 5.18.0 / 0.562.0 |

### Backend
| Purpose | Technology | Version |
|---------|-----------|---------|
| Authentication | NextAuth | 5.0.0-beta.30 |
| Validation | Zod | 3.25.76 |
| HTTP Client | Axios | 1.13.5 |
| Rate Limiting | Bottleneck | 2.19.5 |
| Concurrency | async-mutex | 0.5.0 |
| Logging | Winston + Logtail | 3.17.0 / 0.5.5 |
| PDF Generation | @react-pdf/renderer + PDFKit | 4.3.0 / 0.17.1 |
| PDF Parsing | pdf-parse | 1.1.1 |
| Web Scraping | Puppeteer | 24.34.0 |
| API Docs | Swagger (swagger-jsdoc) | 6.2.8 |

### AI/ML
| Purpose | Technology | Version |
|---------|-----------|---------|
| LLM (Primary) | Google Vertex AI | 1.10.0 |
| LLM (Secondary) | Google GenAI (Gemini) | 1.34.0 |

### Cloud & Infrastructure
| Purpose | Technology |
|---------|-----------|
| Cloud Provider | AWS |
| Compute | EC2 |
| Storage | S3 |
| Email | SES |
| Messaging | SQS |
| Notifications | SNS |
| Container Registry | ECR |
| Secrets | AWS Secrets Manager |
| IaC | Terraform |
| Containerization | Docker (multi-stage) |
| Reverse Proxy | Nginx 1.28.0 |
| Process Manager | PM2 |
| CI/CD | GitHub Actions |

### Testing
| Purpose | Technology | Version |
|---------|-----------|---------|
| Test Runner | Jest | 29.7.0 |
| Component Testing | React Testing Library | 16.3.0 |
| HTTP Mocking | Supertest | - |

---

## 3. Architecture Patterns

### 3.1 Layered Architecture (ADR-005)

```
┌─────────────────────────────────────────────┐
│                 UI Layer                      │
│  components/ (84 files)                      │
│  React functional components, MUI, Zustand   │
│  Client-side only (ADR-002)                  │
├────────────────────┬────────────────────────-┤
│                    │ HTTP (fetch)             │
├────────────────────▼────────────────────────-┤
│                 API Layer                     │
│  app/api/v1/ (38 endpoints)                  │
│  Next.js route handlers                      │
│  Auth via proxy.ts (ADR-007)                 │
├────────────────────┬────────────────────────-┤
│                    │ Function calls           │
├────────────────────▼────────────────────────-┤
│              Service Layer                    │
│  services/ (44 files, ~9,200 LOC)            │
│  Business logic, orchestration               │
│  Pure functions (ADR-020)                    │
├────────────────────┬────────────────────────-┤
│                    │ Prisma Client            │
├────────────────────▼────────────────────────-┤
│               Model Layer                     │
│  models/ (37 files)                          │
│  Prisma operations, data access              │
├────────────────────┬────────────────────────-┤
│                    │ SQL                      │
├────────────────────▼────────────────────────-┤
│              PostgreSQL 15                    │
│  40 tables, pg_trgm, 129 migrations         │
└──────────────────────────────────────────────┘
```

### 3.2 Authentication & Authorization Flow (ADR-006, ADR-007)

```
Request
  │
  ▼
proxy.ts ─────────────────────────────────────┐
  │                                            │
  ├─ Public routes? ──yes──▶ Pass through      │
  │                                            │
  ├─ Has session? ──yes──▶ Validate NextAuth   │
  │                        Set x-user-email    │
  │                        Set x-user-role     │
  │                                            │
  ├─ Has Bearer token? ──yes──▶ Validate API   │
  │                             token (cached)  │
  │                             Check perms    │
  │                                            │
  └─ Neither? ──▶ Redirect to /auth/signin     │
                                               │
  Route permission check:                      │
  ├─ Admin routes: role === 'admin'            │
  ├─ Manager routes: role === 'manager'        │
  ├─ User routes: role === 'user'              │
  └─ Forbidden: redirect to role home page     │
───────────────────────────────────────────────┘
```

**Auth Providers:**
- **Google OAuth**: Internal users (@truvify.com domain only)
- **Credentials**: External users (email/password with optional MFA)
- **API Tokens**: Service-to-service (CRM webhooks, external integrations)

### 3.3 Search Pipeline Architecture (ADR-010)

```
User Search Request
        │
        ▼
  searchService.ts (orchestrator)
        │
        ├──▶ Person Search ──▶ personCasesService
        │                       └──▶ cases model (pg_trgm)
        │
        ├──▶ Company Search ──▶ companyService
        │                       └──▶ company model
        │
        ├──▶ Entity Search ──▶ entitySearchService
        │                      └──▶ person_entities model
        │
        ├──▶ Professional Registries (parallel)
        │     ├── bankIsraelService
        │     ├── accountantService
        │     ├── medicalProfessionService
        │     ├── constructorService
        │     ├── humanResourceService
        │     └── jobService
        │
        ├──▶ Risk Databases (parallel)
        │     ├── knownCriminalsService
        │     ├── interpolCriminalsService
        │     ├── financialSanctionsService
        │     ├── terrorListService
        │     └── cryptoWalletService
        │
        └──▶ News & Articles ──▶ postaService
                                  └──▶ postaArticleScoringService
        │
        ▼
  filters/ (deduplication, relevance, proximity)
        │
        ▼
  confidenceEngine.ts (trust score calculation)
        │
        ▼
  Search Results + Trust Score
```

### 3.4 Document Classification Pipeline (ADR-011)

```
Court Document (PDF)
        │
        ▼
  pdf-parse (text extraction)
        │
        ▼
  llm/llmCall.ts (API call)
        │
        ▼
  Domain-Specific Prompts:
  ├── criminal/ (arrest, verdict, sentence, release)
  ├── civil/ (decisions)
  ├── bankruptcy/ (decisions, verdicts)
  ├── enforcement-proceedings/
  ├── generalCaseExtraction
  └── caseTypeClassification
        │
        ▼
  llm/utils/jsonCleaner.ts (parse response)
        │
        ▼
  doc_classification + person_entities (database)
```

### 3.5 CRM Integration Architecture (ADR-023)

```
Bizsense CRM (BIZ_ID: 9545)
        │
        ├──▶ POST /webhook/crm/user (Bearer token auth)
        │     │
        │     ▼
        │   crmWebhookService.processCrmUserWebhook()
        │     ├── Create/update user
        │     ├── Map package_id → credits (package_mapping)
        │     └── Add credits → org (if org member) or user
        │
        ├──▶ POST /webhook/crm/tx (Bearer token auth)
        │     │
        │     ▼
        │   crmWebhookService.processCrmTransactionWebhook()
        │     ├── SUCCESS → Add credits to org or user
        │     └── FAIL → Send billing failure email (SES)
        │
        └──◀ Outbound: crmOutboundService
              │
              ▼
            On quota exhaustion (autoRenew packages)
            → HTTP POST to CRM with renewal pipeline data
```

### 3.6 External API Integrations (ADR-024)

| Service | Protocol | Rate Limiting | Auth |
|---------|----------|---------------|------|
| D&B (Dun & Bradstreet) | SOAP/XML | None | Username/password |
| ME (Mobile provider) | Custom | None | Account SID/token |
| Bank of Israel | Web scraping | Bottleneck | Public |
| Pashar (Tax authority) | Web scraping | Bottleneck | Public |
| Posta Articles | REST API | None | Internal service |
| Google Vertex AI (Gemini) | REST/gRPC | 120 req/min, 10 concurrent | Service account |
| AWS SES | SDK | AWS limits | IAM |
| AWS S3 | SDK | AWS limits | IAM |
| AWS SQS/SNS | SDK | AWS limits | IAM |
| Bizsense CRM (inbound) | REST webhooks | None | Bearer token |
| Bizsense CRM (outbound) | REST HTTP | None | None |

### 3.7 Caching Architecture (ADR-026)

```
In-Memory Caches (Map-based, per-process):

┌─────────────────────────────────────────┐
│ proxy.ts: API Token Cache               │
│  TTL: 5 minutes                         │
│  Cleanup: setInterval every 60s         │
│  Content: token → {email, role, perms}  │
├─────────────────────────────────────────┤
│ organizationService.ts: Org Cache       │
│  TTL: 60 minutes                        │
│  Content: orgId → organization data     │
└─────────────────────────────────────────┘

No external cache (Redis/Memcached).
Cache lost on process restart or deployment.
```

### 3.8 Email Notification Flow (ADR-027)

```
Trigger Events                    emailService.ts           AWS SES
      │                                │                       │
      ├── Password reset ────────────▶ │ ──▶ HTML email ─────▶ │ → User
      ├── MFA token ─────────────────▶ │ ──▶ HTML email ─────▶ │ → User
      ├── Trial approval ────────────▶ │ ──▶ Hebrew email ───▶ │ → User + Sales BCC
      ├── Trial dismissal ───────────▶ │ ──▶ Hebrew email ───▶ │ → User
      ├── Billing failure ───────────▶ │ ──▶ Hebrew email ───▶ │ → Sales team
      └── First password setup ──────▶ │ ──▶ HTML email ─────▶ │ → User

Toggle: ENABLE_EMAIL_SENDING (disabled in dev/test)
```

---

## 4. Data Architecture

### 4.1 Entity Relationship Overview

```
                    ┌──────────────┐
                    │ organization │
                    └──────┬───────┘
                           │ 1:N
              ┌────────────┼────────────┐
              ▼            ▼            ▼
          ┌──────┐    ┌───────┐    ┌───────┐
          │ user │    │ usage │    │billing│
          └──┬───┘    └───────┘    └───────┘
             │
    ┌────────┼────────────┐
    ▼        ▼            ▼
┌────────┐ ┌──────────┐ ┌────────────┐
│api_token│ │user_usage│ │mfa_token   │
└────┬───┘ └──────────┘ └────────────┘
     ▼
┌──────────────────┐
│api_token_permissn│
└──────────────────┘

              ┌───────────────┐
              │ personal_info │ (CENTRAL HUB)
              └───────┬───────┘
                      │ 1:N to 14+ tables
    ┌─────────────────┼──────────────────────┐
    │     │     │     │     │     │     │     │
    ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼
  person bank  acct  med   job  pashar posta trust
  cases  israel      prof                    report
    │
    ▼
  cases ──▶ doc_classification ──▶ person_entities
```

### 4.2 High-Volume Tables

| Table | Warning Level | Optimization |
|-------|--------------|-------------|
| `cases` | CRITICAL | pg_trgm GIN indexes, composite indexes on scrape_status |
| `doc_classification` | HIGH | Indexed on case_uuid, file_name |
| `person_entities` | HIGH | Indexed on case_uuid, id_number, name fields |
| `person_cases` | MEDIUM | Indexed on person_uuid, case_uuid |

### 4.3 Key Database Features
- **Full-text search**: pg_trgm extension with GIN indexes for Hebrew name fuzzy matching
- **UUID generation**: uuid-ossp extension for primary keys
- **Cascade deletes**: Most entities cascade from personal_info
- **Self-referencing**: personal_info.spouse_uuid for family relationships

---

## 5. Deployment Architecture

### 5.1 Environment Topology

```
┌─────────────────────────────────────────┐
│              GitHub Actions              │
│  Push to develop → staging              │
│  Push to main → production              │
│  PR → test only                         │
└──────────────┬──────────────────────────┘
               │ Docker push to ECR
               │ SSH deploy to EC2
               ▼
┌─────────────────────────────────────────┐
│            AWS EC2 Instance              │
│                                          │
│  ┌─────────────────────────────────┐    │
│  │     Nginx Container             │    │
│  │     (TLS, security headers,     │    │
│  │      reverse proxy)             │    │
│  │     Ports: 80, 443             │    │
│  └──────────────┬──────────────────┘    │
│                 │ proxy_pass :3000       │
│  ┌──────────────▼──────────────────┐    │
│  │     Next.js App Container       │    │
│  │     (PM2 managed)               │    │
│  │     Port: 3000                  │    │
│  │     + Headless Chrome           │    │
│  └─────────────────────────────────┘    │
│                                          │
│  Docker network: pentagon-network        │
└──────────────┬──────────────────────────┘
               │
     ┌─────────┼──────────┬──────────┐
     ▼         ▼          ▼          ▼
  ┌─────┐  ┌─────┐  ┌─────┐  ┌──────────┐
  │ RDS │  │ S3  │  │ SES │  │ Secrets   │
  │(PG) │  │     │  │     │  │ Manager   │
  └─────┘  └─────┘  └─────┘  └──────────┘
```

### 5.2 Security Architecture

| Layer | Protection |
|-------|-----------|
| Network | Nginx TLS 1.2/1.3 termination |
| Headers | HSTS, CSP, X-Frame-Options DENY, X-Content-Type-Options nosniff |
| Auth | NextAuth sessions + API tokens with permissions |
| MFA | Token-based MFA for OAuth users |
| Secrets | AWS Secrets Manager (not in code) |
| DB Safety | prisma-guard.ts prevents production destructive operations |
| Passwords | Hashed with salt, history tracking, lockout |
| CORS | Environment-specific allowed origins |
| HTTP Methods | TRACE blocked, RFC 9110 compliant |

### 5.3 CI/CD Pipeline

```
PR / Push
    │
    ▼
┌──────────────────────┐
│   Test Job            │
│                       │
│  1. npm install       │
│  2. npm run lint      │
│  3. prisma validate   │
│  4. prisma migrate    │  ◀── PostgreSQL 15 service container
│  5. npm run build     │
│  6. npm test          │  ◀── 188 test files
└──────────┬───────────┘
           │ (push only, tests pass)
           ▼
┌──────────────────────┐
│   Deploy Job          │
│                       │
│  1. AWS credentials   │
│  2. ECR login         │
│  3. Fetch secrets     │
│  4. Build app image   │
│  5. Build nginx image │
│  6. Push to ECR       │
│  7. SSH to EC2        │
│  8. Pull & run        │
│  9. Run migrations    │
└──────────────────────┘
```

---

## 6. Domain Model

### 6.1 Core Domain Concepts

| Concept | Description | Key Tables |
|---------|-------------|------------|
| **Person** | Individual being investigated | personal_info (hub), person_cases, person_company, person_entities |
| **Case** | Court case record | cases, doc_classification, associates |
| **Organization** | Customer tenant | organization, usage, billing |
| **User** | Platform user | user, user_usage, api_token |
| **Search** | Background check request | searches, linked to personal_info |
| **Trust Report** | Generated risk assessment | trust_report, confidence scores |

### 6.2 Data Source Registry

| Source | Service | Model | Type |
|--------|---------|-------|------|
| Court Records | caseService | cases | Internal DB + Scraping |
| Bank of Israel | bankIsraelService | bank_israel | Internal DB |
| Accountants Registry | accountantService | accountant | Internal DB |
| Medical Professionals | medicalProfessionService | medical_profession | Internal DB |
| Construction Licenses | constructorService | constructor | Internal DB |
| HR Records | humanResourceService | human_resource | Internal DB |
| Known Criminals | knownCriminalsService | known_criminals | Internal DB |
| Interpol | interpolCriminalsService | interpol_criminals | Scraping |
| Financial Sanctions | financialSanctionsService | financial_sanctions | Internal DB |
| Terror Watch Lists | terrorListService | terror_list | Internal DB |
| Tax Arrangements | taxArrangementsService | tax_arrangements | Internal DB |
| Company Registry | companyService | company | Internal DB |
| News Articles | postaService | posta | Scraping + Scoring |
| Crypto Wallets | cryptoWalletService | crypto_wallet | Internal DB |
| City Data | cityService | cities | Internal DB |

---

## 7. Directory Structure

```
pentagon2/
├── app/                          # Next.js App Router
│   ├── api/                      # API routes (38 endpoints)
│   │   ├── auth/                 # Authentication endpoints
│   │   ├── v1/                   # Versioned API
│   │   │   ├── admin/            # Admin CRUD
│   │   │   ├── user/             # User operations
│   │   │   ├── manager/          # Manager billing
│   │   │   └── webhook/crm/     # CRM webhooks
│   │   ├── docs/                 # Swagger UI
│   │   └── health/               # Health check
│   ├── admin/                    # Admin dashboard pages
│   ├── auth/                     # Auth flow pages
│   ├── user/                     # User dashboard pages
│   ├── trust-report/             # Report pages
│   └── styles/                   # Global styles
├── components/                   # React components (84 files)
│   ├── admin/                    # Admin UI
│   ├── cases/                    # Case display
│   ├── common/                   # Shared components
│   ├── trust-report-preview/     # Hebrew report
│   ├── trust-report-preview-english/  # English report
│   └── ui/                       # Base UI components
├── services/                     # Business logic (44 files)
├── models/                       # Prisma data access (37 files)
├── searches/                     # Search implementations (15+ files)
├── filters/                      # Search result filtering
├── types/                        # TypeScript types (17 files)
├── utils/                        # Utilities (22 files)
├── llm/                          # AI/LLM integration
│   ├── prompts/                  # Domain-specific prompts
│   └── utils/                    # JSON cleaning, PDF helpers
├── aws/                          # AWS SDK wrappers
├── store/                        # Zustand stores
├── hooks/                        # Custom React hooks
├── config/                       # App configuration
├── lib/                          # Library configs
├── prisma/                       # Database schema + migrations
├── nginx/                        # Nginx configs + Dockerfiles
├── terraform/                    # Infrastructure as Code
├── __tests__/                    # Test suite (188 files)
├── __mocks__/                    # Jest mocks
├── auth.ts                       # NextAuth configuration
├── proxy.ts                      # Auth middleware (Next.js 16)
├── logger.ts                     # Winston logger setup
├── Dockerfile                    # App container
├── Dockerfile.base               # Base image
└── .github/workflows/            # CI/CD pipelines
```

---

## 8. Cross-Cutting Concerns

### 8.1 Error Handling
- Winston logger with structured `{ data: { ... } }` format
- Error context includes function parameters and state
- PII prohibited in all log output

### 8.2 Testing Strategy
- **Unit tests**: Services, models, utilities (Jest)
- **Component tests**: React components (React Testing Library)
- **API tests**: Route handlers with mocked services
- **Integration**: PostgreSQL service container in CI
- **Coverage**: All layers except utils/ (excluded from coverage reports)

### 8.3 Data Privacy
- PII logging prohibition enforced via CLAUDE.md standards
- Anonymized identifiers (userId, caseId) in logs
- Password hashing with salt and history tracking
- Account lockout after failed login attempts

### 8.4 Performance Considerations
- pg_trgm GIN indexes for fuzzy name matching
- Bottleneck rate limiter for external API calls
- Token cache (5-minute TTL) in proxy.ts
- CLAUDE.md warns about large tables needing careful queries

---

## 9. Gaps & Recommendations

### Infrastructure

| Gap | Risk | Recommendation |
|-----|------|----------------|
| Single EC2 instance | No HA, no auto-recovery | Consider ECS/Fargate or at minimum ASG |
| No load balancer | Single point of failure | Add ALB for health checks and HA |
| No database backups documented | Data loss risk | Verify RDS automated backups |
| No distributed caching | In-memory only, lost on restart | Consider Redis when horizontal scaling needed |

### Security & Reliability

| Gap | Risk | Recommendation |
|-----|------|----------------|
| No API rate limiting | Abuse from external consumers | Add rate limiting middleware |
| NextAuth beta (v5.0.0-beta.30) | Breaking changes, stability risk | Monitor for GA release, plan upgrade |
| No webhook signature verification | CRM webhook spoofing risk | Add HMAC signature verification |
| No circuit breaker | Cascading failures from external APIs | Add circuit breaker pattern (e.g., opossum) |

### Observability

| Gap | Risk | Recommendation |
|-----|------|----------------|
| No APM/error tracking | Blind to production errors | Add Sentry or similar |
| No metrics/dashboards | Can't monitor system health | Add Prometheus/Grafana or CloudWatch dashboards |
| No SES bounce handling | Email deliverability degradation | Implement SNS bounce/complaint handler |

### Code Quality

| Gap | Risk | Recommendation |
|-----|------|----------------|
| Mixed styling (MUI + Tailwind) | Developer confusion | Standardize on one approach |
| No typed config layer | Silent env var typos | Add startup validation (envalid/zod) |
| Inline email templates | Hard to maintain, no preview | Extract to template engine (MJML/Handlebars) |
| No i18n framework | Duplicate components per language | Consider react-intl if adding languages |
| No scheduled job framework | Manual script execution | Add node-cron or Bull if recurring tasks needed |

---

*This document was reverse-engineered from codebase analysis (28 ADRs). Run `/architect.clarify` to refine with team input, or `/architect.implement` to generate a full Rozanski & Woods AD.*
