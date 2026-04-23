# Changelog

All notable changes to the Specify CLI and templates are documented here.

# [Unreleased]

# [0.5.13] - 2026-04-23

### Fixed

- **Restored constitution command**: `adlc.spec.constitution` command now restored to agentic-sdlc preset
  - Uses hook-based architecture (`before_constitution` hook)
  - Integrates with team-ai-directives extension for team principles loading
  - Follows same pattern as other preset commands (adlc.spec.plan, adlc.spec.clarify, etc.)
  - No custom scripts required - pure hook-based loading

# [0.5.12] - 2026-04-23

### Changed

- **Removed context-template.md**: `context-template.md` and the legacy `context.md` feature file have been removed from the agentic-sdlc preset
  - Auto-discovery of team context is now handled exclusively by `team-ai-directives` extension
  - Removed template file from `presets/agentic-sdlc/templates/`
  - Removed `context-template` entry from `preset.yml`
  - Removed `populate_context_file()` function and `CONTEXT_TEMPLATE` resolution from `create-new-feature.sh` (bash and PowerShell)
  - Removed `context.md` file generation from feature creation workflow
  - Updated tests to remove context-template references

- **Removed AD.md references**: Architecture Description file references removed from scripts
  - The `@extensions/architect` extension now provides architecture via hooks (`before_*` hooks)
  - Removed AD checks and output from `setup-plan.sh` (scripts/ and .specify/scripts/)
  - Removed AD checks from `check-prerequisites.sh`
  - Removed AD from `common.sh` environment variable output (note: AD was never actually exported, only displayed)

- **Sync setup-plan.sh**: Synchronized `.specify/scripts/bash/setup-plan.sh` with `scripts/bash/setup-plan.sh`
  - Removed CONTEXT_FILE from JSON output
  - Removed AD output block
  - Both directories now identical after sync

- **Removed constitution scripts**: Functionality moved to `team-ai-directives/commands/constitution.md`
  - Deleted `setup-constitution.sh` from `.specify/scripts/bash/`
  - Deleted `validate-constitution.sh` from `.specify/scripts/bash/`
  - Deleted command files referencing removed scripts:
    - `.opencode/command/spec.constitution.md`
    - `.opencode/command/adlc.spec.constitution.md`
    - `presets/agentic-sdlc/commands/adlc.spec.constitution.md`
  - Removed mentions of `validate-constitution.sh` from levelup validate commands

- **Hook-based architecture loading**: Replaced hardcoded AD.md/adr.md file loading in preset commands with hook-based architecture
  - Architecture context now loaded via `before_specify`/`before_analyze`/`before_clarify` hooks
  - Removed direct file path references from `adlc.spec.analyze.md` and `adlc.spec.clarify.md`
  - Aligns with extension hook system for better extensibility

# [0.5.11] - 2026-04-23

### Added

- **DeepEval Integration**: Full support for DeepEval as alternative evaluation framework
  - Custom metric class generation with DeepEval v3.x API support
  - Automatic version compatibility validation (DeepEval >=3.0.0 required)
  - System detection to choose between PromptFoo and DeepEval
- **Atomic Generation Order**: Prevents import errors in generated configurations
  - Graders generated before config (normal Python imports work)
  - Validation step with rollback on failure
  - Clear error messages for missing dependencies

### Changed

- **Command Naming**: Renamed `evals.trace` to `evals.analyze` for clarity
- **Command Structure**: Standardized command interface across all evals commands

### Fixed

- **Import Errors**: Resolved chicken-and-egg problem in DeepEval config generation
- **Version Compatibility**: Added clear error messages for DeepEval v2.x users with upgrade instructions
- **Documentation**: Clarified threshold parameter usage in EDD binary evaluation mode

# [0.5.10] - 2026-04-20

### Added

- **team-ai-directives reference mode**: Local directories are now used in-place without copying
  - When `--team-ai-directives` points to a local directory, it's used directly (reference mode)
  - When `--team-ai-directives` is a ZIP URL, it's downloaded and installed to `.specify/extensions/`
  - Added `get_team_directives_path()` helper to resolve path from init-options or extensions dir
  - Added `install` parameter to `sync_team_ai_directives()` for explicit control

### Changed

- **Hook-based architecture loading**: Replaced hardcoded AD.md/adr.md file loading in preset commands with hook-based architecture
  - Architecture context now loaded via `before_specify`/`before_analyze`/`before_clarify` hooks
  - Removed direct file path references from `adlc.spec.analyze.md` and `adlc.spec.clarify.md`
  - Aligns with extension hook system for better extensibility

### Fixed

- **team-ai-directives duplicate installation**: Removed duplicate `sync_team_ai_directives()` call
  - The function was being called twice: once in main init flow and once in `pre_init()` hook
  - This caused "already installed" error on clean installs
  - Now only called via `pre_init()` hook in cli_customization

- **team-ai-directives init-options**: Removed duplicate save of ZIP URL in `init-options.json`
  - The `team_ai_directives` field was being saved twice: first as the original ZIP URL, then as the local path
  - Now only saves the local filesystem path after extension installation
  - Ensures `init-options.json` contains usable path instead of download URL

- **team-ai-directives save error handling**: Separated `save_init_options()` from sync exception handler
  - Moved save logic outside the try/except block to prevent silent failures
  - When sync fails, early return prevents save attempt
  - When sync succeeds, save failures will now raise visible errors instead of being swallowed

# [0.5.9] - 2026-04-20

### Added

- **ZIP install for team-ai-directives**:
  - `sync_team_ai_directives()` now downloads ZIP from GitHub releases
  - Installs via ExtensionManager to `.specify/extensions/`
  - Stores `source_url` and `target_repo` in extension registry for levelup
  - Updated `load_team_directives_config()` to check extensions/ only

- **Documentation**: Added team-ai-directives extension integration docs to README.md
  - Removed legacy `.specify/memory` support and git clone

### Removed

- **Legacy memory path**: All `.specify/memory/team-ai-directives` fallbacks removed
- **Git clone**: No longer supported for team-ai-directives

### Changed

- **Path resolution**: Now only checks `.specify/extensions/team-ai-directives`

# [0.5.8] - 2026-04-19

### Fixed

- **Dead code removal**: 
  - Removed unused `--outdated` option from `skill_list` command
  - Removed unused `original_ref` parameter from `_generate_skill_id`
  - Found via vulture dead code detection

### Changed

- **Clarify handoffs alignment**: Changed `send: false` to `send: true` for auto-validation in init/specify commands

# [0.5.6] - 2026-04-19

### Fixed

- **Preset commands aligned with templates**:
  - Fixed hook filtering style from exclusive (`enabled: true` required) to inclusive (default enabled)
  - Changed template path reference to relative path `templates/tasks-template.md`
  - Added branch numbering mode support with `init-options.json` checking
  - Fixed YAML indentation in `adlc.spec.plan.md`

### Added

- **Pre/Post-Execution Checks**: Added missing hook checking sections to:
  - `adlc.spec.checklist.md`
  - `adlc.spec.clarify.md`
  - `adlc.spec.analyze.md`

# [0.5.4] - 2026-04-16

### Changed

- **Upstream merge**: Synced with github/spec-kit (076bb40)
  - Integration catalog: new discovery, versioning, and community distribution system
  - `specify integration list --catalog`: browse remote integrations
  - `specify integration upgrade`: diff-aware upgrade with modified file detection
  - Documentation: integrations FAQ and extensions reference

### Added

- **New integration**: `catalog.py` module with `IntegrationCatalog` and `IntegrationDescriptor`
  - Fetches remote catalogs from configurable sources
  - Caches for 1 hour in `.specify/integrations/.cache/`
  - Validates integration YAML descriptors

# [0.5.3] - 2026-04-16

### Changed

- **Upstream merge**: Synced with github/spec-kit (752683d)
  - Release 0.7.1 upstream changes
  - CI: Windows test matrix support
  - Docs cleanup (removed deprecated --skip-tls)
  - Merged cleanly with fork customizations preserved

# [0.5.2] - 2026-04-16

### Fixed

- **UI improvements for init output**:
  - Fixed duplicate "Initialize Specify Project" title in Live display
  - Capitalized status labels for better readability:
    - "team-directives" → "Team AI Directives setup"
    - "extensions" → "Install bundled extensions"
    - "presets" → "Install bundled presets"

### Changed

- **Upstream merge**: Synced with github/spec-kit (8fc2bd3)
  - Claude skill chaining for hook execution (#2227)
  - Preserved fork customizations (adlc namespace, auto-correction, warnings)

### Fixed

- Test compatibility with upstream (disable-model-invocation: false)

# [0.5.0] - 2026-04-15

### Changed

- **Upstream merge**: Synced with github/spec-kit (b78a3cd)
  - Merged upstream changes while preserving fork customizations (adlc namespace, theming, bundled extensions)

# [0.4.12] - 2026-04-16

### Fixed

- **Version detection**: Fixed `specify version` and `get_speckit_version()` to correctly detect `agentic-sdlc-specify-cli` package (was showing "unknown" before)

# [0.4.11] - 2026-04-16

### Added

- **Evals Extension**: Complete EDD (Eval-Driven Development) implementation with PromptFoo integration
  - **Complete EDD Methodology**: All 10 EDD principles implemented and validated
  - **Goldset Lifecycle**: Full ADR/CDR pattern with `init` → `specify` → `clarify` → `analyze` → `implement` workflow
  - **Evaluation Pyramid**: Tier 1 fast checks (<30s) + Tier 2 semantic evaluation (<5min) + production sampling
  - **Statistical Validation**: TPR/TNR analysis with 95% confidence intervals and holdout dataset validation
  - **PromptFoo Integration**: Automatic config generation, executable grader creation, and seamless results processing
  - **Cross-Functional Intelligence**: `levelup` command generates stakeholder-specific insights and team PRs
  - **Smart Task Matching**: `tasks` command provides intelligent eval-task alignment with coverage analysis
  - **Production-Ready**: Complete validation pipeline, error handling, and production loop closure
  - **8 Commands**: `init`, `specify`, `clarify`, `analyze`, `implement`, `validate`, `levelup`, `tasks`
  - **Comprehensive Documentation**: 190+ section README with architecture guide, examples, and troubleshooting

## [0.4.10] - 2026-04-14

### Changed

- **Upstream merge**: Synced with github/spec-kit
  - Added claude-ask-questions to community preset catalog (#2191)

## [0.4.9] - 2026-04-14

### Changed

- **Command prefix**: Changed display from `/speckit.{name}` to `/spec.{name}` to match fork's command namespace
- **Theming**: Fixed ○ bullet symbols in Enhancement Commands to use accent() function for orange color

## [0.4.8] - 2026-04-14

### Changed

- **Upstream merge**: Synced with github/spec-kit
  - SFSpeckit: Salesforce SDD extension (18 commands)
  - Gitflow: single-segment branch prefix support

## [0.4.7] - 2026-04-14

### Changed

- **Full theming consistency**: Replaced all 47 `[cyan]` markup with `accent()` function calls
  - TAGLINE now uses `accent_style()` instead of hardcoded bright_yellow
  - StepTracker title uses accent()
  - Status symbols use orange hex code (#f47721)
  - select_with_arrows table uses accent_style() for borders
  - All Panel borders use accent_style() throughout

## [0.4.6] - 2026-04-14

### Changed

- **Merge recovery**: Merged backup-main-20260413 to recover lost commits
  - Architect v2.0.0 - R&W methodology alignment
  - TDD extension hooks (before_implement)
  - Extension script path rewriting bug fix
  - Team-ai-directives persistence to init-options.json
- **Extension bundling unification**: Fork extensions now use `core_pack/extensions/` like git extension
  - Updated pyproject.toml force-include paths
  - Extensions: levelup, architect, product, quick, tdd
- **Catalog.json updated**: Added `bundled: true` and `preinstall: true` to fork extensions

### Fixed

- **Version detection bug**: Fixed "Invalid version: 'unknown'" error when installing bundled extensions
  - Added early return in `check_compatibility()` for unknown versions
  - Bundled extensions are now guaranteed compatible

## [0.3.48] - 2026-04-13

### Added

- **TDD extension hooks**: Added `after_plan` hook for `tdd.plan` command (optional)
- **TDD extension hooks**: Added `after_implement` hook for `tdd.validate` command (optional)

### Changed

- **TDD extension hooks**: `tdd.implement` now triggers on `before_implement` instead of `after_implement` - ensures TDD cycle runs BEFORE implementation (RED→GREEN→REFACTOR)
- **Hook re-registration fix**: Fixed bug where hooks weren't updated when extension.yml was modified
  - Now compares both version AND manifest hash to trigger re-registration
  - This ensures hooks get updated when extension.yml changes, even if version wasn't bumped

## [0.3.47] - 2026-04-13

### Fixed

- **Extension script path bug**: Fixed session execution failure caused by incorrect path rewriting
  - Extension command files used relative paths like `scripts/bash/setup-architect.sh`
  - The `rewrite_project_relative_paths()` function rewrites `scripts/` to `.specify/scripts/`
  - But extension scripts are actually at `.specify/extensions/<ext>/scripts/`
  - Changed 22 extension command files across 4 extensions to use fully-qualified paths
  - Affected extensions: architect (5 files), product (7 files), levelup (7 files), tdd (3 files)
  - Fix uses `.specify/extensions/<ext>/scripts/...` paths which bypass the rewriting bug

## [0.3.46] - 2026-04-13

### Changed

- **Removed issue tracker integration**: Cleaned up `@issue-tracker` references and traceability features
  - Removed Smart Trace Validation section from `/spec.analyze` command
  - Removed issue tracker references from docs/quickstart.md examples
  - Removed issue tracker integration from levelup trace scripts and templates
  - Removed issue tracker integration from implement command

### Fixed

- **RELEASE.md**: Trimmed to release instructions only (removed Lessons Learned historical debug notes)

## [0.3.45] - 2026-04-13

### Fixed

- **check-prerequisites.sh/ps1**: Fixed undefined `$ARCHITECTURE` variable bug
  - `common.sh` was refactored to export `AD` (path to `AD.md`) but `check-prerequisites.sh` still referenced undefined `$ARCHITECTURE`
  - Renamed JSON output fields: `ARCHITECTURE_*` → `AD_*` (`AD_EXISTS`, `AD_VIEWS`, `AD_DIAGRAMS`)
  - Updated PowerShell `common.ps1` to remove legacy `ARCHITECTURE` export
  - Updated `adlc.spec.clarify.md` command to parse new field names
  - Architecture Alignment pillar in `/spec.clarify` now correctly detects `AD.md` when architect extension is activated

## [0.3.44] - 2026-04-13

### Changed

- **Product extension before_specify hook**: Replaced noisy `adlc.product.specify` with lightweight `adlc.product.link`
  - New command silently exits if no PDRs exist (eliminates "No PDR file found" AI output)
  - If PDRs exist, presents selection table to link feature to Feature PDR
  - Reduces spurious output for users not using product extension workflow

### Added

- **New command `adlc.product.link`**: Lightweight PDR linking command designed for hook use
  - Checks team-directives, memory, and drafts locations for PDRs
  - Silent exit if no PDRs found
  - Full selection flow if PDRs exist

## [0.3.43] - 2026-04-13

### Fixed

- **Claude Code slash commands**: Fixed preset and extension command naming for slash command invocation
  - Added `compute_skill_output_name()` function in `cli_customization.py` with fork-specific namespace handling
  - Preset commands with `adlc.spec.*` prefix now generate `/adlc-spec-*` instead of `/speckit-adlc-spec-*`
  - Preset alias commands with `spec.*` prefix now generate `/spec-*` instead of `/speckit-spec-*`
  - Extension commands (e.g., `adlc.architect.init`) similarly now generate `/adlc-architect-init` instead of `/speckit-adlc-architect-init`
  - Root cause: `_compute_output_name()` in `agents.py` always prepended `speckit-` regardless of command namespace

## [0.3.42] - 2026-04-13

### Fixed

- **Bundled extension hooks**: Register hooks during `specify init`
  - Added `hook_executor.register_hooks(manifest)` in `_install_bundled_extensions()`
  - Creates `.specify/extensions.yml` when bundled extensions (architect, product, tdd) have hooks
  - Aligns fork behavior with upstream `install_from_directory()` method
  - Root cause: Custom bundled extension installation path was missing hook registration step

## [0.3.41] - 2026-04-13

### Fixed

- **adlc.spec.plan**: Plan command now creates all required artifacts
  - Added imperative Outline section with explicit "CREATE" instructions for each artifact
  - Fixed bug where agent only wrote plan.md but didn't generate research.md, data-model.md, contracts/, or quickstart.md
  - Removed ~150 lines of legacy feature architecture content (moved to architect extension hooks)
  - Consolidated duplicate phase numbering (removed "Core Workflow" Phase 1-2, kept "Phases" Phase 0-1)
  - Trimmed Triage Framework section from 70 lines to 20 essential criteria
  - File size reduced from 421 lines to 296 lines (30% reduction)
  - Root cause: Missing clear execution instructions; agent interpreted phases as documentation rather than actionable steps

## [0.3.40] - 2026-04-13

### Fixed

- **spec.specify hooks**: Align hook event names with upstream template convention
  - Changed product extension hooks from `before_spec`/`after_spec` to `before_specify`/`after_specify`
  - Matches `templates/commands/specify.md` and `EXTENSION-API-REFERENCE.md` naming
  - Fixes hooks not triggering due to naming mismatch

- **adlc.spec.specify**: Remove inline Phase 2 PDR selection (now hook-only)
  - Removed "Phase 2: PDR Reference Selection" from preset command
  - PDR selection now exclusively handled by `before_specify` hook (`adlc.product.specify`)
  - Added Pre-Execution Checks and Post-Execution Hooks sections
  - Eliminates spurious "No PDR file found - skipping Phase 2" AI output
  - Mission Brief workflow preserved (agentic-sdlc enhancement)

## [0.3.39] - 2026-04-13

### Fixed

- **Preset commands for markdown agents**: Resolve `{SCRIPT}` placeholders correctly
  - Preset commands registered for markdown-based agents (opencode, claude, windsurf, etc.) now properly replace `{SCRIPT}` with actual script paths
  - Previously, `{SCRIPT}` was only resolved for skill-based agents (codex, kimi)
  - Root cause: `register_commands()` in `agents.py` didn't call `resolve_skill_placeholders()` for non-skill agents

## [0.3.38] - 2026-04-13

### Fixed

- **adlc.spec.constitution**: Simplified command from 199 to 88 lines
  - Removed `validation_scripts:` section (wasn't being path-rewritten by CLI)
  - Replaced complex 4-phase "Constitution Architect" workflow with 9 clear steps
  - Aligned structure with upstream `templates/commands/constitution.md`
  - Preserved team constitution inheritance feature
  - Root cause: Complex multi-phase instructions caused models to skip script execution and write to wrong file paths

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to to [Semantic Versioning](https://semver.spec/v2.0.0/).

## [0.3.36] - 2026-04-12

### Fixed

- **--team-ai-directives**: Persist to init-options.json (upstream standard) + read from all scripts
  - pre_init() saves team_ai_directives to .specify/init-options.json (not config.json)
  - bash scripts: load_team_directives_config() in common.sh reads from init-options.json
  - PowerShell scripts: Load-TeamDirectivesConfig() in common.ps1 reads from init-options.json
  - Extension scripts (both bash/PS) use centralized functions
  - Falls back to memory location if not in init-options.json

  Scripts fixed:
  - src/specify_cli/cli_customization.py - save to init-options.json
  - scripts/bash/common.sh - load_team_directives_config()
  - scripts/bash/create-new-feature.sh
  - scripts/bash/setup-plan.sh
  - scripts/powershell/common.ps1 - Load-TeamDirectivesConfig()
  - scripts/powershell/create-new-feature.ps1
  - scripts/powershell/setup-plan.ps1
  - scripts/powershell/setup-constitution.ps1
  - extensions/*/scripts/bash/setup-*.sh
  - extensions/*/scripts/powershell/setup-*.ps1

## [0.3.31] - 2026-04-10

### Fixed

- **scaffold extensions**: Always overwrite existing files on re-init
  - Previously skipped scaffold if extension.yml existed
  - Now copies all files from source, overwriting existing
  - Fixes v1.1.4 extensions not updating over v1.1.3

## [0.3.30] - 2026-04-10

### Fixed

- **bundled extensions**: Version comparison during init/re-init
  - Compare installed vs bundled version when scaffolding extensions
  - Update to newer version if bundled is higher
  - Previously skipped all existing extensions preventing updates
  - Fixes workflow where implement skipped all ADRs due to wrong status

## [0.3.28] - 2026-04-10

### Fixed

- **init workflow**: Remove all auto-trigger references to clarify
  - Clarify is now a manual step you run after init
  - Prevents hidden sub-agent calls during brownfield analysis
  - Updated Description and Output sections to reflect manual flow

### Changed

- **clarify workflow**: Add ADR/PDR approval step before implement
  - Added Phase 5.5 to ask users to approve ADRs/PDRs

## [0.3.29] - 2026-04-10

### Changed

- **spec.plan Phase 1**: Clarify interface contracts scope
  - More general: libraries, CLI, web services, parsers, UI
  - Skip internal-only projects
  - Only "Accepted" status records processed by implement
  - Fixes workflow where implement skipped all ADRs due to wrong status

## [0.3.24] - 2026-04-09

### Changed

- **preset commands**: Updated next steps suggestions to use command aliases
  - Replaced full command names (`/adlc.spec.*`) with shorter aliases (`/spec.*`)
  - Updated in `adlc.spec.plan.md` and `adlc.spec.specify.md`
  - Improves user experience with shorter, more intuitive command suggestions

## [0.3.23] - 2026-04-09

### Changed

- **levelup extension**: Fixed missing remote tag to trigger release

## [0.3.22] - 2026-04-09

### Changed

- **levelup.clarify**: Simplified UX to align with architect.clarify and product.clarify patterns
  - Removed auto-assessment phase (no pre-computed validity/scope/coverage)
  - Replaced batch overview with simple gap identification table
  - Simplified action picker: Accept/Reject/Defer (removed Investigate/Split)
  - Aligned session limits: 5 clarifications total (like architect/product)
  - Inline questions when gaps detected (no separate Investigate action)
  - Updated documentation: added CDR Quality Checklist
  - 31% line reduction: 694 → 478 lines

## [0.3.21] - 2026-04-09

### Fixed

- **architect extension v1.0.1**: Fixed misleading documentation about `--architecture` flag
  - Removed references to non-existent flag from command documentation
  - Correctly documented hook-based feature architecture integration
  - Updated all "When NOT to Use" sections with accurate guidance
  - Feature architecture now correctly documented as `before_plan` hook in `.specify/extensions.yml`

## [0.3.20] - 2026-04-09

### Changed

- **product extension v1.0.2**: Removed hardcoded architect handoff, now uses hooks-only integration
  - Extensions are fully decoupled - external references only via project-level hooks
  - If architect is not installed, no reference to it exists in product workflow

### Fixed

- **Extension coupling**: Product extension no longer has hardcoded references to other extensions
  - Cross-extension integration now exclusively through `.specify/extensions.yml` hooks configuration
  - Follows best practice for extension architecture

## [0.3.19] - 2026-04-09

### Added

- **specify skill commands**: Restored skill package manager CLI commands that were removed
  during upstream merge. Available commands:
  - `specify skill search <query>` - Search skills registry
  - `specify skill install <ref>` - Install from GitHub/GitLab/local
  - `specify skill update [name|--all]` - Update installed skills
  - `specify skill remove <name>` - Uninstall a skill
  - `specify skill list` - Show installed skills
  - `specify skill eval <path>` - Evaluate skill quality
  - `specify skill sync-team` - Sync with team manifest
  - `specify skill check-updates` - Check for available updates
  - `specify skill config [key] [value]` - View/modify configuration
- **specify skill theming**: Commands now use Tikalk orange accent color
- **specify skill tests**: Added test suite for skill CLI commands

### Fixed

- **httpx dependency**: Added missing httpx dependency required by skills module
  (was causing "Skills module not available" error)
- Implementation follows fork pattern: CLI commands in `cli_customization.py`,
  core logic reuses existing `skills/` module

## [0.3.18] - 2026-04-09

### Added

- **ADLC preset path validation**: Added explicit path validation and non-git repository 
  support to all ADLC preset commands to prevent AI agents from writing files to project 
  root instead of the correct `specs/<branch>/` directory
  - adlc.spec.specify.md
  - adlc.spec.plan.md  
  - adlc.spec.tasks.md
  - adlc.spec.implement.md
  - adlc.spec.checklist.md
  - adlc.spec.analyze.md
  - adlc.spec.clarify.md
  - adlc.spec.constitution.md

### Non-Git Repository Support

- All ADLC commands now include guidance for setting `SPECIFY_FEATURE` environment 
  variable when working without git

## [0.4.2] - 2026-04-13

### Changed

- **Upstream merge**: Merged 29 upstream commits from github/spec-kit (v0.6.2 release + v0.6.3.dev0)
- **Theme**: Fixed banner to use orange BANNER_COLORS instead of hardcoded blue/cyan
- **New agents**: Added Goose AI agent support and cursor-agent skill mode
- **Lean preset**: New minimal workflow preset with constitution, specify, plan, tasks, implement commands
- **Git extension**: Improved auto-commit and feature branch workflow
- **Catalog updates**: Added Worktrees, What-if Analysis, GitHub Issues Integration to community catalog

### Fixed

- **CLI hooks**: Restored --team-ai-directives parameter and pre_init/post_init hook calls
- **Missing functions**: Added sync_team_ai_directives and _run_git_command functions
- **Theme consistency**: Banner now uses BANNER_COLORS from cli_customization.py

## [0.4.0] - 2026-04-09

### Changed

- **Upstream merge**: Merged upstream changes from github/spec-kit while preserving fork customizations
- **preinstall filtering**: Bundled extensions now only scaffold/install extensions with `preinstall: true` in catalog.json (was installing all extensions as fallback)

### Fixed

- **Path bug**: Fixed `_install_bundled_extensions()` path bug where `ext_path / d` should be `ext_path / d.name`
- **Duplicate TAGLINE**: Removed duplicate TAGLINE line from merge conflict resolution

### Added

- **Hook integration**: Added pre_init and post_init hook calls to init() function for fork-specific functionality

## [0.3.11] - 2026-04-04

### Added

- **cli_customization.py**: Isolated all fork customizations into a single module to minimize merge conflicts with upstream
- **accent() helper**: New function for consistent theming without hardcoding color values
- **accent_style() helper**: New function for Rich style= parameters
- **FORK.md**: Documentation for maintaining the fork and merging upstream

### Changed

- **Extension namespace configuration**: Now reads from cli_customization.py for configurable command namespaces
- **Package name detection**: Uses PKG_NAMES from cli_customization.py (fork package checked first)
- **Import pattern**: Uses try/except to import customizations with upstream defaults as fallback

### Fixed

- **Extension patterns**: EXTENSION_COMMAND_NAME_PATTERN and EXTENSION_ALIAS_NAME_PATTERN now dynamically built from configuration

## [0.3.13] - 2026-04-04

### Fixed

- **Extension command registration**: Fixed bundled extensions not registering commands to agent command directories (e.g., `.opencode/command/`)

## [0.3.14] - 2026-04-04

### Fixed

- **Preset command registration**: Fixed bundled presets not registering command overrides to agent command directories

## [0.3.15] - 2026-04-05

### Added

- **LevelUp clarify enhancements**: Added system-discovered assessments and recommended actions
  - Phase 0: Pre-Validation for CDR completeness checks
  - Phase 3: System Auto-Assessment (Validity, Scope, Coverage, Priority)
  - Phase 4: Batch overview with recommended actions table
  - Phase 5: One-CDR-at-a-time with recommended answer format matching /spec.clarify UX

## [0.3.16] - 2026-04-06

### Changed

- **Upstream merge**: Synced with github/spec-kit (8 commits)
  - Add Confluence extension
  - Add optimize extension to community catalog
  - Add VS Code Ask Questions preset
  - Add security-review v1.1.1 to community extensions catalog
  - fix: serialize multiline descriptions in legacy TOML renderer
  - fix: strip YAML frontmatter from TOML integration prompts
  - fix: accept 4+ digit spec numbers in tests and docs
  - fix(scripts): improve git branch creation error handling

### Changed

- **CLI branding**: Updated intro banner tagline to reflect fork identity
- **TAGLINE moved**: Now imported from cli_customization.py for consistency

### Preserved

- All tikalk-specific features maintained:
  - Orange branding theme (#f47721)
  - --team-ai-directives CLI parameter
  - Bundled extensions (levelup, architect, quick, product, tdd)
  - Bundled presets (agentic-sdlc)

## [0.3.12] - 2026-04-04

### Fixed

- **Bundled extensions installation**: Fixed bug where scaffolded extensions were deleted during install (TDD and other extensions now properly install during `specify init`)
- **Bundled presets installation**: Fixed PresetManifest instantiation (was incorrectly using `.load()` class method)

### Changed

- **pre_init/post_init hooks**: Moved bundled extensions and presets installation to `cli_customization.py` hooks
- **Direct registry registration**: Extensions/presets are now registered directly after scaffolding instead of using `install_from_directory()` which caused destructive delete

## [0.3.10] - 2026-04-04

### Added

- **tdd extension to wheel**: Added tdd extension to wheel and sdist includes (was missing from bundled extensions)
- **--team-ai-directives flag**: New CLI option to specify path or URL for team-ai-directives repository

### Fixed

- **Team AI directives sync**: Now properly syncs during init when --team-ai-directives is provided

## [0.3.9] - 2026-04-04

### Fixed

- **PowerShell dry-run specs dir**: Only create specs/ directory when NOT in dry-run mode
- **PowerShell null template path**: Handle null template path in context-template resolution to prevent `Test-Path` errors

## [0.3.8] - 2026-04-04

### Fixed

- **PowerShell discovery-functions syntax**: Removed stray `]` character causing `Unexpected token ']'` parser error in `discovery-functions.ps1`

### Changed

- **Package description**: Updated pyproject.toml description to reflect tikalk fork branding
- **Repository description**: Updated GitHub About to "🐙 Agentic SDLC toolkit for Spec-Driven Development with bundled extensions and AI agent support"

## [0.3.7] - 2026-04-04

### Fixed

- **PowerShell test fixture**: Added missing `discovery-functions.ps1` to test fixture so PowerShell dry-run tests pass in CI
- **Extension install reporting**: Now shows both installed AND skipped extensions (previously skipped extensions were silently hidden when others succeeded)

### Changed

- Extension install output now sorted alphabetically for consistency

## [0.3.6] - 2026-04-04

### Fixed

- **PowerShell discovery-functions path**: Fixed dot-source of `discovery-functions.ps1` to use `$PSScriptRoot` instead of relative path, enabling the script to run correctly when invoked from any directory or when copied to temp directories in CI

## [0.3.5] - 2026-04-04

### Changed

- **Full tikalk theming restored**: Converted all `[cyan]` color markup to use `ACCENT_COLOR` (#f47721 tikalk orange) for consistent branding across:
  - Selection menus (table columns, key highlighting, panel borders)
  - Init messages (git, JSON merge, permissions, constitution)
  - Setup and Next Steps panels (titles, borders, all commands)
  - Integration/preset/extension commands (install, list, info hints)
  - Error recovery suggestions and security notices

## [0.3.4] - 2026-04-04

### Fixed

- **Extension command patterns**: Allow `adlc.` prefix in addition to `speckit.` for extension command names
- **Extension alias patterns**: Allow shorter `{extension}.{command}` format for aliases (e.g., `architect.init`)

## [0.3.3] - 2026-04-04

### Fixed

- **PowerShell positional args**: Added `Position=0` to `FeatureDescription` parameter and removed `[Parameter()]` from `Number` to ensure positional arguments bind correctly

## [0.3.2] - 2026-04-04

### Fixed

- **PowerShell script syntax**: Moved dot-source of `discovery-functions.ps1` after the `param()` block in `create-new-feature.ps1` (PowerShell requires param to be the first executable statement)

## [0.3.1] - 2026-04-04

### Added

- **Bundled extensions auto-install**: `install_bundled_extensions()` function now automatically installs bundled extensions (levelup, architect, quick, product) during `specify init`
- **Bundled presets auto-install**: `install_bundled_presets()` function now automatically installs the agentic-sdlc preset during `specify init`
- **SPECKIT_SKIP_BUNDLED env var**: Set to skip bundled extension/preset installation (used by tests)

### Changed

- **StepTracker theming**: Restored tikalk orange (`ACCENT_COLOR`) theming for tree title and running step indicator
- **Init tracker steps**: Added "extensions" and "presets" progress steps to init workflow

### Fixed

- **Test determinism**: File inventory tests now use `SPECKIT_SKIP_BUNDLED=1` to prevent bundled assets from affecting expected file lists

## [0.3.0] - 2026-04-04

### Added

- **Upstream merge (v0.5.0)**: Integrated upstream spec-kit changes including:
  - New integration plugin architecture with 30+ AI agent integrations
  - Forge agent support
  - Claude skills mode (`--ai-skills` for Claude)
  - `--dry-run` flag for `create-new-feature.sh` to preview branch names without side effects
  - DEVELOPMENT.md documentation
  - Stage 5/6 skills migration support

### Changed

- **Integration architecture**: Agents now use modular `src/specify_cli/integrations/` structure
- **Tikalk theme**: Preserved tikalk orange accent colors (`#f47721`) and banner styling
- **Package name priority**: `agentic-sdlc-specify-cli` is now checked before `specify-cli` for version detection
- **Team directives**: Added `sync_team_ai_directives()` function for repository-based directive syncing

### Fixed

- **Dry-run mode**: Fixed specs directory creation during dry-run (now properly skipped)
- **Test fixtures**: Updated file inventory tests to include tikalk-specific scripts

## [0.2.4] - 2026-04-01

### Changed

- **LevelUp clarify DX improvements**:
  - Cap at 5 CDRs per session (mirrors SPEC KIT pattern)
  - Sequential one-CDR-at-a-time (replaces batch questioning)
  - Bulk actions FIRST (Accept All / Reject All / Individual)
  - Auto-skip coverage questions if no TEAM_DIRECTIVES
  - Early exit support ("stop", "done", "skip remaining")
  - Dynamic question limit (10 if TEAM_DIRECTIVES exists, 5 if not)
- **LevelUp extension**: Version bumped to 1.1.0

## [0.2.1] - 2026-03-28

### Changed

- **Quick extension**: Redesigned to low-friction mode with 1-stop (Mission Brief) + task-level commits as checkpoints

## [0.1.23] - 2026-03-25

### Added

- **Assumptions section**: Added new Assumptions section to spec-template.md for documenting project assumptions
- **Preset alignment**: Updated agentic-sdlc preset to align with upstream template changes

### Changed

- **Success Criteria terminology**: Updated preset commands to use "Success Criteria" instead of "Non-Functional Requirements" (aligning with upstream v0.4.1)

## [0.1.22] - 2026-03-25

### Added

- **product.roadmap command**: New command to track milestone progress by analyzing feature spec task completion and update PDR status to "Completed"
- **PDR reference fields in spec template**: Added `Milestone Reference` and `Feature PDR Reference` fields to spec header for traceability
- **Phase 2 PDR selection in spec.specify**: Added optional phase to read PDR file and prompt user to select which Feature PDR the feature belongs to

### Changed

- **product.implement handoffs**: Added tracking of roadmap progress after generating PRD

## [0.1.21] - 2026-03-23

### Changed

- Removed extension summary from banner display

## [0.1.20] - 2026-03-22

### Fixed

- **Template download source**: `specify init` now downloads templates from `tikalk/agentic-sdlc-spec-kit` instead of `github/spec-kit`, ensuring users get the tikalk fork's templates with tikalk-specific agent support.

## [0.1.19] - 2026-03-22

### Fixed

- **StepTracker key for team directives**: Fixed mismatch between tracker key used in `init` (was `"directives"`, now `"team-ai-directives"`) and the key used in StepTracker initialization, ensuring team AI directives are tracked correctly.
- **Template version for fork packages**: Changed `specify version` to fetch the template version from `tikalk/agentic-sdlc-spec-kit` instead of `github/spec-kit`.
- **Type annotation fixes**: Fixed various pre-existing type annotation issues in `__init__.py` (optional parameters with `None` defaults, `None` guard for extension ID, `None` guard for project name, and `None` guard for backup registry entry).
- **Preset command refresh**: Added `refresh_preset_commands()` method to `PresetManager` to properly re-register commands for already-installed presets during `preset update`.

## [0.1.18] - 2026-03-21

### Fixed

- **Version detection for fork packages**: `specify init` now correctly resolves the CLI version when the package is installed under `agentic-sdlc-specify-cli` (e.g., via `uv tool install`). Previously it only tried `specify-cli`, causing preset compatibility checks to fail with `Invalid version: 'unknown'` for bundled presets like `agentic-sdlc`.

## [0.1.17] - 2026-03-20

### Changed

- **product extension v1.0.1**: PDR lifecycle alignment with architect extension
  - Added explicit `drafts_location` and `memory_location` keys in `extension.yml`
  - Added PDR lifecycle documentation comment
  - Renamed "Cleanup Phase" to "Phase 6: PDR Lifecycle Management" in implement.md
  - Updated pdr-template.md with 3-location model

### Preserved

- All tikalk-specific features maintained (orange branding, --team-ai-directives, skills, bundled extensions)

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

## [0.7.3] - 2026-04-17

### Changed

- fix: replace shell-based context updates with marker-based upsert (#2259)
- Add Community Friends page to docs site (#2261)
- Add Spec Scope extension to community catalog (#2172)
- docs: add Community-maintained plugin for Claude Code and GitHub Copilot CLI that installs Spec Kit skills via the plugin marketplace to README (#2250)
- fix: suppress CRLF warnings in auto-commit.ps1 (#2258)
- feat: register Blueprint in community catalog (#2252)
- preset: Update preset-fiction-book-writing to community catalog -> v1.5.0 (#2256)
- chore(deps): bump actions/upload-pages-artifact from 3 to 5 (#2251)
- fix: add reference/*.md to docfx content glob (#2248)
- chore: release 0.7.2, begin 0.7.3.dev0 development (#2247)

## [0.7.2] - 2026-04-16

### Changed

- docs: add core commands reference and simplify README CLI section (#2245)
- docs: add workflows reference, reorganize into docs/reference/, and add --version flag (#2244)
- docs: add presets reference page and rename pack_id to preset_id (#2243)
- docs: add extensions reference page and integrations FAQ (#2242)
- docs: consolidate integration documentation into docs/integrations.md (#2241)
- feat: update memorylint and superpowers-bridge versions to 1.3.0 with new download URLs (#2240)
- feat: Integration catalog — discovery, versioning, and community distribution (#2130)
- Add Catalog CI extension to community catalog (#2239)
- Added issues extension (#2194)
- chore: release 0.7.1, begin 0.7.2.dev0 development (#2235)

## [0.7.1] - 2026-04-15

### Changed

- ci: add windows-latest to test matrix (#2233)
- docs: remove deprecated --skip-tls references from local-development guide (#2231)
- fix: allow Claude to chain skills for hook execution (#2227)
- docs: merge TESTING.md into CONTRIBUTING.md, remove TESTING.md (#2228)
- Add agent-assign extension to community catalog (#2030)
- fix: unofficial PyPI warning (#1982) and legacy extension command name auto-correction (#2017) (#2027)
- feat: register architect-preview in community catalog (#2214)
- chore: deprecate --ai flag in favor of --integration on specify init (#2218)
- chore: release 0.7.0, begin 0.7.1.dev0 development (#2217)

## [0.7.0] - 2026-04-14

### Changed

- Add workflow engine with catalog system (#2158)
- docs(catalog): add claude-ask-questions to community preset catalog (#2191)
- Add SFSpeckit — Salesforce SDD Extension (#2208)
- feat(scripts): optional single-segment branch prefix for gitflow (#2202)
- chore: release 0.6.2, begin 0.6.3.dev0 development (#2205)
- Add Worktrees extension to community catalog (#2207)
- feat: Update catalog.community.json for preset-fiction-book-writing (#2199)

## [0.6.2] - 2026-04-13

### Changed

- feat: Register "What-if Analysis" community extension (#2182)
- feat: add GitHub Issues Integration to community catalog (#2188)
- feat(agents): add Goose AI agent support (#2015)
- Update ralph extension to v1.0.1 in community catalog (#2192)
- fix: skip docs deployment workflow on forks (#2171)
- chore: release 0.6.1, begin 0.6.2.dev0 development (#2162)

## [0.6.1] - 2026-04-10

### Changed

- feat: add bundled lean preset with minimal workflow commands (#2161)
- Add Brownfield Bootstrap extension to community catalog (#2145)
- Add CI Guard extension to community catalog (#2157)
- Add SpecTest extension to community catalog (#2159)
- fix: bundled extensions should not have download URLs (#2155)
- Add PR Bridge extension to community catalog (#2148)
- feat(cursor-agent): migrate from .cursor/commands to .cursor/skills (#2156)
- Add TinySpec extension to community catalog (#2147)
- chore: bump spec-kit-verify to 1.0.3 and spec-kit-review to 1.0.1 (#2146)
- Add Status Report extension to community catalog (#2123)
- chore: release 0.6.0, begin 0.6.1.dev0 development (#2144)

## [0.6.0] - 2026-04-09

### Changed

- Add Bugfix Workflow community extension to catalog and README (#2135)
- Add Worktree Isolation extension to community catalog (#2143)
- Add multi-repo-branching preset to community catalog (#2139)
- Readme clarity (#2013)
- Rewrite AGENTS.md for integration architecture (#2119)
- docs: add SpecKit Companion to Community Friends section (#2140)
- feat: add memorylint extension to community catalog (#2138)
- chore: release 0.5.1, begin 0.5.2.dev0 development (#2137)

## [0.5.1] - 2026-04-08

### Changed

- fix: pin typer>=0.24.0 and click>=8.2.1 to fix import crash (#2136)
- feat: update fleet extension to v1.1.0 (#2029)
- fix(forge): use hyphen notation in frontmatter name field (#2075)
- fix(bash): sed replacement escaping, BSD portability, dead cleanup in update-agent-context.sh (#2090)
- Add Spec Diagram community extension to catalog and README (#2129)
- feat: Git extension stage 2 — GIT_BRANCH_NAME override, --force for existing dirs, auto-install tests (#1940) (#2117)
- fix(git): surface checkout errors for existing branches (#2122)
- Add Branch Convention community extension to catalog and README (#2128)
- docs: lighten March 2026 newsletter for readability (#2127)
- fix: restore alias compatibility for community extensions (#2110) (#2125)
- Added March 2026 newsletter (#2124)
- Add Spec Refine community extension to catalog and README (#2118)
- Add explicit-task-dependencies community preset to catalog and README (#2091)
- Add toc-navigation community preset to catalog and README (#2080)
- fix: prevent ambiguous TOML closing quotes when body ends with `"` (#2113) (#2115)
- fix speckit issue for trae (#2112)
- feat: Git extension stage 1 — bundled `extensions/git` with hooks on all core commands (#1941)
- Upgraded confluence extension to v.1.1.1 (#2109)
- Update V-Model Extension Pack to v0.5.0 (#2108)
- Add canon extension and canon-core preset. (#2022)
- [stage2] fix: serialize multiline descriptions in legacy TOML renderer (#2097)
- [stage1] fix: strip YAML frontmatter from TOML integration prompts (#2096)
- Add Confluence extension (#2028)
- fix: accept 4+ digit spec numbers in tests and docs (#2094)
- fix(scripts): improve git branch creation error handling (#2089)
- Add optimize extension to community catalog (#2088)
- feat: add "VS Code Ask Questions" preset (#2086)
- Add security-review v1.1.1 to community extensions catalog (#2073)
- Add `specify integration` subcommand for post-init integration management (#2083)
- Remove template version info from CLI, fix Claude user-invocable, cleanup dead code (#2081)
- fix: add user-invocable: true to skill frontmatter (#2077)
- fix: add actions:write permission to stale workflow (#2079)
- feat: add argument-hint frontmatter to Claude Code commands (#1951) (#2059)
- Update conduct extension to v1.0.1 (#2078)
- chore(deps): bump astral-sh/setup-uv from 7.6.0 to 8.0.0 (#2072)
- chore(deps): bump actions/configure-pages from 5 to 6 (#2071)
- feat: add spec-kit-fixit extension to community catalog (#2024)
- chore: release 0.5.0, begin 0.5.1.dev0 development (#2070)
- feat: add Forgecode agent support (#2034)

## [0.5.0] - 2026-04-02

### Changed

- Introduces DEVELOPMENT.md (#2069)
- Update cc-sdd reference to cc-spex in Community Friends (#2007)
- chore: release 0.4.5, begin 0.4.6.dev0 development (#2064)

## [0.4.5] - 2026-04-02

### Changed

- Stage 6: Complete migration — remove legacy scaffold path (#1924) (#2063)
- Install Claude Code as native skills and align preset/integration flows (#2051)
- Add repoindex 0402 (#2062)
- Stage 5: Skills, Generic & Option-Driven Integrations (#1924) (#2052)
- feat(scripts): add --dry-run flag to create-new-feature (#1998)
- fix: support feature branch numbers with 4+ digits (#2040)
- Add community content disclaimers (#2058)
- docs: add community extensions website link to README and extensions docs (#2014)
- docs: remove dead Cognitive Squad and Understanding extension links and from extensions/catalog.community.json (#2057)
- Add fix-findings extension to community catalog (#2039)
- Stage 4: TOML integrations — gemini and tabnine migrated to plugin architecture (#2050)
- feat: add 5 lifecycle extensions to community catalog (#2049)
- Stage 3: Standard markdown integrations — 19 agents migrated to plugin architecture (#2038)
- chore: release 0.4.4, begin 0.4.5.dev0 development (#2048)

## [0.4.4] - 2026-04-01

### Changed

- Stage 2: Copilot integration — proof of concept with shared template primitives (#2035)
- docs: sync AGENTS.md with AGENT_CONFIG for missing agents (#2025)
- docs: ensure manual tests use local specify (#2020)
- Stage 1: Integration foundation — base classes, manifest system, and registry (#1925)
- fix: harden GitHub Actions workflows (#2021)
- chore: use PEP 440 .dev0 versions on main after releases (#2032)
- feat: add superpowers bridge extension to community catalog (#2023)
- feat: add product-forge extension to community catalog (#2012)
- feat(scripts): add --allow-existing-branch flag to create-new-feature (#1999)
- fix(scripts): add correct path for copilot-instructions.md (#1997)
- Update README.md (#1995)
- fix: prevent extension command shadowing (#1994)
- Fix Claude Code CLI detection for npm-local installs (#1978)
- fix(scripts): honor PowerShell agent and script filters (#1969)
- feat: add MAQA extension suite (7 extensions) to community catalog (#1981)
- feat: add spec-kit-onboard extension to community catalog (#1991)
- Add plan-review-gate to community catalog (#1993)
- chore(deps): bump actions/deploy-pages from 4 to 5 (#1990)
- chore(deps): bump DavidAnson/markdownlint-cli2-action from 19 to 23 (#1989)
- chore: bump version to 0.4.3 (#1986)

## [0.4.3] - 2026-03-26

### Changed

- Unify Kimi/Codex skill naming and migrate legacy dotted Kimi dirs (#1971)
- fix(ps1): replace null-conditional operator for PowerShell 5.1 compatibility (#1975)
- chore: bump version to 0.4.2 (#1973)

## [0.4.2] - 2026-03-25

### Changed

- feat: Auto-register ai-skills for extensions whenever applicable (#1840)
- docs: add manual testing guide for slash command validation (#1955)
- Add AIDE, Extensify, and Presetify to community extensions (#1961)
- docs: add community presets section to main README (#1960)
- docs: move community extensions table to main README for discoverability (#1959)
- docs(readme): consolidate Community Friends sections and fix ToC anchors (#1958)
- fix(commands): rename NFR references to success criteria in analyze and clarify (#1935)
- Add Community Friends section to README (#1956)
- docs: add Community Friends section with Spec Kit Assistant VS Code extension (#1944)

## [0.4.1] - 2026-03-24

### Changed

- Add checkpoint extension (#1947)
- fix(scripts): prioritize .specify over git for repo root detection (#1933)
- docs: add AIDE extension demo to community projects (#1943)
- fix(templates): add missing Assumptions section to spec template (#1939)

## [0.4.0] - 2026-03-23

### Changed

- fix(cli): add allow_unicode=True and encoding="utf-8" to YAML I/O (#1936)
- fix(codex): native skills fallback refresh + legacy prompt suppression (#1930)
- feat(cli): embed core pack in wheel for offline/air-gapped deployment (#1803)
- ci: increase stale workflow operations-per-run to 250 (#1922)

## [0.3.2] - 2026-03-19

## [0.4.1] - 2026-03-24

### Changed

- Add checkpoint extension (#1947)
- fix(scripts): prioritize .specify over git for repo root detection (#1933)
- docs: add AIDE extension demo to community projects (#1943)
- fix(templates): add missing Assumptions section to spec template (#1939)

## [0.4.0] - 2026-03-23

### Changed

- fix(cli): add allow_unicode=True and encoding="utf-8" to YAML I/O (#1936)
- fix(codex): native skills fallback refresh + legacy prompt suppression (#1930)
- feat(cli): embed core pack in wheel for offline/air-gapped deployment (#1803)
- ci: increase stale workflow operations-per-run to 250 (#1922)
- docs: update publishing guide with Category and Effect columns (#1913)
- fix: Align native skills frontmatter with install_ai_skills (#1920)
- feat: add timestamp-based branch naming option for `specify init` (#1911)
- docs: add Extension Comparison Guide for community extensions (#1897)
- docs: update SUPPORT.md, fix issue templates, add preset submission template (#1910)
- Add support for Junie (#1831)
- feat: migrate Codex/agy init to native skills workflow (#1906)

## [0.3.2] - 2026-03-19

### Changed

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

## [0.1.12] - 2026-03-02

### Changed

- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)

## [0.1.11] - 2026-03-02

### Changed

- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)

## [0.1.10] - 2026-02-27

### Changed

- fix: prepend YAML frontmatter to Cursor .mdc files (#1699)

## [0.1.9] - 2026-02-28

### Changed

- chore(deps): bump astral-sh/setup-uv from 6 to 7 (#1709)

## [0.1.8] - 2026-02-28

### Changed

- chore(deps): bump actions/setup-python from 5 to 6 (#1710)

## [0.1.7] - 2026-02-27

### Changed

- chore: Update outdated GitHub Actions versions (#1706)
- docs: Document dual-catalog system for extensions (#1689)
- Fix version command in documentation (#1685)
- Add Cleanup Extension to README (#1678)
- Add retrospective extension to community catalog (#1681)

## [0.1.6] - 2026-02-23

### Changed

- Add Cleanup Extension to catalog (#1617)
- Fix parameter ordering issues in CLI (#1669)
- Update V-Model Extension Pack to v0.4.0 (#1665)
- docs: Fix doc missing step (#1496)
- Update V-Model Extension Pack to v0.3.0 (#1661)

## [0.1.5] - 2026-02-21

### Changed

- Fix #1658: Add commands_subdir field to support non-standard agent directory structures (#1660)
- feat: add GitHub issue templates (#1655)
- Update V-Model Extension Pack to v0.2.0 in community catalog (#1656)
- Add V-Model Extension Pack to catalog (#1640)
- refactor: remove OpenAPI/GraphQL bias from templates (#1652)

## [0.1.4] - 2026-02-20

### Changed

- fix: rename Qoder AGENT_CONFIG key from 'qoder' to 'qodercli' to match actual CLI executable (#1651)

## [0.1.3] - 2026-02-20

### Changed

- Add generic agent support with customizable command directories (#1639)

## [0.1.2] - 2026-02-20

### Changed

- fix: pin click>=8.1 to prevent Python 3.14/Homebrew env isolation crash (#1648)

## [0.0.102] - 2026-02-20

### Changed

- fix: include 'src/**' path in release workflow triggers (#1646)

## [0.0.101] - 2026-02-19

### Changed

- chore(deps): bump github/codeql-action from 3 to 4 (#1635)

## [0.0.100] - 2026-02-19

### Changed

- Add pytest and Python linting (ruff) to CI (#1637)
- feat: add pull request template for better contribution guidelines (#1634)

## [0.0.99] - 2026-02-19

### Changed

- Feat/ai skills (#1632)

## [0.0.98] - 2026-02-19

### Changed

- chore(deps): bump actions/stale from 9 to 10 (#1623)
- feat: add dependabot configuration for pip and GitHub Actions updates (#1622)

## [0.0.97] - 2026-02-18

### Changed

- Remove Maintainers section from README.md (#1618)

## [0.0.96] - 2026-02-17

### Changed

- fix: typo in plan-template.md (#1446)

## [0.0.95] - 2026-02-12

### Changed

- Feat: add a new agent: Google Anti Gravity (#1220)

## [0.0.94] - 2026-02-11

### Changed

- Add stale workflow for 180-day inactive issues and PRs (#1594)

## [0.0.93] - 2026-02-10

### Changed

- Add modular extension system (#1551)

## [0.0.92] - 2026-02-10

### Changed

- Fixes #1586 - .specify.specify path error (#1588)

## [0.0.91] - 2026-02-09

### Changed

- fix: preserve constitution.md during reinitialization (#1541) (#1553)
- fix: resolve markdownlint errors across documentation (#1571)

## [0.0.90] - 2025-12-04

### Changed

- Update Markdown formatting
- Update Markdown formatting
- docs: Add existing project initialization to getting started

## [0.0.89] - 2025-12-02

### Changed

- Update scripts/bash/create-new-feature.sh
- fix(scripts): prevent octal interpretation in feature number parsing
- fix: remove unused short_name parameter from branch numbering functions
- Update scripts/powershell/create-new-feature.ps1
- Update scripts/bash/create-new-feature.sh
- fix: use global maximum for branch numbering to prevent collisions

## [0.0.88] - 2025-12-01

### Changed

- fix the incorrect task-template file path

## [0.0.87] - 2025-12-01

### Changed

- Limit width and height to 200px to match the small logo
- docs: Switch readme logo to logo_large.webp
- fix:merge
- fix
- fix
- feat:qoder agent
- docs: Enhance quickstart guide with admonitions and examples
- docs: add constitution step to quickstart guide (fixes #906)
- Update supported AI agents in README.md
- cancel:test
- test
- fix:literal bug
- fix:test
- test
- fix:qoder url
- fix:download owner
- test
- feat:support Qoder CLI

## [0.0.86] - 2025-11-26

### Changed

- feat: add bob to new update-agent-context.ps1 + consistency in comments
- feat: add support for IBM Bob IDE

## [0.0.85] - 2025-11-14

### Changed

- Unset CDPATH while getting SCRIPT_DIR

## [0.0.84] - 2025-11-14

### Changed

- docs: fix broken link and improve agent reference
- docs: reorganize upgrade documentation structure
- docs: remove related documentation section from upgrading guide
- fix: remove broken link to existing project guide
- docs: Add comprehensive upgrading guide for Spec Kit
- Refactor ESLint configuration checks in implement.md to address deprecation

## [0.0.83] - 2025-11-14

### Changed

- feat: Add OVHcloud SHAI AI Agent

## [0.0.82] - 2025-11-14

### Changed

- fix: incorrect logic to create release packages with subset AGENTS or SCRIPTS

## [0.0.81] - 2025-11-14

### Changed

- Fix tasktoissues.md to use the 'github/github-mcp-server/issue_write' tool

## [0.0.80] - 2025-11-14

### Changed

- Refactor feature script logic and update agent context scripts
- Update templates/commands/taskstoissues.md
- Update CHANGELOG.md
- Update agent configuration
- Update scripts/powershell/create-new-feature.ps1
- Update src/specify_cli/__init__.py
- Create create-release-packages.ps1
- Script changes
- Update taskstoissues.md
- Create taskstoissues.md
- Update src/specify_cli/__init__.py
- Update CONTRIBUTING.md
- Potential fix for code scanning alert no. 3: Workflow does not contain permissions
- Update src/specify_cli/__init__.py
- Update CHANGELOG.md
- Fixes #970
- Fixes #975
- Support for version command
- Exclude generated releases
- Lint fixes
- Prompt updates
- Hand offs with prompts
- Chatmodes are back in vogue
- Let's switch to proper prompts
- Update prompts
- Update with prompt
- Testing hand-offs
- Use VS Code handoffs

## [0.0.79] - 2025-10-23

### Changed

- docs: restore important note about JSON output in specify command
- fix: improve branch number detection to check all sources
- feat: check remote branches to prevent duplicate branch numbers

## [0.0.78] - 2025-10-21

### Changed

- Update CONTRIBUTING.md
- docs: add steps for testing template and command changes locally
- update specify to make "short-name" argu for create-new-feature.sh in the right position

## [0.0.77] - 2025-10-21

### Changed

- fix: include the latest changelog in the `GitHub Release`'s  body

## [0.0.76] - 2025-10-21

### Changed

- Fix update-agent-context.sh to handle files without Active Technologies/Recent Changes sections

## [0.0.75] - 2025-10-21

### Changed

- Fixed indentation.
- Added correct `install_url` for Amp agent CLI script.
- Added support for Amp code agent.

## [0.0.74] - 2025-10-21

### Changed

- feat(ci): add markdownlint-cli2 for consistent markdown formatting

## [0.0.73] - 2025-10-21

### Changed

- revert vscode auto remove extra space
- fix: correct command references in implement.md
- fix regarding copilot suggestion
- fix: correct command references in speckit.analyze.md
- Support more lang/Devops of Common Patterns by Technology
- chore: replace `bun` by `node/npm` in the `devcontainer` (as many CLI-based agents actually require a `node` runtime)
- chore: add Claude Code extension to devcontainer configuration
- chore: add installation of `codebuddy` CLI in the `devcontainer`
- chore: fix path to powershell script in vscode settings
- fix: correct `run_command` exit behavior and improve installation instructions (for `Amazon Q`) in `post-create.sh` + fix typos in `CONTRIBUTING.md`
- chore: add `specify`'s github copilot chat settings to `devcontainer`
- chore: add `devcontainer` support  to ease developer workstation setup

## [0.0.72] - 2025-10-18

### Changed

- fix: correct argument parsing in create-new-feature.sh script

## [0.0.71] - 2025-10-18

### Changed

- fix: Skip CLI checks for IDE-based agents in check command
- Change loop condition to include last argument

## [0.0.70] - 2025-10-18

### Changed

- fix: broken media files
- Update README.md
- The function parameters lack type hints. Consider adding type annotations for better code clarity and IDE support.
- - **Smart JSON Merging for VS Code Settings**: `.vscode/settings.json` is now intelligently merged instead of being overwritten during `specify init --here` or `specify init .`   - Existing settings are preserved   - New Spec Kit settings are added   - Nested objects are merged recursively   - Prevents accidental loss of custom VS Code workspace configurations
- Fix: incorrect command formatting in agent context file, refix #895

## [0.0.69] - 2025-10-15

### Changed

- Update scripts/bash/create-new-feature.sh
- Update create-new-feature.sh
- Update files
- Update files
- Create .gitattributes
- Update wording
- Update logic for arguments
- Update script logic

## [0.0.68] - 2025-10-15

### Changed

- format content as copilot suggest
- Ruby, PHP, Rust, Kotlin, C, C++

## [0.0.67] - 2025-10-15

### Changed

- Use the number prefix to find the right spec

## [0.0.66] - 2025-10-15

### Changed

- Update CodeBuddy agent name to 'CodeBuddy CLI'
- Rename CodeBuddy to CodeBuddy CLI in update script
- Update AI coding agent references in installation guide
- Rename CodeBuddy to CodeBuddy CLI in AGENTS.md
- Update README.md
- Update CodeBuddy link in README.md
- update codebuddyCli

## [0.0.65] - 2025-10-15

### Changed

- Fix: Fix incorrect command formatting in agent context file
- docs: fix heading capitalization for consistency
- Update README.md

## [0.0.64] - 2025-10-14

### Changed

- Update tasks.md
- Update README.md

## [0.0.63] - 2025-10-14

### Changed

- fix: update CODEBUDDY file path in agent context scripts
- docs(readme): add /speckit.tasks step and renumber walkthrough

## [0.0.62] - 2025-10-11

### Changed

- A few more places to update from code review
- fix: align Cursor agent naming to use 'cursor-agent' consistently

## [0.0.61] - 2025-10-10

### Changed

- Update clarify.md
- add how to upgrade specify installation

## [0.0.60] - 2025-10-10

### Changed

- Update vscode-settings.json
- Update instructions and bug fix

## [0.0.59] - 2025-10-10

### Changed

- Update __init__.py
- Consolidate Cursor naming
- Update CHANGELOG.md
- Git errors are now highlighted.
- Update __init__.py
- Refactor agent configuration
- Update src/specify_cli/__init__.py
- Update scripts/powershell/update-agent-context.ps1
- Update AGENTS.md
- Update templates/commands/implement.md
- Update templates/commands/implement.md
- Update CHANGELOG.md
- Update changelog
- Update plan.md
- Add ignore file verification step to /speckit.implement command
- Escape backslashes in TOML outputs
- update CodeBuddy to international site
- feat: support codebuddy ai
- feat: support codebuddy ai

## [0.0.58] - 2025-10-08

### Changed

- Add escaping guidelines to command templates
- Update README.md
- Update README.md

## [0.0.57] - 2025-10-06

### Changed

- Update CHANGELOG.md
- Update command reference
- Package up VS Code settings for Copilot
- Update tasks-template.md
- Update templates/tasks-template.md
- Cleanup
- Update CLI changes
- Update template and docs
- Update checklist.md
- Update templates
- Cleanup redundancies
- Update checklist.md
- Codex CLI is now fully supported
- Update specify.md
- Prompt updates
- Update prompt prefix
- Update .github/workflows/scripts/create-release-packages.sh
- Consistency updates to commands
- Update commands.
- Update logs
- Template cleanup and reorganization
- Remove Codex named args limitation warning
- Remove Codex named args limitation from README.md

## [0.0.56] - 2025-10-02

### Changed

- docs(readme): link Amazon Q slash command limitation issue
- docs: clarify Amazon Q limitation and update init docstring
- feat(agent): Added Amazon Q Developer CLI Integration

## [0.0.55] - 2025-09-30

### Changed

- Update URLs to Contributing and Support Guides in Docs
- fix: add UTF-8 encoding to file read/write operations in update-agent-context.ps1
- Update __init__.py
- Update src/specify_cli/__init__.py
- docs: fix the paths of generated files (moved under a `.specify/` folder)
- Update src/specify_cli/__init__.py
- feat: support 'specify init .' for current directory initialization
- feat: Add emacs-style up/down keys

## [0.0.54] - 2025-09-25

### Changed

- Update CONTRIBUTING.md
- Refine `plan-template.md` with improved project type detection, clarified structure decision process, and enhanced research task guidance.
- Update __init__.py

## [0.0.53] - 2025-09-24

### Changed

- Update template path for spec file creation
- Update template path for spec file creation
- docs: remove constitution_update_checklist from README

## [0.0.52] - 2025-09-22

### Changed

- Update analyze.md
- Update templates/commands/analyze.md
- Update templates/commands/clarify.md
- Update templates/commands/plan.md
- Update with extra commands
- Update with --force flag
- feat: add uv tool install instructions to README

## [0.0.51] - 2025-09-21

### Changed

- Update with Roo Code support

## [0.0.50] - 2025-09-21

### Changed

- Update generate-release-notes.sh
- Update error messages
- Auggie folder fix

## [0.0.49] - 2025-09-21

### Changed

- Update scripts/powershell/update-agent-context.ps1
- Update templates/commands/implement.md
- Cleanup the check command
- Add support for Auggie
- Update AGENTS.md
- Updates with Kilo Code support
- Update README.md
- Update templates/commands/constitution.md
- Update templates/commands/implement.md
- Update templates/commands/plan.md
- Update templates/commands/specify.md
- Update templates/commands/tasks.md
- Update README.md
- Stop splitting the warning over multiple lines
- Update templates based on #419
- docs: Update README with codex in check command

## [0.0.48] - 2025-09-21

### Changed

- Update scripts/powershell/check-prerequisites.ps1
- Update CHANGELOG.md
- Update CHANGELOG.md
- Update changelog
- Update scripts/bash/update-agent-context.sh
- Fix script config
- Update scripts/bash/common.sh
- Update scripts/powershell/update-agent-context.ps1
- Update scripts/powershell/update-agent-context.ps1
- Clarification
- Update prompts
- Update update-agent-context.ps1
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update contribution guidelines.
- Root detection logic
- Update templates/plan-template.md
- Update scripts/bash/update-agent-context.sh
- Update scripts/powershell/create-new-feature.ps1
- Simplification
- Script and template tweaks
- Update config
- Update scripts/powershell/check-prerequisites.ps1
- Update scripts/bash/check-prerequisites.sh
- Fix script path
- Script cleanup
- Update scripts/bash/check-prerequisites.sh
- Update scripts/powershell/check-prerequisites.ps1
- Update script delegation from GitHub Action
- Cleanup the setup for generated packages
- Use proper line endings
- Consolidate scripts

## [0.0.47] - 2025-09-20

### Changed

- Updating agent context files

## [0.0.46] - 2025-09-20

### Changed

- Update update-agent-context.ps1
- Update package release
- Update config
- Update __init__.py
- Update __init__.py
- Remove Codex-specific logic in the initialization script
- Update version rev
- Update __init__.py
- Enhance Codex support by auto-syncing prompt files, allowing spec generation without git, and documenting clearer /specify usage.
- Consistency tweaks
- Consistent step coloring
- Update __init__.py
- Update __init__.py
- Quick UI tweak
- Update package release
- Limit workspace command seeding to Codex init and update Codex documentation accordingly.
- Clarify Codex-specific README note with rationale for its different workflow.
- Bump to 0.0.7 and document Codex support
- Normalize Codex command templates to the scripts-based schema and auto-upgrade generated commands.
- Fix remaining merge conflict markers in __init__.py
- Add Codex CLI support with AGENTS.md and commands bootstrap

## [0.0.45] - 2025-09-19

### Changed

- Update with Windsurf support
- expose token as an argument through cli --github-token
- add github auth headers if there are GITHUB_TOKEN/GH_TOKEN set

## [0.0.44] - 2025-09-18

### Changed

- Update specify.md
- Update __init__.py

## [0.0.43] - 2025-09-18

### Changed

- Update with support for /implement

## [0.0.42] - 2025-09-18

### Changed

- Update constitution.md

## [0.0.41] - 2025-09-18

### Changed

- Update constitution.md

## [0.0.40] - 2025-09-18

### Changed

- Update constitution command

## [0.0.39] - 2025-09-18

### Changed

- Cleanup
- fix: commands format for qwen

## [0.0.38] - 2025-09-18

### Changed

- Fix template path in update-agent-context.sh
- docs: fix grammar mistakes in markdown files

## [0.0.37] - 2025-09-17

### Changed

- fix: add missing Qwen support to release workflow and agent scripts

## [0.0.36] - 2025-09-17

### Changed

- feat: Add opencode ai agent
- Fix --no-git argument resolution.

## [0.0.35] - 2025-09-17

### Changed

- chore(release): bump version to 0.0.5 and update changelog
- chore: address review feedback - remove comment and fix numbering
- feat: add Qwen Code support to Spec Kit

## [0.0.34] - 2025-09-15

### Changed

- Update template.

## [0.0.33] - 2025-09-15

### Changed

- Update scripts

## [0.0.32] - 2025-09-15

### Changed

- Update template paths

## [0.0.31] - 2025-09-15

### Changed

- Update for Cursor rules & script path
- Update Specify definition
- Update README.md
- Update with video header
- fix(docs): remove redundant white space

## [0.0.30] - 2025-09-12

### Changed

- Update update-agent-context.ps1

## [0.0.29] - 2025-09-12

### Changed

- Update create-release-packages.sh
- Update with check changes

## [0.0.28] - 2025-09-12

### Changed

- Update wording
- Update release.yml

## [0.0.27] - 2025-09-12

### Changed

- Support Cursor

## [0.0.26] - 2025-09-12

### Changed

- Saner approach to scripts

## [0.0.25] - 2025-09-12

### Changed

- Update packaging

## [0.0.24] - 2025-09-12

### Changed

- Fix package logic

## [0.0.23] - 2025-09-12

### Changed

- Update config
- Update __init__.py
- Refactor with platform-specific constraints
- Update README.md
- Update CLI reference
- Update __init__.py
- refactor: extract Claude local path to constant for maintainability
- fix: support Claude CLI installed via migrate-installer

## [0.0.22] - 2025-09-11

### Changed

- Update release.yml
- Update create-release-packages.sh
- Update create-release-packages.sh
- Update release file

## [0.0.21] - 2025-09-11

### Changed

- Consolidate script creation
- Update how Copilot prompts are created
- Update local-development.md
- Local dev guide and script updates
- Update CONTRIBUTING.md
- Enhance HTTP client initialization with optional SSL verification and bump version to 0.0.3
- Complete Gemini CLI command instructions
- Refactor HTTP client usage to utilize truststore for SSL context
- docs: Update Commands sections renaming to match implementation
- docs: Fix formatting issues in README.md for consistency
- Update docs and release

## [0.0.20] - 2025-09-08

### Changed

- Update docs/quickstart.md
- Docs setup

## [0.0.19] - 2025-09-08

### Changed

- Update README.md

## [0.0.18] - 2025-09-08

### Changed

- Update README.md

## [0.0.17] - 2025-09-08

### Changed

- Remove trailing whitespace from tasks.md template

## [0.0.16] - 2025-09-07

### Changed

- Fix release workflow to work with repository rules

## [0.0.15] - 2025-09-07

### Changed

- Use `/usr/bin/env bash` instead of `/bin/bash` for shebang

## [0.0.14] - 2025-09-04

### Changed

- fix: correct typos in spec-driven.md

## [0.0.13] - 2025-09-04

### Changed

- Fix formatting in usage instructions

## [0.0.12] - 2025-09-04

### Changed

- Fix template path in plan command documentation

## [0.0.11] - 2025-09-04

### Changed

- fix: incorrect tree structure in examples

## [0.0.10] - 2025-09-04

### Changed

- fix minor typo in Article I

## [0.0.9] - 2025-09-03

### Changed

- Update CLI commands from '/spec' to '/specify'

## [0.0.8] - 2025-09-02

### Changed

- adding executable permission to the scripts so they execute when the coding agent launches them

## [0.0.7] - 2025-09-02

### Changed

- doco(spec-driven): Fix small typo in document

## [0.0.6] - 2025-08-25

### Changed

- Update README.md

## [0.0.5] - 2025-08-25

### Changed

- Update .github/workflows/release.yml
- Fix release workflow to work with repository rules

## [0.0.4] - 2025-08-25

### Changed

- Add John Lam as contributor and release badge

## [0.0.3] - 2025-08-22

### Changed

- Update requirements

## [0.0.2] - 2025-08-22

### Changed

- Update README.md

## [0.0.1] - 2025-08-22

### Changed

- Update release.yml

