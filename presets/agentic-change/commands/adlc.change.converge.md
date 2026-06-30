---
description: Assess the change scope against the change spec and tasks, then append any remaining work as new tasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Close the gap between what a change proposal calls for and what the codebase currently implements. Read `changes/{NNN-name}/spec.md` and `changes/{NNN-name}/tasks.md` as the sole sources of intent, assess the current state of the code, and append any remaining work as new tasks.

If a `plan.md` exists in the change directory, also assess against plan decisions and architecture choices. If `plan.md` is absent, proceed with spec + tasks only — this change may not require a full plan.

## Operating Constraints

**APPEND-ONLY**: The command's only write is appending a `## Phase N: Convergence` section to `tasks.md`. It MUST NOT modify `spec.md` or `plan.md`, rewrite or reorder existing tasks, or modify application code.

When the codebase already satisfies everything, leave `tasks.md` byte-for-byte unchanged and report a clean result.

## Execution Steps

### 1. Load Change Context

Ask the user which change to converge (if not specified). Load:

- `changes/{NNN-name}/spec.md` — original goal, success criteria, requirements
- `changes/{NNN-name}/tasks.md` — current task list
- `changes/{NNN-name}/plan.md` — if present, load plan decisions and design references

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

### 4. Append Convergence Tasks (or report converged)

**If gaps exist**: Append a `## Phase N: Convergence` section to `tasks.md` with one checklist item per gap, ordered by severity.

**If converged**: Do not modify `tasks.md`. Report: **"Converged — the implementation satisfies the change spec."**

### 5. Next Actions

- On `tasks_appended`: recommend running `__SPECKIT_COMMAND_IMPLEMENT__` to complete remaining work.
- On `converged`: recommend proceeding to verification (run `/change.verify`).
