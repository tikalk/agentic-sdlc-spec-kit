---
description: "Run deterministic + AI evaluation, grade quality gates, append actionable tasks, update verify.md, write evidence.md, loop-state.yml, and next-spec.md"
scripts:
  sh: .specify/extensions/edd/scripts/bash/run-deterministic.sh
  ps: .specify/extensions/edd/scripts/powershell/run-deterministic.ps1
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Run a unified evaluation of the current feature implementation. This command performs five phases:

1. **Deterministic checks**: lint, tests, smoke (via bundled scripts)
2. **AI-driven evaluation**: verify Mission Brief against artifacts, map evidence, check oracle adequacy, analyze findings
3. **Grade & Prompt**: aggregate into a structured grade; on failure, classify findings as actionable (→ tasks.md) or spec-level (→ next-spec.md)
4. **Append Actionable Tasks**: append implementation-level verification gaps to `tasks.md` following converge's append-only contract
5. **Update verify.md**: fill EDD placeholder sections in converge's `verify.md`, making it the unified evidence bundle

This command is invoked as `/edd.verify`.

## Operating Constraints

- Write feature-local artifacts:
  - `FEATURE_DIR/evidence.md` — verification dossier (human-readable)
  - `FEATURE_DIR/.eval/loop-state.yml` — structured machine state spine with history (replaces grade.json)
  - `FEATURE_DIR/next-spec.md` — spec-level corrections for `spec.specify` (only on FAIL, spec-level issues)
  - `FEATURE_DIR/tasks.md` — append actionable verification tasks (only on FAIL, implementation-level issues)
  - `FEATURE_DIR/verify.md` — update EDD placeholder sections (always, when verify.md exists)
- **APPEND-ONLY to tasks.md**: follow converge's append-only contract — append a new `## Phase N: EDD` section; never rewrite, renumber, or delete existing tasks
- Be conservative: if proof is missing, mark the item as `Not Validated`
- Do not invent evidence from implication or stylistic confidence
- Prefer explicit artifact citations over narrative claims
- Use the Mission Brief (`Goal`, `Success Criteria`, `Constraints`) as the organizing frame

## Execution Steps

### 0. Resolve Feature Context

Determine the feature directory path (`FEATURE_DIR`). Features live under `specs/<branch-name>/` — list `specs/` in the repo root to find it. Use the AI tool `Bash` or `Glob` to locate the active feature directory.

Once identified, list the feature directory contents and derive these absolute paths:

- `SPEC = FEATURE_DIR/spec.md`
- `PLAN = FEATURE_DIR/plan.md`
- `TASKS = FEATURE_DIR/tasks.md`
- `TRACE = FEATURE_DIR/trace.md`
- `EVIDENCE = FEATURE_DIR/evidence.md`
- `TASKS_META = FEATURE_DIR/tasks_meta.json`
- `CHECKLIST_DIR = FEATURE_DIR/checklists/`
- `EVAL_DIR = FEATURE_DIR/.eval/`
- `LOOP_STATE = EVAL_DIR/loop-state.yml`
- `NEXT_SPEC = FEATURE_DIR/next-spec.md`
- `VERIFY = FEATURE_DIR/verify.md`
- `TASKS = FEATURE_DIR/tasks.md`

Create `EVAL_DIR` if it does not exist.

### 1. Run Deterministic Checks

If `{SCRIPT}` is available, run it to produce `.eval/deterministic.json`. If not, skip this step gracefully.

The deterministic script runs (when enabled in config):
- **Lint**: project linter, captured as pass/fail + error count
- **Tests**: test runner, captured as pass/fail + pass count + fail count + coverage %
- **Smoke**: smoke/E2E runner, captured as pass/fail + scenario count

Expected output from the script (if present):
```json
{
  "lint": {"passed": true, "errors": 0, "warnings": 2},
  "tests": {"passed": true, "pass_count": 42, "fail_count": 0, "coverage": 85},
  "smoke": {"passed": true, "scenarios": 3}
}
```

If the script is not available or fails, note the failure in the grade but continue with AI evaluation.

### 2. Load Mission Brief

From the top of `spec.md`, extract:

- `Goal`
- `Success Criteria`
- `Constraints`

If any section is missing, note that explicitly in the output under **Residual Risks**.

### 3. Load Available Evidence Sources

Read only the minimum required context from:

- `spec.md`
- `plan.md` if present
- `tasks.md` if present
- `trace.md` if present
- `tasks_meta.json` if present
- checklist files under `checklists/` if present
- `.eval/deterministic.json` if present

Optional sources may strengthen evidence but are not required:

- `evals/results/` outputs if present
- architecture/product outputs if present and directly relevant

### 4. Read Quality Gates (from spec or config)

Check if `spec.md` contains a `## Quality Gates` section. If yes, use the gates defined there as the evaluation criteria. If no, use the default gates:

1. All tests pass (deterministic)
2. Code coverage ≥ 80% (deterministic, if available)
3. Oracle adequacy score ≥ 80% (AI-driven)
4. No CRITICAL/HIGH findings (AI-driven)
5. All Success Criteria validated (AI-driven)
6. All Constraints validated (AI-driven)

### 5. Build a Verification Model

Construct an internal model with these dimensions:

- **Goal validation summary**: whether there is direct evidence that the core objective was achieved
- **Success Criteria map**: one row per criterion with status `Validated`, `Partially Validated`, or `Not Validated`
- **Constraint map**: one row per constraint with status `Validated`, `Manual / Assumed`, or `Not Validated`
- **Deterministic checks**: lint, tests, smoke results
- **Checked evidence list**: concrete artifact-backed proof that exists
- **Unchecked evidence list**: expected evidence that is missing
- **Residual risks**: explicit unresolved concerns
- **Provenance**: CLI/preset generation context

### 6. Status Assignment Rules

Use strict rules:

#### Goal

- `Validated` only if multiple strong sources support the outcome (for example, completed tasks plus trace summary)
- `Partially Validated` if implementation evidence exists but proof is incomplete
- `Not Validated` if there is no direct supporting artifact

#### Success Criteria

- `Validated` when explicitly supported by a concrete source such as `trace.md`, `tasks_meta.json`, checklist findings, evaluator results, or deterministic test output
- `Partially Validated` when there is implementation evidence but no direct verification proof
- `Not Validated` when no artifact supports the criterion

#### Constraints

- `Validated` only when an artifact explicitly confirms the constraint was checked
- `Manual / Assumed` when the constraint appears respected but no proof exists
- `Not Validated` when no validation path is visible

### 7. Grade the Gates

For each gate defined in the Quality Gates (from spec or config):

- **Deterministic gates** (lint, tests, smoke):
  - PASS if the deterministic check passed
  - FAIL otherwise, with detail from `.eval/deterministic.json`
- **AI gates** (oracle adequacy, evidence validation, analyze findings):
  - PASS if the corresponding AI evaluation passes the threshold
  - FAIL otherwise, with specific detail

Compute overall verdict:
- **PASS**: ALL gates pass
- **FAIL**: ANY gate fails

Score format: `{pass_count}/{total_gates} ({percentage}%)`

### 7a. Guardrail Checks

After computing the grade, load or create `.eval/loop-state.yml` to extract history. Determine the current iteration number:
- If `loop-state.yml` does not exist, this is **iteration 1**, history is empty
- If it exists, read the `history` array; the current iteration is `last_iteration + 1`

Append the current record to the in-memory history:
```json
{"iteration": 1, "score_pct": 67, "verdict": "FAIL", "timestamp": "2026-06-14T10:00:00Z"}
```

Read `no_progress_threshold` and `max_cost_usd` from `.specify/extensions/edd/edd-config.yml` (or use defaults: threshold=2, cost=20).

**No-progress detection** — if history has at least `threshold + 1` entries:
- Check if the last `threshold` scores are all ≤ the score at position `-(threshold + 1)`
- If yes: override verdict to `"STALL"`. Write escalation section in evidence.md (see section 8). Delete `next-spec.md` if it exists. Stop — do not generate a corrective prompt or append tasks.

**Budget ceiling** — compute cumulative cost as `iteration * 4` (heuristic $4/iteration):
- If cumulative cost exceeds `max_cost_usd`: override verdict to `"BUDGET"`. Write escalation section in evidence.md. Delete `next-spec.md` if it exists. Stop — do not generate a corrective prompt or append tasks.

**Regression detection** — if history has at least 2 entries:
- Compare current `score_pct` with the previous iteration's `score_pct`
- If current < previous: flag `REGRESSION` for use in next-spec.md

The updated history (including the new record) will be written to `loop-state.yml` in section 9.

### 8. Generate `evidence.md`

Write `FEATURE_DIR/evidence.md` with this exact structure:

```markdown
# Feature Evidence: [FEATURE NAME]

**Feature**: `[branch-or-feature-dir]`
**Generated**: [ISO timestamp]
**Spec**: `spec.md`
**Plan**: `plan.md` or `Not Present`
**Tasks**: `tasks.md` or `Not Present`
**Trace**: `trace.md` or `Not Present`

## Mission Brief Summary

**Goal**: ...

**Success Criteria**:
- ...

**Constraints**:
- ...

## Goal Validation

**Status**: Validated | Partially Validated | Not Validated

**Evidence**:
- [artifact citation]

## Success Criteria Validation

| Success Criterion | Status | Evidence Source | Notes |
|-------------------|--------|-----------------|-------|

## Constraint Validation

| Constraint | Status | Validation Type | Notes / Residual Risk |
|------------|--------|-----------------|------------------------|

## Deterministic Checks

| Check | Status | Detail |
|-------|--------|--------|
| Lint | PASS/FAIL | ... |
| Tests | PASS/FAIL | ... |
| Smoke | PASS/FAIL | ... |

## Quality Gates

| Gate | Status | Threshold | Detail |
|------|--------|-----------|--------|

## What Was Checked

- ...

## What Was Not Checked

- ...

## Residual Risks

- ...

## Loop Termination (only present on STALL or BUDGET)

If verdict is STALL or BUDGET, include this section:

```markdown
## Loop Termination

**Status**: STALLED | BUDGET_EXCEEDED

**Reason**: [Explanation of why the loop was terminated — no-progress or budget]

**Iteration**: [N]

**Last Score**: [score]

**History**:
- [iteration 1]: [score] — [verdict]
- [iteration 2]: [score] — [verdict]
- ...

**Recommendation**: [Guidance for the human reviewing this — e.g., "Consider adjusting quality gates, reducing scope, or investigating the root cause of stagnation."]
```

## Provenance

- CLI Version: ...
- Preset Version: ...
- Generated At: ...
```

### 9. Write `loop-state.yml`

Write `FEATURE_DIR/.eval/loop-state.yml` with this exact schema (replaces the old `grade.json`):

```yaml
schema_version: "1.0"
loop:
  id: "sdd-loop-<run-id>"
  started_at: "2026-06-14T10:00:00Z"
  status: "running"           # running | passed | stalled | budget_exceeded
  phase: "verifying"          # specifying | planning | tasking | implementing | verifying
  iteration: 3
exit_conditions:
  max_iterations: 5
  max_cost_usd: 20
current_eval:
  iteration: 3
  score: "5/6 (83%)"
  score_pct: 83
  verdict: "FAIL"             # PASS | FAIL | STALL | BUDGET
  score_threshold: "6/6 (100%)"
  deterministic_passed: true
  ai_passed: false
  next_spec_file: "next-spec.md"
  gates:
    - id: lint
      type: deterministic
      description: "Lint checks pass"
      status: "PASS"
      detail: "0 errors, 2 warnings"
    - id: tests
      type: deterministic
      description: "All tests pass"
      status: "PASS"
      detail: "42 pass, 0 fail, 85% coverage"
    - id: oracle
      type: ai
      description: "Mission Brief oracle adequacy"
      status: "FAIL"
      detail: "4/6 (67%)"
    - id: evidence
      type: ai
      description: "All Success Criteria validated"
      status: "FAIL"
      detail: "2/3 SCs validated"
    - id: criticals
      type: ai
      description: "No CRITICAL/HIGH findings"
      status: "PASS"
      detail: "0 critical, 0 high"
history:
  - iteration: 1
    score_pct: 50
    verdict: "FAIL"
    timestamp: "2026-06-14T10:00:00Z"
  - iteration: 2
    score_pct: 58
    verdict: "FAIL"
    timestamp: "2026-06-14T11:00:00Z"
  - iteration: 3
    score_pct: 83
    verdict: "FAIL"
    timestamp: "2026-06-14T12:00:00Z"
```

If the verdict is `"FAIL"` (not overridden by STALL/BUDGET), populate the failing gates. For STALL or BUDGET, set the appropriate status and skip detailed gate output.

### 10. Classify Findings and Generate `next-spec.md` (on FAIL only)

If `verdict` is `"FAIL"`, classify each failed gate's findings into two categories:

**Actionable (implementation-level)** — these get appended as tasks to `tasks.md` in Phase 4:

| Finding type | Example task |
|---|---|
| Test coverage < threshold | "Add tests for uncovered paths per FR-###" |
| Constraint unvalidated | "Validate constraint C-###: {description}" |
| CRITICAL/HIGH analyze finding | "Fix {finding} per {source-ref}" |
| Specific SC not validated | "Add verification evidence for SC-###" |
| Lint/test failures | "Fix {N} lint errors in {file}" / "Fix {N} failing tests" |

**Spec-level** — these go to `next-spec.md` for `spec.specify`:

| Finding type | Example correction |
|---|---|
| Oracle adequacy < threshold | "Quantify SC-###, add measurable acceptance criteria" |
| Ambiguous requirement | "Clarify FR-###: {what's ambiguous}" |
| Missing success criterion | "Add SC-### for {capability}" |
| Missing constraint | "Add constraint for {uncovered concern}" |

If there are spec-level findings, write `FEATURE_DIR/next-spec.md`:

```markdown
# Next Spec Correction — Iteration [N]

> This file contains spec-level corrections for `spec.specify`.
> Implementation-level fixes were appended directly to tasks.md as tasks.

## Spec-Level Issues

1. [Issue]: [description] — [why the spec is insufficient]
2. ...

## Regression (only if score dropped from previous iteration)

⚠️ **REVERT SUGGESTION**: Score dropped from [X]% (iteration [N-1]) to [Y]% (iteration [N]). Consider reverting the changes from this iteration before continuing.

The following may have caused the regression:
- [List changes that may have caused the regression]

## Revised Feature Request

[Write a concise, self-contained feature request that incorporates the spec-level fixes above. This should read like a fresh user prompt to spec.specify, but informed by what we've learned.]
```

If `verdict` is `"PASS"`, delete `next-spec.md` if it exists (the loop is done).

### 11. Append Actionable Tasks (on FAIL only)

For each actionable finding classified in Step 10, append a task to `tasks.md` following converge's append-only contract.

**Append contract (same as converge):**

1. Read `TASKS` (`FEATURE_DIR/tasks.md`). Scan all existing task IDs; let `M` be the maximum numeric ID. Determine the next phase number `N` (highest existing `## Phase` header + 1).
2. Write a single new section header: `## Phase N: EDD`
3. Emit one checklist item per actionable finding, ordered by severity (CRITICAL/HIGH first):

   ```markdown
   - [ ] T{M+1:03d} {imperative description} per {source-ref} ({gap-type})
   ```

4. `<source-ref>` traces the task to its origin: `SC-###`, `C-###` (constraint), `FR-###`, gate ID, or constitution article.
5. `<gap-type>` is one of `missing` (test/evidence absent), `partial` (incomplete coverage), `contradicts` (fails a constraint), `unrequested` (unexpected finding).
6. **Never reuse or renumber existing IDs.** If a prior `## Phase N: EDD` section exists, add a new, separately-numbered one below it.
7. Do **not** modify `spec.md`, `plan.md`, `verify.md`, or any application code — completing the appended tasks is the job of `__SPECKIT_COMMAND_IMPLEMENT__`.

**If any tasks were appended**, set `tasks_appended = true` for the output signal.

**If verdict is PASS or STALL or BUDGET**, do not append any tasks.

### 12. Update `verify.md` (always, when verify.md exists)

Converge wrote `verify.md` with placeholder sections for EDD. Fill them in now.

Read `VERIFY` (`FEATURE_DIR/verify.md`). If it does not exist, skip this step gracefully (converge may not have written it — e.g., if converge found gaps and stopped before the verification phases).

Locate these placeholder markers and replace their content:

#### EDD Evidence section

Replace `_Pending: EDD verification has not yet run._` with:

```markdown
| Gate | Type | Status | Score | Detail |
|------|------|--------|-------|--------|
| Tests pass | deterministic | ✅/❌ | X/Y | {pass_count} pass, {fail_count} fail |
| Coverage ≥ 80% | deterministic | ✅/❌ | XX% | {coverage}% |
| Lint clean | deterministic | ✅/❌ | X issues | {errors} errors, {warnings} warnings |
| Oracle adequacy ≥ 80% | AI | ✅/❌ | X/6 | {detail} |
| No CRITICAL/HIGH findings | AI | ✅/❌ | X findings | {detail} |
| SC/Constraint validation | AI | ✅/❌ | X/Y validated | {detail} |

**EDD Verdict**: {PASS/FAIL/STALL/BUDGET}
**Score**: {pass_count}/{total_gates} ({percentage}%)
**Tasks Appended**: {count} (or "none")
**next-spec.md**: {written / not needed}
**Iteration**: {N}
```

#### What Was Checked — EDD subsection

Replace the EDD placeholder with:

```markdown
### EDD
- EDD: lint via {linter} — {result}
- EDD: {N} tests run — {pass} passed, {fail} failed
- EDD: coverage — {coverage}%
- EDD: oracle adequacy — {N}/6 items passed ({percentage}%)
- EDD: {N} success criteria validated against evidence
- EDD: {N} constraints validated
- EDD: {N} quality gates passed of {total}
```

#### What Was NOT Checked — EDD subsection

Replace the EDD placeholder with:

```markdown
### EDD
- EDD: {list any gates not run or incomplete, e.g. "smoke tests not configured"}
- EDD: {list any SCs/constraints with insufficient evidence}
- EDD: {list any unvalidated assumptions}
```

If all gates passed and nothing was left unchecked, write: `All EDD gates passed — no unchecked items.`

#### Residual Risks — EDD subsection

Replace the EDD placeholder with:

```markdown
### EDD
- EDD: {risk from failed gate, e.g. "Test coverage at 65% — below 80% threshold"}
- EDD: {unvalidated assumption or constraint}
```

If verdict is PASS, write: `No EDD residual risks — all gates passed.`

#### Provenance — EDD line

Replace the EDD provenance placeholder with:

```markdown
- EDD Version: 1.1.0
- EDD Iteration: {N}
- EDD Verdict: {PASS/FAIL/STALL/BUDGET}
- EDD Score: {pass_count}/{total_gates} ({percentage}%)
```

### 13. Report Back

After writing all files, summarize:

- paths written (`evidence.md`, `loop-state.yml`, `next-spec.md` if applicable, `tasks.md` if tasks appended, `verify.md` if updated)
- verdict (PASS, FAIL, STALL, or BUDGET)
- score (e.g., "5/6 (83%)")
- which gates passed and which failed, with detail
- count of residual risks
- **tasks appended**: count of EDD tasks added to tasks.md (or "none")
- **next-spec.md**: written / not needed (spec-level corrections)
- **verify.md**: updated / skipped (not found)
- if STALL: iteration, last score, threshold, and degradation pattern
- if BUDGET: cumulative cost estimate and ceiling

## Exit Code

- **0** if `verdict` is `"PASS"` — all gates pass, no tasks appended, no next-spec.md
- **1** if `verdict` is `"FAIL"` — tasks appended to tasks.md and/or next-spec.md written
- **2** if `verdict` is `"STALL"` — no progress detected, human intervention needed
- **3** if `verdict` is `"BUDGET"` — budget ceiling hit, human intervention needed

**Loop signal**: If exit code is 1, the caller should check for `next-spec.md`:
- If `next-spec.md` exists → route to `spec.specify` (spec-level correction), then plan → tasks → implement
- If `next-spec.md` does not exist → route to `spec.implement` (task-level correction only)

## Notes

- This command replaces the old `spec.verify` preset command
- `loop-state.yml` is the unified machine state spine — replaces the old `grade.json` and tracks history across iterations
- `next-spec.md` (renamed from `next-prompt.md`) contains only spec-level corrections targeting `spec.specify`; implementation-level fixes are appended directly to `tasks.md` as actionable tasks
- EDD is a convergence partner: it appends tasks to `tasks.md` using the same append-only contract as converge, and fills EDD placeholder sections in converge's `verify.md` to produce a unified evidence bundle
- Guardrails (no-progress, budget, regression) prevent runaway loops per Loop Engineering principles (Van Horn, Osmani, prateek, Campos, Chawla 2026)
- **Loop routing**: `next-spec.md` → `spec.specify` → plan → tasks → implement → converge; `tasks_appended` (no next-spec.md) → implement → converge
