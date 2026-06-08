---
description: "Merge a completed task branch back into the feature branch (worktree mode only)"
---

# Merge Task Branch into Feature

Integrate a task branch's work back into the current feature branch. Run from within the feature worktree (after the task subagent has returned). This command is **worktree-mode only** — the script will refuse to run in a primary checkout.

## User Input

```text
$ARGUMENTS
```

The first argument MUST be a task ID matching `^T[0-9]+$` (e.g., `T007`, `T042`). The task branch is resolved from the manifest using the same `{feature}--task-{id}-{task-slug}` pattern as `git.task`.

## Prerequisites

- Verify you are inside a feature worktree (see `git.task` for the `is-in-worktree` check).
- Verify the task branch exists and is fully committed (`git status --porcelain` is empty on the task branch).
- The feature branch must currently be checked out in the worktree.

## Execution

The preferred path is to use the `merge-task-branch` subcommand, which handles the full merge + cleanup flow:

- **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh merge-task-branch --feature <FEATURE> --task-id <TNNN> [--delegate-conflicts]`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 merge-task-branch -Feature <FEATURE> -TaskId <TNNN> [-DelegateConflicts]`

If you need to perform the merge manually (e.g. the subcommand is unavailable), follow these steps:

1. **Read the manifest** to confirm the task branch is registered:
   - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh read-manifest --worktree-path <WORKTREE_PATH>`
   - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 read-manifest -WorktreePath <WORKTREE_PATH>`
   - If the task ID is NOT in `task_branches[]`, abort with: `[error] Task <TNNN> is not registered in the worktree manifest. Did you run \`git.task <TNNN>\` first?`
2. **Switch to the feature branch** if not already on it:
   - `git checkout <FEATURE>`
3. **Merge the task branch** with `--no-ff` to preserve the topology in `git log --graph`:
   - `git merge --no-ff <task-branch> -m "Merge task <TNNN> into <FEATURE>"`
4. **On merge conflict**: do NOT auto-resolve. Instead:
   - Surface the conflicting files in the agent's response
   - Dispatch a new subagent with a conflict-resolution prompt containing the file list, the merge state (`git status` output), and instructions to use `git checkout --ours` / `git checkout --theirs` for non-overlapping hunks or manual editing for overlapping hunks
   - After the subagent resolves, re-run `git merge --continue` (or `git add` + `git merge --continue`)
5. **Remove the task branch** and unregister it from the manifest:
   - This is handled automatically by `merge-task-branch` on successful merge.
   - If you are following the manual fallback path instead, use:
   - **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh remove-task-branch --feature <FEATURE> --task-id <TNNN>`
   - **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 remove-task-branch -Feature <FEATURE> -TaskId <TNNN>`
6. **Verify** the manifest no longer lists the task:
   - `read-manifest` (same script as step 1)

## Output

The agent should report back with:
- Task ID and merged commit count
- Feature branch tip SHA after the merge
- Whether the merge was a fast-forward, no-ff, or had conflicts
- For conflicts: the resolution subagent's summary

## Graceful Degradation

- If Git is not available: abort.
- If not in a worktree: abort.
- If the task branch is not in the manifest: abort (see step 1).
- If `git merge` fails with conflicts: do NOT auto-resolve; delegate to a subagent (see step 4).
