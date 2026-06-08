---
description: "Validate current branch follows feature branch naming conventions"
---

# Validate Feature Branch

Validate that the current Git branch follows the expected feature branch naming conventions.

## Prerequisites

- Check if Git is available by running `git rev-parse --is-inside-work-tree 2>/dev/null`
- If Git is not available, output a warning and skip validation:
  ```
  [specify] Warning: Git repository not detected; skipped branch validation
  ```

## Validation Rules

Get the current branch name:

```bash
git rev-parse --abbrev-ref HEAD
```

The branch name must match one of these patterns:

1. **Sequential**: `^[0-9]{3,}-` (e.g., `001-feature-name`, `042-fix-bug`, `1000-big-feature`)
2. **Timestamp**: `^[0-9]{8}-[0-9]{6}-` (e.g., `20260319-143022-feature-name`)
3. **Configured template**: when `.specify/extensions/git/git-config.yml` enables `branch_pattern`, validate against that template instead. Examples: `feat/001-PROJ-123-user-auth` or `feat/001-1234-user-auth`

Example Jira-aware configuration:

```yaml
branch_pattern:
  enabled: true
  template: "{prefix}/{number}-{issue}-{slug}"
  allowed_prefixes:
    - feat
  number_padding: 3
  issue_format: jira
```

Example numeric-issue configuration:

```yaml
branch_pattern:
  enabled: true
  template: "{prefix}/{number}-{issue}-{slug}"
  allowed_prefixes:
    - feat
  number_padding: 3
  issue_format: numeric
```

If `{prefix}` is present, generation uses the first configured prefix while validation accepts
any configured prefix.

## Execution

If on a feature branch (matches either pattern):
- Output: `✓ On feature branch: <branch-name>`
- Check if the corresponding spec directory exists under `specs/`:
  - For sequential branches, look for `specs/<prefix>-*` where prefix matches the numeric portion
  - For timestamp branches, look for `specs/<prefix>-*` where prefix matches the `YYYYMMDD-HHMMSS` portion
- If spec directory exists: `✓ Spec directory found: <path>`
- If spec directory missing: `⚠ No spec directory found for prefix <prefix>`

If NOT on a feature branch:
- Output: `✗ Not on a feature branch. Current branch: <branch-name>`
- Output either:
  - `Feature branches should be named like: 001-feature-name or 20260319-143022-feature-name`
  - or the configured template guidance from `branch_pattern.template`

## Graceful Degradation

If Git is not installed or the directory is not a Git repository:
- Check the `SPECIFY_FEATURE` environment variable as a fallback
- If set, validate that value against the naming patterns
- If not set, skip validation with a warning
