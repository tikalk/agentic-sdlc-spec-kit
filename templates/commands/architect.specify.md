---
description: Interactive PRD exploration and system-level ADR creation through guided architectural discussion
handoffs:
  - label: Refine ADRs
    agent: architect.clarify
    prompt: |
      Review ADRs created from greenfield PRD exploration.
      Ask questions about:
      - Trade-offs and alternatives not yet considered
      - Industry best practices and standards alignment
      - Scalability and future growth concerns
      - Team constraints and skill requirements
      Focus on refining decisions with best practices, not validating existing code.
    send: true
  - label: Generate Architecture
    agent: architect.implement
    prompt: Generate full architecture description from ADRs
    send: false
scripts:
  sh: scripts/bash/setup-architecture.sh "specify {ARGS}"
  ps: scripts/powershell/setup-architecture.ps1 "specify {ARGS}"
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

- `"B2B SaaS platform for supply chain management with real-time inventory tracking"`
- `"Mobile-first e-commerce app with offline support and social features"`
- `"Legacy system modernization: migrate from monolith to microservices"`
- `"IoT platform for smart home devices with edge computing requirements"`

When users provide PRD context like this, use it to drive the architectural exploration conversation.

## Goal

Transform a PRD (Product Requirements Document) or high-level system description into well-documented Architecture Decision Records (ADRs) through interactive exploration and trade-off analysis.

**Key Insight**: Unlike direct architecture generation, this command prioritizes **discussion and exploration** before committing to formal documentation. The goal is to surface trade-offs, validate assumptions, and make informed decisions collaboratively.

### Flags

- `--views VIEWS`: Architecture views to include in final AD.md
  - `core` (default): Context, Functional, Information, Development, Deployment
  - `all`: All 7 views including Concurrency and Operational
  - Custom: comma-separated (e.g., `concurrency,operational`)

- `--adr-heuristic HEURISTIC`: ADR generation strategy
  - `surprising` (default): Skip obvious ecosystem defaults
  - `all`: Document all decisions discussed
  - `minimal`: Only high-risk/unconventional decisions

## Role & Context

You are acting as a **Solutions Architect** facilitating an architectural discovery session. Your role involves:

- **Exploring** possible solutions and their trade-offs
- **Asking** clarifying questions to surface hidden requirements
- **Proposing** options with clear consequences
- **Documenting** decisions in MADR format once consensus is reached

### Two-Level Architecture System

| Level | Location | ADR File | Architecture Description |
|-------|----------|----------|--------------------------|
| **System** | Main branch | `.specify/memory/adr.md` | `AD.md` (root) |
| **Feature** | Feature branch | `specs/{feature}/adr.md` | `specs/{feature}/AD.md` |

This command operates at the **System level**, creating ADRs in `.specify/memory/adr.md`.

## Outline

Given the PRD input, execute this workflow:

1. **Parse PRD Context**: Extract key requirements, constraints, and quality attributes
2. **Load Governance**: Check `.specify/memory/constitution.md` for architectural constraints
3. **Exploration Phase**: Interactive discussion to surface trade-offs and options
4. **Decision Phase**: Document decisions as ADRs with full rationale
5. **Output**: Write ADRs to `.specify/memory/adr.md`

**NOTE:** This is an interactive command. You will engage the user in conversation before finalizing ADRs.

## Execution Steps

### Phase 1: PRD Analysis

**Objective**: Extract architectural drivers from the PRD

1. **Identify Functional Drivers**:
   - Core capabilities the system must provide
   - Key user interactions and workflows
   - Integration requirements with external systems

2. **Identify Quality Attribute Drivers**:
   - Performance requirements (latency, throughput)
   - Scalability expectations (users, data volume)
   - Availability/reliability targets
   - Security and compliance constraints
   - Maintainability and extensibility needs

3. **Identify Constraints**:
   - Technology mandates or prohibitions
   - Budget and timeline constraints
   - Team skills and organizational factors
   - Regulatory or compliance requirements

4. **Load Constitution**:
    - Read `.specify/memory/constitution.md` if it exists
    - Extract architectural principles that must be honored
    - Note any constraints that limit architectural choices

5. **Check Existing Documentation**:
    - Scan `README.md` for already-documented tech stack
    - Check `AGENTS.md` for project context
    - Review `CONTRIBUTING.md` for dev guidelines
    - Note: Don't duplicate - reference existing docs

**Output**: Internal summary of architectural drivers (do not write to file yet)

### Phase 2: Architectural Exploration (Interactive)

**Objective**: Explore solution options through guided discussion

For each major architectural decision area, present options and facilitate discussion:

#### Decision Areas to Explore

1. **System Architecture Style**
   - Monolith vs Microservices vs Modular Monolith
   - Event-driven vs Request-response
   - Serverless vs Traditional hosting

2. **Data Architecture**
   - Database selection (SQL vs NoSQL vs Hybrid)
   - Data partitioning and scaling strategy
   - Caching approach
   - Event sourcing vs CRUD

3. **Integration Architecture**
   - API style (REST vs GraphQL vs gRPC)
   - Async messaging patterns
   - Third-party integration approach

4. **Security Architecture**
   - Authentication mechanism
   - Authorization model
   - Data protection strategy

5. **Deployment Architecture**
   - Cloud provider selection
   - Container orchestration
   - CI/CD approach

#### Exploration Format

For each decision area requiring user input, present:

```markdown
## Architectural Decision: [Decision Area]

**Context**: [Why this decision matters based on PRD]

**Options Being Considered**:

| Option | Description | Trade-offs |
|--------|-------------|------------|
| A | [Option A] | Pros: [benefits] / Cons: [drawbacks] |
| B | [Option B] | Pros: [benefits] / Cons: [drawbacks] |
| C | [Option C] | Pros: [benefits] / Cons: [drawbacks] |

**Recommended**: Option [X] - [Reasoning based on PRD requirements]

**Questions for Clarification**:
1. [Question about constraints or preferences]
2. [Question about trade-off priorities]

Reply with your choice (A/B/C), or provide additional context.
```

#### Exploration Rules

- Present **one decision area at a time** to maintain focus
- Always provide a **recommended option** with clear reasoning
- Ask **targeted questions** to surface hidden requirements
- Allow user to **propose alternatives** not in the initial options
- After user responds, **summarize the decision** before moving to next area
- Skip decisions that are **already determined** by PRD or constitution
- Limit to **5-7 key decisions** (defer less critical decisions)

### Phase 3: Decision Documentation

**Objective**: Convert exploration outcomes into formal ADRs

After each decision is confirmed:

1. **Create ADR Entry**:
   - Use MADR format from `templates/adr-template.md`
   - Document context, decision, consequences, and alternatives
   - Link to constitution principles if applicable

2. **ADR Format**:

```markdown
## ADR-[NNN]: [Decision Title]

### Status
Proposed

### Date
[YYYY-MM-DD]

### Owner
[User/AI collaboration]

### Context
[Problem statement and forces from exploration]

### Decision
[Clear statement of what was decided]

### Consequences

#### Positive
- [Benefit 1]
- [Benefit 2]

#### Negative
- [Trade-off 1]
- [Trade-off 2]

#### Risks
- [Risk 1 with mitigation]

### Common Alternatives

#### Option A: [Alternative Name]
**Description**: [Brief description]
**Trade-offs**: [Neutral comparison - when this would be better/worse, not "rejected because"]

#### Option B: [Alternative Name]
**Description**: [Brief description]
**Trade-offs**: [Neutral comparison]
```

3. **Number ADRs sequentially**: Start from ADR-001 for new projects, or continue from highest existing number

### Phase 4: ADR Output

**Objective**: Write finalized ADRs to file

1. **Run Setup Script**:
   - Execute `{SCRIPT}` to ensure `.specify/memory/adr.md` exists
   - Script creates from template if file doesn't exist

2. **Write ADRs**:
   - Append new ADRs to `.specify/memory/adr.md`
   - Update ADR index table at top of file
   - Preserve any existing ADRs (don't overwrite)

3. **Report Summary**:
   - List of ADRs created with IDs and titles
   - Constitution alignment status
   - Recommended next steps

## Key Rules

### Exploration First

- **Do NOT generate architecture directly** from PRD
- **Engage in discussion** to validate assumptions
- **Surface trade-offs** before committing to decisions
- **Allow iteration** - user can revisit earlier decisions

### Constitution Compliance

- ADRs must **align with constitution** principles
- **Flag conflicts** between PRD requirements and constitution
- Constitution violations require explicit override with justification

### Incremental ADRs

- Create **focused ADRs** - one decision per ADR
- **Link related ADRs** when decisions interact
- **Defer decisions** that can be made later
- Mark **provisional decisions** that may need revision

### Quality Standards

- Every ADR must have **clear context** explaining why decision was needed
- **Consequences** must include both positive and negative outcomes
- **Alternatives** must explain why they were rejected
- Decisions must be **actionable** - clear enough to implement

## Workflow Guidance & Transitions

### After `/architect.specify`

Recommended next steps:

1. **Review ADRs**: Ensure all decisions are accurate and complete
2. **Run `/architect.clarify`**: Refine any ambiguous or incomplete ADRs
3. **Run `/architect.implement`**: Generate full Architecture Description from ADRs
4. **Proceed to features**: Use `/spec.specify` to create feature specs within this architecture

### When to Use This Command

- **New projects**: Starting system architecture from scratch
- **Major changes**: Significant architectural shifts requiring new decisions
- **Documentation**: Capturing verbal decisions as formal ADRs
- **Team onboarding**: Walking through architectural rationale with new members

### When NOT to Use This Command

- **Brownfield projects**: Use `/architect.init` instead to reverse-engineer from code
- **Minor updates**: Use `/architect.clarify` for ADR refinements
- **Feature-level**: Feature architecture is handled via `/spec.plan --architecture`

## Context

{ARGS}
