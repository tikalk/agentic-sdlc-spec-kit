# Changelog

## [1.1.0] - 2026-07-02

### Changed

- **EDD is now a convergence partner**, not just an evaluator. EDD appends actionable verification gaps as tasks to `tasks.md` (under `## Phase N: EDD`), following converge's append-only contract
- **Renamed `next-prompt.md` → `next-spec.md`** — now contains only spec-level corrections (oracle adequacy, ambiguous requirements, missing success criteria) targeting `spec.specify`; implementation-level fixes go to `tasks.md` instead
- **Fills EDD placeholder sections in converge's `verify.md`** — EDD's `after_converge` hook updates the placeholder sections (EDD Evidence, What Was Checked/Not Checked, Residual Risks, Provenance) that converge writes, producing a unified evidence bundle in a single file
- Updated `loop-state.yml` schema: `next_prompt_file` → `next_spec_file`
- Updated exit code documentation: exit 1 signals tasks appended and/or next-spec.md written; caller checks for next-spec.md to determine routing

### Added

- **Finding classification** — failed gates are classified as actionable (→ tasks.md) or spec-level (→ next-spec.md)
- **Phase 4 (Append Actionable Tasks)** — appends implementation-level verification gaps to tasks.md
- **Phase 5 (Update verify.md)** — fills EDD placeholder sections in converge's verify.md
- **Loop routing signal** — exit code documentation specifies: next-spec.md exists → route to spec.specify; tasks_appended only → route to implement
- Updated README documenting: finding classification, loop routing, unified evidence bundle

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
