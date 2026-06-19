---
description: "Remove a feature worktree and optionally delete the feature branch"
---

# Worktree Cleanup

Remove a feature worktree directory. This command is **idempotent** — if the worktree is already removed, it reports success.

## User Input

```text
$ARGUMENTS
```

The first argument MUST be the feature branch name (e.g., `003-user-auth`).

Optional flags:
- `--delete-branch` / `-DeleteBranch`: also delete the feature branch from the repository after removing the worktree
- `--force` / `-Force`: skip safety checks (uncommitted changes, missing manifest)

## Prerequisites

- Verify Git is available
- Verify the worktree exists at the configured base directory

## Safety Checks

By default, the command refuses to proceed if:
- The worktree has uncommitted changes (excluding the manifest file)
- The worktree manifest is missing (unless `--force` is used)

## Execution

Run the appropriate script based on your platform:

- **Bash**: `.specify/extensions/git/scripts/bash/worktree-cleanup.sh --feature <FEATURE> [--delete-branch] [--force]`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-cleanup.ps1 -Feature <FEATURE> [-DeleteBranch] [-Force]`

The script will:
1. Check for uncommitted changes (excluding the manifest)
2. Remove the worktree directory via `git worktree remove` (with `--force` fallback to `rm -rf`)
3. Optionally delete the feature branch if `--delete-branch` is passed
4. Report what was removed

## Output

JSON output:
- `removed`: true if worktree was removed
- `worktree_path`: path to the removed worktree
- `branch_deleted`: true if branch was also deleted
- `ok`: true on success

## Graceful Degradation

- If the worktree does not exist: report success (idempotent)
- If Git is not available: abort with error
- If uncommitted changes exist: abort unless `--force`
