# Changelog

## [1.0.0] - 2026-06-14

### Added

- Initial release of EDD (Evaluation-Driven Development) extension
- `edd.verify` command: unified deterministic + AI evaluation, grading, and corrective prompt generation
- Deterministic check runners: lint, tests, smoke (auto-detects project type)
- AI evaluation: Mission Brief evidence mapping, oracle adequacy scoring, analyze findings check
- `grade.json` schema for machine-readable PASS/FAIL verdict
- `next-prompt.md` generation for loop-driven development workflows
- `sdd-loop.yml` workflow: `do-while` loop wrapping specify → plan → tasks → implement → verify
- Quality Gates reference template for per-feature criteria definition
- Config template for thresholds and check toggles
