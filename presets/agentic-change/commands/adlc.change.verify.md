---
description: Verify change completeness against the change specification
handoffs:
  - label: Extract Lessons from This Change
    agent: adlc.change.levelup
    prompt: Run levelup to extract reusable patterns and CDRs from this completed change
    send: true
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

1. If `.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `.specify/extensions.yml` and find `hooks.before_verify`.
3. Skip any hook with `enabled: false`. Skip any hook with a non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`): Read the command file for `{command}`. **First, read the extension's `extension.yml` manifest** and look up the `provides.commands` entry matching `{command}` to get the `file` field. Use that `file` path relative to the extension directory. If the manifest cannot be read, fall back to looking for `{command}.md` directly in the extension commands directory. Execute the command file's full instructions NOW before continuing.
   - **Optional** (`optional: true`): Display the hook name, command, and description. Let the user decide.
5. State which hooks were executed, then proceed to User Input.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## Verification

### 1. Load Change Context

Ask the user which change to verify (if not specified). Load:
- `changes/{NNN-name}/spec.md` — original goal, success criteria, requirements

### 2. Verify Each Success Criterion

For each success criterion from spec.md:
- **PASS**: Criterion met based on implementation evidence
- **FAIL**: Criterion not met — describe what's missing

### 3. Verify Requirements

For each functional requirement:
- **PASS**: Requirement implemented and demonstrable
- **FAIL**: Gap identified — describe what's missing

### 4. Status Decision

| Condition | Status |
|-----------|--------|
| All criteria + requirements pass | **Completed** |
| Some fail | **Active** — document gaps |

### 5. Update spec.md

Update the `Status:` field in `changes/{NNN-name}/spec.md`:
- `Active` → `Completed` (if all pass)
- Or leave as `Active` with note on remaining gaps

### 6. Report

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
Change verified. Run /change.levelup to contribute lessons from this change.
```

---

## Post-Execution Hooks

1. If `.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_verify`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`): Read the command file for `{command}`. **First, read the extension's `extension.yml` manifest** and look up the `provides.commands` entry matching `{command}` to get the `file` field. Use that `file` path relative to the extension directory. If the manifest cannot be read, fall back to looking for `{command}.md` directly in the extension commands directory. Execute the command file's full instructions immediately.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
