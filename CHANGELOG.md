# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

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
