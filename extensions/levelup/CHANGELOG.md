# Changelog

All notable changes to the LevelUp extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-03

### Added

- Initial release of LevelUp extension
- `levelup.init` command for brownfield CDR discovery
- `levelup.clarify` command for resolving CDR ambiguities
- `levelup.specify` command for refining CDRs from feature context
- `levelup.skills` command for building skills from accepted CDRs
- `levelup.implement` command for creating PRs to team-ai-directives
- Context Directive Record (CDR) template
- Support for both submodule and clone paths for team-ai-directives
- Bash and PowerShell scripts for setup and analysis

### Related

- GitHub Issue: [#56](https://github.com/tikalk/agentic-sdlc-spec-kit/issues/56)
- Replaces monolithic `/spec.levelup` command
