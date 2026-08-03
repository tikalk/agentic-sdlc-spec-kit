# Changelog

## [1.8.1] - 2026-08-02

### Fixed

- PowerShell `-Number` parameter typed as `[string]` with explicit Int64 parsing to prevent parameter-binder crashes on non-numeric/overflow inputs.
- Empty `-Number ""` stripped from `$PSBoundParameters` before delegation so it is treated as omitted.
- `Get-NextBranchNumber` double-increment removed — branch numbering now returns the correct next number (`001`, `002`, …) instead of skipping one.
- Numeric prefixes exceeding `[long]::MaxValue` (e.g. `9223372036854775808-`) ignored by `Get-HighestNumberFromSpecs`/`Get-HighestNumberFromNames` instead of crashing.
- Non-dry text mode prints the `SPECIFY_FEATURE` persist hint to both stdout and stderr for cross-shell visibility.

## [1.8.0] - 2026-07-07

### Added

- Configurable Conventional Commit support (`commit_style: conventional`) in the auto-commit flow (#3390/#3413).
- Namespaced git feature branch templates (#3293) and Jira-style `{issue}` templates migrated onto upstream `branch_template`.

### Changed

- Jira branch templates migrated onto the upstream `branch_template` mechanism (fork no longer diverges on template handling).
- `{prefix}` placeholder expansion in `branch_template` now matches the bash twin's behavior.
- Branch validation honors configured feature branch templates when `branch_pattern.enabled: true`.

### Fixed

- PowerShell honors explicit `-Number 0` (#3412) and rejects negative `-Number` (#3538).
- PowerShell emits the `'# To persist'` `SPECIFY_FEATURE` hint for parity with bash (#3632).
- Trailing whitespace trimmed before stripping commit-message quotes (#3673).

## [1.7.0] - 2026-06-20

### Added

- `speckit.git.publish` command (aliased `git.publish`) — platform-neutral PR (GitHub `gh`) / MR (GitLab `glab`) creation.
- `speckit.git.commit` `--message` flag for explicit commit messages.

## [1.6.0] - 2026-06-19

### Added

- `speckit.git.worktree-list` command to list feature worktrees with provenance metadata.
- `speckit.git.worktree-cleanup` command to remove worktrees with safety checks (refuses uncommitted changes unless `--force`).
- Idempotent worktree creation: if worktree exists → return path; if branch exists remotely → attach worktree.
- Hardened "MUST cd into worktree" instruction in `speckit.git.feature.md` to prevent agents from skipping the directory change.

### Changed

- **Simplified worktree model**: removed per-task branch machinery. Worktrees are now feature-only — all task work happens directly on the feature branch inside the worktree.
- Default base branch changed from current branch to `origin/main` (falls back to `origin/master` or current branch).
- Removed `git.task`, `git.task-merge`, `git.task-list` commands and all task-branch subcommands from `worktree-utils.{sh,ps1}`.
- Removed `task_branch_pattern`, `task_execution`, and `task_generation` config sections.
- Removed `--mode` / `--task-id` flags and `[TNNN]` commit prefixes from `auto-commit.{sh,ps1}`.
- Removed `before_task_execute` and `after_task_execute` hooks from `extension.yml`.
- Simplified manifest schema: removed `task_branches[]` array.

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
