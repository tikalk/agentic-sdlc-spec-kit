# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to to [Semantic Versioning](https://semver.org/spec/v2.0.0/).

## [0.1.0] - 2026-03-14

### BREAKING CHANGE: Preset Architecture Migration

This release migrates fork-specific customizations to a preset system to reduce merge conflicts with upstream GitHub Spec Kit.

### Added

- **`agentic-sdlc` preset**: Fork-specific templates and commands now bundled as a preset
  - Auto-installed with priority 1 (highest precedence) during `specify init`
  - Templates: `context-template.md`, `delegation-template.md`, enhanced `spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, `constitution-template.md`
  - Commands: `adlc.spec.specify`, `adlc.spec.plan`, `adlc.spec.clarify`, `adlc.spec.tasks`, `adlc.spec.checklist`, `adlc.spec.analyze`, `adlc.spec.implement`, `adlc.spec.constitution` (with `spec.*` aliases)
  - Governance features: team-ai-directives integration, dual execution loop, before_plan/after_plan hooks
- **`install_bundled_presets()`**: New function to auto-install bundled presets during init
- **Extension script consolidation**: Trace scripts moved to levelup extension, diagram scripts moved to architect extension

### Changed

- **Core templates/commands reset to upstream**: All core `templates/` and `templates/commands/` now match upstream spec-kit
- **Extension scripts moved**:
  - `generate-trace.sh`, `validate-trace.sh` → `extensions/levelup/scripts/bash/`
  - `ascii-generator.sh`, `mermaid-generator.sh` → `extensions/architect/scripts/bash/`

### Removed

- **Duplicate architecture templates**: `templates/adr-template.md`, `AD-template.md`, `feature-AD-template.md` (use architect extension templates)
- **Fork-only templates from core**: `context-template.md`, `delegation-template.md` (now in preset)
- **Unused scripts**: `constitution-evolution.sh`, `verify-dates.sh`, `test-dual-execution-loop.sh`
- **Extension scripts from core**: Trace and diagram scripts (now in their respective extensions)

### Migration Guide

**For existing projects**: Run `specify preset add agentic-sdlc` or re-run `specify init --here` to get the preset installed.

**For new projects**: The preset is automatically installed during `specify init`.

## [0.0.139] - 2026-03-14

### Added

- **Preset system**: Merged upstream v0.3.0 preset system with pluggable template/command overrides
  - New `specify preset` CLI commands: list, add, remove, search, resolve, info
  - Preset catalog support with priority-based stacking
  - `--preset` option on `specify init` for preset installation during setup
  - New files: `presets.py`, `agents.py`, `presets/` directory with scaffold and self-test examples
  - Shell scripts (`common.sh`, `common.ps1`) now include `resolve_template()` / `Resolve-Template` functions
- **DocGuard extension**: Added to community catalog for CDD enforcement

### Changed

- **CommandRegistrar refactored**: Moved to shared `agents.py` module for use by both extensions and presets
- **Template resolution**: Scripts now use preset-aware template resolution with priority stack


## [0.0.138] - 2026-03-14

### Fixed

- **Cross-reference fixes**: Corrected remaining references to output file locations
  - Fixed `context_modules/AD.md` → `{TD}/AD.md` (TD root)
  - Fixed `context_modules/PRD.md` → `{TD}/PRD.md` (TD root)

## [0.0.137] - 2026-03-14

### Changed

- **Refined output file locations for extensions**:
  - architect.implement: AD.md → `{TD}/AD.md` (TD root), accepted ADRs → `{TD}/context_modules/adr.md`
  - product.implement: PRD.md → `{TD}/PRD.md` (TD root), accepted PDRs → `{TD}/context_modules/pdr.md`
  - levelup.implement: accepted CDRs → `{TD}/context_modules/cdr.md`
  - When NOT configured: All extensions copy accepted records to `.specify/memory/` and clean up `.specify/drafts/`

## [0.0.136] - 2026-03-13

### Fixed

- **levelup trace skill duplicate**: Removed "trace" alias from levelup extension to prevent duplicate skill creation (keeps only `levelup-trace`, removes unwanted `trace`)

## [0.0.135] - 2026-03-13

### Fixed

- (placeholder for changes)

## [0.0.134] - 2026-03-13

### Fixed

- **Product extension bundling**: Added `extensions/product` to bundled extensions in pyproject.toml, fixing "Manifest not found" error during installation
- **levelup.implement validation**: Added explicit verification checkpoints to prevent skipping context module file creation (rules, personas, examples, skills). The command now requires verifying all output files exist before committing.

## [0.0.133] - 2026-03-13

### Fixed

- **Extension commands refresh on init**: Re-running `specify init` now properly refreshes extension command files via `_ensure_commands_for_agent` (reverted broken remove/reinstall approach that caused "Manifest not found" errors)

## [0.0.132] - 2026-03-13

### Fixed

- **Extensions always reinstall on init**: Re-running `specify init` now properly reinstalls bundled extensions by removing existing ones first (previously failed because `install_from_directory` rejects existing extensions)

## [0.0.131] - 2026-03-13

### Fixed

- **Extensions always reinstall on init**: Re-running `specify init` now reinstalls all bundled extensions to get latest versions (previously skipped existing extensions, preventing updates)

## [0.0.130] - 2026-03-13

### Added

- **doctor extension**: Added to community catalog for project health diagnostics

### Changed

- **Security hardening**: Shell injection prevention in bash scripts via `printf '%q'`
- **JSON safety**: Safe JSON construction with `jq -cn` when available, `json_escape()` fallback
- **Bash 3.2 compatibility**: Replaced `declare -A` with indexed arrays for macOS support

### Fixed

- **Extension commands always refresh on init**: Re-running `specify init` now overwrites existing extension command files with fresh versions, ensuring updates are applied correctly
- **setup-levelup.sh reads config.json**: LevelUp scripts now read `team_directives.path` from `.specify/config.json` (written by `specify init`), fixing `TEAM_DIRECTIVES` resolution when path is outside standard locations
- **JSON output fix**: Fixed malformed JSON output in `setup-levelup.sh` (double `}}` removed)
- **Timestamp matching**: Handle 'Last updated' with or without bold markers

## [0.0.129] - 2026-03-13

### Added

- **selftest extension**: New core extension for validating extension lifecycle (discovery, installation, registration)
- **Jules agent**: Added Google's Jules agent to supported agents list
- **agy deprecation handler**: Explicit `--ai agy` without `--ai-skills` now fails with clear guidance

### Changed

- **Qwen format**: Migrated Qwen Code CLI from TOML to Markdown format
- **Extension resolution**: Improved extension ID/name resolution for catalog operations

### Fixed

- Test version requirements updated to `>=0.0.80` for compatibility
- Cleaned up command templates (specify, analyze)

## [0.0.128] - 2026-03-13

### Changed

- Patch version bump

## [0.0.127] - 2026-03-13

### Changed

- **Breaking**: Reverted CDR storage from JSON to markdown
  - `/levelup.init` now outputs to `{PROJECT}/.specify/memory/cdr.md` (local)
  - `/levelup.clarify` reads/writes `.specify/memory/cdr.md`
  - `/levelup.skills` validates only CDRs with status "Accepted"
  - `/levelup.implement` copies only accepted CDRs to `{TEAM_DIRECTIVES}/CDR.md` (root)
  - Added `CDR_FILE` to setup-levelup scripts output
  - Removed status field from `.skills.json` references

## [0.0.126] - 2026-03-12

### Changed

- Patch version bump

## [0.0.125] - 2026-03-12

### Changed

- **Breaking**: Migrated CDR (Context Directive Record) system from `.specify/memory/cdr.md` to `{TEAM_DIRECTIVES}/.cdrs.json`
  - Removed local `cdr.md` file creation and management
  - Created `.cdrs.json` in team-ai-directives to track context modules (34 modules pre-populated)
  - Added `status` field to `.skills.json` for skill lifecycle tracking
  - Updated all levelup commands to read/write from `.cdrs.json` in team-ai-directives
  - Status values: `discovered` | `proposed` | `accepted` | `active` | `deprecated`
  - Migration path: All levelup commands now work directly with upstream repository
  - **Removed**: Redundant `TEAM_DIRECTIVES_EXISTS` flag from setup scripts - existence is now checked implicitly via `TEAM_DIRECTIVES` value

## [0.3.0] - 2026-03-13

### Changed

- No changes have been documented for this release yet.

<!-- Entries for 0.2.x and earlier releases are documented in their respective sections below. -->
- make c ignores consistent with c++ (#1747)
- chore: bump version to 0.1.13 (#1746)
- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)
- chore: bump version to 0.1.12 (#1737)
- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)


## [Unreleased]

### Added

- feat(presets): Pluggable preset system with preset catalog and template resolver
- Preset manifest (`preset.yml`) with validation for artifact, command, and script types
- `PresetManifest`, `PresetRegistry`, `PresetManager`, `PresetCatalog`, `PresetResolver` classes in `src/specify_cli/presets.py`
- CLI commands: `specify preset search`, `specify preset add`, `specify preset list`, `specify preset remove`, `specify preset resolve`, `specify preset info`
- CLI commands: `specify preset catalog list`, `specify preset catalog add`, `specify preset catalog remove` for multi-catalog management
- `PresetCatalogEntry` dataclass and multi-catalog support mirroring the extension catalog system
- `--preset` option for `specify init` to install presets during initialization
- Priority-based preset resolution: presets with lower priority number win (`--priority` flag)
- `resolve_template()` / `Resolve-Template` helpers in bash and PowerShell common scripts
- Template resolution priority stack: overrides → presets → extensions → core
- Preset catalog files (`presets/catalog.json`, `presets/catalog.community.json`)
- Preset scaffold directory (`presets/scaffold/`)
- Scripts updated to use template resolution instead of hardcoded paths
- feat(presets): Preset command overrides now propagate to agent skills when `--ai-skills` was used during init
- feat: `specify init` persists CLI options to `.specify/init-options.json` for downstream operations
- feat(extensions): support `.extensionignore` to exclude files/folders during `specify extension add` (#1781)

## [0.2.1] - 2026-03-11

### Changed

- **Breaking**: Aligned `--ai-skills` skill names with the `adlc.*` command namespace
  - Skills now strip `adlc.` prefix and use hyphens (e.g., `spec-specify`, `tdd-plan`, `levelup-init`)
  - Kimi agent uses dot notation (e.g., `spec.specify`, `levelup.specify`)
  - Matches the short command form used by extensions
- Added February 2026 newsletter (#1812)
- feat: add Kimi Code CLI agent support (#1790)
- docs: fix broken links in quickstart guide (#1759) (#1797)
- docs: add catalog cli help documentation (#1793) (#1794)
- fix: use quiet checkout to avoid exception on git checkout (#1792)
- feat(extensions): support .extensionignore to exclude files during install (#1781)
- feat: add Codex support for extension command registration (#1767)
- chore: bump version to 0.2.0 (#1786)
- fix: sync agent list comments with actual supported agents (#1785)
- feat(extensions): support multiple active catalogs simultaneously (#1720)
- Pavel/add tabnine cli support (#1503)
- Add Understanding extension to community catalog (#1778)
- Add ralph extension to community catalog (#1780)
- Update README with project initialization instructions (#1772)
- feat: add review extension to community catalog (#1775)
- Add fleet extension to community catalog (#1771)
- Integration of Mistral vibe support into speckit (#1725)
- fix: Remove duplicate options in specify.md (#1765)
- fix: use global branch numbering instead of per-short-name detection (#1757)
- Add Community Walkthroughs section to README (#1766)
- feat(extensions): add Jira Integration to community catalog (#1764)
- Add Azure DevOps Integration extension to community catalog (#1734)
- Fix docs: update Antigravity link and add initialization example (#1748)
- fix: wire after_tasks and after_implement hook events into command templates (#1702)
- make c ignores consistent with c++ (#1747)
- chore: bump version to 0.1.13 (#1746)
- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)
- chore: bump version to 0.1.12 (#1737)
- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)



## [Unreleased]

## [0.0.123] - 2026-03-12

### Fixed

- Restore corrupted create-release-packages.sh (syntax errors, duplicate functions)
- Add kimi (Kimi Code CLI) agent support to bash and PowerShell release scripts
- Remove q (Amazon Q) agent from release scripts to align with upstream

## [0.0.122] - 2026-03-11

### Fixed

- Ensure extension commands are registered for all agents, even when extensions were already installed

## [0.0.121] - 2026-03-11

### Fixed

- Add missing agents (agy, vibe, generic, q, codex, cursor-agent) to AGENT_CONFIGS for extension command registration

## [0.0.120] - 2026-03-10

### Fixed

- Fix release asset naming: use `agentic-sdlc-spec-kit-template-*` prefix consistently across release scripts
- Add `q` agent back to release scripts for backward compatibility (fork-specific)
- Update create-github-release.sh to use glob pattern for package inclusion

## [0.0.119] - 2026-03-10

### Fixed

- Fix lint errors from merge conflict: duplicate imports and missing functions in extensions.py and __init__.py



## [0.2.0] - 2026-03-09

### Changed

- fix: sync agent list comments with actual supported agents (#1785)
- feat(extensions): support multiple active catalogs simultaneously (#1720)
- Pavel/add tabnine cli support (#1503)
- Add Understanding extension to community catalog (#1778)
- Add ralph extension to community catalog (#1780)
- Update README with project initialization instructions (#1772)
- feat: add review extension to community catalog (#1775)
- Add fleet extension to community catalog (#1771)
- Integration of Mistral vibe support into speckit (#1725)
- fix: Remove duplicate options in specify.md (#1765)
- fix: use global branch numbering instead of per-short-name detection (#1757)
- Add Community Walkthroughs section to README (#1766)
- feat(extensions): add Jira Integration to community catalog (#1764)
- Add Azure DevOps Integration extension to community catalog (#1734)
- Fix docs: update Antigravity link and add initialization example (#1748)
- fix: wire after_tasks and after_implement hook events into command templates (#1702)
- make c ignores consistent with c++ (#1747)
- chore: bump version to 0.1.13 (#1746)
- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)
- chore: bump version to 0.1.12 (#1737)
- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)

### Added (Downstream)

- **Mistral Vibe Support**: Integrated Mistral Vibe agent from upstream
- **New Extensions**: Added Understanding, ralph, review, and fleet extensions from upstream community catalog
- **Subsystem Discovery**: Added subsystem detection to product and levelup init commands (from downstream fork)

### Added (Downstream)

- Merged upstream changes while preserving downstream package name (`agentic-sdlc-specify-cli`)


## [0.1.14] - 2026-03-09

### Added

- feat: add Tabnine CLI agent support
- **Multi-Catalog Support (#1707)**: Extension catalog system now supports multiple active catalogs simultaneously via a catalog stack
  - New `specify extension catalog list` command lists all active catalogs with name, URL, priority, and `install_allowed` status
  - New `specify extension catalog add` and `specify extension catalog remove` commands for project-scoped catalog management
  - Default built-in stack includes `catalog.json` (default, installable) and `catalog.community.json` (community, discovery only) — community extensions are now surfaced in search results out of the box
  - `specify extension search` aggregates results across all active catalogs, annotating each result with source catalog
  - `specify extension add` enforces `install_allowed` policy — extensions from discovery-only catalogs cannot be installed directly
  - Project-level `.specify/extension-catalogs.yml` and user-level `~/.specify/extension-catalogs.yml` config files supported, with project-level taking precedence
  - `SPECKIT_CATALOG_URL` environment variable still works for backward compatibility (replaces full stack with single catalog)
  - All catalog URLs require HTTPS (HTTP allowed for localhost development)
  - New `CatalogEntry` dataclass in `extensions.py` for catalog stack representation
  - Per-URL hash-based caching for non-default catalogs; legacy cache preserved for default catalog
  - Higher-priority catalogs win on merge conflicts (same extension id in multiple catalogs)
  - 13 new tests covering catalog stack resolution, merge conflicts, URL validation, and `install_allowed` enforcement
  - Updated RFC, Extension User Guide, and Extension API Reference documentation

## [0.1.13] - 2026-03-03

### Changed

- **Global Branch Numbering**: Use global branch numbering instead of per-short-name detection (from upstream)
- **Agent List Updates**: Merged upstream agent additions (vibe, q)

### Fixed

- **README Instructions**: Updated project initialization instructions from upstream
- **Duplicate Options**: Removed duplicate options in specify.md from upstream

## [0.0.117] - 2026-03-09

### Changed

- **LevelUp Command Rename**: Renamed `/levelup.spec` to `/levelup.specify` for consistency with `architect.specify` and full-verb naming convention
  - Renamed command file `spec.md` → `specify.md`
  - Updated all internal references across extension files and documentation
  - No backward compatibility - users must use `/levelup.specify`

## [0.0.116] - 2026-03-08

### Fixed

- **create-new-feature.sh Syntax Error**: Fixed unclosed quote in `discover_skills()` function at line 444 that caused bash syntax errors
- **git fetch Output Suppression**: Fixed `git fetch --all --prune` output being captured into `BRANCH_NUMBER` variable causing "10#Fetching" errors

## [0.0.115] - 2026-03-08

### Added

- **Context Auto-Discovery (Issue #47)**: Automatic team-ai-directives discovery
  - `discover_directives()` function with grep-based search for constitutions, personas, rules
  - Discovers relevant content from team-ai-directives directory structure
  - JSON output includes DISCOVERED_DIRECTIVES with file paths and search metadata
  - Support for both local paths and Git URL-based team-ai-directives

- **Skills Discovery (Issue #49)**: 5-layer skill discovery system
  - Manifest-based discovery from `.skills.json` (required/recommended/blocked skills)
  - Local skill discovery from team-ai-directives/skills/ with SKILL.md validation
  - Cache directory with 24h TTL refresh for performance optimization
  - URL fetching for remote manifest skills via manifest URLs
  - Automatic candidate extraction (max 5 skills, configurable threshold)
  - JSON output includes DISCOVERED_SKILLS with skill paths and relevance scores

- **Two-Tier Discovery Architecture**:
  - Layer 1 (Scripts): Fast, deterministic baseline discovery via grep search
  - Layer 2 (Templates): AI-powered semantic enhancement in command templates
  - Affects `/spec.specify` and `/spec.plan` templates with AI discovery sections

- **Template Updates**:
  - `context-template.md`: AI discovery sections for directives/skills with DISCOVERED_DIRECTIVES/DISCOVERED_SKILLS placeholders
  - `specify.md`: AI-Powered Discovery section after initial context generation
  - `plan.md`: AI-Powered Context/Skills Refresh section before implementation

### Changed

- **Team-AI-Directives Integration**: Discovery features automatically use team-ai-directives path
  - Supports both local paths (`~/workspace/team-ai-directives`) and Git URLs
  - Automatic Git cloning for remote repositories
  - Discovery results integrated into context.md generation

- **Skill Caching**: Daily refresh (24h TTL) for performance optimization
  - `skills-cache/.last_refresh` marker file for tracking cache age
  - Automatic cache rebuild when timestamp exceeds 24 hours
  - Graceful fallback when team-ai-directives unavailable

### Documentation

- Added Context Auto-Discovery and Skills Discovery features to README.md
- Updated Team AI Directives integration section with discovery workflow
- Added comprehensive discovery documentation to docs/discovery.md
- Documented two-tier discovery architecture (scripts → templates)

## [0.0.114] - 2026-03-07

### Added

- **Architect Validation Integration**: Added READ-ONLY `adlc.architect.validate` command that validates plan alignment with architecture
  - Validates 7 PILLAR checks: component alignment, interface contracts, data model consistency, context/functional/information/development view alignment
  - Checks diagram consistency: system boundaries and data flows
  - Returns structured JSON with blocking, high-severity, and warnings findings
  - Gracefully skips when architecture doesn't exist (returns `{"status":"skipped"}`)

- **Extension Hooks for Architect**: Added automatic extension hook integration for architect workflow
  - `before_plan` hook: Creates feature-level ADRs using `adlc.architect.specify`
  - `after_plan` hook: Validates plan alignment using `adlc.architect.validate --for-plan`
  - Hooks execute automatically when `.specify/memory/adr.md` exists

- **Multi-line Framework Options Format**: Updated spec-template.md to use multi-line format for clarity
  ```
  contracts={contracts}
  data_models={data_models}
  ```

### Changed

- **Simplified Framework Options**: Removed deprecated CLI flags (--tdd, --architecture)
  - Retained only user-configurable flags: `--contracts`, `--no-contracts`, `--data-models`, `--no-data-models`
  - TDD and architecture validation now handled via extensions (architect, tdd)

- **Architecture Validation Workflow**: Moved validation from spec level to plan level
  - Previous: validation in clarify.md (spec spec)
  - New: validation via architect.validate command with after_plan hook (plan level)
  - README.md and docs/architecture.md updated with new workflow

- **Architect Extension Scripts**: Added validate action to setup-architect.sh and setup-architect.ps1
  - bash: New `action_validate()` function with graceful skip behavior
  - PowerShell: New `Invoke-Validate()` function with graceful skip behavior

### Documentation

- `extensions/architect/README.md`: Added validate command to commands table and hooks integration section
- `extensions/architect/commands/validate.md`: Complete command documentation with flags and usage
- `docs/architecture.md`: Updated workflow to describe hooks-based architecture validation
- `README.md`: Added Framework Options section documenting simplified CLI flags

## [0.0.112] - 2026-03-06

### Fixed

- **Pre-Installed Extension Banner**: Fixed catalog.json search path to properly detect and display pre-installed extensions
  - Added `.specify/catalog.json` as primary search path before `.specify/extensions/catalog.json`
  - Banner now correctly shows up to 4 pre-installed extensions (LevelUp, Architect, Quick)
  - Previous code failed silently due to incorrect path checking

## [0.0.112] - 2026-03-06

### Fixed

- **Pre-Installed Extension Banner**: Fixed catalog.json search path to properly detect and display pre-installed extensions
  - Added `.specify/catalog.json` as primary search path before `.specify/extensions/catalog.json`
  - Banner now correctly shows up to 4 pre-installed extensions (LevelUp, Architect, Quick)
  - Previous code failed silently due to incorrect path checking

## [0.0.111] - 2026-03-06

### Removed

- **Spec-Code Synchronization Feature**: Removed `--spec-sync` CLI option and all related code
  - Removed broken stub implementation that created `.mcp.json` with incorrect format
  - Removed scripts: `spec-hooks-install.{sh,ps1}`, `spec-sync-*.{sh,ps1}` (8 files)
  - Removed documentation references to automatic spec-to-code synchronization
  - Users can still manually configure `.mcp.json` with correct `command/args/env` format

- **MCP CLI Arguments**: Removed `--issue-tracker`, `--async-agent`, `--git-platform` CLI options
  - Removed configuration dictionaries: `ISSUE_TRACKER_CONFIG`, `AGENT_MCP_CONFIG`, `GIT_PLATFORM_CONFIG`
  - Removed configuration functions: `configure_mcp_servers()`, `configure_agent_mcp_servers()`, `configure_git_platform_mcp_servers()`
  - Removed "Configure gateway" dead tracker entry
  - CLI-generated `.mcp.json` files used incorrect `type/url` format instead of required `command/args/env` format
  - Users should manually configure `.mcp.json` instead

- **Gateway Configuration**: Removed "Configure gateway" tracker entry (dead code with no implementation)

### Documentation

- Removed spec-code synchronization feature documentation from README.md, AGENTS.md, and roadmap.md
- Removed MCP CLI argument examples from installation docs
- Removed "Issue Tracker Extension Refactor" future enhancement from roadmap

## [0.0.110] - 2026-03-06

*(No changes - version bump only)*

## [0.0.109] - 2026-06

### Fixed

- **Quick Extension Enforcement**: Add mandatory checkpoints to prevent AI from skipping workflow phases
  - Added 7 enforcement checkpoints with mandatory user confirmations
  - Strengthened directive language from permissive to mandatory
  - Added enforcement mode section with critical rules at template start
  - Prevent AI from defaulting to file analysis mode
  - Ensures Mission Brief is always collected before file operations

### Removed

- Remove build mode leftover references from codebase after build/spec mode removal in 0.0.106

## [0.0.108] - 2026-03-06

### Added

- **Quick Extension**: Session-based ad-hoc task execution workflow
  - Single-command `/quick.implement` for rapid task execution without file artifacts
  --session-based workflow with no PLAN.md, TASKS.md, CONTEXT.md files
  - 2 approval points: Mission Brief confirmation + Task breakdown approval
  - Sequential execution with stop-on-error handling
  - Simple task checklist format (3-8 tasks, markdown checkboxes)
  - Auto-installed by default (preinstall: true in catalog)

## [0.0.107] - 2026-03-06

### Added

- CLI banner now displays installed extension summary when run from spec-kit projects
- `specify version` command now shows installed extensions in version output table
- Extension visibility improvements: makes extensions more discoverable without requiring separate commands

### Fixed

- Correctly display extension names instead of command names (e.g., not showing "trace" as an extension)

## [0.0.106] - 2026-03-06

### Changed

- **BREAKING**: Remove build/spec mode architecture from core commands
  - Core commands now use framework options only (--tdd, --contracts, --data-models, --risk-tests)
  - Removed mode-aware behavior, mode detection, and mode-specific logic from 20 files
  - Removed build templates: spec-template-build.md, plan-template-build.md
  - Eval tests reduced from 23→22 LLM eval tests
  - Simplified tools framework to single spec-driven workflow

### Removed

- tests/test_mode_evolution.py (obsolete build/spec mode tests)

## [0.0.105] - 2026-03-06

### Added

- feat(extensions): add Jira Integration to community catalog (#1764)
- Add Azure DevOps Integration extension to community catalog (#1734)

## [0.0.97] - 2026-03-05

### Fixed

- fix: only install bundled extensions that actually exist (not just catalog entries)

## [0.0.96] - 2026-03-05

### Fixed

- fix: allow adlc.* command names in extension validation (was only accepting speckit.*)

## [0.0.95] - 2026-03-05

### Changed

- feat!: migrate command namespace from speckit.* to adlc.*
  - Primary command names changed from speckit.* to adlc.*
  - Short aliases now available (architect.*, levelup.*)
  - Removed legacy setup-architecture.{sh,ps1} scripts
  - Fixed setup-architect.ps1 help text

## [0.0.94] - 2026-03-05

### Fixed

- fix: version banner now correctly detects package name for agentic-sdlc-specify-cli
  - Updated `version()` command to try both package names like `get_speckit_version()`
  - Resolves issue where CLI version showed "unknown" when package installed as agentic-sdlc-specify-cli


## [0.0.93] - 2026-03-05

### Changed

- Breaking change/adlc prefix migration (#66)
- chore: remove orphaned test artifacts (bin/act, tmp/)


## [0.0.90] - 2026-03-04

### Changed

- fix: correct release-trigger workflow for agentic-sdlc-v tag format
- fix: update release workflow to trigger on agentic-sdlc-v* tags


## [Unreleased]

## [0.0.89] - 2026-03-04

### Merged from Upstream (spec-kit 0.1.13)

This release merges upstream changes from github/spec-kit while preserving all custom features.

#### New Features from Upstream

- **Extension Hook Support**: Added before/after hooks for tasks and implement commands
  - `before_tasks` hook: Execute extensions before task generation
  - `after_tasks` hook: Execute extensions after task generation
  - `before_implement` hook: Execute extensions before implementation
  - `after_implement` hook: Execute extensions after implementation
  - Supports both optional and mandatory hooks
  - Condition evaluation deferred to HookExecutor implementation

#### Template Improvements from Upstream

- **implement.md**: Added Pre-Execution Checks section for extension hooks
- **tasks.md**: Added Pre-Execution Checks section for extension hooks
- **C ignore patterns**: Made consistent with C++ patterns

#### Documentation Updates from Upstream

- **README.md**: Updated Antigravity link to correct URL (antigravity.google)
- **README.md**: Added Antigravity initialization example
- **README.md**: Added generic agent initialization example

#### Conflict Resolution

Integrated upstream changes while preserving fork-specific features:

- **Mode Detection**: Retained Build Mode and Spec Mode workflow detection
- **Dual Execution Loop**: Preserved SYNC/ASYNC task classification system
- **TDD Support**: Maintained TDD mode option integration
- **Risk-Based Testing**: Kept risk test generation capabilities
- **Issue Tracker Integration**: Retained ASYNC task labeling and tracking

### Added

- **Hook Test Infrastructure**: New test files for validating extension hooks
  - `tests/hooks/.specify/extensions.yml`: Test extension configuration
  - `tests/hooks/TESTING.md`: Hook testing documentation
  - `tests/hooks/plan.md`, `spec.md`, `tasks.md`: Test scenario files

### Changed

- **Agent References**: Kept `spec.*` agent references (not changed to `speckit.*`)

## [0.0.88] - 2026-03-04

### Fixed

- **Architect Extension Bundling**: Add architect extension to pyproject.toml for proper bundling in release packages
  - Extension was merged in #57 but not included in wheel/sdist builds
  - Now bundled alongside levelup extension in `specify_cli/bundled_extensions/`

### Merged from Upstream (spec-kit 0.1.13)

- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)

### Added

- **LevelUp Extension**: Modularized `/spec.levelup` into dedicated extension with 5 CDR-based commands (#56)
  - `/levelup.init` - Brownfield codebase scan to discover Context Decision Records (CDRs)
  - `/levelup.clarify` - Resolve CDR ambiguities and accept/reject decisions
  - `/levelup.specify` - Extract CDRs from current feature spec context (replaces old `/spec.levelup`)
  - `/levelup.skills` - Build ONE skill at a time from accepted CDRs
  - `/levelup.implement` - Compile accepted CDRs into PR to team-ai-directives
  - CDRs stored in `.specify/memory/cdr.md` (similar to ADRs)
  - Skill drafts stored in `.specify/drafts/skills/{skill-name}/`
  - Supports `SPECIFY_TEAM_DIRECTIVES` env var for team directives path
  - **Auto-installed by default**: LevelUp extension is now automatically installed during `specify init`

### Changed

- **CLI Help Text**: Updated `/spec.levelup` references to `/levelup.specify` in init command help and next steps panel
- **Context View Blackbox Enforcement**: Updated architect commands to strictly enforce blackbox system representation in Context View
  - System MUST appear as a single unified node (no internal components)
  - Only external actors (stakeholders/users) and external systems shown
  - Internal databases, services, caches explicitly excluded from Context View
  - Added validation checklist to `architect.implement` command
  - Updated diagram templates with proper styling for stakeholders vs external systems
  - Clear guidance on what belongs in Context View vs Functional/Deployment views

### Added

- **Lean Architecture Views**: Configurable view generation with core vs optional views
  - Default "core" views: Context, Functional, Information, Development, Deployment
  - Optional views: Concurrency, Operational (via `--views` flag)
  - Support for: `--views all`, `--views core`, `--views concurrency,operational`
  - Marked optional views in templates with HTML comments

- **Surprise-Value Heuristic for ADRs**: Skip obvious ecosystem defaults, document only surprising/risky decisions
  - Configurable via `--adr-heuristic` flag: `surprising` (default), `all`, `minimal`
  - Heuristic rules distinguish obvious (PostgreSQL for relational) vs surprising (custom auth)
  - Configuration in `config.json`: `architecture.adr.heuristic`

- **Constitution Cross-Reference**: Strict checking for ADR/Constitution alignment
  - Always enabled in `/architect.clarify`
  - Detects duplicates (constitution already mandates), violations, unclear alignment
  - **Option A (Amend Constitution) as PRIMARY resolution** for violations
  - Adds "Constitution Alignment" section to ADR template

- **ADR Template Improvements**:
  - Renamed "Alternatives Considered" to "Common Alternatives"
  - Changed framing from "Rejected because" to neutral "Trade-offs"
  - Added "Discovered" status for reverse-engineered ADRs
  - Removed fabricated rejection rationale requirement
  - Added "Constitution Alignment" section with compliance tracking

- **Existing Docs Deduplication**: Scan and reference instead of duplicate
  - Scans `docs/` directory and root `*.md` files (configurable paths)
  - References existing docs (README, AGENTS.md, CONTRIBUTING) instead of duplicating
  - Auto-merges when existing architecture found (no prompt)
  - New `scan_existing_docs()` function in setup-architecture.sh

- **Risks & Gaps Analysis**: Cross-cutting analysis in `/architect.clarify`
  - Identifies operational gaps, technical debt, SPOFs, security concerns
  - Section-based gap IDs (e.g., `3.6.1` = Deployment view, gap #1)
  - Runs BEFORE constitution cross-reference (Phase 2.5)
  - Output integrated into existing view sections

### Changed

- **BREAKING: Architecture File Paths**: Updated to new two-file structure
  - Architecture Description: `AD.md` at project root (was `memory/architecture.md`)
  - Architecture Decision Records: `memory/adr.md` (unchanged)
  - Updated all scripts: `setup-architecture.sh`, `setup-plan.sh`, `common.sh`
  - Updated command templates: `architect.init.md`, `architect.specify.md`, `architect.clarify.md`

- **Configuration**: Added comprehensive architecture configuration
  - `architecture.views`: "core", "all", or comma-separated list
  - `architecture.adr.heuristic`: "surprising", "all", "minimal"
  - `architecture.adr.check_constitution`: true (always enabled)
  - `architecture.deduplication.scan_paths`: ["docs/", "*.md"]
  - Helper functions: `get_architecture_views()`, `get_adr_heuristic()`, `get_architecture_config()`

## [0.3.0] - 2026-02-08

### Added

- **Architecture Command Suite**: Split monolithic `/architect` command into 4 focused commands following the Rozanski & Woods methodology
  - `/architect.specify` - Interactive PRD exploration to create system ADRs (greenfield projects)
  - `/architect.clarify` - Refine and resolve ambiguities in existing ADRs
  - `/architect.init` - Reverse-engineer architecture from existing codebase (brownfield projects)
  - `/architect.implement` - Generate full Architecture Description (AD.md) from ADRs
- **New Architecture Templates**:
  - `templates/AD-template.md` - Full Architecture Description with 7 viewpoints + 2 perspectives
  - `templates/adr-template.md` - MADR (Markdown Architecture Decision Record) format
  - `templates/feature-AD-template.md` - Feature-level Architecture Description for `specs/{feature}/`
- **Two-Level Architecture System**: System-level and feature-level architecture governance
  - System ADRs in `memory/adr.md`, system AD in `AD.md` (root)
  - Feature ADRs in `specs/{feature}/adr.md`, feature AD in `specs/{feature}/AD.md`
  - Feature ADRs auto-validate against system ADRs (VIOLATION/Alignment markers)
- **Feature Architecture Option**: `--architecture` flag for `/spec.plan` to generate feature-level architecture artifacts

### Changed

- **BREAKING: Command Naming Convention**: Renamed command prefix from `/speckit.*` to `/spec.*` for consistency
  - `/speckit.specify` -> `/spec.specify`
  - `/speckit.plan` -> `/spec.plan`
  - `/speckit.tasks` -> `/spec.tasks`
  - `/speckit.implement` -> `/spec.implement`
  - `/speckit.analyze` -> `/spec.analyze`
  - `/speckit.clarify` -> `/spec.clarify`
  - `/speckit.checklist` -> `/spec.checklist`
  - `/speckit.constitution` -> `/spec.constitution`
  - `/speckit.levelup` -> `/spec.levelup`
- **BREAKING: Architect Command Split**: Removed monolithic `/spec.architect` command
  - Old `/spec.architect init` -> `/architect.specify` (interactive ADR creation)
  - Old `/spec.architect map` -> `/architect.init` (brownfield reverse-engineering)
  - Old `/spec.architect update` -> `/architect.clarify` (ADR refinement)
  - Old `/spec.architect review` -> `/spec.analyze` (merged into analyze)

### Removed

- `templates/commands/architect.md` - Replaced by `architect.specify.md`, `architect.clarify.md`, `architect.init.md`, `architect.implement.md`

## [0.2.0] - 2026-02-07

### Added

- **Skills Package Manager**: A developer-grade package manager for agent skills
  - **CLI Commands**:
    - `specify skill search <query>` - Search skills.sh registry with keyword filtering
    - `specify skill install <ref>` - Install from GitHub/GitLab/local paths
    - `specify skill update [name|--all]` - Update installed skills
    - `specify skill remove <name>` - Remove installed skill
    - `specify skill list [--outdated|--json]` - List installed skills
    - `specify skill eval <path> [--review|--task|--full|--report]` - Evaluate skill quality
    - `specify skill sync-team [--dry-run]` - Sync with team manifest (install required, show recommended)
    - `specify skill check-updates` - Check for available skill updates
    - `specify skill config [key] [value]` - View/modify skills configuration
  - **Auto-Discovery**: Skills automatically matched to features based on descriptions during `/spec.specify`
    - Keyword extraction with stop word filtering
    - Relevance scoring: 60% description overlap, 40% content overlap
    - Configurable threshold (default: 0.7) and max skills (default: 3)
    - Integration with `/spec.specify` template (Step 7: Context Population)
  - **Team Skills Manifest**: Support for `team-ai-directives/skills.json` with:
    - `required` skills - auto-installed during init if `auto_install_required: true`
    - `recommended` skills - suggested to users during init
    - `blocked` skills - prevented from installation (with `--skip-blocked-check` override)
    - `internal` skills - local team skills
    - Policy enforcement: `enforce_blocked`, `allow_project_override`
  - **Dual Registry**: Search skills.sh registry and install from GitHub/GitLab/local paths
  - **Evaluation Framework**: Review evaluation with 100-point scoring:
    - Frontmatter validation (20 pts): name, description, trigger keywords
    - Content organization (30 pts): line count, sections, headers
    - Self-containment (30 pts): no @rule:/@persona:/@example: references
    - Documentation quality (20 pts): headers, code examples, references, setup
  - **Policy Enforcement**: Team-level policy for required skills auto-installation and blocking
    - Install command checks blocked skills before installation
    - `--skip-blocked-check` flag for override (not recommended)
  - **Global Config Integration**: Skills config in `~/.config/specify/config.json`:
    - `auto_activation_threshold`: 0.7 (minimum relevance score)
    - `max_auto_skills`: 3 (maximum skills to inject)
    - `preserve_user_edits`: true (merge with user-added skills)
    - `registry_url`: <https://skills.sh/api>
    - `evaluation_required`: false
  - **Init Integration**: `specify init` now:
    - Creates `.specify/skills.json` manifest
    - Auto-installs team required skills (if `auto_install_required: true`)
    - Displays recommended skills panel after init completion
  - New module: `src/specify_cli/skills/discovery.py` for auto-discovery engine
  - References: skills.sh Registry (<https://skills.sh>)

## [0.1.0] - 2026-01-30

### Changed

- **BREAKING: Removed Global Mode Management**: Replaced global mode switching with per-spec mode architecture
  - **Deprecated**: `/mode` command removed (use `/specify` parameters instead)
  - **Per-Spec Architecture**: Each feature can operate in different modes simultaneously
  - **Auto-Detection System**: Commands automatically detect mode from spec.md metadata
  - **Parameter-Based Configuration**: Modes and framework options set via `/specify` parameters during feature creation
  - **Metadata Storage**: Mode and framework options stored in spec.md for traceability
  - **Architecture Mode-Agnostic**: `/architect` command remains mode-agnostic (system-level architecture should not be constrained by feature-level modes)
  - Added `detect_workflow_config()` / `Get-WorkflowConfig` functions to bash and PowerShell scripts
  - Updated `setup-plan.sh` and `setup-plan.ps1` to auto-detect mode from spec.md

### Added

- **Per-Spec Mode Architecture**: Feature-level mode configuration with automatic detection
  - **Mixed-Mode Workflows**: Different features can use different modes simultaneously in the same project
  - **Optional Architecture Support**: Architecture documentation available in all modes
  - `/spec.architect` command implementing Rozanski & Woods "Software Systems Architecture" methodology
  - 7 Core Viewpoints: Context, Functional, Information, Concurrency, Development, Deployment, Operational
  - 2 Cross-cutting Perspectives: Security, Performance & Scalability
  - Four actions: `init` (greenfield), `map` (brownfield/reverse-engineering), `update` (sync with changes), `review` (validation)
  - Language-agnostic codebase scanning for brownfield projects
  - Generates `memory/architecture.md` as central architecture artifact
  - Works silently in both build and spec modes
  - Templates: `templates/architecture-template.md` and `templates/commands/architect.md`
  - Scripts: `scripts/bash/setup-architecture.sh` and `scripts/powershell/setup-architecture.ps1`

## [0.0.26] - 2026-01-28

### Changed

- **Command Template Alignment**: Aligned `templates/commands/architect.md` structure with `templates/commands/specify.md` for consistency
  - Fixed YAML frontmatter indentation (2-space consistent across all sections)
  - Added quotes around {ARGS} parameter in scripts section
  - Added new "Outline" section explaining script execution approach
  - Expanded "Mode Detection" section with 3 detailed subsections matching specify.md narrative depth
  - Reorganized "Operating Constraints" into "Role & Context" subsections for better organization
  - Verified heading levels (##, ###, ####) are consistent throughout document
  - Maintained Rozanski & Woods methodology while improving document structure

## [0.0.25] - 2026-01-28

### Fixed

- **Constitution Template Example Dates**: Updated example dates in `memory/constitution.md` from 2025 to 2026 to reflect current year

## [0.0.24] - 2026-01-28

### Added

- Architecture Description (AD) Mode implementation
- Setup scripts for architecture workflow

## [0.0.23] - 2026-01-28

### Changed

- **Global Configuration Support**: Configuration now stored globally in `~/.config/specify/config.json` (XDG Base Directory compliant)
  - Linux: `$XDG_CONFIG_HOME/specify/config.json` (defaults to `~/.config/specify/config.json`)
  - macOS: `~/Library/Application Support/specify/config.json`
  - Windows: `%APPDATA%\specify\config.json`
  - All projects share a single global configuration file
  - Uses `platformdirs` for cross-platform path resolution
  - Updated Python CLI (`src/specify_cli/__init__.py`) with `get_global_config_path()` function
  - Updated bash scripts (`scripts/bash/common.sh`) with `get_global_config_path()` helper
  - Updated PowerShell scripts (`scripts/powershell/common.ps1`) with `Get-GlobalConfigPath` function
  - Old local `.specify/config/` directories are now ignored (added to `.gitignore`)

### Removed

- **`mode_history` from configuration**: Removed `workflow.mode_history` field from config structure (was unused)

## [0.1.0-upstream] - 2026-01-28

### Added

- **Extension System**: Introduced modular extension architecture for Spec Kit
  - Extensions are self-contained packages that add commands and functionality without bloating core
  - Extension manifest schema (`extension.yml`) with validation
  - Extension registry (`.specify/extensions/.registry`) for tracking installed extensions
  - Extension manager module (`src/specify_cli/extensions.py`) for installation/removal
  - New CLI commands:
    - `specify extension list` - List installed extensions
    - `specify extension add` - Install extension from local directory or URL
    - `specify extension remove` - Uninstall extension
    - `specify extension search` - Search extension catalog
    - `specify extension info` - Show detailed extension information
  - Semantic versioning compatibility checks
  - Support for extension configuration files
  - Command registration system for AI agents (Claude support initially)
  - Added dependencies: `pyyaml>=6.0`, `packaging>=23.0`

- **Extension Catalog**: Extension discovery and distribution system
  - Central catalog (`extensions/catalog.json`) for published extensions
  - Extension catalog manager (`ExtensionCatalog` class) with:
    - Catalog fetching from GitHub
    - 1-hour local caching for performance
    - Search by query, tag, author, or verification status
    - Extension info retrieval
  - Catalog cache stored in `.specify/extensions/.cache/`
  - Search and info commands with rich console output
  - Added 9 catalog-specific unit tests (100% pass rate)

- **Jira Extension**: First official extension for Jira integration
  - Extension ID: `jira`
  - Version: 1.0.0
  - Commands:
    - `/speckit.jira.specstoissues` - Create Jira hierarchy from spec and tasks
    - `/speckit.jira.discover-fields` - Discover Jira custom fields
    - `/speckit.jira.sync-status` - Sync task completion status
  - Comprehensive documentation (README, usage guide, examples)
  - MIT licensed

- **Hook System**: Extension lifecycle hooks for automation
  - `HookExecutor` class for managing extension hooks
  - Hooks registered in `.specify/extensions.yml`
  - Hook registration during extension installation
  - Hook unregistration during extension removal
  - Support for optional and mandatory hooks
  - Hook execution messages for AI agent integration
  - Condition support for conditional hook execution (placeholder)

- **Extension Management**: Advanced extension management commands
  - `specify extension update` - Check and update extensions to latest version
  - `specify extension enable` - Enable a disabled extension
  - `specify extension disable` - Disable extension without removing it
  - Version comparison with catalog
  - Update notifications
  - Preserve configuration during updates

- **Multi-Agent Support**: Extensions now work with all supported AI agents (Phase 6)
  - Automatic detection and registration for all agents in project
  - Support for 16+ AI agents (Claude, Gemini, Copilot, Cursor, Qwen, and more)
  - Agent-specific command formats (Markdown and TOML)
  - Automatic argument placeholder conversion ($ARGUMENTS → {{args}})
  - Commands registered for all detected agents during installation
  - Multi-agent command unregistration on extension removal
  - `CommandRegistrar.register_commands_for_agent()` method
  - `CommandRegistrar.register_commands_for_all_agents()` method

- **Configuration Layers**: Full configuration cascade system (Phase 6)
  - **Layer 1**: Defaults from extension manifest (`extension.yml`)
  - **Layer 2**: Project config (`.specify/extensions/{ext-id}/{ext-id}-config.yml`)
  - **Layer 3**: Local config (`.specify/extensions/{ext-id}/local-config.yml`, gitignored)
  - **Layer 4**: Environment variables (`SPECKIT_{EXT_ID}_{KEY}` pattern)
  - Recursive config merging with proper precedence
  - `ConfigManager` class for programmatic config access
  - `get_config()`, `get_value()`, `has_value()` methods
  - Support for nested configuration paths with dot-notation

- **Hook Condition Evaluation**: Smart hook execution based on runtime conditions (Phase 6)
  - Config conditions: `config.key.path is set`, `config.key == 'value'`, `config.key != 'value'`
  - Environment conditions: `env.VAR is set`, `env.VAR == 'value'`, `env.VAR != 'value'`
  - Automatic filtering of hooks based on condition evaluation
  - Safe fallback behavior on evaluation errors
  - Case-insensitive pattern matching

- **Hook Integration**: Agent-level hook checking and execution (Phase 6)
  - `check_hooks_for_event()` method for AI agents to query hooks after core commands
  - Condition-aware hook filtering before execution
  - `enable_hooks()` and `disable_hooks()` methods per extension
  - Formatted hook messages for agent display
  - `execute_hook()` method for hook execution information

- **Documentation Suite**: Comprehensive documentation for users and developers
  - **EXTENSION-USER-GUIDE.md**: Complete user guide with installation, usage, configuration, and troubleshooting
  - **EXTENSION-API-REFERENCE.md**: Technical API reference with manifest schema, Python API, and CLI commands
  - **EXTENSION-PUBLISHING-GUIDE.md**: Publishing guide for extension authors
  - **RFC-EXTENSION-SYSTEM.md**: Extension architecture design document

- **Extension Template**: Starter template in `extensions/template/` for creating new extensions
  - Fully commented `extension.yml` manifest template
  - Example command file with detailed explanations
  - Configuration template with all options
  - Complete project structure (README, LICENSE, CHANGELOG, .gitignore)
  - EXAMPLE-README.md showing final documentation format

- **Unit Tests**: Comprehensive test suite with 39 tests covering all extension system components
  - Test coverage: 83% of extension module code
  - Test dependencies: `pytest>=7.0`, `pytest-cov>=4.0`
  - Configured pytest in `pyproject.toml`

### Changed

- Version bumped to 0.1.0 (minor release for new feature)

## [0.0.22] - 2025-11-07

- Support for VS Code/Copilot agents, and moving away from prompts to proper agents with hand-offs.
- Move to use `AGENTS.md` for Copilot workloads, since it's already supported out-of-the-box.
- Adds support for the version command. ([#486](https://github.com/github/spec-kit/issues/486))
- Fixes potential bug with the `create-new-feature.ps1` script that ignores existing feature branches when determining next feature number ([#975](https://github.com/github/spec-kit/issues/975))
- Add graceful fallback and logging for GitHub API rate-limiting during template fetch ([#970](https://github.com/github/spec-kit/issues/970))

## [0.0.21] - 2025-10-21

- Fixes [#975](https://github.com/github/spec-kit/issues/975) (thank you [@fgalarraga](https://github.com/fgalarraga)).
- Adds support for Amp CLI.
- Adds support for VS Code hand-offs and moves prompts to be full-fledged chat modes.
- Adds support for `version` command (addresses [#811](https://github.com/github/spec-kit/issues/811) and [#486](https://github.com/github/spec-kit/issues/486), thank you [@mcasalaina](https://github.com/mcasalaina) and [@dentity007](https://github.com/dentity007)).
- Adds support for rendering the rate limit errors from the CLI when encountered ([#970](https://github.com/github/spec-kit/issues/970), thank you [@psmman](https://github.com/psmman)).

## [0.0.20] - 2025-10-14

### Added

- **Intelligent Branch Naming**: `create-new-feature` scripts now support `--short-name` parameter for custom branch names
  - When `--short-name` provided: Uses the custom name directly (cleaned and formatted)
  - When omitted: Automatically generates meaningful names using stop word filtering and length-based filtering
  - Filters out common stop words (I, want, to, the, for, etc.)
  - Removes words shorter than 3 characters (unless they're uppercase acronyms)
  - Takes 3-4 most meaningful words from the description
  - **Enforces GitHub's 244-byte branch name limit** with automatic truncation and warnings
  - Examples:
    - "I want to create user authentication" → `001-create-user-authentication`
    - "Implement OAuth2 integration for API" → `001-implement-oauth2-integration-api`
    - "Fix payment processing bug" → `001-fix-payment-processing`
    - Very long descriptions are automatically truncated at word boundaries to stay within limits
  - Designed for AI agents to provide semantic short names while maintaining standalone usability

### Changed

- Enhanced help documentation for `create-new-feature.sh` and `create-new-feature.ps1` scripts with examples
- Branch names now validated against GitHub's 244-byte limit with automatic truncation if needed

## [0.0.19] - 2025-10-10

### Added

- Support for CodeBuddy (thank you to [@lispking](https://github.com/lispking) for the contribution).
- You can now see Git-sourced errors in the Specify CLI.

### Changed

- Fixed the path to the constitution in `plan.md` (thank you to [@lyzno1](https://github.com/lyzno1) for spotting).
- Fixed backslash escapes in generated TOML files for Gemini (thank you to [@hsin19](https://github.com/hsin19) for the contribution).
- Implementation command now ensures that the correct ignore files are added (thank you to [@sigent-amazon](https://github.com/sigent-amazon) for the contribution).

## [0.0.18] - 2025-10-06

### Added

- Support for using `.` as a shorthand for current directory in `specify init .` command, equivalent to `--here` flag but more intuitive for users.
- Use the `/spec.` command prefix to easily discover Spec Kit-related commands.
- Refactor the prompts and templates to simplify their capabilities and how they are tracked. No more polluting things with tests when they are not needed.
- Ensure that tasks are created per user story (simplifies testing and validation).
- Add support for Visual Studio Code prompt shortcuts and automatic script execution.

### Changed

- All command files now prefixed with `spec.` (e.g., `spec.specify.md`, `spec.plan.md`) for better discoverability and differentiation in IDE/CLI command palettes and file explorers

## [0.0.17] - 2025-09-22

### Added

- New `/clarify` command template to surface up to 5 targeted clarification questions for an existing spec and persist answers into a Clarifications section in the spec.
- New `/analyze` command template providing a non-destructive cross-artifact discrepancy and alignment report (spec, clarifications, plan, tasks, constitution) inserted after `/tasks` and before `/implement`.
  - Note: Constitution rules are explicitly treated as non-negotiable; any conflict is a CRITICAL finding requiring artifact remediation, not weakening of principles.

## [0.0.16] - 2025-09-22

### Added

- `--force` flag for `init` command to bypass confirmation when using `--here` in a non-empty directory and proceed with merging/overwriting files.

## [0.0.15] - 2025-09-21

### Added

- Support for Roo Code.

## [0.0.14] - 2025-09-21

### Changed

- Error messages are now shown consistently.

## [0.0.13] - 2025-09-21

### Added

- Support for Kilo Code. Thank you [@shahrukhkhan489](https://github.com/shahrukhkhan489) with [#394](https://github.com/github/spec-kit/pull/394).
- Support for Auggie CLI. Thank you [@hungthai1401](https://github.com/hungthai1401) with [#137](https://github.com/github/spec-kit/pull/137).
- Agent folder security notice displayed after project provisioning completion, warning users that some agents may store credentials or auth tokens in their agent folders and recommending adding relevant folders to `.gitignore` to prevent accidental credential leakage.

### Changed

- Warning displayed to ensure that folks are aware that they might need to add their agent folder to `.gitignore`.
- Cleaned up the `check` command output.

## [0.0.12] - 2025-09-21

### Changed

- Added additional context for OpenAI Codex users - they need to set an additional environment variable, as described in [#417](https://github.com/github/spec-kit/issues/417).

## [0.0.11] - 2025-09-20

### Added

- Codex CLI support (thank you [@honjo-hiroaki-gtt](https://github.com/honjo-hiroaki-gtt) for the contribution in [#14](https://github.com/github/spec-kit/pull/14))
- Codex-aware context update tooling (Bash and PowerShell) so feature plans refresh `AGENTS.md` alongside existing assistants without manual edits.

## [0.0.10] - 2025-09-20

### Fixed

- Addressed [#378](https://github.com/github/spec-kit/issues/378) where a GitHub token may be attached to the request when it was empty.

## [0.0.9] - 2025-09-19

### Changed

- Improved agent selector UI with cyan highlighting for agent keys and gray parentheses for full names

## [0.0.8] - 2025-09-19

### Added

- Windsurf IDE support as additional AI assistant option (thank you [@raedkit](https://github.com/raedkit) for the work in [#151](https://github.com/github/spec-kit/pull/151))
- GitHub token support for API requests to handle corporate environments and rate limiting (contributed by [@zryfish](https://github.com/@zryfish) in [#243](https://github.com/github/spec-kit/pull/243))

### Changed

- Updated README with Windsurf examples and GitHub token usage
- Enhanced release workflow to include Windsurf templates

## [0.0.7] - 2025-09-18

### Changed

- Updated command instructions in the CLI.
- Cleaned up the code to not render agent-specific information when it's generic.

## [0.0.6] - 2025-09-17

### Added

- opencode support as additional AI assistant option

## [0.0.5] - 2025-09-17

### Added

- Qwen Code support as additional AI assistant option

## [0.0.4] - 2025-09-14

### Added

- SOCKS proxy support for corporate environments via `httpx[socks]` dependency

### Fixed

N/A

### Changed

N/A
