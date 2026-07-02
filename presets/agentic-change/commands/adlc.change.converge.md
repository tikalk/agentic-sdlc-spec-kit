---
description: Assess change scope against spec and tasks; append remaining work, or if converged, verify criteria and update change status
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

**APPEND-ONLY**: The command's only write is appending a `## Phase N: Convergence` section to `tasks.md`. It MUST NOT modify `spec.md` or `plan.md` (except the `Status:` field when converged), rewrite or reorder existing tasks, or modify application code.

When the codebase already satisfies everything, leave `tasks.md` byte-for-byte unchanged and report a clean result.

**Constitution Authority**: If `{REPO_ROOT}/.specify/memory/constitution.md` exists, load it for governance constraints. If the implementation violates a constitution principle, it must be flagged as a verification failure regardless of other checks.

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

**If gaps exist** (`tasks_appended` outcome):

Append a `## Phase N: Convergence` section to `tasks.md` with one checklist item per gap, ordered by severity.

**Output the outcome token as the first line of stdout**: print `tasks_appended` on its own line before any other output. Do NOT proceed to verification.

**If converged** (`converged` outcome):

Do not modify `tasks.md`. Report: **"Converged — the implementation satisfies the change spec."**

**Proceed to verification below.**

### 5. Verify Each Success Criterion

For each success criterion from spec.md:
- **PASS**: Criterion met based on implementation evidence
- **FAIL**: Criterion not met — describe what's missing

### 6. Verify Requirements

For each functional requirement:
- **PASS**: Requirement implemented and demonstrable
- **FAIL**: Gap identified — describe what's missing

### 7. Status Decision

| Condition | Status |
|-----------|--------|
| All criteria + requirements pass | **Completed** |
| Some fail | **Active** — document gaps |

### 8. Update spec.md

Update the `Status:` field in `changes/{NNN-name}/spec.md`:
- `Active` → `Completed` (if all pass)
- Or leave as `Active` with note on remaining gaps

If any criteria or requirements fail, append remediation tasks to `tasks.md` and output `tasks_appended` as the first stdout line instead of `converged`.

### 9. Report

```markdown
## Verification: {NNN-name}

**Status**: {Completed / Active}

| Criterion | Result |
|-----------|--------|
| {criterion 1} | ✓ PASS |
| {criterion 2} | ✓ PASS |
| {criterion 3} | ✗ FAIL |

**Summary**: {N}/{M} criteria passed
```

If **Completed**, suggest:
```
Change verified and converged. Run /change.levelup to contribute lessons from this change.
```

### 10. Next Actions

- On `tasks_appended`: recommend running `__SPECKIT_COMMAND_IMPLEMENT__` to complete remaining work.
- On `converged`: report that the change is fully converged and verified.

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
5. **Post-hook override**: After running all `after_converge` hooks, if any mandatory hook reported failures or generated correction artifacts, output `tasks_appended` as the first stdout line to signal more work is needed, overriding the initial `converged` assessment.
6. If no hooks registered, skip silently.
