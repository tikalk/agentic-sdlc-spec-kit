---
description: "List feature worktrees with provenance metadata"
---

# List Worktrees

Show all feature worktrees created by `git.feature` (identified by manifest provenance).

## User Input

```text
$ARGUMENTS
```

No required arguments. Optional flags:
- `--json` / `-Json`: emit machine-readable JSON array
- `--all` / `-All`: list ALL git worktrees (not just ones with manifests)

## Prerequisites

- Verify Git is available

## Execution

Run the appropriate script based on your platform:

- **Bash**: `.specify/extensions/git/scripts/bash/worktree-utils.sh list-worktrees`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/worktree-utils.ps1 list-worktrees`

Or use git directly:
- `git worktree list`

## Output

Default (human-readable table):

```text
FEATURE        BRANCH          PATH                    CREATED
003-user-auth  003-user-auth   .worktrees/003-user-auth  2026-06-19
```

`--json`:

```json
[{"feature":"003-user-auth","branch":"003-user-auth","path":".worktrees/003-user-auth","created_at":"2026-06-19T10:00:00Z"}]
```

## Graceful Degradation

- If no worktrees exist: print friendly message and exit 0
- If Git is not available: abort
