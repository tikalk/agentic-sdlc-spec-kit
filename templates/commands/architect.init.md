---
description: Reverse-engineer architecture from existing codebase (brownfield) to create ADRs, then validate with clarifying questions
handoffs:
  - label: Validate Discovered ADRs
    agent: architect.clarify
    prompt: |
      Review ADRs discovered from brownfield codebase analysis.
      Ask questions about:
      - Current state validity (are inferred decisions still correct?)
      - Team context (size, maturity, constraints)
      - Technical debt and deprecated patterns
      - Migration plans for legacy components
      Focus on validating assumptions, not suggesting new approaches.
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
- Empty input: Scan entire codebase and infer architecture

When users provide context, use it to focus the reverse-engineering effort.

## Goal

Reverse-engineer architecture from an **existing codebase** (brownfield) to create ADRs documenting discovered decisions, then **auto-trigger clarification** to validate findings.

**Output**:

1. **ADRs** documenting inferred architectural decisions in `.specify/memory/adr.md`
2. **Auto-handoff** to `/architect.clarify` to validate discovered decisions

**Key Difference from `/architect.specify`**:

- `/architect.init` (this command) = **Discovers** what's already implemented in code
- `/architect.specify` = **Explores** new possibilities for greenfield projects

This command focuses on **current state analysis** - what IS, not what SHOULD BE.

### Flags

- `--adr-heuristic HEURISTIC`: ADR generation strategy
  - `surprising` (default): Skip obvious ecosystem defaults, document only surprising/risky decisions
  - `all`: Document all discovered decisions
  - `minimal`: Only high-risk decisions

## Role & Context

You are acting as an **Architecture Archaeologist** uncovering implicit architectural decisions from code. Your role involves:

- **Scanning** codebase for technology choices and patterns
- **Inferring** architectural decisions from code structure
- **Documenting** discovered patterns as ADRs
- **Identifying** gaps where decisions are unclear

### Brownfield vs Greenfield

| Scenario | Command | Input | Output |
|----------|---------|-------|--------|
| **Brownfield** (existing code) | `/architect.init` | Codebase scan | Inferred ADRs |
| **Greenfield** (new project) | `/architect.specify` | PRD/requirements | Discussed ADRs |

## Outline

1. **Codebase Scan**: Analyze project structure and detect technologies
2. **Documentation Deduplication**: Scan existing docs (README, AGENTS.md, team-ai-directives/AGENTS.md if configured, etc.) to avoid repeating
3. **Pattern Detection**: Identify architectural patterns in use
4. **ADR Generation**: Create ADRs for discovered decisions (marked "Discovered")
5. **Gap Analysis**: Identify areas where decisions are unclear
6. **Output**: Write ADRs to `.specify/memory/adr.md` (NO AD.md creation)
7. **Auto-Handoff**: Trigger `/architect.clarify` to validate brownfield findings

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

### Phase 2: Pattern Recognition

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
- `team-ai-directives/AGENTS.md` - Team-wide agent usage instructions (if configured)
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
| Team directives AGENTS.md | Reference for team-wide agent instructions |

**Process**:

1. Run `{SCRIPT}` which calls `scan_existing_docs()`
2. Parse findings from JSON output
3. For each finding, determine: Skip ADR / Reference existing / Document new
4. Report: "X decisions covered by existing docs, Y new ADRs created"

### Phase 2: Pattern Detection

**Objective**: Document discovered decisions as ADRs

For each discovered architectural decision:

1. **Identify the Decision**:
   - What technology/pattern was chosen?
   - What alternatives were available when this was built?
   - What forces likely drove this decision?

2. **Create ADR Entry**:

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

**Objective**: Identify areas where decisions are unclear

After scanning, report:

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

**Objective**: Write discovered ADRs to file (NO AD.md creation)

1. **Write ADRs**:
   - Create or update `.specify/memory/adr.md` with discovered ADRs
   - Mark ADRs as "Discovered (Inferred)" status ← USE THIS STATUS
   - Use "Common Alternatives" section with neutral trade-offs (no "Rejected because")
   - Note confidence level for each
   - Tag assumptions that need validation

2. **DO NOT Create AD.md**:
   - Architecture Description will be generated later via `/architect.implement`
   - Only AFTER ADRs are validated through clarification

3. **Generate Summary**:
   - Technologies discovered
   - ADRs created with confidence levels
   - Gaps identified
   - Assumptions made (to be validated in clarify phase)

### Phase 7: Auto-Handoff to Clarify

**Objective**: Validate brownfield findings with user

After generating ADRs, **automatically trigger `/architect.clarify`** with brownfield context:

**Questions Clarify Should Ask** (Brownfield-Specific):

| Question Type | Example |
|---------------|---------|
| **Current State Validity** | "I detected microservices in docker-compose.yml - is this still your current approach?" |
| **Decision Rationale** | "PostgreSQL is used - was this chosen for specific requirements or inherited?" |
| **Team Context** | "Based on git history, team appears small - are current architecture decisions appropriate?" |
| **Technical Debt** | "Found custom authentication - are you considering migration to OAuth/OIDC?" |
| **Migration Plans** | "Legacy patterns detected in X module - any plans to modernize?" |
| **Deprecated Patterns** | "Monolithic deployment with hints of service separation - is microservices migration planned?" |

**Context Passed to Clarify**:

```json
{
  "source": "brownfield",
  "tech_stack_detected": ["detected technologies"],
  "inferred_decisions": ["list of ADRs with confidence levels"],
  "assumptions": ["things that need validation"],
  "files_analyzed": "count"
}
```

The clarify phase will refine ADRs based on your input, then you can run `/architect.implement` to generate the full AD.md.

## Key Rules

### Evidence-Based Documentation

- **Only document what's found in code** - don't invent decisions
- **Cite specific evidence** for each ADR
- **Mark confidence levels** honestly
- **Flag uncertainties** explicitly

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

**Auto-triggered**: `/architect.clarify` runs immediately to validate findings.

After clarification completes:

1. **Review Validated ADRs**: Check `.specify/memory/adr.md` for accuracy
2. **Run `/architect.implement`**: Generate full AD.md from validated ADRs
3. **Update As Needed**: Refine documentation as you learn more

### Complete Brownfield Flow

```
/architect.init "Node.js API, team of 2"
    ↓
[Scan codebase] → Detect technologies, patterns
    ↓
[Generate ADRs] → Write to .specify/memory/adr.md (marked "Discovered")
    ↓
[Auto-trigger /architect.clarify]
    ↓
[Clarify asks] → "Is microservices decision still valid?"
                 "Custom auth detected - considering OAuth?"
    ↓
[Update ADRs] → Refined with your validation
    ↓
[User runs /architect.implement]
    ↓
[Generate AD.md] → Full architecture description
```

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
