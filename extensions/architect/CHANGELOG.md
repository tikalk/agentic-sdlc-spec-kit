# Changelog

All notable changes to the Architect extension will be documented in this file.

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
