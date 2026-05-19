# Changelog

All notable changes to the TDD Extension will be documented in this file.

## [1.0.4] - 2026-05-11

### Added

- **Context detection and in-session TDD flow**: `tdd.implement` now detects when called
  without spec workflow artifacts (e.g., from `/quick.implement`) and automatically runs
  a combined in-session TDD flow: condensed planning → language detection → test increment
  generation → RED→GREEN→REFACTOR. No file artifacts are created; state is tracked in the
  conversation context only.
- **Quick extension integration**: When the TDD extension is installed, `/quick.implement`
  automatically triggers TDD's full workflow via the `before_implement` hook.

### Changed

- `tdd.implement` now includes a "Context Detection" section at the top to determine
  whether to run in file-based mode (standard spec workflow) or in-session mode (quick)
- "Save State" and "Load State" sections now note they only apply to spec mode

## [1.0.3] - 2026-05-07

### Fixed
- **Hook execution deadlock**: Replace `EXECUTE_COMMAND` + "wait for the result" pattern with self-executing hook instructions. The old pattern caused non-deterministic agent deadlocks when mandatory hooks were present. Now uses explicit instructions to read and execute the hook command immediately, with graceful fallback on failure.

## [1.0.2] - 2026-04-13

### Added
- `after_plan` hook for `tdd.plan` command (optional) - TDD planning phase with 5 design questions

### Changed
- `tdd.implement` now triggers on `before_implement` instead of `after_implement` - ensures TDD cycle runs BEFORE implementation (RED→GREEN→REFACTOR)
- `tdd.validate` now has its own `after_implement` hook (optional) - validates test quality after implementation

## [1.0.1] - 2026-04-13

### Fixed

- **Script path resolution**: Fixed session execution failures by using fully-qualified paths in command files
  - Changed from relative `scripts/bash/` to `.specify/extensions/tdd/scripts/bash/`

## [1.0.0] - 2026-03-07

### Added
- Initial release of TDD Extension
- `tdd.plan` command: Planning phase - design tests before writing code
- `tdd.tasks` command: Language detection and hybrid test generation (increment + risk-based)
- `tdd.implement` command: RED→GREEN→REFACTOR workflow execution
- `tdd.validate` command: Test quality validation with scoring
- RFC-compliant extension hooks integration (after_tasks, after_implement)
- Language detection for Python/pytest, TypeScript/vitest, Go/testing, Rust/cargo, Java/junit
- Risk-based testing integration with 12-factors AI-augmented testing methodology
- Increment patterns: CRUD, Data Transform, State Machine, Integration
- Test quality scoring (0-100) with TDD best practices
- Feature-level state persistence for resumable workflows
- Bash and PowerShell validation scripts
- Reference documentation for language configs, testing strategies, quality

### Enhanced
- Test quality validation with anti-pattern penalties:
  - Excessive mocking (-15): Tests imagined behavior, not real
  - DB query tests (-15): Bypass public interface
  - Call count verification (-15): Tests HOW not WHAT
  - File system checks (-15): Bypass interface
  - Implementation detail testing (-15): Breaks on refactors
- TDD principles integrated from best practices:
  - Vertical slicing: ONE test → ONE implementation
  - Public interface testing over internals
  - Test WHAT (behavior) not HOW (implementation)
  - Edge case testing (empty, nil, zero, boundaries)
  - One behavior per test
- Planning phase with 5 key questions:
  1. Interface changes needed?
  2. Behaviors to test?
  3. Design for deep modules?
  4. Design for testability?
  5. Vertical slicing constraint?
- Enhanced prompts with anti-pattern warnings:
  - Don't mock internals
  - Don't verify call counts
  - Don't query DB directly
  - Focus on return values over side effects

### Changed
- TDD functionality moved from core to extension
- Configuration now uses `.specify/extensions.yml` format
- Enhanced scoring system with better weighting

### Removed
- `--tdd` CLI flag (now extension-based only)
- Hard-coded TDD in core templates

### Breaking Changes
- TDD is now an opt-in extension
- Users must configure via `.specify/extensions.yml`
- No longer available via `--tdd` flag