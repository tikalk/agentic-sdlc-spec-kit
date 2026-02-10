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
2. **Architecture Description** (`AD.md` at project root) with 7 Rozanski & Woods viewpoints

This command is for **brownfield projects** where architecture exists in code but lacks documentation.

### Flags

- `--views VIEWS`: Architecture views to generate
  - `core` (default): Context, Functional, Information, Development, Deployment
  - `all`: All 7 views including Concurrency and Operational
  - Custom: comma-separated (e.g., `concurrency,operational`)
  
- `--adr-heuristic HEURISTIC`: ADR generation strategy
  - `surprising` (default): Skip obvious ecosystem defaults, document only surprising/risky decisions
  - `all`: Document all discovered decisions
  - `minimal`: Only high-risk decisions

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
2. **Documentation Deduplication**: Scan existing docs (README, AGENTS.md, etc.) to avoid repeating
3. **Pattern Detection**: Identify architectural patterns in use
4. **ADR Generation**: Create ADRs for discovered decisions
5. **Gap Analysis**: Identify areas where decisions are unclear
6. **Output**: Write ADRs to `memory/adr.md`

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

### Phase 1.5: Documentation Deduplication

**Objective**: Scan existing docs to avoid repeating documented information

**Scan for**:

- `AGENTS.md` - Project context, overview
- `README.md` - Tech stack, project description
- `CONTRIBUTING.md` - Development guidelines
- `AD.md` or `docs/architecture.md` - Existing architecture
- `LICENSE` - Legal context

**Deduplication Rules**:

| Finding | Action |
|---------|--------|
| Tech stack in README | Reference README in ADR, don't duplicate |
| Architecture exists | Auto-merge or offer update vs. create new |
| Guidelines in CONTRIBUTING | Reference in Development View |
| Context in AGENTS.md | Link from Context View |

**Process**:

1. Run `{SCRIPT}` which calls `scan_existing_docs()`
2. Parse findings from JSON output
3. For each finding, determine: Skip ADR / Reference existing / Document new
4. Report: "X decisions covered by existing docs, Y new ADRs created"

### Phase 2: Pattern Detection

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
#### [Likely Alternative]
**Description**: [What it is]
**Trade-offs**: [Why it might have been considered, neutral assessment - NO "Rejected because"]
← DO NOT fabricate rejection rationale - we don't know why it wasn't chosen

### Confidence Level
[HIGH/MEDIUM/LOW] - [Explanation of confidence in inference]
```

3. **ADR Categories to Generate** (apply surprise-value heuristic):

   **Skip if obvious** (heuristic: surprising):
   - PostgreSQL for relational data → Covered by ecosystem default
   - React for SPA frontend → Standard framework choice
   - Docker for containerization → Conventional choice

   **Document as ADRs**:
   - **ADR-001**: System Architecture Style (monolith vs microservices)
   - **ADR-002**: Database Choice (only if non-obvious for context)
   - **ADR-003**: API Style (REST vs GraphQL vs gRPC)
   - **ADR-004**: Frontend Framework (only if unconventional)
   - **ADR-005**: Deployment Platform (serverless vs traditional)
   - **ADR-006**: CI/CD Approach (GitHub Actions vs Jenkins)
   - **Additional**: Any custom/in-house solutions, unusual patterns, risky choices

### Phase 5: Gap Analysis

#### Security Concerns
- Secrets in code or config files
- Missing CORS configuration
- No input validation middleware
- Authentication/authorization gaps

Format findings as **actionable items**, not just observations:

```markdown
## Architecture Discovery Report

### Technologies Detected
| Category | Technology | Confidence | Evidence |
|----------|------------|------------|----------|
| Backend | Django 4.2 | HIGH | requirements.txt, app structure |
| Database | PostgreSQL | HIGH | connection strings, migrations |
| Frontend | React 18 | MEDIUM | package.json, JSX files |
| Cache | Redis | HIGH | redis imports, docker-compose |

### Documentation Deduplication
✓ README.md: Tech stack documented (lines 20-45)
  → Referenced in Context View, skipping tech stack ADRs
✓ CONTRIBUTING.md: Development workflow documented
  → Referenced in Development View 3.5

### ADRs Generated (Surprising/Risky decisions only)
| ID | Decision | Confidence | Why Documented |
|----|----------|------------|----------------|
| ADR-001 | Monolithic Django architecture | HIGH | Architecture style choice |
| ADR-002 | Custom JWT authentication | MEDIUM | Security risk, non-standard |
| ADR-003 | Microservices for small team | HIGH | Scale mismatch, surprising |

### Skipped (Covered by existing docs or obvious)
| Decision | Reason |
|----------|--------|
| PostgreSQL choice | Ecosystem default + README covers |
| React frontend | Standard framework + README covers |
| Docker containerization | Conventional choice |

### Unclear Areas (Need Human Input)
| Area | Question | Suggestion |
|------|----------|------------|
| Auth | OAuth2 or custom JWT? | Found JWT usage, need confirmation |
| Caching | Redis strategy unclear | Cache-aside pattern inferred |
| Scaling | Horizontal scaling setup? | No auto-scaling config found |

### Recommended Clarifications
1. Run `/architect.clarify` to refine ADRs with human input
2. Focus on [specific unclear area]
3. Consider documenting [undocumented pattern]
```

### Phase 6: Output Generation

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
   - Mark ADRs as "Discovered (Inferred)" status ← USE THIS STATUS
   - Use "Common Alternatives" section with neutral trade-offs (no "Rejected because")
   - Note confidence level for each

2. **Create/Update Architecture**:
   - Create `AD.md` at project root (if not exists) from `AD-template.md`
   - Include only views specified by `--views` flag (default: core 5)
   - Mark optional views (Concurrency, Operational) if not included

3. **Generate Summary**:
   - Technologies discovered
   - ADRs created
   - Gaps identified
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

### No Fabricated Rejection Rationale

- **NEVER invent "Rejected because" reasons** for reverse-engineered ADRs
- **Use "Common Alternatives" with neutral "Trade-offs" framing** instead
- **Only document alternatives that were likely considered**
- **Be honest**: "We don't know why X wasn't chosen" is acceptable

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
