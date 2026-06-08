---
description: "Create a feature branch with sequential or timestamp numbering, optionally isolated in a worktree"
---

# Create Feature Branch

Create a new git feature branch for the given specification, optionally isolated in its own worktree. This command handles **branch creation only** — the spec directory and files are created by the core `__SPECKIT_COMMAND_SPECIFY__` workflow.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Environment Variable Override

If the user explicitly provided `GIT_BRANCH_NAME` (e.g., via environment variable, argument, or in their request), pass it through to the script by setting the `GIT_BRANCH_NAME` environment variable before invoking the script. When `GIT_BRANCH_NAME` is set:
- The script uses the exact value as the branch name, bypassing all prefix/suffix generation
- `--short-name`, `--number`, and `--timestamp` flags are ignored
- `FEATURE_NUM` is extracted from the name if it starts with a numeric prefix, otherwise set to the full branch name

## Prerequisites

- Verify Git is available by running `git rev-parse --is-inside-work-tree 2>/dev/null`
- If Git is not available, warn the user and skip branch creation

## Branch Numbering Mode

Determine the branch numbering strategy by checking configuration in this order:

1. Check `.specify/extensions/git/git-config.yml` for `branch_numbering` value
2. Check `.specify/init-options.json` for `branch_numbering` value (backward compatibility)
3. Default to `sequential` if neither exists

## Issue Placeholder Support

If `.specify/extensions/git/git-config.yml` enables `branch_pattern` and the configured
`template` contains `{issue}`, you MUST resolve an issue key before invoking the script.

Resolution order:

1. If `GIT_BRANCH_ISSUE` is already set, use it.
2. Otherwise, if the user request or approved Mission Brief explicitly contains an issue key,
   use that value.
3. Otherwise, STOP and ask the user for the issue key before continuing.

The value MUST match the configured `issue_format` in `git-config.yml`.

- `jira`: values like `PROJ-123`
- `numeric`: values like `1234`

Pass the value through by setting `GIT_BRANCH_ISSUE` before invoking the script, or by
passing `--issue <value>` / `-Issue <value>` when calling the script directly.

## Isolation Mode

Determine whether the feature work is isolated in a worktree or runs on a normal branch by checking configuration in this order:

1. CLI flags on the script call (see Execution below): `--worktree`, `--branch-mode`, `--isolation-mode`
2. `SPECIFY_ISOLATION_MODE` environment variable
3. `.specify/extensions/git/git-config.yml` `isolation_mode` key
4. Default: `branch`

Valid values: `branch` (default; existing behavior — `git checkout -b` in primary), `worktree` (provenance-tracked worktree at `.worktrees/<feature>/`).

## Execution

Generate a concise short name (2-4 words) for the branch:
- Analyze the feature description and extract the most meaningful keywords
- Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
- Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)

Run the appropriate script based on your platform:

**Branch mode (default)**:
- **Bash**: `.specify/extensions/git/scripts/bash/create-new-feature.sh --json --short-name "<short-name>" "<feature description>"`
- **Bash (timestamp)**: `.specify/extensions/git/scripts/bash/create-new-feature.sh --json --timestamp --short-name "<short-name>" "<feature description>"`
- **Bash (issue template)**: `.specify/extensions/git/scripts/bash/create-new-feature.sh --json --issue "<issue-key>" --short-name "<short-name>" "<feature description>"`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/create-new-feature.ps1 -Json -ShortName "<short-name>" "<feature description>"`
- **PowerShell (timestamp)**: `.specify/extensions/git/scripts/powershell/create-new-feature.ps1 -Json -Timestamp -ShortName "<short-name>" "<feature description>"`
- **PowerShell (issue template)**: `.specify/extensions/git/scripts/powershell/create-new-feature.ps1 -Json -Issue "<issue-key>" -ShortName "<short-name>" "<feature description>"`

**Worktree mode** (add `--worktree` / `-Worktree`; optionally `--base <branch>` / `-Base <branch>` to pin the base ref):
- **Bash**: `.specify/extensions/git/scripts/bash/create-new-feature.sh --worktree --json --short-name "<short-name>" "<feature description>"`
- **Bash (with base)**: `.specify/extensions/git/scripts/bash/create-new-feature.sh --worktree --base main --json --short-name "<short-name>" "<feature description>"`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/create-new-feature.ps1 -Worktree -Json -ShortName "<short-name>" "<feature description>"`
- **PowerShell (with base)**: `.specify/extensions/git/scripts/powershell/create-new-feature.ps1 -Worktree -Base main -Json -ShortName "<short-name>" "<feature description>"`

When worktree mode is used, the script returns a `WORKTREE_PATH` and `MANIFEST_PATH` in addition to `BRANCH_NAME`/`FEATURE_NUM`. **The script does NOT auto-`cd` into the worktree** — you must `cd "$WORKTREE_PATH"` separately to enter the worktree before invoking any follow-up commands. The manifest is gitignored.

**IMPORTANT**:
- Do NOT pass `--number` — the script determines the correct next number automatically
- If the active branch pattern template contains `{issue}`, you MUST pass the issue key via
  `GIT_BRANCH_ISSUE`, `--issue`, or `-Issue` before invoking the script
- Always include the JSON flag (`--json` for Bash, `-Json` for PowerShell) so the output can be parsed reliably
- You must only ever run this script once per feature
- The JSON output will contain `BRANCH_NAME` and `FEATURE_NUM` (always), and `ISOLATION_MODE` (always); `WORKTREE_PATH` and `MANIFEST_PATH` are present only in worktree mode
- PowerShell param style uses single-dash (`-Worktree`, `-BranchMode`, `-IsolationMode`, `-Base`); bash uses double-dash (`--worktree`, `--branch-mode`, `--isolation-mode`, `--base`)

## Graceful Degradation

If Git is not installed or the current directory is not a Git repository:
- Branch creation is skipped with a warning: `[specify] Warning: Git repository not detected; skipped branch creation`
- The script still outputs `BRANCH_NAME` and `FEATURE_NUM` so the caller can reference them

## Output

The script outputs JSON with:
- `BRANCH_NAME`: The branch name (e.g., `003-user-auth` or `20260319-143022-user-auth`)
- `FEATURE_NUM`: The numeric or timestamp prefix used
- `ISOLATION_MODE`: Either `branch` (default) or `worktree`
- `WORKTREE_PATH` (worktree mode only): Relative path to the worktree (e.g., `.worktrees/003-user-auth`)
- `MANIFEST_PATH` (worktree mode only): Relative path to the worktree manifest (e.g., `.worktrees/003-user-auth/git.worktree-manifest.json`)
