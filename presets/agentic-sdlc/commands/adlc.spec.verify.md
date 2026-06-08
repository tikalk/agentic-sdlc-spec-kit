---
description: Generate a feature verification evidence dossier from the mission brief and available feature artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Generate a feature-local verification dossier at `specs/{branch}/evidence.md` that maps the approved Mission Brief to the actual evidence available in the feature artifacts.

This command is invoked as `/spec.verify`.

This command answers five questions in one place:

1. What did we intend to build?
2. What did we actually check?
3. What did we not check?
4. What risks remain?
5. Which harness produced this evidence?

## Operating Constraints

- Write exactly one feature-local artifact: `FEATURE_DIR/evidence.md`
- Be conservative: if proof is missing, mark the item as `Not Validated`
- Do not invent evidence from implication or stylistic confidence
- Prefer explicit artifact citations over narrative claims
- Use the Mission Brief (`Goal`, `Success Criteria`, `Constraints`) as the organizing frame

## Execution Steps

### 1. Resolve Feature Context

Run `{SCRIPT}` once from repo root and parse JSON for `FEATURE_DIR` and `AVAILABLE_DOCS`.

Derive absolute paths:

- `SPEC = FEATURE_DIR/spec.md`
- `PLAN = FEATURE_DIR/plan.md`
- `TASKS = FEATURE_DIR/tasks.md`
- `TRACE = FEATURE_DIR/trace.md`
- `EVIDENCE = FEATURE_DIR/evidence.md`
- `TASKS_META = FEATURE_DIR/tasks_meta.json`
- `CHECKLIST_DIR = FEATURE_DIR/checklists/`

Abort if `spec.md` is missing.

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

Optional sources may strengthen evidence but are not required:

- `evals/results/` outputs if present
- architecture/product outputs if present and directly relevant

### 4. Build a Verification Model

Construct an internal model with these dimensions:

- **Goal validation summary**: whether there is direct evidence that the core objective was achieved
- **Success Criteria map**: one row per criterion with status `Validated`, `Partially Validated`, or `Not Validated`
- **Constraint map**: one row per constraint with status `Validated`, `Manual / Assumed`, or `Not Validated`
- **Checked evidence list**: concrete artifact-backed proof that exists
- **Unchecked evidence list**: expected evidence that is missing
- **Residual risks**: explicit unresolved concerns
- **Provenance**: CLI/preset generation context

### 5. Status Assignment Rules

Use strict rules:

#### Goal

- `Validated` only if multiple strong sources support the outcome (for example, completed tasks plus trace summary)
- `Partially Validated` if implementation evidence exists but proof is incomplete
- `Not Validated` if there is no direct supporting artifact

#### Success Criteria

- `Validated` when explicitly supported by a concrete source such as `trace.md`, `tasks_meta.json`, checklist findings, or evaluator results
- `Partially Validated` when there is implementation evidence but no direct verification proof
- `Not Validated` when no artifact supports the criterion

#### Constraints

- `Validated` only when an artifact explicitly confirms the constraint was checked
- `Manual / Assumed` when the constraint appears respected but no proof exists
- `Not Validated` when no validation path is visible

### 6. Generate `evidence.md`

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

### 7. Evidence Requirements

- Every success criterion must appear in the validation table
- Every constraint must appear in the validation table
- If no checklist, no trace, or no task metadata exists, say so explicitly
- `What Was Not Checked` must never be empty if any item is only partially validated or not validated
- `Residual Risks` must include missing Mission Brief fields, missing trace, missing task metadata, and manual-only validation areas when applicable

### 8. Provenance

For V1 provenance, include at minimum:

- CLI version from the current fork release
- Preset version from `preset.yml`
- current UTC timestamp

### 9. Report Back

After writing the file, summarize:

- path written
- number of validated / partially validated / not validated success criteria
- number of validated / manual / not validated constraints
- count of residual risks

## Notes

- This is a verification dossier, not another analysis report
- This command complements `spec.checklist`, `spec.analyze`, and `spec.trace`
- `spec.verify` produces the proof record; it does not replace the tools that generate the proof
