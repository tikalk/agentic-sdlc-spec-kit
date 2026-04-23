# Changelog

## [v1.1.0] - 2026-04-20

### Added

- **extension.yml** - Spec-kit extension manifest
  - `adlc.team-ai-directives.verify` command for health checks
  - Enables spec-kit extension system integration

- **Documentation**:
  - README.md: Added installation section (extension vs clone)
  - AGENTS.md: Added installation locations section

## [v1.4.0] - 2026-03-13

### Changed

- **Breaking**: Reverted CDR storage from `.cdrs.json` to markdown-based `CDR.md`
  - CDRs now stored in `.specify/memory/cdr.md` in project directories (local)
  - Approved CDRs copied to `{TEAM_DIRECTIVES}/CDR.md` during `/levelup.implement`
  - Status values simplified: `Accepted` | `Rejected`
  - `/levelup.skills` now requires CDR status = "Accepted" (not "Proposed")
- **Removed `.cdrs.json`** - Single source of truth is now markdown-based
- **Removed `status` field from `.skills.json`** - Skills no longer have lifecycle status

### Updated Documentation

- **AGENTS.md** - Updated to reference CDR.md instead of .cdrs.json
- **README.md** - Added CDR.md to repository layout

## [v1.3.0] - 2026-03-12

### Added

- **`.cdrs.json`** - Context Module Registry (reverted in v1.4.0)
  - Centralized tracking of all context modules (personas, rules, examples)
  - 34 modules pre-populated with `status` field
  - Status values: `discovered` | `proposed` | `accepted` | `active` | `deprecated`
  - Enables lifecycle management of context modules

### Changed

- **Updated `AGENTS.md`** - Added Context Module Registry documentation
- **Updated `README.md`** - Added `.cdrs.json` to repository layout
- **`.skills.json`** - Added `status` field to skills for lifecycle tracking

### Note

This version was superseded by v1.4.0 which reverted the CDR storage approach.

## [v1.2.0] - 2025-02-14

### Lean Starter Kit Refactor
- **Added root `AGENTS.md`**: Instructions for AI agents on how to use the repository
- **Added `GETTING_STARTED.md`**: 5-minute quickstart guide for new users
- **Updated `README.md`**: Repositioned as "Team AI Directives Starter Kit"
- **Updated personas**: Added Rule References to Java, Python, Data Analyst, DevOps personas

### Architecture Simplification
- **Skills are self-contained**: Removed all `@rule:/@example:` references from SKILL.md files
- **Rules via personas**: Rules now accessed through persona Rule References, not skills
- **Deleted redundant files**:
  - `skills/AGENTS.md` (moved to root)
  - `skills/SKILL_TEMPLATES.md` (redundant with AGENTS.md)
  - `skills/external_skills.md` (replaced by `.skills.json` registry)

### Breaking Changes
- `skills/AGENTS.md` deleted - use root `AGENTS.md` instead
- `skills/SKILL_TEMPLATES.md` deleted - use root `AGENTS.md` instead
- Skills no longer contain `@rule:` or `@example:` references

## [v1.1.0] - 2025-02-01

### Skills Simplification & External Skills Registry
- **Added skills/external_skills.md**: URL-based registry for external skills from vercel-labs and other sources
- **Simplified skills frontmatter**: Removed complex metadata, keeping only name + description (vercel-labs format)
- **Refactored skills/ directory structure**: Moved vercel-react-best-practices to skills/ root, removed fullstack/ directory
- **Updated skills/AGENTS.md**: Removed metadata references, added external skills section
- **Updated CONTRIBUTING.md**: Removed metadata requirements, added external skills contribution guidelines
- **Updated README.md**: Removed skills.manifest.yml references, added external skills explanation
- **Simplified vercel-react-best-practices skill**: Updated frontmatter to vercel-labs simple format

### Key Features
- **External Skills**: URL-based registry for skills from other repositories, fetched on-demand via agent webfetch
- **Simple Frontmatter**: Adopted vercel-labs format (name + description only) for better LLM compatibility
- **LLM-Based Discovery**: Skills discovered using natural language matching instead of structured metadata
- **Flattened Structure**: Simplified skills directory structure following vercel-labs patterns

### Breaking Changes
- Removed complex skill metadata (category, platforms, keywords, requires_context, use_cases)
- Deleted skills.manifest.yml - skills discovered via LLM matching instead
- Deleted docs/SKILL_METADATA_STANDARD.md - no longer needed with simple format
- External skills now referenced via URL instead of being copied/wrapped

### Migration Notes
- Existing skills with complex metadata will still work but should be simplified gradually
- Teams using git submodules will automatically get new external skills registry
- Skill discovery now relies on LLM matching rather than structured metadata
- External skills are fetched on-demand via agent webfetch capabilities

## [Unreleased] - 2025-01-10
- Refactored repository structure to match final layout
- Merged principles into constitution.md at root
- Moved templates to context_modules/examples/patterns/
- Added skills/ and prompts/ directories
- Moved skills/ from context_modules/skills/ to skills/ (same level as context_modules/)
- Updated README.md to reflect new structure
- Restructured constitution: moved language-specific items (dependency injection, null safety) to rules/style-guides/
- Generalized dependency injection as neutral rule
- Renamed examples/patterns/ to examples/prompts/ for clarity (contains prompt templates)
- Moved constitution.md from root to context_modules/ for better organization of guidance content
## [Unreleased] - 2025-01-16
- Added Spring Boot framework patterns (constructor injection, JPA, testing, configuration)
- Added DevOps Engineer persona (generic DevOps philosophy, tool-agnostic)
- Added AGENTS.md meta-pattern for skills (self-contained, portable, progressive disclosure)
- Added DevOps rules directory with 7 generic patterns:
  - GitHub Actions workflows and reusable actions
  - Helm packaging and values design principles
  - Helm chart library pattern for DRY template management
  - Helm wrapper charts for extending upstream charts
  - Helm template helpers for consistent naming and labels
  - External Secrets Operator patterns for secret management
  - GKE Workload Identity for cloud authentication
- Added Phase 2 generic patterns with complete abstraction:
  - Generic DRY secrets management pattern with standalone Helm templates
  - Generic Crossplane compositions with provider-agnostic examples
  - Updated DevOps Engineer persona with complete rule references
  - All patterns work with any cloud provider without competitive advantage loss
- Added Phase 3 comprehensive externalization:
  - Added Python testing rule with pytest patterns and class-based organization
  - Added orchestration rules directory with generic Airflow and Airbyte patterns
  - Added generic skill templates for skill development patterns
  - Added Cloud Native Platform Architect persona with generic rule references
  - Updated DevOps Engineer persona with complete rule coverage
  - All patterns work with any cloud provider without competitive advantage loss