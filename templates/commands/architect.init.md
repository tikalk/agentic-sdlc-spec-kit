---
description: Reverse-engineer architecture from existing codebase to create ADRs and Architecture Description
handoffs:
  - label: Clarify ADRs
    agent: architect.clarify
    prompt: Refine the reverse-engineered ADRs
    send: true
  - label: Generate Architecture
    agent: architect.implement
    prompt: Generate full architecture description from ADRs
    send: false
scripts:
  sh: scripts/bash/setup-architecture.sh "init {ARGS}"
  ps: scripts/powershell/setup-architecture.ps1 "init {ARGS}"
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:

- `"Django monolith with PostgreSQL, React frontend, AWS deployment"`
- `"Node.js microservices with MongoDB and RabbitMQ"`
- `"Legacy Java application, focus on understanding data layer"`
- `"--team-size small"` — override auto-detected team size
- Empty input: Scan entire codebase and infer architecture

When users provide context, use it to focus the reverse-engineering effort.

## Goal

Reverse-engineer architecture from an existing codebase to create:

1. **ADRs** documenting inferred architectural decisions in `memory/adr.md`
2. **Architecture Description** overview in `memory/architecture.md`

This command is for **brownfield projects** where architecture exists in code but lacks documentation.

## Role & Context

You are acting as an **Architecture Archaeologist** uncovering implicit architectural decisions from code. Your role involves:

- **Scanning** codebase for technology choices and patterns
- **Inferring** architectural decisions from code structure
- **Documenting** only the decisions that add value (non-obvious, surprising, or risky)
- **Identifying** gaps, risks, and technical debt

### Brownfield vs Greenfield

| Scenario | Command | Input | Output |
|----------|---------|-------|--------|
| **Brownfield** (existing code) | `/architect.init` | Codebase scan | Inferred ADRs |
| **Greenfield** (new project) | `/architect.specify` | PRD/requirements | Discussed ADRs |

## Outline

1. **Codebase Scan**: Analyze project structure and detect technologies
2. **Context Calibration**: Estimate team size and set output depth
3. **Existing Docs Scan**: Read existing documentation to avoid duplication
4. **Pattern Detection**: Identify architectural patterns in use
5. **ADR Generation**: Create ADRs for surprising/non-obvious decisions only
6. **Risks & Gap Analysis**: Identify what's missing, broken, or risky (most valuable output)
7. **Output**: Write ADRs to `memory/adr.md` and architecture to `memory/architecture.md`

## Execution Steps

### Phase 1: Codebase Analysis

**Objective**: Discover what technologies and patterns are in use

1. **Run Setup Script**:
   - Execute `{SCRIPT}` to initialize architecture files
   - Script scans codebase and outputs structured findings

2. **Technology Detection**:

   | Indicator | Technology Category | Files to Check |
   |-----------|---------------------|----------------|
   | `package.json` | Node.js ecosystem | Dependencies, scripts |
   | `requirements.txt` / `pyproject.toml` | Python ecosystem | Dependencies |
   | `pom.xml` / `build.gradle` | JVM ecosystem | Dependencies |
   | `Cargo.toml` | Rust | Dependencies |
   | `go.mod` | Go | Dependencies |
   | `Dockerfile` | Containerization | Base images, stages |
   | `docker-compose.yml` | Container orchestration | Services, networks |
   | `*.tf` / `*.tfvars` | Terraform/IaC | Infrastructure |
   | `kubernetes/*.yaml` | Kubernetes | Deployment configs |
   | `.github/workflows/*` | GitHub Actions | CI/CD |

3. **Framework Detection**:

   | Pattern | Framework | Evidence |
   |---------|-----------|----------|
   | `from django` imports | Django | Python web |
   | `@SpringBoot` | Spring Boot | Java web |
   | `import express` | Express.js | Node.js web |
   | `import { Component }` | React/Angular/Vue | Frontend |
   | `from fastapi` | FastAPI | Python API |

4. **Database Detection**:

   | Evidence | Database Type |
   |----------|---------------|
   | PostgreSQL connection strings | PostgreSQL |
   | MongoDB/mongoose imports | MongoDB |
   | Redis client imports | Redis cache |
   | ORM migrations | Relational DB |
   | DynamoDB SDK usage | AWS DynamoDB |

### Phase 2: Context Calibration

**Objective**: Determine project scale to calibrate output depth

1. **Estimate team size** using these signals (in priority order):
   - **User override**: If `--team-size small|medium|large` was passed, use that directly
   - **Git history**: Count unique committers in `git log` (last 6 months)
   - **Project docs**: Check for `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md` — team references, contributor guidelines
   - **Repo indicators**: Number of active branches, PR volume

2. **Assign tier**:

   | Tier | Team Size | Characteristics |
   |------|-----------|-----------------|
   | **small** | 1-3 engineers | Startup, side project, solo dev. Everyone knows the codebase. |
   | **medium** | 4-15 engineers | Growing team. Some specialization, onboarding matters. |
   | **large** | 16+ engineers | Multiple teams. Formal processes, compliance needs. |

3. **Output depth per tier**:

   | Aspect | Small | Medium | Large |
   |--------|-------|--------|-------|
   | ADRs | Only surprising/non-obvious decisions | Key decisions + framework deviations | Comprehensive (all categories) |
   | Architecture doc | Lean template (AD-template-lean.md) | Lean template + optional expanded sections | Full Rozanski & Woods (AD-template.md) |
   | Gap analysis | **Primary output** — lead with this | Prominent section | Standard appendix |
   | Alternatives section | Skip unless genuinely informative | Brief "Common Alternatives" | Full analysis |

### Phase 3: Existing Documentation Scan

**Objective**: Avoid duplicating what's already documented

1. **Check for existing docs** at repo root and common locations:
   - `CLAUDE.md`, `AGENTS.md` — AI agent instructions (often contain architecture/conventions)
   - `CONTRIBUTING.md`, `README.md` — project conventions and setup
   - `docs/` directory — existing documentation
   - `.specify/` directory — existing spec framework artifacts

2. **Extract already-documented information**:
   - Coding conventions and style rules
   - Architecture patterns (e.g., "UI -> API -> Service -> Model")
   - Technology choices already explained
   - Deployment and infrastructure details

3. **Set deduplication context**: Store a summary of what's already documented. In Phase 7 (Output), you will:
   - **Not repeat** conventions, patterns, or decisions already documented elsewhere
   - **Add a complementary note** at the top of generated output referencing existing docs
   - **Focus on gaps** — document what existing docs *don't* cover

### Phase 4: Pattern Recognition

**Objective**: Identify architectural patterns from code structure

#### Architecture Style Detection

| Pattern | Evidence | ADR Topic |
|---------|----------|-----------|
| **Monolith** | Single deployable, shared database | ADR: System Architecture Style |
| **Microservices** | Multiple services, service discovery | ADR: System Architecture Style |
| **Modular Monolith** | Single deploy, module boundaries | ADR: System Architecture Style |
| **Event-Driven** | Message queue usage, event handlers | ADR: Communication Pattern |
| **Serverless** | Lambda functions, managed services | ADR: Deployment Model |

#### Code Organization Detection

| Pattern | Evidence |
|---------|----------|
| **Layered** | `controllers/`, `services/`, `repositories/` |
| **Feature-Based** | `features/`, `modules/` per domain |
| **Clean Architecture** | `domain/`, `application/`, `infrastructure/` |
| **Hexagonal** | `ports/`, `adapters/` |

#### API Style Detection

| Pattern | Evidence |
|---------|----------|
| **REST** | Route decorators, HTTP verbs, resource URLs |
| **GraphQL** | Schema files, resolvers, `gql` imports |
| **gRPC** | `.proto` files, gRPC client/server setup |
| **WebSocket** | Socket.io, WebSocket handlers |

### Phase 5: ADR Generation

**Objective**: Document discovered decisions as ADRs — but only the ones that add value

#### ADR Filtering: The Surprise-Value Heuristic

**Generate an ADR only if at least one of these is true:**

1. **A new engineer would be surprised by this choice** — it's not what you'd expect for this type of project
2. **A reasonable person might be tempted to change it** — the decision needs context to understand why it was made
3. **The decision goes against framework/ecosystem conventions** — e.g., CSR-only in Next.js, NoSQL for relational data, monorepo without a monorepo tool

**Do NOT generate ADRs for:**

- Standard/default technology choices that match the ecosystem norm (e.g., "PostgreSQL for relational data", "React for frontend when package.json shows React", "Winston for Node.js logging", "Nginx as reverse proxy", "Jest for testing in a Node.js project")
- Choices that are obvious from the project type (e.g., "npm for package management" in a Node.js project)
- Infrastructure defaults (e.g., "Docker for containerization" when there's a Dockerfile)

**For small teams**: Apply this filter aggressively. A 2-person team doesn't need an ADR explaining why they use PostgreSQL. Focus on decisions that would trip up a new hire or a future maintainer.

**For large teams**: Be more inclusive — document more decisions for compliance and onboarding purposes, but still skip truly obvious defaults.

#### ADR Template for Discovered Decisions

For each ADR that passes the filter:

```markdown
## ADR-[NNN]: [Discovered Decision]

### Status
Discovered (Inferred from codebase)

### Date
[Current date]

### Owner
Legacy/Inferred

### Context
[Inferred problem statement based on code patterns]

**Evidence Found**:
- [File/pattern evidence 1]
- [File/pattern evidence 2]

### Decision
[Statement of what was decided, inferred from implementation]

### Consequences

#### Positive (Observed)
- [Benefit visible in codebase]

#### Negative (Potential)
- [Trade-off inherent to this choice]

#### Risks
- [Risk if this decision is not well understood]

### Common Alternatives
[OPTIONAL — only include if genuinely informative]

Other options in this space include:
- **[Alternative 1]**: [Brief factual description — what it is and when it's typically used]
- **[Alternative 2]**: [Brief factual description]

> *For discovered ADRs, do not fabricate rejection rationale. State alternatives factually without assuming why they weren't chosen.*

### Confidence Level
[HIGH/MEDIUM/LOW] - [Explanation of confidence in inference]
```

**Important guidance for the "Common Alternatives" section:**

- This section is **optional**. Only include it when the alternatives are genuinely worth noting.
- **Never use "Rejected because:" framing** — you are reverse-engineering, not documenting a decision that was actively debated. You don't know why alternatives weren't chosen.
- **State alternatives factually**: "Other options in this space include X, Y" — not "X was rejected because..."
- For small teams: skip this section entirely unless the alternative is commonly confused with the chosen option
- For large teams: include when it helps onboarding engineers understand the landscape

### Phase 6: Risks, Gaps & Recommendations

**Objective**: Identify what's missing, broken, or risky — this is the most valuable output

**For small teams, this is the PRIMARY output.** Lead with this before ADRs.

Analyze the codebase for:

#### Operational Gaps
- Missing backup strategy or no evidence of backups
- No monitoring/alerting configuration found
- No health check endpoints
- No error tracking service (Sentry, Bugsnag, etc.)
- No log aggregation beyond local files
- Missing rate limiting on APIs

#### Technical Debt
- Pinned beta/alpha/RC package versions
- Deprecated API usage
- TODO/FIXME/HACK comments in code (count and categorize)
- Dependencies with known vulnerabilities (`npm audit`, etc.)
- Outdated major version dependencies

#### Single Points of Failure
- Single database instance without replica
- No failover configuration
- Single deployment target
- Hard-coded credentials or secrets not in a vault

#### Missing Safety Nets
- No database migration rollback plan
- Missing test coverage for critical paths
- No CI/CD pipeline or incomplete pipeline
- No environment variable validation
- Missing `.env.example` or environment documentation

#### Security Concerns
- Secrets in code or config files
- Missing CORS configuration
- No input validation middleware
- Authentication/authorization gaps

Format findings as **actionable items**, not just observations:

```markdown
## Risks, Gaps & Recommendations

### Critical (Address Soon)
| Finding | Impact | Recommendation |
|---------|--------|----------------|
| No database backup config found | Data loss risk | Set up automated daily backups |
| Secrets in .env committed to git | Security breach risk | Move to secrets manager, add .env to .gitignore |

### Important (Plan For)
| Finding | Impact | Recommendation |
|---------|--------|----------------|
| No monitoring/alerting setup | Silent failures | Add health checks + basic alerting |
| 15 TODO comments in payment module | Technical debt | Triage and prioritize |

### Nice to Have
| Finding | Impact | Recommendation |
|---------|--------|----------------|
| Test coverage unclear | Regression risk | Add coverage reporting |
```

### Phase 7: Output Generation

**Objective**: Write discoveries to files, calibrated to team size

1. **Add complementary note** if existing docs were found (Phase 3):

   ```markdown
   > This document complements existing project documentation ([CLAUDE.md], [README.md], etc.).
   > Conventions and coding standards documented there are not repeated here.
   ```

2. **Write Risks & Gaps** (most valuable content):
   - For **small teams**: This goes at the TOP of `memory/architecture.md`, before architectural views
   - For **medium/large teams**: This goes in a prominent section (not buried as an appendix)

3. **Write ADRs**:
   - Create or update `memory/adr.md` with discovered ADRs
   - Mark ADRs as "Discovered (Inferred)" status
   - Note confidence level for each
   - Only include ADRs that passed the surprise-value filter

4. **Write Architecture Description**:
   - For **small teams**: Use the lean template (`AD-template-lean.md`) — system overview, context diagram, key data flows, deployment topology, tech stack, risks & gaps
   - For **medium teams**: Use the lean template with optional expanded sections as needed
   - For **large teams**: Use the full template (`AD-template.md`) with all Rozanski & Woods viewpoints

5. **Generate Summary**:
   - Team size detected and tier used
   - Existing documentation found and what was deduplicated
   - Risks and gaps identified (highlight critical ones)
   - ADRs created (with brief justification for why each passed the filter)
   - Recommended next steps

## Key Rules

### Evidence-Based Documentation

- **Only document what's found in code** — don't invent decisions
- **Cite specific evidence** for each ADR
- **Mark confidence levels** honestly
- **Flag uncertainties** explicitly
- **Never fabricate rejection rationale** for alternatives in discovered ADRs

### Surprise-Value Filter

- **Skip obvious defaults** — don't document decisions that match ecosystem norms
- **Document what surprises** — non-obvious choices, convention violations, unusual constraints
- **Scale with team size** — small teams get fewer, more targeted ADRs

### No Duplication

- **Read existing docs first** — CLAUDE.md, README, CONTRIBUTING, etc.
- **Don't repeat** what's already documented elsewhere
- **Reference, don't reproduce** — link to existing docs instead of copying content

### Confidence Levels

| Level | Criteria |
|-------|----------|
| **HIGH** | Multiple clear evidence sources, unambiguous choice |
| **MEDIUM** | Some evidence, but could be interpreted differently |
| **LOW** | Limited evidence, significant uncertainty |

### Non-Destructive

- **Don't overwrite** existing ADRs without user approval
- **Merge intelligently** with existing documentation
- **Preserve manual additions** to architecture files

### Interactive When Needed

- For **LOW confidence** discoveries, ask user for confirmation
- For **contradictory evidence**, present options
- For **gaps**, suggest clarification questions

## Workflow Guidance & Transitions

### After `/architect.init`

Recommended next steps:

1. **Address Critical Gaps**: Fix any critical risks/gaps identified
2. **Review Discoveries**: Verify inferred ADRs are accurate
3. **Run `/architect.clarify`**: Fill gaps with human knowledge
4. **Run `/architect.implement`**: Generate full AD.md from ADRs (for medium/large teams)
5. **Update As Needed**: Refine documentation as you learn more

### When to Use This Command

- **Brownfield projects**: Existing code without architecture docs
- **Legacy modernization**: Understanding current state before changes
- **Team onboarding**: Quickly documenting implicit decisions
- **Technical debt assessment**: Identifying undocumented patterns

### When NOT to Use This Command

- **Greenfield projects**: Use `/architect.specify` for new projects
- **Architecture exists**: If `AD.md` exists, use `/architect.clarify` to refine
- **Feature-level**: Feature architecture via `/spec.plan --architecture`

## Context

{ARGS}
