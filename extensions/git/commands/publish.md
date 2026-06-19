---
description: "Push current branch and create a PR (GitHub) or MR (GitLab)"
---

# Publish Changes

Push the current branch to origin and create a pull request (GitHub) or merge request (GitLab).

## Behavior

This command:

1. Detects the platform from the git remote URL:
   - `github.com` or `gh/` → GitHub
   - `gitlab` or `/gl/` or `gitlab.` → GitLab
   - Falls back to `gh` CLI if remote is ambiguous
2. Reads `$ARGUMENTS` for options:
   - `--draft` — Create as draft PR/MR
   - `--title "..."` — PR/MR title (required)
   - `--body "..."` — PR/MR description
   - `--source-branch "..."` — Source branch (default: current branch)
   - `--target-branch "..."` — Target branch (default: main)
3. Pushes the current branch to origin
4. Creates the PR or MR via the appropriate tool:
   - GitHub: `gh pr create` (preferred) or MCP `create_pull_request`
   - GitLab: `glab mr create` (preferred) or MCP `create_merge_request`
5. Returns the PR/MR URL

## Execution

### Step 1: Parse Arguments

Parse `$ARGUMENTS` for:
- `--draft` → `DRAFT=true`
- `--title "..."` → Extract title string
- `--body "..."` → Extract body string
- `--target-branch "..."` → Default: main
- Source branch is auto-detected from `git rev-parse --abbrev-ref HEAD`

If no `--title` is provided, generate one from the branch name.

### Step 2: Run the Script

- **Bash**: `.specify/extensions/git/scripts/bash/publish.sh --title "$TITLE" [--body "$BODY"] [--draft] [--target-branch "$TARGET"]`
- **PowerShell**: `.specify/extensions/git/scripts/powershell/publish.ps1 -Title "$TITLE" [-Body "$BODY"] [-Draft] [-TargetBranch "$TARGET"]`

The script will:
1. Detect the remote platform (GitHub, GitLab, or Azure DevOps)
2. Push the current branch to origin
3. Create a PR (via `gh`) or MR (via `glab`)
4. Output a summary table

## Notes

- Requires `gh` CLI for GitHub or `glab` CLI for GitLab (or MCP tools as fallback)
- Branch must already have commits to push
- If no changes to push, the command stops with a warning
- `--draft` creates a draft PR/MR that signals "not ready for review"
- Title and body can contain markdown formatting
