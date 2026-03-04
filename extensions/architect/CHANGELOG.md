# Changelog

All notable changes to the Architect extension will be documented in this file.

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
