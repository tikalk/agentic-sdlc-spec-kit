# Changelog

All notable changes to the Architect extension will be documented in this file.

## [1.1.1] - 2026-04-11

### Fixed

- **.specify directory detection**: Scripts now search upward for `.specify` directory before falling back to git root, fixing file creation in monorepo/sub-project setups
- **REPO_ROOT initialization order**: Moved common.sh sourcing before first REPO_ROOT usage to prevent undefined variable errors

## [1.1.0] - 2026-04-10

### Added

- **Multi-agent DAG orchestration** for `/architect.implement` command
  - Three-phase workflow: Plan → Execute → Summarize
  - State persistence in `.specify/architect/state.json` for resumability
  - Per-view outputs in `.specify/architect/views/{subsystem}/{view}.md`
  - Works with any AI agent (Claude, Copilot, Cursor, etc.)

- **View templates** extracted from AD-template.md:
  - `templates/views/context.md` - Context View template
  - `templates/views/functional.md` - Functional View template
  - `templates/views/information.md` - Information View template
  - `templates/views/concurrency.md` - Concurrency View template
  - `templates/views/development.md` - Development View template
  - `templates/views/deployment.md` - Deployment View template
  - `templates/views/operational.md` - Operational View template

- **Perspective templates**:
  - `templates/perspectives/security.md` - Security Perspective template
  - `templates/perspectives/performance.md` - Performance Perspective template

- **New script actions** for DAG workflow:
  - `plan-dag` - Phase 1: Generate DAG execution plan for user approval
  - `execute-dag` - Phase 2: Execute DAG to generate views per sub-system
  - `summarize` - Phase 3: Aggregate views into unified AD.md

- **DAG customization rules** based on sub-system characteristics:
  - Serverless → Deployment view first
  - Event-driven → Include Concurrency view
  - Data-intensive → Information view priority
  - Microservices → Expanded Functional view

### Changed

- **`/architect.implement`** completely rewritten with DAG orchestration
  - Sub-system detection from ADR index table
  - Dependency context passing between views
  - Cross-subsystem conflict resolution using ADRs as source of truth
  - Unified AD.md generation from per-view outputs

- **extension.yml** updated with DAG configuration:

  ```yaml
  dag:
    enabled: true
    base_location: ".specify/architect/"
    state_location: ".specify/architect/state.json"
    views_location: ".specify/architect/views/"
    view_templates: "templates/views/"
    perspective_templates: "templates/perspectives/"
  ```

### Migration

- Existing projects: No action needed (DAG workflow is opt-in via `/architect.implement`)
- Previous single-context generation still works if state.json doesn't exist

## [1.0.1] - 2026-04-09

### Fixed

- **Documentation accuracy**: Removed references to non-existent `--architecture` flag
  - Updated command documentation to correctly describe hook-based integration
  - Feature architecture now correctly documented as `before_plan` hook in `.specify/extensions.yml`
  - Clarified that architect extension must be installed for feature architecture generation

## [1.0.0] - 2026-03-04

### Added

- Initial release as extension (migrated from built-in commands)
- `/architect.init` - Brownfield ADR discovery from existing codebase
- `/architect.specify` - Greenfield PRD exploration to create ADRs
- `/architect.clarify` - ADR refinement and validation through questions
- `/architect.implement` - AD.md generation using Rozanski & Woods methodology
- `/architect.analyze` - **NEW** ADR to AD consistency analysis with 7 detection passes

### Changed

- Commands now use `speckit.architect.*` naming with `architect.*` aliases
- Handoffs defined in extension.yml instead of individual command files
- Scripts moved to extension directory

### Migration

- Users with existing architect commands: extension is auto-bundled during `specify init`
- Existing `.specify/memory/adr.md` and `AD.md` files are fully compatible
