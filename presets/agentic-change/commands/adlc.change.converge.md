---
description: Assess change scope against spec and tasks; append remaining work, or if converged, run test gate, diff analysis, 4-pillar assessment, write verify.md, and update change status
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Close the gap between what a change proposal calls for and what the codebase currently implements. Read `changes/{NNN-name}/spec.md` and `changes/{NNN-name}/tasks.md` as the sole sources of intent, assess the current state of the code, and append any remaining work as new tasks.

If a `plan.md` exists in the change directory, also assess against plan decisions and architecture choices. If `plan.md` is absent, proceed with spec + tasks only — this change may not require a full plan.

If converged, run the test gate, diff analysis, 4-pillar quality assessment, and write a unified `verify.md` evidence bundle — same verification rigor as `spec.converge`.

## Operating Constraints

**APPEND-ONLY**: The command's only write is appending a `## Phase N: Convergence` section to `tasks.md`. It MUST NOT modify `spec.md` or `plan.md` (except the `Status:` field when converged), rewrite or reorder existing tasks, or modify application code.

When the codebase already satisfies everything, leave `tasks.md` byte-for-byte unchanged and report a clean result.

**Constitution Authority**: If `{REPO_ROOT}/.specify/memory/constitution.md` exists, load it for governance constraints. If the implementation violates a constitution principle, it must be flagged as a verification failure regardless of other checks.

## Execution Steps

### 1. Load Change Context

Ask the user which change to converge (if not specified). Load:

- `CHANGE_DIR = changes/{NNN-name}/`
- `SPEC = CHANGE_DIR/spec.md` — original goal, success criteria, requirements
- `TASKS = CHANGE_DIR/tasks.md` — current task list
- `PLAN = CHANGE_DIR/plan.md` — if present, load plan decisions and design references
- `CONSTITUTION = {REPO_ROOT}/.specify/memory/constitution.md` (if present)

If `spec.md` or `tasks.md` is missing, STOP with a clear, actionable message.

### 2. Build the Intent Inventory

For each success criterion, functional requirement, and plan decision (if plan.md present), determine whether the current code satisfies it:

- **Satisfied**: The requirement is met in the code.
- **Missing**: The work is absent.
- **Partial**: Some aspects are done, some remain.
- **Contradicts**: The code conflicts with stated intent.

### 3. Present Findings

Output a compact summary of any gaps found:

## Convergence Findings

| ID | Gap Type | Source | Evidence | Remaining Work |
|----|----------|--------|----------|----------------|

**Summary metrics:**

- Requirements / acceptance criteria checked
- Plan decisions checked (if plan.md present)
- Constitution principles checked (or "skipped — none")
- Findings by gap type (missing / partial / contradicts / unrequested)
- Findings by severity

### 4. Append Convergence Tasks (or report converged)

**If gaps exist** (`tasks_appended` outcome):

Append a `## Phase N: Convergence` section to `tasks.md` with one checklist item per gap, ordered by severity (CRITICAL/HIGH first). Follow the same append-only contract as `spec.converge`:

- Scan existing task IDs; let M be the maximum. Next phase N = highest existing + 1.
- One checklist item per finding: `- [ ] T{M+1:03d} {description} per {source-ref} ({gap-type})`
- Never reuse or renumber existing IDs.

**Output the outcome token as the first line of stdout**: print `tasks_appended` on its own line before any other output. Do NOT proceed to verification phases.

**If converged** (`converged` outcome):

Do not modify `tasks.md`. Report: **"Converged — the implementation satisfies the change spec."**

Include the summary counts of what was checked.

**Proceed to the verification phases below.**

### 5. Test Gate

**Tests MUST pass before assessment.** Run the project's test suite:

1. Detect available test runners (search for `package.json` scripts, `pytest.ini`, `Cargo.toml`, `Makefile`, etc.)
2. Run tests once:
   - If tests pass → proceed to Diff Analysis
   - If tests fail → append a task "Fix failing tests" to `tasks.md` under a new `## Phase N: Convergence` section, output `tasks_appended` as the first stdout line, and STOP. Do NOT continue to Diff Analysis or 4-Pillar Assessment until tests pass.

### 6. Diff Analysis

Read `git diff` to understand what changed:

1. Run `git diff HEAD --name-only` (or `git diff --name-only` if no commits yet) to identify changed files
2. Categorize changes:
   - **Change-spec files** under `CHANGE_DIR/`
   - **Implementation files** (source code, configs)
   - **Test files**
   - **Documentation files**

### 7. 4-Pillar Assessment

Assess the change against four pillars. For each, produce a score (0-100), evidence, and specific findings.

#### Pillar 1: Spec Compliance

Compare implementation against the full change spec in `CHANGE_DIR/spec.md`:

- **Goal alignment** — Does the implementation achieve the change goal?
- **Success Criteria coverage** — Are all SC items met?
- **Constraint adherence** — Are all Constraints respected?
- **Functional Requirements** — Are all FR items addressed? (cite each: ✅ FR-NNN or ❌ FR-NNN)
- **Delta description** — Are ADDED/MODIFIED/REMOVED items all reflected in the code?

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

### 8. Read Available Evidence Sources

Before writing the verification report, check for and read these optional artifacts produced by other extensions/commands:

- `CHANGE_DIR/tdd-quality-report.md` — TDD test quality score (produced by the `tdd` extension's `after_implement` hook)
- `CHANGE_DIR/evidence.md` — EDD evidence dossier (produced by the `edd` extension's `after_converge` hook on a previous loop iteration; absent on the first converge run)
- `CHANGE_DIR/trace.md` — Execution trace (produced by `spec.trace`, if run)
- `CHANGE_DIR/checklists/` — Checklist results (produced by `spec.checklist`, if run)

For each source:
- If present → extract: score/findings, what was checked, what was not checked, residual risks
- If absent → note as "not available" — this will appear in the What Was NOT Checked section

### 9. Write Verification Report

Write to `CHANGE_DIR/verify.md`:

```markdown
# Verification Report: [Change Name]

**Change**: `{NNN-name}`
**Generated**: [ISO timestamp]
**Spec Kit**: [CLI version] | **Preset**: [name + version]

## Intent

**Mission Brief** (from `spec.md`):
- **Goal**: [change goal]
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
- **Categories**: [Change-spec: N, Implementation: N, Tests: N, Docs: N]

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

**IMPORTANT**: If `CHANGE_DIR` is not set, output the report inline instead of writing to a file.

If any pillar score is below 70, append remediation tasks to `tasks.md` under a new `## Phase N: Convergence` section, and output `tasks_appended` as the first stdout line instead of `converged`.

### 10. Verify Success Criteria and Requirements

For each success criterion from spec.md:
- **PASS**: Criterion met based on implementation evidence
- **FAIL**: Criterion not met — describe what's missing

For each functional requirement:
- **PASS**: Requirement implemented and demonstrable
- **FAIL**: Gap identified — describe what's missing

### 11. Status Decision

| Condition | Status |
|-----------|--------|
| All criteria + requirements pass + all pillars >= 70 | **Completed** |
| Some fail | **Active** — document gaps |

### 12. Update spec.md

Update the `Status:` field in `changes/{NNN-name}/spec.md`:
- `Active` → `Completed` (if all pass)
- Or leave as `Active` with note on remaining gaps

### 13. Report

```markdown
## Verification: {NNN-name}

**Status**: {Completed / Active}

| Criterion | Result |
|-----------|--------|
| {criterion 1} | ✓ PASS |
| {criterion 2} | ✓ PASS |
| {criterion 3} | ✗ FAIL |

**4-Pillar Overall**: [X]/100 — ✅ VERIFIED / ❌ NOT VERIFIED

**Summary**: {N}/{M} criteria passed
```

If **Completed**, suggest:
```
Change verified and converged. Run /change.levelup to contribute lessons from this change.
```

### 14. Next Actions (Handoff)

- On `tasks_appended`: state how many tasks were appended under which phase, and recommend
  running `__SPECKIT_COMMAND_IMPLEMENT__` to complete them; note that a follow-up converge
  run will find fewer or no remaining items.
- On `converged`: report that the change is fully converged and verified. No further
  implement pass is needed for this change's specified scope.

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

   **Loop routing signal**: The caller should check for `next-spec.md` in the change directory:
   - If `next-spec.md` exists → the spec itself needs correction; route to `__SPECKIT_COMMAND_SPECIFY__` (feeding next-spec.md as input), then plan → tasks → implement → converge
   - If `next-spec.md` does not exist but `tasks_appended` → only implementation tasks were appended; route to `__SPECKIT_COMMAND_IMPLEMENT__` → converge
6. If no hooks registered, skip silently.
