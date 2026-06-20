---
description: Execute tasks from a change proposal
handoffs:
  - label: Verify Change Completion
    agent: adlc.change.verify
    prompt: Verify the completed implementation against the change specification
scripts:
  sh: |
    for path in "$(pwd)/.specify/scripts/bash/common.sh" "$(dirname "$(pwd)")/scripts/bash/common.sh"; do
        [[ -f "$path" ]] && source "$path" 2>/dev/null && break
    done
    REPO_ROOT=$(get_repo_root 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)
    echo "REPO_ROOT='$REPO_ROOT'"
  ps: |
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $commonPath = Join-Path $scriptDir "..\..\..\scripts\powershell\common.ps1"
    if (Test-Path $commonPath) { . $commonPath }
    $repoRoot = Get-RepoRoot
    "REPO_ROOT='$repoRoot'"
---

## MANDATORY: Pre-Execution Hooks

**STOP. Before reading User Input or doing ANY other work, execute extension hooks.**

1. If `.specify/extensions.yml` does not exist, state `No hooks file found` and skip to User Input.
2. Read `.specify/extensions.yml` and find `hooks.before_implement`.
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

## Implementation

### 1. Load Change Context

Ask the user which change to implement (if not specified in arguments). Load the change directory:
- `changes/{NNN-name}/spec.md` (required) — goal, requirements, delta description
- `changes/{NNN-name}/plan.md` (if exists) — technical approach, decisions
- `changes/{NNN-name}/tasks.md` (required) — task checklist

### 2. Execute Tasks

For each task in tasks.md (in order):
1. **Before task**: Check `.specify/extensions.yml` for `hooks.before_task_execute`. Filter out disabled hooks. Execute mandatory hooks immediately; for optional hooks, skip silently. If no hooks registered, continue silently.
2. **Execute** the task — make the required code changes
3. **Mark task complete** — update `tasks.md` checkbox from `[ ]` to `[x]`
4. **After task**: Check `.specify/extensions.yml` for `hooks.after_task_execute`. Same dispatch logic as before_task_execute.

On task failure:
1. Dispatch `after_task_execute` hooks (allows WIP checkpoint)
2. Display error and ask: retry, skip, or stop?

### 3. Completion

Display summary:
```
Change Implementation Complete

Tasks: 3/3 completed
Files modified: {count}
Change: changes/{NNN-name}/

Next step: /change.verify
```

---

## Post-Execution Hooks

1. If `.specify/extensions.yml` does not exist, skip silently.
2. Read `hooks.after_implement`.
3. Skip hooks with `enabled: false` or non-empty `condition`.
4. For each remaining hook:
   - **Mandatory** (`optional: false`): Read the command file for `{command}`. **First, read the extension's `extension.yml` manifest** and look up the `provides.commands` entry matching `{command}` to get the `file` field. Use that `file` path relative to the extension directory. If the manifest cannot be read, fall back to looking for `{command}.md` directly in the extension commands directory. Execute the command file's full instructions immediately.
   - **Optional** (`optional: true`): Display hook info for user decision.
5. If no hooks registered, skip silently.
