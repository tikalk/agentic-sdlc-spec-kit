# Git Branching Workflow Extension

Git repository initialization, feature branch creation, numbering (sequential/timestamp), validation, remote detection, and auto-commit for Spec Kit.

## Overview

This extension provides Git operations as an optional, self-contained module. It manages:

- **Repository initialization** with configurable commit messages
- **Feature branch creation** with sequential (`001-feature-name`) or timestamp (`20260319-143022-feature-name`) numbering
- **Optional custom feature branch templates** including issue-aware names like `feat/001-PROJ-123-user-auth`
- **Branch validation** to ensure branches follow naming conventions
- **Git remote detection** for GitHub integration (e.g., issue creation)
- **Auto-commit** after core commands (configurable per-command with custom messages)

## Commands

| Command | Description |
|---------|-------------|
| `speckit.git.initialize` | Initialize a Git repository with a configurable commit message |
| `speckit.git.feature` | Create a feature branch with sequential or timestamp numbering |
| `speckit.git.validate` | Validate current branch follows feature branch naming conventions |
| `speckit.git.remote` | Detect Git remote URL for GitHub integration |
| `speckit.git.commit` | Auto-commit changes (configurable per-command enable/disable and messages) |

## Hooks

| Event | Command | Optional | Description |
|-------|---------|----------|-------------|
| `before_constitution` | `speckit.git.initialize` | No | Init git repo before constitution |
| `before_specify` | `speckit.git.feature` | No | Create feature branch before specification |
| `before_clarify` | `speckit.git.commit` | Yes | Commit outstanding changes before clarification |
| `before_plan` | `speckit.git.commit` | Yes | Commit outstanding changes before planning |
| `before_tasks` | `speckit.git.commit` | Yes | Commit outstanding changes before task generation |
| `before_implement` | `speckit.git.commit` | Yes | Commit outstanding changes before implementation |
| `before_checklist` | `speckit.git.commit` | Yes | Commit outstanding changes before checklist |
| `before_analyze` | `speckit.git.commit` | Yes | Commit outstanding changes before analysis |
| `before_taskstoissues` | `speckit.git.commit` | Yes | Commit outstanding changes before issue sync |
| `after_constitution` | `speckit.git.commit` | Yes | Auto-commit after constitution update |
| `after_specify` | `speckit.git.commit` | Yes | Auto-commit after specification |
| `after_clarify` | `speckit.git.commit` | Yes | Auto-commit after clarification |
| `after_plan` | `speckit.git.commit` | Yes | Auto-commit after planning |
| `after_tasks` | `speckit.git.commit` | Yes | Auto-commit after task generation |
| `after_implement` | `speckit.git.commit` | Yes | Auto-commit after implementation |
| `after_checklist` | `speckit.git.commit` | Yes | Auto-commit after checklist |
| `after_analyze` | `speckit.git.commit` | Yes | Auto-commit after analysis |
| `after_taskstoissues` | `speckit.git.commit` | Yes | Auto-commit after issue sync |
| `before_task_execute` | `speckit.git.commit` | Yes | Auto-commit before each individual task execution |
| `after_task_execute` | `speckit.git.commit` | Yes | Auto-commit after each individual task execution |

## Configuration

Configuration is stored in `.specify/extensions/git/git-config.yml`:

```yaml
# Branch numbering strategy: "sequential" or "timestamp"
branch_numbering: sequential

# Custom commit message for git init
init_commit_message: "[Spec Kit] Initial commit"

# Optional custom feature branch naming
branch_pattern:
  enabled: false
  template: "{prefix}/{number}-{issue}-{slug}"
  allowed_prefixes:
    - feat
  number_padding: 3
  issue_format: jira

# Auto-commit per command (all disabled by default)
# Example: enable auto-commit after specify
auto_commit:
  default: false
  after_specify:
    enabled: true
    message: "[Spec Kit] Add specification"
  after_task_execute:
    enabled: false
    message: "[Spec Kit] Task checkpoint"
```

Supported placeholders in `branch_pattern.template`:

- `{prefix}`: first configured prefix from `allowed_prefixes` during generation; validation accepts any configured prefix
- `{number}`: sequential feature number with `number_padding`
- `{timestamp}`: `YYYYMMDD-HHMMSS`
- `{issue}`: issue key whose format is controlled by `issue_format`
- `{slug}`: kebab-cased feature slug

Rules:

- `{slug}` is required
- exactly one of `{number}` or `{timestamp}` is required
- if `{prefix}` is used, `allowed_prefixes` must not be empty
- if `{issue}` is used, provide `--issue <value>`, `-Issue <value>`, or `GIT_BRANCH_ISSUE=<value>`

`issue_format` values:

- `jira`: values like `PROJ-123`
- `numeric`: values like `1234`

## Issue-Aware Hook Flow

If `branch_pattern.enabled: true` and `branch_pattern.template` contains `{issue}`, the
`before_specify` hook path must resolve an issue key before `git.feature` runs.

Resolution order used by the documented flow:

1. `GIT_BRANCH_ISSUE` if it is already set
2. an issue key explicitly present in the user request or approved Mission Brief
3. otherwise stop and ask the user for the issue key before branch creation

This matters because `git.feature` runs as a mutating `before_specify` hook after Mission Brief
approval. If no issue key is available and the active template requires `{issue}`, branch
creation will fail by design.

The user-facing contract is now:

- set `GIT_BRANCH_ISSUE` before invoking `/spec.specify`, or
- ensure the approved Mission Brief/user request contains the issue key, or
- provide `--issue` / `-Issue` when invoking the extension script directly

## Jira Branch Patterns

Recommended GitFlow-style Jira template:

```yaml
branch_pattern:
  enabled: true
  template: "{prefix}/{number}-{issue}-{slug}"
  allowed_prefixes:
    - feat
    - fix
    - docs
    - chore
  number_padding: 3
  issue_format: jira
```

Examples:

```bash
# Bash CLI
bash .specify/extensions/git/scripts/bash/create-new-feature.sh \
  --issue PROJ-123 \
  --short-name user-auth \
  "Add user authentication"

# Environment variable
GIT_BRANCH_ISSUE=PROJ-123 bash .specify/extensions/git/scripts/bash/create-new-feature.sh \
  --short-name user-auth \
  "Add user authentication"
```

```powershell
# PowerShell CLI
pwsh -NoProfile -File .specify/extensions/git/scripts/powershell/create-new-feature.ps1 `
  -Issue PROJ-123 `
  -ShortName user-auth `
  "Add user authentication"
```

Expected branch name:

```text
feat/001-PROJ-123-user-auth
```

Notes:

- Jira keys are normalized to uppercase during generation.
- Validation uses the configured template when `branch_pattern.enabled: true`.
- Spec directory resolution still uses the `{number}` or `{timestamp}` identity, so `feat/001-PROJ-123-user-auth` maps to `specs/001-*`.
- If multiple prefixes are listed, generation uses the first prefix in `allowed_prefixes`.

## Numeric Issue Patterns

You can also use numeric issue identifiers instead of Jira-style keys:

```yaml
branch_pattern:
  enabled: true
  template: "{prefix}/{number}-{issue}-{slug}"
  allowed_prefixes:
    - feat
  number_padding: 3
  issue_format: numeric
```

Examples:

```bash
GIT_BRANCH_ISSUE=1234 bash .specify/extensions/git/scripts/bash/create-new-feature.sh \
  --short-name user-auth \
  "Add user authentication"
```

Expected branch name:

```text
feat/001-1234-user-auth
```

Notes:

- Numeric issue values are not uppercased.
- Validation still uses the configured template and issue format.

## Installation

```bash
# Install the bundled git extension (no network required)
specify extension add git
```

## Disabling

```bash
# Disable the git extension (spec creation continues without branching)
specify extension disable git

# Re-enable it
specify extension enable git
```

## Graceful Degradation

When Git is not installed or the directory is not a Git repository:
- Spec directories are still created under `specs/`
- Branch creation is skipped with a warning
- Branch validation is skipped with a warning
- Remote detection returns empty results

## Scripts

The extension bundles cross-platform scripts:

- `scripts/bash/create-new-feature.sh` — Bash implementation
- `scripts/bash/git-common.sh` — Shared Git utilities (Bash)
- `scripts/powershell/create-new-feature.ps1` — PowerShell implementation
- `scripts/powershell/git-common.ps1` — Shared Git utilities (PowerShell)
