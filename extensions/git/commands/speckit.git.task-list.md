---
description: "List active task branches in the current feature worktree (worktree mode only)"
---

# List Task Branches

Show the active task branches registered in the current feature worktree's manifest, along with their commit counts relative to the feature branch. This command is **worktree-mode only** — it reads the worktree manifest which only exists in worktree mode.

## User Input

```text
$ARGUMENTS
```

No required arguments. Optional flags:
- `--json` (Bash) / `-Json` (PowerShell): emit a machine-readable JSON array of objects (one per task branch) instead of the default human-readable table.
- `--ids-only` (Bash) / `-IdsOnly` (PowerShell): emit just the task IDs (one per line), suitable for piping into `xargs` or `ForEach-Object`.

## Prerequisites

- Verify you are inside a feature worktree (see `git.task` for the `is-in-worktree` check).
- If NOT in a worktree, abort with: `[error] git.task-list requires worktree isolation. Run \`git.feature --worktree\` first.`

## Execution

Read the manifest and format the output:

1. **Read the manifest**:
   - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh read-manifest`
   - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 read-manifest`
2. **For each task branch in `task_branches[]`**:
   - Compute the commit count ahead of the feature branch: `git rev-list --count <FEATURE>..<task-branch>`
   - Compute the commit count behind: `git rev-list --count <task-branch>..<FEATURE>`
   - Optionally include the most recent commit subject: `git log -1 --format=%s <task-branch>`
3. **Format the output**:
   - Default (no flags): a table with columns `TASK_ID`, `BRANCH`, `AHEAD`, `BEHIND`, `LAST_COMMIT`
   - `--json` / `-Json`: `[{id, branch, ahead, behind, last_commit}]`
   - `--ids-only` / `-IdsOnly`: `T001\nT002\n...` (one ID per line, in manifest order)

## Output Examples

Default (human-readable table):

```text
TASK_ID  BRANCH                                    AHEAD  BEHIND  LAST_COMMIT
T007     003-user-auth--task-7-add-oauth-provider     3       0  [T007] Add OAuth provider config
T008     003-user-auth--task-8-add-token-endpoint     1       0  [T008] Add /token endpoint
T012     003-user-auth--task-12-add-user-migration    0       2  [T012] Migration scaffold
```

`--json`:

```json
[{"id": "T007", "branch": "003-user-auth--task-7-add-oauth-provider", "ahead": 3, "behind": 0, "last_commit": "[T007] Add OAuth provider config"}]
```

`--ids-only`:

```text
T007
T008
T012
```

## Graceful Degradation

- If Git is not available: abort.
- If not in a worktree: abort (see Prerequisites).
- If the manifest is empty (`task_branches: []`): print a friendly message and exit 0: `[ok] No active task branches in this worktree.`
