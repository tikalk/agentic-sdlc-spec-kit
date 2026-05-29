# Changelog

All notable changes to the Team AI Directives extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
