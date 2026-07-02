# Changelog

## [1.0.1] - 2026-07-02

### Changed

- Hook moved from `after_implement` to `after_converge` — EDD now fires after `spec.converge` instead of `spec.implement`, aligning deep evaluation with the convergence gate
- Deleted `sdd-loop.yml` workflow — replaced by `impl-converge-loop` workflow in the `loop` extension (the sdd-loop workflow had non-functional `file_exists()`/`read()` expressions and was never registered in any catalog)

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
