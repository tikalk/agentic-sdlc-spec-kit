---
description: Generate full Product Requirements Document (PRD) from PDRs using multi-agent DAG orchestration
scripts:
  sh: scripts/bash/setup-product.sh "implement {ARGS}"
  ps: scripts/powershell/setup-product.ps1 "implement {ARGS}"
---

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Examples of User Input**:

- `"Focus on problem and scope sections - we need clear boundaries"`
- `"Generate full PRD with all sections"`
- `"Update existing PRD.md with new PDRs from recent decisions"`
- Empty input: Generate complete PRD from all PDRs

### Flags

- `--sections SECTIONS`: PRD sections to generate
  - `all` (default): All 11 sections
  - Custom: comma-separated (e.g., `problem,scope,requirements`)

## Goal

Transform Product Decision Records (PDRs) into a comprehensive Product Requirements Document (PRD) using a **multi-agent DAG orchestration** approach:

1. **Plan Agent**: Analyze PDRs, detect feature-areas, generate customized DAG, get user approval
2. **Execute Agent**: Generate sections per feature-area following the DAG, with dependency context
3. **Summarize Agent**: Aggregate all sections, resolve conflicts, generate unified PRD.md

**Key Insight**: PDRs capture **why** decisions were made; the PRD captures **what** the product will deliver as a result of those decisions.

## Role & Context

You are acting as a **Product Orchestrator** managing a multi-phase documentation generation workflow. Your role involves:

- **Planning** the generation DAG based on feature-area analysis
- **Executing** section generation with proper dependency ordering
- **Summarizing** sections into a unified Product Requirements Document
- **Persisting** state for resumability across AI agent sessions

### Product Document Hierarchy

| Document | Purpose | Location |
|----------|---------|----------|
| `{REPO_ROOT}/.specify/drafts/pdr.md` | Product decisions with rationale | Input |
| `{REPO_ROOT}/.specify/product/state.json` | DAG execution state | State |
| `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md` | Per-section outputs | Intermediate |
| `PRD.md` (root or team-directives) | Full Product Requirements Document | Output |
| `{REPO_ROOT}/.specify/memory/constitution.md` | Product vision/strategy | Constraint |

### Section Templates

Located in the extension's `templates/sections/` directory:

| Template | Purpose |
|----------|---------|
| `templates/sections/overview.md` | Overview section template |
| `templates/sections/problem.md` | Problem section template |
| `templates/sections/goals.md` | Goals/Objectives section template |
| `templates/sections/metrics.md` | Success Metrics section template |
| `templates/sections/personas.md` | Personas section template |
| `templates/sections/requirements.md` | Functional Requirements section template |
| `templates/sections/nfrs.md` | Non-Functional Requirements section template |
| `templates/sections/out-of-scope.md` | Out of Scope section template |
| `templates/sections/risks.md` | Risks & Mitigation section template |
| `templates/sections/roadmap.md` | Roadmap & Milestones section template |
| `templates/sections/pdr-summary.md` | PDR Summary section template |

## Three-Phase DAG Workflow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PHASE 1: PLAN                                      │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │ Load PDRs   │───▶│ Detect Feature- │───▶│ Generate DAG per Feature-  │ │
│  │             │    │ Areas           │    │ Area (apply customization) │ │
│  └─────────────┘    └─────────────────┘    └──────────────┬──────────────┘ │
│                                                           │                 │
│                                            ┌──────────────▼──────────────┐ │
│                                            │ Present Plan for Approval   │ │
│                                            │ (user confirms or modifies) │ │
│                                            └──────────────┬──────────────┘ │
│                                                           │                 │
│                                            ┌──────────────▼──────────────┐ │
│                                            │ Write state.json            │ │
│                                            └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PHASE 2: EXECUTE                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  For each feature-area, execute DAG in topological order:           │   │
│  │                                                                      │   │
│  │  ┌──────────┐    ┌─────────┐    ┌───────┐    ┌─────────┐            │   │
│  │  │ Overview │───▶│ Problem │───▶│ Goals │───▶│ Metrics │            │   │
│  │  └──────────┘    └─────────┘    └───────┘    └─────────┘            │   │
│  │        │              │                            │                 │   │
│  │        ▼              ▼                            │                 │   │
│  │  ┌──────────┐   ┌─────────────┐                   │                 │   │
│  │  │ Personas │──▶│Requirements │◀──────────────────┘                 │   │
│  │  └──────────┘   └─────────────┘                                     │   │
│  │                       │                                              │   │
│  │        ┌──────────────┼──────────────┐                              │   │
│  │        ▼              ▼              ▼                              │   │
│  │  ┌─────────┐   ┌────────────┐  ┌─────────┐                         │   │
│  │  │  NFRs   │   │Out of Scope│  │  Risks  │                         │   │
│  │  └─────────┘   └────────────┘  └─────────┘                         │   │
│  │        │              │              │                              │   │
│  │        └──────────────┼──────────────┘                              │   │
│  │                       ▼                                              │   │
│  │                 ┌──────────┐    ┌─────────────┐                     │   │
│  │                 │ Roadmap  │───▶│ PDR Summary │                     │   │
│  │                 └──────────┘    └─────────────┘                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Each section: Read dependencies → Generate content → Write to sections dir │
│                → Update state.json with progress                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PHASE 3: SUMMARIZE                                 │
│  ┌──────────────────┐    ┌─────────────────────┐    ┌──────────────────┐   │
│  │ Read all section │───▶│ Detect cross-       │───▶│ Resolve conflicts│   │
│  │ files            │    │ feature conflicts   │    │ using PDRs       │   │
│  └──────────────────┘    └─────────────────────┘    └────────┬─────────┘   │
│                                                               │             │
│  ┌──────────────────┐                               ┌────────▼─────────┐   │
│  │ Move Accepted    │◀──────────────────────────────│ Aggregate into   │   │
│  │ PDRs to memory   │                               │ unified PRD.md   │   │
│  └──────────────────┘                               └──────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: PLAN (Plan Agent)

**Objective**: Analyze PDRs, detect feature-areas, generate customized DAG, get user approval

**Script Action**: Run `{SCRIPT}` which calls `plan-dag` internally

### Step 1.1: Load and Analyze PDRs

1. **Read PDR File**: Load `{REPO_ROOT}/.specify/drafts/pdr.md`
2. **Parse PDR Index**: Extract feature-areas from the PDR index table
3. **Group PDRs by Feature-Area**: Create mapping of feature-area → PDRs

**PDR Index Table Format**:

```markdown
| ID | Category | Feature-Area | Decision | Status | Date | Owner |
|----|----------|--------------|----------|--------|------|-------|
| PDR-001 | Problem | Core | Target enterprise users | Accepted | 2024-01-15 | @product |
| PDR-002 | Persona | Auth | Developer persona | Accepted | 2024-01-16 | @ux |
| PDR-003 | Feature | Data | Real-time sync | Accepted | 2024-01-17 | @product |
```

### Step 1.2: Detect Feature-Areas and Characteristics

For each feature-area, analyze PDRs to detect:

| Characteristic | Detection Pattern | DAG Customization |
|---------------|-------------------|-------------------|
| B2B Focus | Enterprise, B2B, organization | Expand Personas, add NFRs early |
| B2C Focus | Consumer, individual, user | Prioritize UX in Requirements |
| Platform | API, SDK, integration | Technical Requirements first |
| Data-heavy | Analytics, ML, data | Information section priority |
| Marketplace | Multi-sided, vendors, buyers | Multiple Persona paths |

### Step 1.3: Generate Customized DAG per Feature-Area

**Default DAG (All Sections)**:

```text
Overview → Problem → Goals → Metrics
                ↓         ↓
           Personas → Requirements
                          ↓
           ┌──────────────┼──────────────┐
           ↓              ↓              ↓
         NFRs      Out of Scope       Risks
           └──────────────┼──────────────┘
                          ↓
                       Roadmap → PDR Summary
```

**DAG Customization Rules**:

| Pattern Detected | DAG Modification |
|-----------------|------------------|
| B2B Focus | Personas expanded, NFRs earlier |
| Platform Product | Requirements before Personas |
| Data Product | Metrics has higher priority |
| Marketplace | Multiple Persona branches |
| MVP Focus | Skip Roadmap details |

### Step 1.4: Present Plan for User Approval

Present the execution plan to the user:

```markdown
## DAG Execution Plan

**Feature-areas detected**: 3
**Total sections to generate**: 33 (11 sections × 3 feature-areas)

### Feature-Area: Core
**PDRs**: PDR-001, PDR-005, PDR-008
**Characteristics**: B2B Focus, Platform
**DAG**: Overview → Problem → Goals → Metrics → Personas → Requirements → NFRs → Out of Scope → Risks → Roadmap → PDR Summary

### Feature-Area: Auth
**PDRs**: PDR-002, PDR-006
**Characteristics**: Technical, Security-focused
**DAG**: Overview → Problem → Goals → Requirements → NFRs → Personas → Metrics → Out of Scope → Risks → Roadmap → PDR Summary

### Feature-Area: Data
**PDRs**: PDR-003, PDR-004, PDR-007
**Characteristics**: Data-heavy
**DAG**: Overview → Problem → Metrics → Goals → Personas → Requirements → NFRs → Out of Scope → Risks → Roadmap → PDR Summary

---

**Approve this plan?** [Yes/Modify/Cancel]
```

### Step 1.5: Write state.json

After user approval, write the execution plan to `{REPO_ROOT}/.specify/product/state.json`:

```json
{
  "version": "1.1.0",
  "created_at": "2024-01-20T10:30:00Z",
  "updated_at": "2024-01-20T10:30:00Z",
  "phase": "plan_approved",
  "sections_mode": "all",
  "feature_areas": [
    {
      "id": "core",
      "name": "Core",
      "pdrs": ["PDR-001", "PDR-005", "PDR-008"],
      "characteristics": ["b2b", "platform"],
      "dag": ["overview", "problem", "goals", "metrics", "personas", "requirements", "nfrs", "out-of-scope", "risks", "roadmap", "pdr-summary"],
      "progress": {
        "overview": "pending",
        "problem": "pending",
        "goals": "pending",
        "metrics": "pending",
        "personas": "pending",
        "requirements": "pending",
        "nfrs": "pending",
        "out-of-scope": "pending",
        "risks": "pending",
        "roadmap": "pending",
        "pdr-summary": "pending"
      }
    }
  ],
  "output_file": "PRD.md"
}
```

---

## PHASE 2: EXECUTE (Execute Agent)

**Objective**: Generate sections per feature-area following the DAG, with dependency context passing

**Script Action**: The agent reads `state.json` and executes sections in DAG order

### Step 2.1: Read Execution State

1. Load `{REPO_ROOT}/.specify/product/state.json`
2. Identify next section(s) to generate (sections with all dependencies completed)
3. Load relevant PDRs for the current feature-area

### Step 2.2: Generate Sections in DAG Order

For each section in the DAG:

1. **Check Dependencies**: Ensure all dependency sections are completed
2. **Load Dependency Context**: Read completed section files for context
3. **Load Section Template**: Read from `templates/sections/{section}.md`
4. **Generate Section Content**: Fill template with PDR-derived content
5. **Write Section File**: Save to `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md`
6. **Update State**: Mark section as "completed" in state.json

### Step 2.3: Section Generation Details

#### 1. Overview

**Purpose**: High-level product description
**Dependencies**: None (first in DAG)
**Template**: `templates/sections/overview.md`
**PDRs to Reference**: Problem, Business Model, Scope

#### 2. Problem

**Purpose**: Articulate the problem being solved
**Dependencies**: Overview
**Template**: `templates/sections/problem.md`
**PDRs to Reference**: Problem category PDRs

#### 3. Goals/Objectives

**Purpose**: Define what success looks like
**Dependencies**: Overview, Problem
**Template**: `templates/sections/goals.md`
**PDRs to Reference**: Problem, Metric PDRs

#### 4. Success Metrics

**Purpose**: Define measurable outcomes
**Dependencies**: Goals
**Template**: `templates/sections/metrics.md`
**PDRs to Reference**: Metric category PDRs

#### 5. Personas

**Purpose**: Define target users
**Dependencies**: Problem
**Template**: `templates/sections/personas.md`
**PDRs to Reference**: Persona category PDRs

#### 6. Functional Requirements

**Purpose**: Define what the product must do
**Dependencies**: Personas, Goals, Metrics
**Template**: `templates/sections/requirements.md`
**PDRs to Reference**: Scope, Feature, Prioritization PDRs

#### 7. Non-Functional Requirements

**Purpose**: Define quality attributes
**Dependencies**: Requirements
**Template**: `templates/sections/nfrs.md`
**PDRs to Reference**: NFR category PDRs

#### 8. Out of Scope

**Purpose**: Define explicit exclusions
**Dependencies**: Requirements
**Template**: `templates/sections/out-of-scope.md`
**PDRs to Reference**: Scope PDRs (negative decisions)

#### 9. Risks & Mitigation

**Purpose**: Document product risks
**Dependencies**: Requirements
**Template**: `templates/sections/risks.md`
**PDRs to Reference**: All PDRs (consequence sections)

#### 10. Roadmap & Milestones

**Purpose**: Define release milestones
**Dependencies**: Requirements, NFRs, Out of Scope, Risks
**Template**: `templates/sections/roadmap.md`
**PDRs to Reference**: Milestone category PDRs

#### 11. PDR Summary

**Purpose**: Traceable summary of all decisions
**Dependencies**: All sections
**Template**: `templates/sections/pdr-summary.md`
**PDRs to Reference**: All PDRs

### Step 2.4: Update Progress in state.json

After each section is generated:

```json
{
  "progress": {
    "overview": "completed",
    "problem": "completed",
    "goals": "in_progress",
    "metrics": "pending",
    "personas": "pending",
    "requirements": "pending",
    "nfrs": "pending",
    "out-of-scope": "pending",
    "risks": "pending",
    "roadmap": "pending",
    "pdr-summary": "pending"
  },
  "updated_at": "2024-01-20T11:15:00Z"
}
```

### Step 2.5: Resumability

If the agent session is interrupted:

1. Next session loads `state.json`
2. Identifies sections with `"pending"` or `"in_progress"` status
3. Continues from where it left off
4. Skips already `"completed"` sections

---

## PHASE 3: SUMMARIZE (Summarize Agent)

**Objective**: Aggregate all sections, resolve conflicts, generate unified PRD.md

**Script Action**: Run `summarize` action

### Step 3.1: Read All Section Files

1. Scan `{REPO_ROOT}/.specify/product/sections/` directory

**Directory Structure**:

```text
{REPO_ROOT}/.specify/product/sections/
├── core/
│   ├── overview.md
│   ├── problem.md
│   ├── goals.md
│   ├── metrics.md
│   ├── personas.md
│   ├── requirements.md
│   ├── nfrs.md
│   ├── out-of-scope.md
│   ├── risks.md
│   ├── roadmap.md
│   └── pdr-summary.md
├── auth/
│   └── ... (same structure)
└── data/
    └── ... (same structure)
```

### Step 3.2: Detect Cross-Feature-Area Conflicts

Compare sections across feature-areas for:

| Conflict Type | Detection | Resolution |
|--------------|-----------|------------|
| Priority conflicts | Same feature, different priorities | Defer to PDR with higher impact |
| Persona overlap | Same persona, different needs | Merge and reference both PDRs |
| Metric conflicts | Same metric, different targets | Use most conservative target |
| Scope conflicts | Feature in-scope vs out-of-scope | Defer to explicit PDR decision |

### Step 3.3: Resolve Conflicts Using PDRs

**PDRs are the Source of Truth**. When conflicts are detected:

1. Find the relevant PDR(s) that govern the conflicting area
2. Apply the PDR decision to resolve the conflict
3. Document the resolution in the unified section

### Step 3.4: Aggregate into Unified PRD.md

**Structure of Unified PRD.md**:

```markdown
# Product Requirements Document: [Product Name]

## 1. Overview
[Unified from all feature-area overviews]

## 2. The Problem
[Merged problem statements]

## 3. Goals/Objectives
[Consolidated goals]

## 4. Success Metrics
[Unified metrics with targets]

## 5. Personas
[Merged personas from all feature-areas]

## 6. Functional Requirements
[Consolidated user stories and features]

## 7. Non-Functional Requirements
[Merged NFRs]

## 8. Out of Scope
[Unified exclusions]

## 9. Risks & Mitigation
[Consolidated risk register]

## 10. Roadmap & Milestones
[Unified timeline]

## 11. PDR Summary
[Master index of all PDRs]

## Appendix
[Glossary, References, Change History]
```

### Step 3.5: PDR Lifecycle Management

After generating PRD:

1. **Identify Accepted PDRs**: Filter PDRs with "Accepted" status
2. **Determine Canonical Location**:
   - If `SPECIFY_TEAM_DIRECTIVES` configured → `{TEAM_DIRECTIVES}/context_modules/pdr.md`
   - Otherwise → `{REPO_ROOT}/.specify/memory/pdr.md`
3. **Copy Accepted PDRs** to canonical location
4. **Update Drafts**: Remove accepted PDRs from `{REPO_ROOT}/.specify/drafts/pdr.md` (or delete if empty)

### Step 3.6: Generate Final Report

```markdown
## Product Requirements Document Generated

**Output**: PRD.md (project root or team-directives)
**Sections Mode**: [all|custom]
**Feature-Areas Processed**: N

**Sections Generated**:
| Feature-Area | Sections | Status |
|--------------|----------|--------|
| Core | All 11 | ✓ |
| Auth | All 11 | ✓ |
| Data | All 11 | ✓ |

**Conflicts Resolved**: M
**PDR Coverage**: X/Y PDRs incorporated

**PDR Lifecycle**:
- Promoted to canonical: N PDRs
- Remaining in drafts: M PDRs

**Recommended Next Steps**:
1. Review generated PRD for accuracy
2. Run `/product.analyze` for consistency validation
3. Share with stakeholders for review
4. Begin feature development with `/spec.specify`
```

---

## State File Schema

**Location**: `{REPO_ROOT}/.specify/product/state.json`

```json
{
  "version": "1.1.0",
  "created_at": "ISO8601 timestamp",
  "updated_at": "ISO8601 timestamp",
  "phase": "planning | plan_approved | executing | summarizing | completed",
  "sections_mode": "all | custom",
  "feature_areas": [
    {
      "id": "lowercase-kebab-case",
      "name": "Display Name",
      "pdrs": ["PDR-001", "PDR-002"],
      "characteristics": ["b2b", "platform"],
      "dag": ["overview", "problem", "goals", "metrics", "personas", "requirements", "nfrs", "out-of-scope", "risks", "roadmap", "pdr-summary"],
      "progress": {
        "overview": "pending | in_progress | completed | skipped",
        "problem": "pending | in_progress | completed | skipped"
      }
    }
  ],
  "conflicts_detected": [],
  "conflicts_resolved": [],
  "output_file": "PRD.md"
}
```

---

## Key Rules

### PDR Traceability

- **Every section** must reference source PDRs
- **No content** without PDR backing
- **PDRs are source of truth** for conflict resolution

### State Persistence

- **Always update** state.json after each operation
- **Resume gracefully** from any interruption
- **Track progress** at section granularity

### Multi-Agent Compatibility

- State file works with any AI agent (Claude, Copilot, Cursor, etc.)
- No agent-specific dependencies
- Human-readable state for debugging

### Quality Standards

- **Validate** requirements are actionable
- **Ensure** acceptance criteria are testable
- **Check** metric definitions are measurable

---

## Workflow Guidance & Transitions

### After `/product.implement`

1. **Review PRD**: Verify product documentation is accurate
2. **Run `/product.analyze`**: Validate consistency and completeness
3. **Share for Review**: Get stakeholder feedback
4. **Start Features**: Use `/spec.specify` to create feature specs

### When to Use This Command

- **After `/product.specify`**: Generate PRD from discussed PDRs
- **After `/product.init`**: Document existing product
- **PDR Updates**: Regenerate PRD after new decisions
- **Documentation Sprint**: Create comprehensive product docs

### When NOT to Use This Command

- **No PDRs exist**: Use `/product.specify` or `/product.init` first
- **Feature-level**: Feature PRD generated via `/spec.plan --product`
- **Minor updates**: Use direct editing for small changes

---

## Context

{ARGS}
