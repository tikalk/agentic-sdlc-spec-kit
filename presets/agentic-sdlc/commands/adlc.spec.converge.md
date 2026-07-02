---
description: Assess the codebase against spec, plan, and tasks; append remaining work as new tasks, or if converged, run test gate, diff analysis, and 4-pillar quality assessment
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

0. Determine `{REPO_ROOT}` by running `git rev-parse --show-toplevel 2>/dev/null`. If that fails, walk up from the current directory until you find a `.git` directory or `.specify/init-options.json` and use that parent as `{REPO_ROOT}`.
1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `{REPO_ROOT}/.specify/extensions.yml` and find `hooks.before_converge`.
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

Close the gap between what a feature's specification, plan, and tasks call for and what the
codebase currently implements. Read `spec.md`, `plan.md`, and `tasks.md` as the **sole
source of intent** (with the constitution as governing constraints), assess the current
state of the code, determine which requirements, acceptance criteria, plan decisions, and
existing tasks are unmet, incomplete, or only partially satisfied, and **append each piece
of remaining work as a new, traceable task** at the bottom of `tasks.md` so that
`__SPECKIT_COMMAND_IMPLEMENT__` can complete it. This command MUST run only after
`__SPECKIT_COMMAND_IMPLEMENT__` has run on the current `tasks.md`, and after `__SPECKIT_COMMAND_TASKS__` has produced a complete `tasks.md`.

This is **not** a diff tool and does **not** track changes. It assesses the present state
of the code relative to the feature's artifacts — no git, no branch comparison, no history.

## Operating Constraints

**APPEND-ONLY, NEVER REWRITE**: The command's **only** write is appending a new
`## Phase N: Convergence` section to `tasks.md`. It MUST NOT:

- modify `spec.md` or `plan.md` in any way;
- rewrite, renumber, reorder, or delete any existing task (including tasks from a prior
  Convergence phase);
- modify, create, or delete any application code — completing the appended tasks is the
  job of `__SPECKIT_COMMAND_IMPLEMENT__`.

When the codebase already satisfies everything, the command MUST leave `tasks.md`
**byte-for-byte unchanged** (no empty Convergence header) and report a clean result.

**Constitution Authority**: The project constitution (`{REPO_ROOT}/.specify/memory/constitution.md`) is
**non-negotiable**. Code that violates a MUST principle is the highest-severity finding and
produces a corresponding remediation task. If the constitution is an unfilled template,
skip constitution checks gracefully rather than failing.

## Execution Steps

### 1. Initialize Convergence Context

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md
- CONSTITUTION = `{REPO_ROOT}/.specify/memory/constitution.md` (if present)
If `spec.md`, `plan.md`, or `tasks.md` is missing, STOP with a clear, actionable message naming the
prerequisite command to run (`__SPECKIT_COMMAND_SPECIFY__` for a missing spec, `__SPECKIT_COMMAND_PLAN__` for a missing plan,
`__SPECKIT_COMMAND_TASKS__` for missing tasks). Do not produce partial output.
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**

- Functional Requirements (FR-###)
- Success Criteria (SC-###) — include only items requiring buildable work; exclude
  post-launch outcome metrics and business KPIs
- User Stories and their Acceptance Scenarios
- Edge Cases (if present)

**From plan.md:**

- Architecture/stack choices and technical decisions
- Data Model references
- Phases and named touch-points (files/components the plan says will be created or edited)
- Technical constraints

**From tasks.md:**

- Task IDs (to compute the next ID and next phase number)
- Descriptions, phase grouping, and referenced file paths

**From constitution (if not an unfilled template):**

- Principle names and MUST/SHOULD normative statements

### 3. Build the Intent Inventory

Create an internal model (do not echo raw artifacts):

- **Requirements inventory**: one stable key per FR-### / SC-### / user-story acceptance
  scenario (e.g. `US1/AC2`), plus the plan decisions and constitution principles that
  impose buildable obligations.
- **Code-scope map**: from the file paths named in `plan.md` and `tasks.md`, plus a keyword
  search for the concepts each requirement describes, derive the set of source files and
  components in scope for assessment. Bound the assessment to these — do **not** infer
  scope beyond what the artifacts define.

### 4. Assess the Codebase and Classify Findings

For each item in the intent inventory, inspect the current code in scope and produce a
`Finding` only where there is a gap. Classify every finding by **gap type**:

- **`missing`**: the required work is absent from the code entirely.
- **`partial`**: the work exists but does not yet fully satisfy the requirement /
  acceptance criterion / plan decision.
- **`contradicts`**: the code does something that conflicts with stated intent or a
  constitution MUST principle.
- **`unrequested`**: the code contains work not called for by the spec, plan, or tasks
  (surfaced for awareness — converge does **not** delete code, it only appends a task to
  review/justify or remove it).

Each `Finding` records: a stable id, the `source-ref` it traces to, the `gap-type`, a
severity, and a short human-readable description with the evidence (the file/area observed).

**Edge cases:**

- **Little or no code yet**: treat the entire specified scope as `missing` remaining work
  rather than failing.
- **Nothing remains**: produce zero findings and follow the converged branch in Step 7.

### 5. Assign Severity

- **CRITICAL**: violates a constitution MUST principle, or a `missing`/`contradicts` gap
  that blocks baseline functionality of a P1 user story.
- **HIGH**: a `missing` or `partial` gap on a core functional requirement or acceptance
  criterion.
- **MEDIUM**: a `partial` gap on a secondary requirement, or an `unrequested` addition with
  unclear justification.
- **LOW**: minor partial gaps, polish, or low-risk `unrequested` additions.

### 6. Present the In-Session Findings Summary

Before appending anything, output a compact, severity-graded summary (no file writes yet):

## Convergence Findings

| ID | Gap Type | Severity | Source | Evidence | Remaining Work |
|----|----------|----------|--------|----------|----------------|
| F1 | missing  | HIGH     | FR-008 | Example: no append-only guard detected in path/to/module.py when writing tasks.md | Add append-only enforcement |

**Summary metrics:**

- Requirements / acceptance criteria checked
- Plan decisions checked
- Constitution principles checked (or "skipped — template")
- Findings by gap type (missing / partial / contradicts / unrequested)
- Findings by severity

### 7. Append Convergence Tasks (or report converged)

**If there are one or more actionable findings** (`tasks_appended` outcome):

Append to the **end** of `tasks.md`, per the append contract:

1. Scan all existing task IDs; let `M` be the maximum. Determine the next phase number `N`
   (highest existing phase + 1).
2. Write a single new section header `## Phase N: Convergence`.
3. Emit one checklist item per actionable finding, ordered CRITICAL/HIGH first, assigning
   zero-padded IDs `T{M+1:03d}, T{M+2:03d}, …`:

   ```markdown
   - [ ] T042 <imperative description> per <source-ref> (<gap-type>)
   ```

   `<source-ref>` traces the task to its origin: e.g. `FR-003`, `SC-002`,
   `US1/AC2`, `plan: storage decision`, `Constitution II`.

   `<gap-type>` is one of `missing`, `partial`, `contradicts`, `unrequested`.

   Constitution-violation tasks MUST be emitted first and described as
   `CRITICAL`.
4. Never reuse or renumber existing IDs. If a prior Convergence phase exists, add a new,
   separately-numbered one below it — do not touch the old one.

**Output the outcome token as the first line of stdout**: print `tasks_appended` on its own
line before any other output. Then output the findings summary and handoff.

Do NOT proceed to the Test Gate, Diff Analysis, or 4-Pillar Assessment — those phases run
only when the codebase is converged.

**If there are no actionable findings** (`converged` outcome):

- Do **not** modify `tasks.md` at all — no empty phase header.
- Report: **"Converged — the implementation satisfies the spec, plan, and tasks."**
- Include the summary counts of what was checked.
- **Proceed to the verification phases below** (Test Gate → Diff Analysis → 4-Pillar).

### 8. Test Gate

**Tests MUST pass before assessment.** Run the project's test suite:

1. Detect available test runners (search for `package.json` scripts, `pytest.ini`, `Cargo.toml`, `Makefile`, etc.)
2. Run tests once:
   - If tests pass → proceed to Diff Analysis
   - If tests fail → append a task "Fix failing tests" to `tasks.md` under a new `## Phase N: Convergence` section, output `tasks_appended` as the first stdout line, and STOP. Do NOT continue to Diff Analysis or 4-Pillar Assessment until tests pass.

If `SPECIFY_FEATURE_DIRECTORY` is not set and no feature.json exists, skip Test Gate (not in a feature context).

### 9. Diff Analysis

Read `git diff` to understand what changed:

1. Run `git diff HEAD --name-only` (or `git diff --name-only` if no commits yet) to identify changed files
2. Categorize changes:
   - **Spec-related files** under `SPECIFY_FEATURE_DIRECTORY/`
   - **Implementation files** (source code, configs)
   - **Test files**
   - **Documentation files**

### 10. 4-Pillar Assessment

Assess the feature against four pillars. For each, produce a score (0-100), evidence, and specific findings.

#### Pillar 1: Spec Compliance

Compare implementation against the full spec contract in `SPECIFY_FEATURE_DIRECTORY/spec.md`:

- **Goal alignment** — Does the implementation achieve the spec Goal?
- **Success Criteria coverage** — Are all SC items met?
- **Constraint adherence** — Are all Constraints respected?
- **Functional Requirements** — Are all FR items addressed? (cite each: ✅ FR-NNN or ❌ FR-NNN)
- **Non-Functional Requirements** — Are NFR items addressed?
- **Risk Register items** — Are documented risks mitigated?

Read the spec in full. For each FR and SC, trace to evidence in the implementation (files, test output, config). Flag any that are partially or fully unmet.

#### Pillar 2: Code Quality

Assess implementation quality:

- **Structure** — Is the code well-organized? Follows project conventions?
- **Error handling** — Are error paths handled gracefully?
- **Edge cases** — Are edge cases from the spec addressed?
- **Consistency** — Consistent patterns, naming, and style?

#### Pillar 3: Test Adequacy

Assess test coverage:

- **Coverage** — Are all FRs and SCs covered by tests?
- **Quality** — Are tests meaningful (not just pass-through)?
- **Edge cases** — Are edge cases tested?
- **Regression risk** — Are there untested paths that could break?

#### Pillar 4: Risk & Evidence

Assess remaining risk:

- **Unverified assumptions** — What assumptions remain untested?
- **Technical debt** — What shortcuts or TODOs exist?
- **Integration risk** — Are integration points verified?
- **Evidence quality** — Is the evidence for each claim credible (test output, logs, manual verification)?

### 10.5 Read Available Evidence Sources

Before writing the verification report, check for and read these optional artifacts produced by other extensions/commands:

- `FEATURE_DIR/tdd-quality-report.md` — TDD test quality score (produced by the `tdd` extension's `after_implement` hook)
- `FEATURE_DIR/evidence.md` — EDD evidence dossier (produced by the `edd` extension's `after_converge` hook on a previous loop iteration; absent on the first converge run)
- `FEATURE_DIR/trace.md` — Execution trace (produced by `spec.trace`, if run)
- `FEATURE_DIR/checklists/` — Checklist results (produced by `spec.checklist`, if run)

For each source:
- If present → extract: score/findings, what was checked, what was not checked, residual risks
- If absent → note as "not available" — this will appear in the What Was NOT Checked section

These sources populate the evidence-bundle sections of `verify.md` below.

### 11. Write Verification Report

Write to `SPECIFY_FEATURE_DIRECTORY/verify.md`:

```markdown
# Verification Report: [Feature Name]

**Feature**: [branch-or-feature-dir]
**Generated**: [ISO timestamp]
**Spec Kit**: [CLI version] | **Preset**: [name + version]

## Intent

**Mission Brief** (from `spec.md`):
- **Goal**: [spec goal]
- **Success Criteria**:
  - [SC-001: ...]
  - [SC-002: ...]
- **Constraints**:
  - [C-001: ...]

## Verification Summary

| Check | Status | Score | Source |
|-------|--------|-------|--------|
| Converge (4-Pillar) | ✅/❌ | [overall]/100 | verify.md |
| TDD (Test Quality) | ✅/❌/N/A | [X/100] | tdd-quality-report.md |
| EDD (Quality Gates) | _Pending_ | _Pending_ | evidence.md |
| Trace (Coverage) | ✅/❌/N/A | [X%] | trace.md |

## Test Gate
- **Result**: PASS / FAIL
- **Details**: [Test output summary if failed]

## Diff Summary
- **Files changed**: [N]
- **Categories**: [Spec: N, Implementation: N, Tests: N, Docs: N]

## 4-Pillar Assessment

### Pillar 1: Spec Compliance
**Score**: [0-100]/100
**Evidence**: [Summary of findings]
**Unmet items**:
- ❌ FR-001: [Description] → [What's missing]
- ❌ SC-001: [Description] → [What's missing]

### Pillar 2: Code Quality
**Score**: [0-100]/100
**Strengths**: [What's good]
**Issues**: [What needs improvement]

### Pillar 3: Test Adequacy
**Score**: [0-100]/100
**Coverage**: [% estimated]
**Gaps**: [What's untested]

### Pillar 4: Risk & Evidence
**Score**: [0-100]/100
**Risks**: [Remaining risks]
**Evidence quality**: [How strong is the evidence]

## EDD Evidence

<!-- EDD fills this section via after_converge hook -->
_Pending: EDD verification has not yet run._

## Overall Verdict

| Pillar | Score | Status |
|--------|-------|--------|
| Spec Compliance | [X] | ✅ PASS / ❌ FAIL |
| Code Quality | [X] | ✅ PASS / ❌ FAIL |
| Test Adequacy | [X] | ✅ PASS / ❌ FAIL |
| Risk & Evidence | [X] | ✅ PASS / ❌ FAIL |

**Overall**: ✅ VERIFIED / ❌ NOT VERIFIED

*Threshold: All pillars >= 70 for overall PASS.*

## What Was Checked

### Converge
- [4-pillar findings: FR/SC coverage, code quality assessment, test adequacy, risk assessment]

### EDD
<!-- EDD fills this via after_converge hook -->
_Pending: EDD verification has not yet run._

### TDD
[If tdd-quality-report.md exists: summarize score and findings. Else: "TDD not run — test quality not assessed."]

## What Was NOT Checked

### Converge
- [unmet FRs/SCs, untested paths from Pillar 3, gaps from Pillar 4]

### EDD
<!-- EDD fills this via after_converge hook -->
_Pending: EDD verification has not yet run._

### TDD
[If TDD not run: "TDD not run — test quality not assessed."]

## Residual Risks

### Converge (Pillar 4)
- [risks from Pillar 4 assessment]

### EDD
<!-- EDD fills this via after_converge hook -->
_Pending: EDD verification has not yet run._

### TDD
[TDD anti-patterns if available, else: "TDD not run."]

## Provenance

- CLI Version: [from pyproject.toml]
- Preset: [name + version]
- Converge Result: [converged/tasks_appended]
- Generated At: [UTC timestamp]
- EDD: _Pending_
- TDD: [run/not run]

## Recommended Actions

[If failed, list specific actions to address each failing pillar]
```

**IMPORTANT**: If `SPECIFY_FEATURE_DIRECTORY` is not set, output the report inline instead of writing to a file.

If any pillar score is below 70, append remediation tasks to `tasks.md` under a new `## Phase N: Convergence` section, and output `tasks_appended` as the first stdout line instead of `converged`.

### 12. Provide Next Actions (Handoff)

- On `tasks_appended`: state how many tasks were appended under which phase, and recommend
  running `__SPECKIT_COMMAND_IMPLEMENT__` to complete them; note that a follow-up converge
  run will find fewer or no remaining items.
- On `converged`: report that the feature is fully converged and verified. No further
  implement pass is needed for this feature's specified scope.

## Post-Execution Hooks

1. If `{REPO_ROOT}/.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_converge`.
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
5. **Post-hook override**: After running all `after_converge` hooks, if any mandatory hook:
   - reported failures (exit code 1)
   - generated correction artifacts (`next-spec.md`)
   - appended tasks to `tasks.md` (check if `tasks.md` was modified after converge wrote it)

   ...output `tasks_appended` as the first stdout line to signal more work is needed, overriding the initial `converged` assessment. This ensures the implement↺converge loop continues when deep evaluation (e.g., EDD) finds issues.

   **Loop routing signal**: The caller should check for `next-spec.md` in the feature directory:
   - If `next-spec.md` exists → the spec itself needs correction; route to `__SPECKIT_COMMAND_SPECIFY__` (feeding next-spec.md as input), then plan → tasks → implement → converge
   - If `next-spec.md` does not exist but `tasks_appended` → only implementation tasks were appended; route to `__SPECKIT_COMMAND_IMPLEMENT__` → converge
6. If no hooks registered, skip silently.
