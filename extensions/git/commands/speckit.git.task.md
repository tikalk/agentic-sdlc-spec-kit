---
description: "Execute a single task on an isolated task branch within a feature worktree (worktree mode only)"
---

# Execute Task in Worktree

Create or resume a task branch in the current feature worktree and dispatch the task work to a subagent. This command is **worktree-mode only** — it requires that the current repository state is a worktree created by `git.feature` (use `git.feature --worktree` first if you are not already in a worktree).

## User Input

```text
$ARGUMENTS
```

The first argument MUST be a task ID matching `^T[0-9]+$` (e.g., `T007`, `T042`). Additional positional arguments are passed through to the dispatched subagent as the task description.

## Prerequisites

- Verify you are inside a feature worktree by checking the script:
  - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh is-in-worktree`
  - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 is-in-worktree`
  - Exit code `0` means primary checkout (NOT a worktree — refuse to run).
  - Exit code `2` means inside a feature worktree (proceed).
- If NOT in a worktree, abort with: `[error] git.task requires worktree isolation. Run \`git.feature --worktree\` first, then \`cd\` into the returned WORKTREE_PATH and re-invoke.`
- Verify the feature manifest exists at `.git.worktree-manifest.json` in the worktree root. The `is-in-worktree` script also prints `FEATURE` and `MANIFEST_PATH` to stdout for the agent to use.

## Task Branch Naming

The task branch follows the pattern `{feature}--task-{id}-{task-slug}` where:
- `{feature}` is the current feature branch name (e.g., `003-user-auth`)
- `{id}` is the task ID with the leading `T` stripped (e.g., `T007` -> `7`)
- `{task-slug}` is a 2-4 word kebab-cased summary derived from the task title

Example: feature `003-user-auth` + task `T007` + title "Add OAuth provider" -> branch `003-user-auth--task-7-add-oauth-provider`

## Execution

1. **Create the task branch** (idempotent — skip if it already exists):
   - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh create-task-branch --feature <FEATURE> --task-id <TNNN> --task-slug <task-slug>`
   - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 create-task-branch -Feature <FEATURE> -TaskId <TNNN> -TaskSlug <task-slug>`
2. **Check out the task branch** in the current worktree:
   - `git checkout <task-branch>` (the worktree's working dir is the same as the feature worktree)
3. **Dispatch the task work to a subagent** with a generic prompt containing:
   - The task ID, title, file list, and execution wave (from `.tasks_dag.json` if it exists)
   - The task branch name (so the subagent can include it in commit subjects)
   - Instructions to commit work with `[TNNN]`-prefixed messages (use `auto-commit.sh` with `--mode parallel --task-id <TNNN>` or `SPECKIT_TASK_MODE=parallel SPECKIT_TASK_ID=<TNNN>`)
4. **Record the task branch** in the manifest:
   - The `create-task-branch` script already records the branch in the manifest on creation. Verify with:
     - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh read-manifest`
     - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 read-manifest`
5. **Switch back to the feature branch** when the subagent returns (or when the user moves on):
   - `git checkout <FEATURE>` (so subsequent commands in the worktree see the integrated state)

## Output

The agent should report back with:
- Task ID and title
- Task branch name (for later use with `git.task-merge`)
- Commit list (subjects + SHAs) made on the task branch
- Any conflicts or failures encountered (delegate resolution to a subagent via `git.task-merge`)

## Graceful Degradation

- If Git is not available: abort with a clear error.
- If not in a worktree: abort with the message in Prerequisites.
- If the manifest is missing or corrupt: abort and ask the user to recreate the worktree.
- If `create-task-branch` fails (e.g., manifest is read-only): abort and surface the script's stderr.
