# Changelog

## [1.5.0] - 2026-06-08

### Added

- Configurable `branch_pattern` support for feature branches.
- Jira-style `{issue}` placeholder support with keys like `PROJ-123`.
- CLI/env issue input support via `--issue`, `-Issue`, and `GIT_BRANCH_ISSUE`.
- Installed-extension end-to-end coverage for configured Jira branch generation and validation.

### Changed

- Branch validation now honors configured feature branch templates when `branch_pattern.enabled: true`.
- Jira issue keys are normalized to uppercase during branch generation.
- Documentation now includes recommended Jira-aware GitFlow examples and configuration guidance.
- Documentation now explains the end-to-end `before_specify` hook contract for `{issue}` templates, including how users provide issue keys and how prefix selection works during generation versus validation.
