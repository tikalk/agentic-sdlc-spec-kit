---
description: Discover child repositories and register them as Git submodules for multi-repo workspace coordination.
aliases: ["git.workspace"]
scripts:
  sh: scripts/bash/workspace-submodules.sh --json
  ps: scripts/powershell/workspace-submodules.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

Optional: `--dry-run` to preview changes without executing them.

## Overview

This command sets up a multi-repo workspace by discovering child git repositories at depth 1 from the project root and registering them as Git submodules.

**When to use:**
- After `specify init` when you have multiple implementation repos alongside your coordination workspace
- When you've cloned new child repos into the workspace and want to register them as submodules
- To convert an existing multi-repo setup to use submodules for better git isolation

## How It Works

1. **Discover child repos**: Scan depth 1 for directories containing `.git/`
2. **Check existing submodules**: Skip directories already registered in `.gitmodules`
3. **Read remote URLs**: Get `origin` URL from each child repo's git config
4. **Register as submodules**: Run `git submodule add <url> <path>` for each
5. **Commit changes**: Create a commit with the updated `.gitmodules` file

## Outline

1. **Run discovery script**: Execute `{SCRIPT}` from the repo root
2. **Parse JSON output**: Extract `DISCOVERED_REPOS`, `REGISTERED_COUNT`, `SKIPPED_COUNT`, `ERRORS`
3. **Report results**: Display which repos were registered vs skipped
4. **Handle errors**: If any repos couldn't be registered (no remote URL, etc.), display warnings

## Example Output

```
Workspace Submodule Setup Complete

Registered (3):
  ✓ frontend → git@github.com:org/frontend.git
  ✓ backend-api → git@github.com:org/backend-api.git
  ✓ shared-libs → git@github.com:org/shared-libs.git

Skipped (1):
  - local-only-repo (no remote URL configured)
```

## Key Rules

- Child repos must have a remote `origin` URL configured
- Already-registered submodules are skipped (idempotent)
- Requires git to be initialized in the workspace root
- Only discovers repos at depth 1 (direct subdirectories)
- Directories named `.specify`, `node_modules`, `.venv`, etc. are ignored

## Safety

This command is safe to run multiple times. It will:
- Not modify child repo contents
- Not unregister existing submodules
- Skip repos without remote URLs (with a warning)
- Skip common development directories (node_modules, etc.)
