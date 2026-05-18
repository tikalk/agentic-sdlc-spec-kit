---
description: Generate full Product Requirements Document (PRD) from PDRs using multi-agent DAG orchestration with mandatory checkpoint after Requirements
scripts:
  sh: .specify/extensions/product/scripts/bash/setup-product.sh "implement {ARGS}"
  ps: .specify/extensions/product/scripts/powershell/setup-product.ps1 "implement {ARGS}"
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
- `"--no-checkpoint"` - Skip Requirements checkpoint (not recommended)
- Empty input: Generate complete PRD from all PDRs

### Flags

- `--sections SECTIONS`: PRD sections to generate
  - `all` (default): All 11 sections
  - Custom: comma-separated (e.g., `problem,scope,requirements`)

- `--no-checkpoint`: Skip Requirements section checkpoint
  - **Warning**: Requirements is the cornerstone that shapes NFRs, Out-of-Scope, Risks, and Roadmap
  - Not recommended for complex products

- `--force`: Bypass workflow state validation (emergency use only)
  - **WARNING**: May result in processing unapproved PDRs or incomplete architecture

## Goal

Transform Product Decision Records (PDRs) into a comprehensive Product Requirements Document (PRD) using a **multi-agent DAG orchestration** approach:

1. **Plan Agent**: Analyze PDRs, detect feature-areas, generate customized DAG, get user approval
2. **Execute Agent**: Generate sections per feature-area with **mandatory checkpoint after Requirements**
3. **Summarize Agent**: Aggregate all sections, resolve conflicts, generate unified PRD.md

**Key Insight**: PDRs capture **why** decisions were made; the PRD captures **what** the product will deliver. The **Requirements section is the cornerstone** that shapes all subsequent sections.

## Role & Context

You are acting as a **Product Orchestrator** managing a multi-phase documentation generation workflow with strict quality enforcement.

### Why Requirements is the Cornerstone

> "The Requirements section is the cornerstone of most PRDs... It usually drives the shape of other sections such as NFRs, Out-of-Scope, Risks, and Roadmap."

**Requirements** defines:
- What gets built (NFRs, Out-of-Scope boundaries)
- What risks exist (technical feasibility)
- When it gets built (Roadmap prioritization)

**Therefore**: User approval after Requirements is **mandatory** before proceeding.

### Product Document Hierarchy

| Document | Purpose | Location |
|----------|---------|----------|
| `{REPO_ROOT}/.specify/drafts/pdr.md` | Product decisions with rationale | Input |
| `{REPO_ROOT}/.specify/product/state.json` | DAG execution state | State |
| `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md` | Per-section outputs | Intermediate |
| `PRD.md` (root) | Full Product Requirements Document | Output |

## Three-Phase DAG Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: PLAN (Plan Agent)                                      │
│ Load PDRs → Detect Feature-Areas → Generate DAG → Approval      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: EXECUTE (Execute Agent)                                │
│ Per feature-area:                                               │
│   Overview → Problem → Goals → Metrics → Personas               │
│   → [REQUIREMENTS CHECKPOINT] ← MANDATORY USER APPROVAL         │
│   → NFRs → Out-of-Scope → Risks → Roadmap → PDR-Summary         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: SUMMARIZE (Summarize Agent)                            │
│ Read sections → Detect conflicts → Resolve → PRD.md             │
└─────────────────────────────────────────────────────────────────┘
```

## Pre-Flight Validation (MANDATORY)

**Before starting Phase 1, validate prerequisites:**

### Workflow State Check (unless --force)

1. **Check clarify completion in state.json**:
   - Load `{REPO_ROOT}/.specify/product/state.json`
   - Check `workflow.clarify_completed` field
   - If `false` or missing:
     ```
     ❌ WORKFLOW VALIDATION FAILED
     
     The implement command requires PDRs to be approved via /product.clarify first.
     
     Current workflow state: clarify_completed = false
     
     Required: Run /product.clarify and complete Phase 5.5 (PDR Approval)
     
     Options:
     1. Run /product.clarify to approve PDRs (resolves inconsistency flags)
     2. Use --force to bypass (NOT RECOMMENDED - may process unapproved PDRs)
     ```
     - **HALT execution** (unless `--force` flag provided)

### PDR Status Check

2. **Check PDRs exist**: Verify `{REPO_ROOT}/.specify/drafts/pdr.md` exists
3. **Check for Accepted PDRs**: Count PDRs with status "Accepted"
   - If **zero Accepted PDRs**: **STOP** and output:
     ```
     ❌ Cannot proceed: No Accepted PDRs found
     
     The implement command requires PDRs with "Accepted" status.
     Current PDRs are: [list statuses found]
     
     Run /product.clarify to review and approve PDRs first.
     ```
   - If **≥1 Accepted PDR**: Proceed and report: "✓ Found N Accepted PDRs"

## Mandatory Execution Constraints

> **CRITICAL -- READ THIS BEFORE PROCEEDING**
>
> The following constraints are MANDATORY. Violation invalidates the output.

### Constraint 1: Section Files MUST Be Written to Disk

You **MUST** write each section to disk before proceeding:
- Location: `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md`
- Each file MUST be readable and standalone
- Minimum content: 20 lines with proper section headers

### Constraint 2: State MUST Be Updated After EACH Section

Update state.json after EACH section completion — not at the end.

### Constraint 3: Requirements Checkpoint is MANDATORY

You **MUST** pause after Requirements section for user approval (unless `--no-checkpoint`).

**Checkpoint Options**:
- **A**: Approve - Continue to remaining sections
- **B**: Modify - Edit requirements, then continue
- **C**: Restart - Regenerate from Problem phase
- **D**: Cancel - Stop execution

### Constraint 4: Phase "completed" Requires Verification

Mark phase as "completed" in state.json only after:
- All section files exist on disk
- PRD.md has been written
- Drafts cleanup performed
- Final verification checklist completed

### Constraint 5: PRD.md Content MUST Come From Section Files

Do NOT write PRD.md directly from PDRs. Content MUST come from reading generated section files.

### Constraint 6: Phase 3 MUST Read From Disk

Read section files from disk in Phase 3, not from memory.

## PHASE 1: PLAN (Plan Agent)

**Objective**: Analyze PDRs, detect feature-areas, generate customized DAG

### Step 1.1: Load and Analyze PDRs

1. **Read PDR File**: Load `{REPO_ROOT}/.specify/drafts/pdr.md`
2. **Parse PDR Index**: Extract feature-areas from PDR metadata
3. **Group PDRs by Feature-Area**: Create mapping
4. **Validate PDR Status** (MANDATORY):
   - Count PDRs by status: Accepted / Proposed / Discovered
   - If **zero Accepted PDRs**: **STOP execution**
   - Report: "✓ Found [N] Accepted PDRs ready for implementation"

### Step 1.2: Detect Feature-Areas and Characteristics

For each feature-area, analyze PDRs to detect characteristics:

| Characteristic | Detection Pattern | DAG Customization |
|---------------|-------------------|-------------------|
| B2B SaaS | Enterprise, admin features, SSO | Include compliance sections |
| Consumer App | Mobile, freemium, social | Simplify requirements |
| Platform | API, integrations, developer | Expand NFRs |
| Marketplace | Multi-sided, transaction | Add business model sections |

### Step 1.3: Generate Customized DAG per Feature-Area

**Default DAG (All Sections)**:

```
Overview → Problem → Goals → Metrics → Personas → Requirements
    [CHECKPOINT: User approval required]
    → NFRs → Out-of-Scope → Risks → Roadmap → PDR-Summary
```

**DAG Dependency Rules**:

| Section | Dependencies | Can Parallelize |
|---------|--------------|-----------------|
| Overview | None | Yes |
| Problem | Overview | Yes |
| Goals | Problem | Yes |
| Metrics | Goals | Yes |
| Personas | Problem, Goals | Yes |
| **Requirements** | Goals, Personas | **No - CHECKPOINT** |
| NFRs | Requirements | No |
| Out-of-Scope | Requirements | No |
| Risks | Requirements, Out-of-Scope | No |
| Roadmap | Requirements, Goals | No |
| PDR-Summary | All above | No |

### Step 1.4: Present Plan for User Approval

```markdown
## DAG Execution Plan

**Feature-Areas detected**: 3
**Total sections to generate**: 33 (11 sections × 3 areas)

### Feature-Area: Core
**PDRs**: PDR-001, PDR-005, PDR-008
**Characteristics**: B2B SaaS, Platform
**DAG**: Overview → Problem → Goals → Metrics → Personas → [Requirements Checkpoint] → NFRs → Out-of-Scope → Risks → Roadmap → PDR-Summary

**Checkpoint**: After Requirements section, execution will pause for approval.

**Approve this plan?** [Yes/Modify/Cancel]
```

### Step 1.5: Write state.json

After approval, write execution plan to state.

## PHASE 2: EXECUTE (Execute Agent)

**Objective**: Generate sections per feature-area following the DAG

### Section Generation Order

For each section in the DAG:

1. **Check Dependencies**: Ensure all dependencies completed
2. **Load Dependency Context**: Read completed section files
3. **Load Section Template**: Read from `templates/sections/{section}.md`
4. **Generate Section Content**: Fill template with PDR-derived content
5. **Write Section File**: Save to disk
6. **Update State**: Mark section as "completed"

### Requirements Section Checkpoint (MANDATORY)

**After generating Requirements section**:

```markdown
## 🛑 CHECKPOINT: Requirements Section Complete

The Requirements section has been generated for "{feature-area}".

**Why checkpoint here?** Requirements is the cornerstone that shapes:
- NFRs (how requirements are met)
- Out-of-Scope (what's NOT required)
- Risks (technical feasibility of requirements)
- Roadmap (priority and sequencing)

### Generated Requirements Summary

| ID | Requirement | Priority | PDR Source |
|----|-------------|----------|------------|
| REQ-001 | User authentication | Must have | PDR-002 |
| REQ-002 | Admin dashboard | Should have | PDR-005 |

### Options

**A) Approve** - Continue to NFRs, Out-of-Scope, Risks, Roadmap

**B) Modify** - Edit requirements now, then continue

**C) Restart** - Regenerate from Problem phase

**D) Cancel** - Stop execution

**Your choice?** [A/B/C/D]
```

**If user chooses B (Modify)**:
- Allow editing of requirements
- Re-generate requirements section
- Present checkpoint again

**If user chooses C (Restart)**:
- Reset progress from Problem phase
- Re-generate Problem → Goals → Metrics → Personas → Requirements
- Present checkpoint again

### Placeholder Validation (MANDATORY)

**Before finalizing any section, validate placeholders:**

| Pattern | Example | Severity | Action |
|---------|---------|----------|--------|
| `[TBD]` | `[TBD]` | CRITICAL | Must be filled |
| `[REQUIREMENT_*]` | `[REQUIREMENT_1]` | CRITICAL | Must be replaced |
| `[PERSONA_*]` | `[PERSONA_1]` | CRITICAL | Must be replaced |
| `[METRIC_*]` | `[METRIC_1]` | HIGH | Should be filled |
| `[DATE]` | `[DATE]` | MEDIUM | Must be replaced |

Sections with unfilled CRITICAL placeholders **CANNOT** be marked "completed".

### Phase 2→3 Gate Verification (MANDATORY)

**Before proceeding to Phase 3, verify:**

1. For each feature-area in state.json, check every section with status "completed"
2. Verify file exists: `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md`
3. Verify each file is readable and has ≥20 lines

**Verification Checklist** (output this table):

| Feature-Area | Section | File Path | Exists | Readable | Lines |
|--------------|---------|-----------|--------|----------|-------|
| {area} | {section} | {path} | ✓/✗ | ✓/✗ | {N} |

**Gate Decision:**
- If **ALL checks pass** → Proceed to Phase 3
- If **ANY check fails** → STOP and report:
  ```
  ❌ PHASE 2→3 GATE BLOCKED
  
  Missing or invalid section files detected:
  - {area}/{section}: [reason]
  
  Regenerate missing sections before proceeding.
  ```

## PHASE 3: SUMMARIZE (Summarize Agent)

**Objective**: Aggregate sections, resolve conflicts, generate PRD.md

### Step 3.1: Read All Section Files FROM DISK (MANDATORY)

> **CRITICAL**: Read each section file from filesystem. Do NOT use content from memory.

1. **Scan Directory**: List `{REPO_ROOT}/.specify/product/sections/`
2. **Read Each File** (MANDATORY):
   - For each feature-area/section in state.json
   - Read: `{REPO_ROOT}/.specify/product/sections/{feature-area}/{section}.md`
   - If cannot read → **STOP** and report error
3. **Validate Content** (MANDATORY):
   - Each file MUST contain ≥20 lines
   - Each section MUST have proper headers

### Step 3.2: Detect Cross-Feature-Area Conflicts

Compare sections across feature-areas:

| Conflict Type | Detection | Resolution |
|--------------|-----------|------------|
| Duplicate requirements | Same requirement, different wording | Standardize to PDR terminology |
| Priority mismatch | Same feature, different priority | Defer to PDR |
| Metric inconsistency | Same metric, different definition | Use PDR definition |

### Step 3.3: Aggregate into Unified PRD.md

**Structure**:

```markdown
# Product Requirements Document: [Product Name]

## 1. Document Information
[Version, date, status]

## 2. Product Overview
[Unified overview]

## 3. Problem Statement
[Consolidated from all feature-areas]

## 4. Goals & Objectives
[Merged goals]

## 5. Success Metrics
[Unified metrics]

## 6. Target Personas
[Consolidated personas]

## 7. Functional Requirements
[Merged requirements by feature-area]

### 7.1 Core Requirements
[Core feature-area requirements]

### 7.2 Business Requirements
[Business feature-area requirements]

## 8. Non-Functional Requirements
[Consolidated NFRs]

## 9. Out of Scope
[Unified exclusions]

## 10. Risks & Mitigation
[Consolidated risks]

## 11. Roadmap
[Unified timeline]

## 12. Product Decision Records Summary
[Index linking to PDRs]
```

### Step 3.4: PDR Lifecycle Management (MANDATORY)

**Step 1: Filter Accepted PDRs**
- Identify PDRs with status "Accepted"
- Skip Discovered/Proposed PDRs

**Step 2: Copy to Canonical Location**
- Write Accepted PDRs to `{REPO_ROOT}/.specify/memory/pdr.md`
- Merge with existing content

**Step 3: Clean Up Drafts**
- Remove promoted PDRs from drafts
- If no PDRs remain → DELETE drafts file

**Step 4: Report Lifecycle Changes**
```
📋 PDR Lifecycle Summary:
├── Promoted to memory: [N] Accepted PDRs
├── Remaining in drafts: [M] PDRs (Proposed/Discovered)
└── Cleanup verified: ✓
```

### Step 3.5: Generate Final Report

```markdown
## PRD Generation Complete ✓

**Output**: PRD.md (project root)
**Sections Mode**: [all|custom]
**Feature-Areas Processed**: N

### Execution Summary
| Phase | Status |
|-------|--------|
| Plan | ✓ Approved |
| Execute | ✓ Completed (with checkpoint) |
| Summarize | ✓ Completed |

### Sections Generated
| Feature-Area | Sections | Status |
|--------------|----------|--------|
| Core | 11/11 | ✓ |
| Business | 11/11 | ✓ |

### Conflicts Resolved
| Type | Count |
|------|-------|
| Duplicate requirements | 2 |
| Priority mismatches | 1 |

### PDR Lifecycle
- Promoted to canonical: N PDRs
- Remaining in drafts: M PDRs

### Next Steps
1. Review PRD.md for accuracy
2. Run `/product.analyze` for validation
3. Share with stakeholders
4. Begin feature development with `/spec.specify`
```

## Final Completion Verification (MANDATORY)

**Before marking state.json phase as "completed", verify:**

| Check | Expected | Verification | Status |
|-------|----------|--------------|--------|
| 1. Section files on disk | N files | List sections directory | ☐ |
| 2. PRD.md exists | Yes | Check file existence | ☐ |
| 3. PRD.md content size | >200 lines | Count lines | ☐ |
| 4. PRD.md has all sections | N headers | Parse headers | ☐ |
| 5. Memory PDRs promoted | N Accepted | Count in memory | ☐ |
| 6. Drafts cleaned | No duplicates | Compare drafts vs memory | ☐ |
| 7. state.json consistent | All sections "completed" | Verify progress | ☐ |

**Gate Rule:**
- If **ALL checks pass**: Mark phase as "completed"
- If **ANY check fails**: Do NOT mark as completed

## State File Schema

**Location**: `{REPO_ROOT}/.specify/product/state.json`

```json
{
  "version": "1.1.0",
  "created_at": "ISO8601 timestamp",
  "updated_at": "ISO8601 timestamp",
  "phase": "planning | plan_approved | executing | summarizing | completed",
  "sections_mode": "all | custom",
  "checkpoint": {
    "enabled": true,
    "after_section": "requirements",
    "status": "pending | approved | modified | restarted"
  },
  "feature_areas": [
    {
      "id": "core",
      "name": "Core",
      "pdrs": ["PDR-001"],
      "characteristics": ["b2b", "saas"],
      "dag": ["overview", "problem", "goals", "metrics", "personas", "requirements", "nfrs", "out-of-scope", "risks", "roadmap", "pdr-summary"],
      "progress": {
        "overview": "completed",
        "problem": "completed",
        "requirements": "completed",
        "checkpoint_status": "approved"
      }
    }
  ],
  "conflicts_detected": [],
  "conflicts_resolved": [],
  "output_file": "PRD.md"
}
```

## Key Rules

### PDR Traceability
- **Every section** must reference source PDRs
- **No content** without PDR backing
- **PDRs are source of truth** for conflict resolution

### State Persistence
- **Always update** state.json after each operation
- **Resume gracefully** from any interruption
- **Track progress** at section granularity

### Quality Standards
- **Validate** requirements are actionable
- **Ensure** acceptance criteria are testable
- **Check** metric definitions are measurable
- **Verify** placeholder validation passes

## Workflow Guidance

### After `/product.implement`

1. **Review PRD**: Verify documentation is accurate
2. **Run `/product.analyze`**: Validate consistency
3. **Share for Review**: Get stakeholder feedback
4. **Start Features**: Use `/spec.specify` to create feature specs

### When to Use This Command

- **After `/product.clarify`**: Generate PRD from validated PDRs
- **After `/product.init`**: Document existing product
- **PDR Updates**: Regenerate after new decisions

### When NOT to Use This Command

- **No Accepted PDRs**: Run `/product.clarify` first
- **Feature-level**: Use `/spec.plan --product`
- **Minor updates**: Edit PRD.md directly

## Context

{ARGS}
