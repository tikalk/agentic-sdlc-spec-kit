---
description: Perform cross-artifact consistency and quality analysis. Automatically detects pre vs post-implementation context based on project state.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_analyze`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Pre-Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}

      Wait for the result of the hook command before proceeding.
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Perform consistency and quality analysis across artifacts with automatic context detection:

**Auto-Detection Logic**:

- **Pre-Implementation**: When spec.md exists but no implementation artifacts detected (tasks.md and plan.md required)
- **Post-Implementation**: When implementation artifacts exist (source code, build outputs, etc.)

This command adapts its behavior based on project state.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

**Auto-Detection Logic**:

1. Auto-detect project state:
   - **Pre-implementation**: No implementation artifacts exist (check for source code, compiled outputs, deployment artifacts)
   - **Post-implementation**: Implementation artifacts exist (source code directories, compiled outputs, or deployment artifacts)
2. Apply analysis depth:
   - **Pre-implementation**: Comprehensive analysis with full validation
   - **Post-implementation**: Code-focused analysis with refinement recommendations

**Constitution Authority**: The project constitution (`{REPO_ROOT}/.specify/memory/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `__SPECKIT_COMMAND_ANALYZE__`.

## Execution Steps

### 1. Initialize Analysis Context

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Auto-Detect Analysis Mode

Determine analysis mode based on project state:
- If source code / implementation artifacts exist → Post-Implementation mode
- If only spec/plan/tasks → Pre-Implementation mode

### 3. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**
- Overview/Context
- Functional Requirements
- Success Criteria (measurable outcomes — e.g., performance, security, availability, user success, business impact)
- User Stories
- Edge Cases (if present)

**From plan.md:**
- Architecture/stack choices
- Data Model references
- Phases
- Technical constraints

**From tasks.md:**
- Task IDs
- Descriptions
- Phase grouping
- Parallel markers [P]
- Referenced file paths

**From constitution:**
- Load `{REPO_ROOT}/.specify/memory/constitution.md` for principle validation

### 4. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: For each Functional Requirement (FR-###) and Success Criterion (SC-###), record a stable key. Use the explicit FR-/SC- identifier as the primary key when present, and optionally also derive an imperative-phrase slug for readability. Include only Success Criteria items that require buildable work, and exclude post-launch outcome metrics and business KPIs.
- **User story/action inventory**: Discrete user actions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Constitution rule set**: Extract principle names and MUST/SHOULD normative statements

### 5. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### Pre-Implementation Detection Passes

**A. Duplication Detection**
- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

**B. Ambiguity Detection**
- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, etc.)

**C. Underspecification**
- Requirements with verbs but missing object or measurable outcome
- User stories missing acceptance criteria alignment
- Tasks referencing files or components not defined in spec/plan

**D. Constitution Alignment**
- Any requirement or plan element conflicting with a MUST principle
- Missing mandated sections or quality gates from constitution

**E. Coverage Gaps**
- Requirements with zero associated tasks
- Tasks with no mapped requirement/story
- Success Criteria requiring buildable work not reflected in tasks

**F. Inconsistency**
- Terminology drift (same concept named differently across files)
- Data entities referenced in plan but absent in spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)

#### Post-Implementation Detection Passes

**G. Documentation Drift**
- Code artifacts not documented in spec/plan
- Spec requirements not implemented
- Implementation details not reflected in tasks

**H. Implementation Quality**
- Code follows project conventions
- Error handling consistency
- Test coverage alignment

**I. Real-World Usage Gaps**
- Missing error paths in implementation
- Edge cases not handled
- Performance bottlenecks

**J. Refinement Opportunities**
- Code patterns that could be simplified
- Duplication that emerged during implementation
- Architecture improvements suggested by actual usage

### 6. Severity Assignment

Use this heuristic to prioritize findings:

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Violates constitution MUST, missing core spec artifact, or requirement with zero coverage that blocks baseline functionality |
| **HIGH** | Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion |
| **MEDIUM** | Terminology drift, missing non-functional task coverage, underspecified edge case |
| **LOW** | Style/wording improvements, minor redundancy not affecting execution order |

### 7. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| A1 | Duplication | HIGH | spec.md:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**Coverage Summary Table:**

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

**Constitution Alignment Issues:** (if any)

**Unmapped Tasks:** (if any)

**Metrics:**
- Total Requirements
- Total Tasks
- Coverage % (requirements with >=1 task)
- Ambiguity Count
- Duplication Count
- Critical Issues Count

### 8. Provide Next Actions

At end of report, output a concise Next Actions block:

- If CRITICAL issues exist: Recommend resolving before `__SPECKIT_COMMAND_IMPLEMENT__`
- If only LOW/MEDIUM: User may proceed, but provide improvement suggestions
- Provide explicit command suggestions: e.g., "Run __SPECKIT_COMMAND_SPECIFY__ with refinement", "Run __SPECKIT_COMMAND_PLAN__ to adjust architecture", "Manually edit tasks.md to add coverage for 'performance-metrics'"

### 9. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize constitution violations** (these are always CRITICAL)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)

### Auto-Detection Guidelines

- Pre-implementation: Focus on spec/plan/tasks consistency
- Post-implementation: Focus on implementation/documentation alignment

## Context

{ARGS}

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_analyze`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`):
      ```
      ## Extension Hooks

      **Automatic Hook**: {extension}
      Executing: `/{command}`
      EXECUTE_COMMAND: {command}
      ```
      After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
