---
description: "Run deterministic + AI evaluation, grade quality gates, write evidence.md, grade.json, and next-prompt.md"
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

Run a unified evaluation of the current feature implementation. This command performs three phases:

1. **Deterministic checks**: lint, tests, smoke (via bundled scripts)
2. **AI-driven evaluation**: verify Mission Brief against artifacts, map evidence, check oracle adequacy, analyze findings
3. **Grade & Prompt**: aggregate into a structured grade; on failure, generate a corrective `next-prompt.md`

This command is invoked as `/edd.verify`.

## Operating Constraints

- Write exactly three feature-local artifacts:
  - `FEATURE_DIR/evidence.md` — verification dossier (human-readable)
  - `FEATURE_DIR/.eval/grade.json` — structured machine verdict (exit code relay)
  - `FEATURE_DIR/next-prompt.md` — corrective prompt (only on FAIL)
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
- `GRADE = EVAL_DIR/grade.json`
- `NEXT_PROMPT = FEATURE_DIR/next-prompt.md`

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

## Provenance

- CLI Version: ...
- Preset Version: ...
- Generated At: ...
```

### 9. Write `grade.json`

Write `FEATURE_DIR/.eval/grade.json` with this exact schema:

```json
{
  "schema_version": "1.0",
  "eval_timestamp": "2026-06-14T10:00:00Z",
  "feature": "003-user-auth",
  "verdict": "PASS",
  "score": "6/6 (100%)",
  "threshold": "6/6 (100%)",
  "deterministic_passed": true,
  "ai_passed": true,
  "gates": [
    {
      "id": "lint",
      "type": "deterministic",
      "description": "Lint checks pass",
      "status": "PASS",
      "detail": "0 errors, 2 warnings"
    },
    {
      "id": "tests",
      "type": "deterministic",
      "description": "All tests pass",
      "status": "PASS",
      "detail": "42 pass, 0 fail, 85% coverage"
    },
    {
      "id": "oracle",
      "type": "ai",
      "description": "Mission Brief oracle adequacy",
      "status": "PASS",
      "detail": "6/6 (100%)"
    },
    {
      "id": "evidence",
      "type": "ai",
      "description": "All Success Criteria validated",
      "status": "PASS",
      "detail": "3/3 SCs validated"
    },
    {
      "id": "criticals",
      "type": "ai",
      "description": "No CRITICAL/HIGH findings",
      "status": "PASS",
      "detail": "0 critical, 0 high"
    }
  ],
  "next_prompt_file": "next-prompt.md"
}
```

If FAIL, set `verdict` to `"FAIL"`, `deterministic_passed` or `ai_passed` to `false` as appropriate, and populate the failing gates.

### 10. Generate `next-prompt.md` (on FAIL only)

If `verdict` is `"FAIL"`, write `FEATURE_DIR/next-prompt.md` with a self-contained corrective prompt. This prompt should be suitable for feeding directly into `spec.specify` as if it were a fresh feature request.

Structure:

```markdown
# Corrective Prompt — Iteration [N]

## Failed Gates

- [Gate ID]: [description] — [detail]
- ...

## Action Items

1. [Specific action to fix gate 1]
2. [Specific action to fix gate 2]
3. ...

## Context

- Feature: [feature name]
- Previous iteration artifacts: [list key artifacts]
- Keep: [what was working and should be preserved]
- Fix: [what specifically needs to change]

## Revised Feature Request

[Write a concise, self-contained feature request that incorporates the fixes above. This should read like a fresh user prompt to spec.specify, but informed by what we've learned.]
```

If `verdict` is `"PASS"`, delete `next-prompt.md` if it exists (the loop is done).

### 11. Report Back

After writing all files, summarize:

- path written (`evidence.md`, `grade.json`, `next-prompt.md` if applicable)
- verdict (PASS or FAIL)
- score (e.g., "5/6 (83%)")
- which gates passed and which failed, with detail
- count of residual risks

## Exit Code

- **0** if `verdict` is `"PASS"`
- **1** if `verdict` is `"FAIL"`

## Notes

- This command replaces the old `spec.verify` preset command
- It produces both the human-readable evidence dossier AND the machine-readable grade for workflow loops
- The `next-prompt.md` is the bridge that enables loop-driven development: on failure, feed it back to `spec.specify` for the next iteration
