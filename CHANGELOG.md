# Changelog

All notable changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to to [Semantic Versioning](https://semver.org/spec/v2.0.0/).

## [0.1.16] - 2026-03-20

### Changed

- **Upstream merge**: Synced with github/spec-kit (6 commits)
  - feat: add Junie agent support (#1831)
  - feat: add timestamp-based branch naming option (`--branch-numbering timestamp`) (#1911)
  - fix: Align native skills frontmatter with install_ai_skills (#1920)
  - docs: add Extension Comparison Guide for community extensions (#1897)
  - docs: update SUPPORT.md, fix issue templates, add preset submission template (#1910)
  - docs: update publishing guide with Category and Effect columns (#1913)

- **architect extension v1.0.0**: ADR lifecycle with sequential viewpoint generation
  - Sequential viewpoint generation: "Generate views in this order (earlier views inform later ones)"
  - ADR lifecycle management:
    - `init`/`specify` output to `.specify/drafts/adr.md` (Proposed/Discovered status)
    - `clarify` refines ADRs in drafts
    - `implement` moves Accepted ADRs to canonical location:
      - `.specify/memory/adr.md` (project canonical)
      - `team-ai-directives/context_modules/adr.md` (if team-ai-directives configured)
    - `analyze`/`validate` read from all locations (memory, team, drafts)
  - Updated `extension.yml` and `config-template.yml` with ADR location defaults

### Preserved

- All tikalk-specific features maintained:
  - Orange branding theme (#f47721)
  - `--team-ai-directives` CLI parameter
  - Skills package manager (`specify skill` subcommand)
  - Bundled extensions/presets installation

## [0.1.15] - 2026-03-19

### Changed

- **Upstream merge**: Synced with github/spec-kit v0.3.2
  - feat: migrate Codex/agy init to native skills workflow (#1906)
  - feat(presets): add enable/disable toggle and update semantics (#1891)
  - feat: add iFlow CLI support (#1875)
  - feat(commands): wire before/after hook events into specify and plan templates (#1886)
  - Add conduct extension to community catalog (#1908)
  - feat(extensions): add verify-tasks extension to community catalog (#1871)

### Preserved

- All tikalk-specific features maintained:
  - Skills package manager (`specify skill` subcommand)
  - Orange branding theme (#f47721)
  - Pre-Installed Extensions panel
  - Team AI directives (`--team-ai-directives`)
  - Bundled presets installation

## [0.1.14] - 2026-03-19

### Fixed

- **Upstream merge restoration**: Restored tikalk customizations accidentally deleted during upstream merge 59806bc
  - Orange theme (`ACCENT_COLOR = "#f47721"`, `BANNER_COLORS`)
  - Pre-Installed Extensions panel in `init()` output
  - `--team-ai-directives` CLI parameter and related config.json save logic
  - `spec.*` aliases in user-facing command references (instead of `speckit.*`)

## [0.1.13] - 2026-03-19

### Fixed

- **--team-ai-directives**: Save resolved path to config.json for bash script retrieval (restored from git history)

## [0.1.12] - 2026-03-19

### Fixed

- **Type annotations**: Fixed multiple LSP/type-checker warnings in `__init__.py`
  - Added `Optional[str]` type hint to `select_with_arrows()` parameter
  - Added module-level `_specify_tracker_active` variable instead of dynamic `sys` attribute
  - Fixed `original_cwd` possibly unbound error in `init_git_repo()`
  - Fixed `zip_path` initialization in `preset add` command

## [0.1.11] - 2026-03-19

### Fixed

- **--team-ai-directives**: Restored accidentally deleted CLI parameter from upstream merge
- **README**: Removed non-existent `/spec.trace` from core commands, consolidated extension documentation

### Changed

- **README**: Updated extension documentation for consistency and accuracy

## [0.1.10] - 2026-03-18

### Changed

- **Upstream sync**: Merged upstream commits 6d0b84a, 497b588
  - Added speckit-utils extension to community catalog
  - Added Extensions & Presets documentation section to README

## [0.1.9] - 2026-03-18

### Changed

- **Upstream sync**: Merged upstream commit 33c83a6
  - Updated DocGuard extension to v0.9.11

## [0.1.8] - 2026-03-18

### Changed

- **Upstream sync**: Merged upstream commit f97c8e9
  - Updated cognitive-squad extension catalog entry with Triadic Model description

## [0.1.7] - 2026-03-18

### Fixed

- **Release workflow**: Fixed release package naming mismatch (`agentic-sdlc-spec-kit-template-*` vs `spec-kit-template-*`)
- **Missing dependency**: Added `json5` to dependencies (required by upstream merge)

## [0.1.6] - 2026-03-18

### Changed

- **Upstream merge**: Synced with github/spec-kit (commit cfd99ad)
  - New agents: kimi, trae, pi, bob, vibe, tabnine, and more
  - Updated preset system with PresetCatalog features
  - Extension system enhancements

### Preserved

- All tikalk-specific features maintained:
  - Skills package manager (`specify skill` subcommand)
  - Config management system
  - Bundled extensions and presets installation
  - Team AI directives sync
  - Orange branding theme

## [0.1.5] - 2026-03-15

### Fixed

- **Existing presets now apply `replaces` logic on re-init**: When running `specify init --here` on a project with an existing preset, the `replaces` field is now applied to remove superseded commands
  - Added `refresh_preset_commands()` method to `PresetManager`
  - `install_bundled_presets()` now calls refresh for existing presets
  - Fixes issue where `speckit.*` commands persisted after updating to v0.1.3+

## [0.1.3] - 2026-03-15

### Fixed

- **Preset `replaces` field now implemented**: Commands with `replaces` in preset.yml now properly remove the replaced command files from agent directories
  - Example: `adlc.spec.specify` with `replaces: "speckit.specify"` now removes `speckit.specify.md` before creating the new command
  - Ensures clean command namespace with only `adlc.spec.*` commands and `spec.*` aliases
- **`adlc.spec.constitution`**: Added missing `replaces: "speckit.constitution"` to replace core command

### Added

- **`remove_replaced_commands()`**: New method in `CommandRegistrar` class (`agents.py`) to remove command files across all detected agent directories

## [0.1.1] - 2026-03-14

### Added

- **Mission Brief enforcement**: `/adlc.spec.specify` now requires explicit Mission Brief approval before branch creation
  - Strict checkpoint: Goal, Success Criteria, Constraints, Demo Sentence must be confirmed
  - Supports both extraction from `$ARGUMENTS` and interactive questioning
  - Mission Brief fields populate the spec template's header sections

### Fixed

- **Extension script paths**: Fixed `_adjust_script_paths()` in `agents.py` to resolve extension scripts to `.specify/extensions/<ext-id>/scripts/` path

### Removed

- **roadmap.md**: Removed outdated planning document (1,579 lines with stale references)

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

---

## Upstream Changelog (spec-kit)

The following entries are from the upstream spec-kit project and are included for reference.

## [0.3.2] - 2026-03-19

### Changes

- chore: bump version to 0.3.2
- Add conduct extension to community catalog (#1908)
- feat(extensions): add verify-tasks extension to community catalog (#1871)
- feat(presets): add enable/disable toggle and update semantics (#1891)
- feat: add iFlow CLI support (#1875)
- feat(commands): wire before/after hook events into specify and plan templates (#1886)
- docs(catalog): add speckit-utils to community catalog (#1896)
- docs: Add Extensions & Presets section to README (#1898)
- chore: update DocGuard extension to v0.9.11 (#1899)
- Update cognitive-squad catalog entry — Triadic Model, full lifecycle (#1884)
- feat: register spec-kit-iterate extension (#1887)
- fix(scripts): add explicit positional binding to PowerShell create-new-feature params (#1885)
- fix(scripts): encode residual JSON control chars as \uXXXX instead of stripping (#1872)
- chore: update DocGuard extension to v0.9.10 (#1890)
- Feature/spec kit add pi coding agent pullrequest (#1853)
- feat: register spec-kit-learn extension (#1883)

## [0.3.1] - 2026-03-17

### Changed

- chore: bump version to 0.3.1
- docs: add greenfield Spring Boot pirate-speak preset demo to README (#1878)
- fix(ai-skills): exclude non-speckit copilot agent markdown from skills (#1867)
- feat: add Trae IDE support as a new agent (#1817)
- feat(cli): polite deep merge for settings.json and support JSONC (#1874)
- feat(extensions,presets): add priority-based resolution ordering (#1855)
- fix(scripts): suppress stdout from git fetch in create-new-feature.sh (#1876)
- fix(scripts): harden bash scripts — escape, compat, and error handling (#1869)
- Add cognitive-squad to community extension catalog (#1870)
- docs: add Go / React brownfield walkthrough to community walkthroughs (#1868)
- chore: update DocGuard extension to v0.9.8 (#1859)
- Feature: add specify status command (#1837)
- fix(extensions): show extension ID in list output (#1843)
- feat(extensions): add Archive and Reconcile extensions to community catalog (#1844)
- feat: Add DocGuard CDD enforcement extension to community catalog (#1838)

## [0.3.0] - 2026-03-13

### Changed

- chore: bump version to 0.3.0
- feat(presets): Pluggable preset system with catalog, resolver, and skills propagation (#1787)
- fix: match 'Last updated' timestamp with or without bold markers (#1836)
- Add specify doctor command for project health diagnostics (#1828)
- fix: harden bash scripts against shell injection and improve robustness (#1809)
- fix: clean up command templates (specify, analyze) (#1810)
- fix: migrate Qwen Code CLI from TOML to Markdown format (#1589) (#1730)
- fix(cli): deprecate explicit command support for agy (#1798) (#1808)
- Add /selftest.extension core extension to test other extensions (#1758)
- feat(extensions): Quality of life improvements for RFC-aligned catalog integration (#1776)
- Add Java brownfield walkthrough to community walkthroughs (#1820)

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


## [0.1.13] - 2026-03-03

### Fixed

- **Copilot Extension Commands Not Visible**: Fixed extension commands not appearing in GitHub Copilot when installed via `specify extension add --dev`
  - Changed Copilot file extension from `.md` to `.agent.md` in `CommandRegistrar.AGENT_CONFIGS` so Copilot recognizes agent files
  - Added generation of companion `.prompt.md` files in `.github/prompts/` during extension command registration, matching the release packaging behavior
  - Added cleanup of `.prompt.md` companion files when removing extensions via `specify extension remove`
- Fixed a syntax regression in `src/specify_cli/__init__.py` in `_build_ai_assistant_help()` that broke `ruff` and `pytest` collection in CI.
## [0.1.12] - 2026-03-02

### Changed

- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)


## [0.1.10] - 2026-03-02

### Fixed

- **Version Sync Issue (#1721)**: Fixed version mismatch between `pyproject.toml` and git release tags
  - Split release process into two workflows: `release-trigger.yml` for version management and `release.yml` for artifact building
  - Version bump now happens BEFORE tag creation, ensuring tags point to commits with correct version
  - Supports both manual version specification and auto-increment (patch version)
  - Git tags now accurately reflect the version in `pyproject.toml` at that commit
  - Prevents confusion when installing from source

## [0.1.9] - 2026-02-28

### Changed

- Updated dependency: bumped astral-sh/setup-uv from 6 to 7

## [0.1.8] - 2026-02-28

### Changed

- Updated dependency: bumped actions/setup-python from 5 to 6

## [0.1.7] - 2026-02-27

### Changed

- Updated outdated GitHub Actions versions
- Documented dual-catalog system for extensions

### Fixed

- Fixed version command in documentation

### Added

- Added Cleanup Extension to README
- Added retrospective extension to community catalog

## [0.1.6] - 2026-02-23

### Fixed

- **Parameter Ordering Issues (#1641)**: Fixed CLI parameter parsing issue where option flags were incorrectly consumed as values for preceding options
  - Added validation to detect when `--ai` or `--ai-commands-dir` incorrectly consume following flags like `--here` or `--ai-skills`
  - Now provides clear error messages: "Invalid value for --ai: '--here'"
  - Includes helpful hints suggesting proper usage and listing available agents
  - Commands like `specify init --ai-skills --ai --here` now fail with actionable feedback instead of confusing "Must specify project name" errors
  - Added comprehensive test suite (5 new tests) to prevent regressions

## [0.1.5] - 2026-02-21

### Fixed

- **AI Skills Installation Bug (#1658)**: Fixed `--ai-skills` flag not generating skill files for GitHub Copilot and other agents with non-standard command directory structures
  - Added `commands_subdir` field to `AGENT_CONFIG` to explicitly specify the subdirectory name for each agent
  - Affected agents now work correctly: copilot (`.github/agents/`), opencode (`.opencode/command/`), windsurf (`.windsurf/workflows/`), codex (`.codex/prompts/`), kilocode (`.kilocode/workflows/`), q (`.amazonq/prompts/`), and agy (`.agent/workflows/`)
  - The `install_ai_skills()` function now uses the correct path for all agents instead of assuming `commands/` for everyone

## [0.1.4] - 2026-02-20

### Fixed

- **Qoder CLI detection**: Renamed `AGENT_CONFIG` key from `"qoder"` to `"qodercli"` to match the actual executable name, fixing `specify check` and `specify init --ai` detection failures

## [0.1.3] - 2026-02-20

### Added

- **Generic Agent Support**: Added `--ai generic` option for unsupported AI agents ("bring your own agent")
  - Requires `--ai-commands-dir <path>` to specify where the agent reads commands from
  - Generates Markdown commands with `$ARGUMENTS` format (compatible with most agents)
  - Example: `specify init my-project --ai generic --ai-commands-dir .myagent/commands/`
  - Enables users to start with Spec Kit immediately while their agent awaits formal support

## [0.0.102] - 2026-02-20

- fix: include 'src/**' path in release workflow triggers (#1646)

## [0.0.101] - 2026-02-19

- chore(deps): bump github/codeql-action from 3 to 4 (#1635)

## [0.0.100] - 2026-02-19

- Add pytest and Python linting (ruff) to CI (#1637)
- feat: add pull request template for better contribution guidelines (#1634)
