# Changelog

All notable changes to the Team AI Directives extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - 2026-06-13

### Added

- **Descriptor column in CDR.md index**: New `Descriptor` column in the published CDR.md index
  table provides a "when to use" summary for each context module, enabling LLM-driven relevance
  matching without scanning every file.
- **CDR.md as search surface**: `/team.discover` now loads `CDR.md` as the primary search index
  (analogous to `.skills.json` for skills). Relevance matching uses the `Descriptor` column +
  target module path + type. Full file content is loaded on-demand only for selected modules.
  Falls back to legacy `context_modules/` scan when `CDR.md` is unavailable.
- **cdr_id in output**: Each entry in `team-context.json` now includes a `cdr_id` field linking
  back to its originating CDR.

### Changed

- `/team.repair` re-indexer updated to emit the `Descriptor` column and per-CDR `### Descriptor`
  field. The CDR table parser (`IFS='|' read`) updated for the new column.
- `agents-template.md` updated to document CDR.md as the searchable context index.
- Clarified that `team-ai-directives.discover` owns persistence for discovered feature context.
- Standardized the canonical persisted artifact name to `team-context.json`.
- Standardized the staging artifact location to `.specify/discovery/team-context.json` when the
  feature directory is not known yet.

## [1.7.8] - 2026-05-29

### Added

- **Repair command**: New `/team.repair` command for re-indexing CDR.md, .skills.json, and AGENTS.md
  - Moved from LevelUp extension (`/levelup.repair` -> `/team.repair`)
  - Paired with `/team.verify` for team-admin check-then-fix workflow
  - Auto-fixes orphan files, missing metadata, and corrupted indexes
- **setup-team.sh**: New setup script for team-ai-directives path resolution
- **setup-team.ps1**: PowerShell equivalent of setup-team.sh
- **agents-template.md**: Template for AGENTS.md generation (moved from LevelUp)

### Fixed

- **team.skills script path**: Fixed broken script reference pointing to non-existent path
  - Was: `.specify/extensions/team-ai-directives/scripts/bash/setup-levelup.sh`
  - Now: `.specify/extensions/team-ai-directives/scripts/bash/setup-team.sh`

### Changed

- `extension.yml`: Version bump to 1.7.8

## [1.7.7] - 2026-05-29

### Changed

- Renamed `{KNOWLEDGE_BASE}` placeholder to `{TEAM_AI_DIRECTIVES}` in all commands

## [1.7.6] - 2026-05-28

### Added

- Initial bundled version with verify, discover, constitution, and skills commands
