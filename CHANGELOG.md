# Changelog

All notable changes to the Specify CLI and templates are documented here.

# [0.10.0+adlc13] - 2026-06-14

### Added

- **EDD Extension v1.0.0** (`extensions/edd/`): New Evaluation-Driven Development extension that adds a verification layer to the SDLC cycle. Includes:
  - `edd.verify` command: unified deterministic checks (lint, tests, smoke) with project-type auto-detection + AI-driven evaluation (oracle adequacy, evidence mapping, findings analysis), grades all gates (Quality, Oracle, Evidence, Analyze, Deterministic), and generates a corrective `next-prompt.md` on failure
  - Guardrails (P0-P2): no-progress detection (STALL exit + next-prompt.md), budget ceiling (BUDGET exit with cost tracking), regression detection (REVERT suggestion in next-prompt.md), escalation sections in evidence.md, exit codes (0=PASS, 1=FAIL, 2=STALL, 3=BUDGET)
  - `.eval/loop-state.yml` spine: loop metadata (iteration, cost, started_at, budget), exit conditions, current eval (gates, verdict, score), full iteration history, lifecycle phases
  - `sdd-loop.yml` workflow: `do-while` loop wrapping specify → plan → tasks → implement, condition: `file_exists('next-prompt.md')`, no explicit verify step (hook-driven)
  - Hook-driven verify: `after_implement` hook registered with `optional: false` — fires automatically after implement, no explicit verify step in workflow
  - Deterministic check runners (`run-deterministic.{sh,ps1}`): auto-detects Python (pytest --cov), Node (npm test), Go (go test), Rust (cargo test), Rust workspace; single-capture pattern, --cov flags, smoke scenario parsing
  - Quality Gates reference template (`templates/quality-gates-section.md`) for per-feature criteria definition
  - Config template (`config-template.yml`) for thresholds (score, coverage, lint error/smoke ceilings) and guardrails (no_progress_threshold, max_cost_usd, check toggles)

### Changed

- **Agentic SDLC preset v1.1.0** (breaking):
  - Removed `adlc.spec.verify` preset command — replaced by `adlc.edd.verify` in the EDD extension
  - Removed `adlc.spec.implement` step 3 (Mission Brief pre-flight adequacy check) — redundant with EDD loop gating
  - Updated handoffs in `adlc.spec.implement` and `adlc.spec.trace` to reference `adlc.edd.verify`
  - `spec-template.md` unchanged: Quality Gates section remains (EDD reads it when present)

### Fixed

- **Review bug fixes**: Fixed all issues from initial PR review:
  - `{SCRIPT}` overload: removed redundant `{SCRIPT}` references from verify.md (scripts resolved via config)
  - Script paths: corrected `run-deterministic.{sh,ps1}` path references to `.specify/extensions/edd/` prefix
  - Workflow grade step removed: `sdd-loop.yml` no longer has explicit grade step (grade integrated into verify)
  - Double-run: deterministic scripts use single-capture pattern (output written once)
  - `--cov` flags restored in bash runner (Python coverage collection)
  - Smoke scenario parsing: fixed executable check logic, scenario-only mode emits correct exit codes

# [1.0.11] - 2026-06-13

### Added

- **`mission-brief` checklist domain**: `spec.checklist` now defaults to `mission-brief` when no domain is specified, generating a 6-item Oracle Adequacy Checklist that validates whether the Mission Brief (Goal, Success Criteria, Constraints) is sufficient to serve as its own verification oracle. Auto-fills a score (e.g., "5/6 (83%)") and verdict ("Ready for implementation / Needs refinement").
- **`spec.specify` handoff to `spec.checklist mission-brief`**: after Mission Brief approval, the specify command now suggests running the oracle adequacy check before proceeding to planning.
- **`spec.implement` pre-flight Mission Brief Adequacy check**: before execution tracking initialization, checks if `checklists/mission-brief.md` exists and warns if the adequacy score is < 80%, asking the user whether to proceed.

# [0.10.0+adlc12] - 2026-06-14

### Added

- **`specify preset update` command**: New CLI command mirroring `specify extension update`. Checks bundled CLI presets and remote catalogs for newer versions, performs atomic updates with automatic backup/rollback, and preserves user settings (priority, enabled/disabled state).
- **Fork `_assets_fork.py` module**: Consolidates all fork-specific bundled-asset helpers (previously scattered in `_assets.py` since adlc4/adlc8) into a new leaf module, restoring `_assets.py` to clean-upstream. Contains `get_bundled_extension/preset_version/_path` and the `bundled_presets/` locator fallback.
- **Fuzzy-match suggestions on `specify preset add`**: When a preset ID is not found, the CLI now suggests close matches (e.g., "Did you mean 'agentic-sdlc'?") using `difflib.get_close_matches` against bundled presets and catalog entries.

### Fixed

- **Better error message for preset typos**: The bare "Preset 'X' not found in catalog" error now includes actionable suggestions when a similar preset name exists.

# [0.10.0+adlc11] - 2026-06-13

### Changed

- **CLI bumped to `0.10.0+adlc11`**: this fork release captures the Agentic SDLC preset v1.0.11 mission-brief oracle adequacy changes.
- **Agentic SDLC preset bumped to 1.0.11**: added `mission-brief` checklist domain, `spec.specify` handoff to `spec.checklist mission-brief`, and `spec.implement` pre-flight adequacy warning.

# [0.10.0+adlc10] - 2026-06-13

### Added

- **`quick.levelup` command**: New low-friction command for contributing directives to team-ai-directives. Single-session flow with 6 verifiable phases (Parse & Classify, Structure CDR, Signal Gate + Cross-System Validation, User Review, Publish, PR). Generates CDRs matching `levelup.implement` format with Descriptor column. Includes companion skill auto-detection, output artifact verification, and handoff to `/levelup.validate`. Quick extension bumped to v1.2.0.

# [0.10.0+adlc9] - 2026-06-13

### Added

- **CDR.md as context module search surface**: `/team.discover` now loads `CDR.md` as the primary search index (skills-style), matching relevance from the new `Descriptor` column + path + type. Full file content loaded on-demand only for matched modules. Legacy `context_modules/` scan retained as fallback.
- **Descriptor column in CDR.md index**: New `Descriptor` column in the published CDR.md index table provides a "when to use" summary for each context module, analogous to `.skills.json` for skills. Backfilled for all 27 existing CDRs.
- **cdr_id in team-context.json**: Each entry now links back to its originating CDR for full traceability.

### Changed

- **LevelUp extension bumped to 1.8.0**: `/levelup.implement` emits the Descriptor column and `### Descriptor` per-CDR field.
- **Team AI Directives extension bumped to 1.8.0**: `/team.discover` uses CDR index as search surface, `/team.repair` re-indexer updated for Descriptor column, `agents-template.md` updated.
- **CLI bumped to `0.10.0+adlc9`**: this fork release captures the CDR-index-as-search-surface changes across both team-ai-directives and levelup extensions.

# [0.10.0+adlc8] - 2026-06-12

### Fixed

- **`specify preset add agentic-sdlc` now works from wheel/uv-tool installs**: `_locate_bundled_preset()` was missing a fallback for the `bundled_presets/` directory where the fork's `agentic-sdlc` preset is packaged during wheel builds. Previously the command only succeeded in editable/source installs.

# [1.0.10] - 2026-06-12

### Changed

- **Agentic SDLC preset bumped to 1.0.10**: trimmed duplicate `[SYNC]`/`[ASYNC]` classification guidance in `adlc.spec.plan.md` and `adlc.spec.tasks.md`, replacing inline taxonomies with references to canonical `templates/plan-template.md` and `templates/tasks-template.md`. Saves ~340 tokens with no behavior change.

# [0.10.0+adlc7] - 2026-06-12

### Changed

- **CLI bumped to `0.10.0+adlc7`**: this fork release captures the Agentic SDLC preset v1.0.10 token-reduction trim.
- **Agentic SDLC preset bumped to 1.0.10**: trimmed duplicate `[SYNC]`/`[ASYNC]` classification guidance in `adlc.spec.plan.md` and `adlc.spec.tasks.md`, replacing inline taxonomies with references to canonical `templates/plan-template.md` and `templates/tasks-template.md`. Saves ~340 tokens with no behavior change.

# [0.10.0+adlc6] - 2026-06-08

### Changed

- **CLI bumped to `0.10.0+adlc6`**: this fork release captures the evals extension repairs, the `spec.trace` command-surface move, and the new `spec.verify` verification workflow.
- **Evals extension bumped to 1.1.1**: restored missing PowerShell lifecycle support, fixed stale validation paths, and hardened non-interactive/bash validation behavior for CI and local smoke tests.
- **LevelUp extension remains at 1.7.1**: completed the feature trace ownership move from `levelup.trace` to `spec.trace` with LevelUp continuing to consume `trace.md` via `levelup.specify`.
- **Agentic SDLC preset bumped to 1.0.9**: added `adlc.spec.trace` and `adlc.spec.verify`, updated `spec.implement` handoffs to suggest trace and verify, and made `spec.trace` hand off to `spec.verify`.

### Added

- **`spec.verify` command added**: the Agentic SDLC preset now ships `adlc.spec.verify` / `spec.verify`, which produces a feature-local verification dossier at `specs/{branch}/evidence.md` organized around the approved Mission Brief (Goal, Success Criteria, Constraints).
- **`spec.trace` command added**: the Agentic SDLC preset now owns feature execution trace generation through `adlc.spec.trace` / `spec.trace`, while keeping the artifact path at `specs/{branch}/trace.md`.
- **Evals extension smoke coverage**: added bash smoke tests and PowerShell CI-gated smoke tests for the public evals lifecycle.

# [0.10.0+adlc5] - 2026-06-08

### Added

- **Git extension custom branch templates with Jira issue keys**: the bundled `git` extension now supports configurable `branch_pattern` templates with placeholders like `{prefix}`, `{number}`, `{timestamp}`, `{issue}`, and `{slug}`. Jira-style issue keys are accepted from `--issue` / `-Issue` or `GIT_BRANCH_ISSUE` and normalized to uppercase during branch generation.

### Changed

- **CLI bumped to `0.10.0+adlc5`**: this fork release captures the shipped git extension behavior, documentation updates, and new installed-extension end-to-end coverage.
- **Git extension bumped to 1.5.0**: the bundled `git` extension version now reflects configurable Jira-aware feature branch patterns and matching validation logic.
- **LevelUp extension bumped to 1.7.1**: moved feature trace command ownership from `levelup.trace` to `spec.trace`, keeping `specs/{branch}/trace.md` as the feature-local artifact while preserving LevelUp trace consumption via `levelup.specify`.
- **Agentic SDLC preset bumped to 1.0.8**: added the new `adlc.spec.trace` / `spec.trace` command to the preset command surface and updated core workflow guidance to reference the spec-owned trace command.
- **`spec.verify` command added**: the Agentic SDLC preset now ships `adlc.spec.verify` / `spec.verify`, which produces a feature-local verification dossier at `specs/{branch}/evidence.md` organized around the approved Mission Brief (Goal, Success Criteria, Constraints).
- **`/spec.specify` issue-template contract clarified**: the core and ADLC `specify` command guidance now requires resolving and passing an issue key before executing deferred `git.feature` hooks when the active `branch_pattern.template` contains `{issue}`. This closes the end-to-end gap where hook-driven branch creation could fail even though the underlying git extension scripts already supported `GIT_BRANCH_ISSUE` / `--issue` / `-Issue`.

# [0.10.0+adlc4] - 2026-06-08

### Fixed

- **PowerShell worktree merge test pathing**: `tests/extensions/git/test_merge_task_branch.py` now runs the PowerShell `merge-task-branch` test from the primary checkout script path while keeping the working directory inside the feature worktree. This matches the real execution model and fixes CI failures where the test incorrectly looked for `worktree-utils.ps1` under `.worktrees/<feature>/.specify/...`.

# [0.10.0+adlc3] - 2026-06-08

### Added

- **Real async/[P] execution backend**: the Spec-Driven Development workflow now has script-backed orchestration for both branch-mode sequential execution and worktree-mode wave-based parallel execution.
- **``tasks-meta-utils.sh`` real CLI**: added ``init``, ``add-task``, ``start-task``, ``complete-task``, ``fail-task``, ``review-micro``, ``quality-gate``, ``summary``, ``dispatch-async``, and ``check-status`` subcommands. Async delegation state is now feature-scoped under ``<feature_dir>/.async_state/`` instead of global repo-relative directories.
- **``tasks-meta-utils.ps1`` PowerShell parity**: full PowerShell counterpart with identical CLI surface and feature-scoped async state.
- **``worktree-utils.sh`` merge-task-branch**: new subcommand that merges a completed task branch back into the feature branch with ``--no-ff``, reports conflicts in machine-readable JSON, and cleans up the manifest.
- **``worktree-utils.ps1`` merge-task-branch parity**: PowerShell counterpart with ``-DelegateConflicts`` flag.
- **``implement.sh`` real executor**: branch-mode sequential execution with [SYNC]/[ASYNC] honor, metadata updates, and tasks.md checkbox marking; worktree-mode wave scheduling with DAG consumption.
- **``implement.ps1`` PowerShell parity**: full PowerShell executor with identical branch/worktree mode support.
- **Explicit [SYNC]/[ASYNC] marker parsing**: ``tasks-dag.{sh,ps1}`` now parses explicit ``[SYNC]`` / ``[ASYNC]`` markers from task lines and trusts them over heuristic classification. Both bash and PowerShell DAG generators updated.
- **Delegation template**: added ``templates/delegation-template.md`` as the default template for async task delegation prompts.
- **Git extension bumped to 1.4.0**: the bundled ``git`` extension version now reflects the new async execution backend, explicit mode parsing, and task-merge script support without changing the CLI's upstream base version.

### Changed

- **``tasks-dag.sh`` task record format**: internal record format expanded from ``id|story|par|desc`` to ``id|story|par|exec_mode|desc`` to carry explicit execution mode through the pipeline.
- **``tasks-dag.ps1`` task record format**: same 5-field expansion for PowerShell parity.
- **``_classify_execution_mode`` contract**: bash function now accepts an optional explicit mode as the first positional argument and returns it verbatim when non-empty, falling back to heuristics only when absent.

### Fixed

- **Prompt/code mismatch for tasks-meta-utils**: the ADLC preset ``adlc.spec.tasks.md`` and ``adlc.spec.implement.md`` previously referenced CLI subcommands (``init``, ``add-task``, ``review-micro``, ``quality-gate``) that did not exist in ``tasks-meta-utils.sh``. All referenced subcommands now have real implementations.
- **Prompt/code mismatch for git.task-merge**: ``speckit.git.task-merge.md`` described a merge workflow that was not backed by a script subcommand. The ``merge-task-branch`` subcommand now provides the full merge + cleanup flow.

# [0.10.0+adlc2] - 2026-06-08

### Added

- **Hook command id normalization**: ``.specify/extensions.yml`` now stores alias-normalized hook command ids. After bundled presets install aliases (e.g. ``speckit.plan`` → ``spec.plan``), a post-init pass rewrites stored hook ``command`` fields to their alias form so that skill-based agents see command ids that line up with on-disk skill directory names.
- **Fork helpers for hook normalization**: ``_core_fork.py`` adds ``normalize_hook_command_id()``, ``normalize_hook_config_commands()``, and ``normalize_stored_hook_commands()`` for idempotent alias-aware hook config rewriting.

### Changed

- **``_skill_name_from_command`` delegates to shared fork logic**: ``HookExecutor._skill_name_from_command()`` now uses ``compute_skill_output_name()`` from ``_core_fork.py`` instead of inline alias logic. This correctly handles both canonical form (``speckit.git.commit``) and alias form (``git.commit``) command ids, keeping skill naming consistent with installed skill directories regardless of how the command id is stored.

### Fixed

- **Skill-based hook invocation for aliased commands**: when hook config stores alias form (e.g. ``spec.plan``), skill-based agents (Codex, Claude skills mode, Kimi, Cursor skills mode) now receive the correct skill invocation (``$spec-plan``, ``/spec-plan``, ``/skill:spec-plan``, ``/spec-plan``) instead of an empty skill name.

# [0.10.0+adlc1] - 2026-06-07

### Changed

- **Upstream merge**: Synced with `github/spec-kit` `main` through the upstream `0.10.0` init-flow breaking change, bringing in the bundled `bug` triage extension, private-repo preset/workflow release-asset download hardening, workflow gate prompt rendering improvements, and the upstream `0.9.6.dev0` baseline updates.
- **Init CLI alignment**: the fork now follows upstream by removing legacy `--ai`, `--ai-commands-dir`, and `--ai-skills` flags from `specify init`, while preserving fork theming, alias-aware command guidance, team-directives hooks, and fork package identity.

### Fixed

- **Fork merge preservation**: retained fork-specific `spec` command prefix guidance, themed init panels/messages, fork-aware final success handling, and `team_ai_directives` / `context_file` persistence in init options after adopting upstream's simplified integration-only init path.
- **GitHub release asset downloads**: restored the shared `_github_http.py` helper and tests so fork downloads for private or SSO-protected GitHub-hosted presets/workflows/extensions continue to resolve REST asset URLs correctly.

# [0.9.5+adlc2] - 2026-06-07

### Added

- **Git feature worktree isolation**: `git.feature` now supports `--worktree` / `--branch-mode` / `--isolation-mode` flags and `SPECIFY_ISOLATION_MODE` env var to create feature-level worktrees at `.worktrees/<feature>/` instead of normal branches. Worktree mode provisions a `git.worktree-manifest.json` for provenance tracking.
- **DAG task orchestration**: `tasks-dag.{sh,ps1}` generates `tasks_dag.json` from `tasks.md` with wave-based execution ordering. Supports `generate`, `validate`, `show`, `classify`, and `coalesce` subcommands.
- **Task execution commands**: `git.task`, `git.task-merge`, `git.task-list` (worktree-mode only) for isolated task branches, merge with `--no-ff`, and manifest-backed cleanup.
- **Auto-commit task-mode prefixing**: `auto-commit.{sh,ps1}` now accept `--mode <sync|parallel|async>` and `--task-id <TNNN>` for `[TNNN]`-prefixed commit subjects.
- **PowerShell parity**: all new scripts have PowerShell counterparts with single-dash params and BOM-less UTF-8 output.

### Changed

- **Fork module refactor**: split `cli_customization.py` into `_init_fork.py`, `_core_fork.py`, `_extension_fork.py`, `base_fork.py`, and `extensions_fork.py` to reduce merge conflicts and clarify dependency direction.
- **Template wiring**: `templates/commands/implement.md` and `templates/commands/tasks.md` now conditionally detect `isolation_mode` and wire DAG generation / worktree dispatch when in worktree mode, while preserving existing branch-mode behavior.
- **ADLC preset wiring**: `presets/agentic-sdlc/commands/adlc.spec.implement.md` and `adlc.spec.tasks.md` integrate the same conditional worktree + DAG flow.
- **Git extension bumped to 1.3.0**: adds 3 new commands, `isolation_mode`, `worktrees`, `task_execution`, and `task_generation` config sections.
- **Cursor native worktree detection**: `CursorAgentIntegration.detect_native_worktree()` returns `True` so the worktree feature can defer to Cursor's native tooling.

# [0.9.2+adlc4] - 2026-06-03

### Fixed

- **Self-upgrade targets the fork repo**: `specify self check` / `specify self upgrade` / rollback guidance now use `tikalk/agentic-sdlc-spec-kit` release API and git install URLs instead of `github/spec-kit`, so upgrade and recovery instructions stay aligned with the fork's actual release source.
- **Themed root help output**: `specify --help` now shows a fork-themed Rich help panel under the banner, keeping top-level help visually consistent with the orange CLI branding.
- **Post-merge verification cleanup**: updated self-upgrade tests to expect fork URLs, fixed the generic integration quickstart-guide assertion to use the active fork prefix, and resolved targeted Ruff issues in touched repo/test files. Ruff now also excludes intentionally non-Python eval template assets under `extensions/evals/templates/*.py`.

# [0.9.2+adlc3] - 2026-06-03

### Changed

- **Upstream main merge**: Synced with `github/spec-kit` `main` after upstream `0.9.2`, bringing in workflow self-upgrade docs/tests additions and the workflow run-state hardening from `bb2b49d`.

### Fixed

- **Workflow run-state path traversal hardening**: adopted upstream `RunState` validation so `RunState.load()` now rejects malformed `run_id` values before constructing filesystem paths under `.specify/workflows/runs/`, preventing path traversal / file probing via resume IDs. `RunState.__init__()` now treats `run_id=None` as the only auto-generate case and rejects explicit empty-string IDs consistently.
- **Workflow regression coverage**: adopted upstream tests for malformed workflow `run_id` values, covering traversal vectors and ensuring `RunState.__init__()`, `RunState._validate_run_id()`, and `RunState.load()` stay aligned.

# [0.9.2+adlc2] - 2026-06-03

### Fixed

- **Project-scoped alias resolution for skills/hooks**: `HookExecutor._skill_name_from_command()` now accepts `project_root` and resolves aliases against the target project instead of `Path.cwd()`. `HookExecutor._render_hook_invocation()` now passes `self.project_root`, so hook invocations correctly render `spec-plan` / `spec-tasks` inside projects with the `agentic-sdlc` preset installed, while preserving `speckit-*` for commands that intentionally remain upstream-named (`git.*`, `agent-context`, `tasktoissues`) or for clean projects without the preset.
- **Project-scoped alias resolution for generated skill filenames**: `CommandRegistrar._compute_output_name()` now threads `project_root` into `compute_skill_output_name(...)` at registration, alias-registration, and unregister cleanup sites. Generated skill/command output names now depend on the project's installed preset/extension aliases rather than the process working directory.
- **Fork CI regressions in clean checkouts**: restored the correct expectations for commands without fork aliases (`speckit-git-feature`, `speckit-specify`, `speckit-shortcut`) and updated hook-rendering tests to install the bundled `agentic-sdlc` preset before asserting `spec-` output for core commands like `plan` and `tasks`.

# [0.9.2+adlc1] - 2026-06-03

### Changed

- **Upstream merge**: Synced with `github/spec-kit` (base upstream 0.9.2, 14 commits since v0.9.0):
  - `ee17b04` refactor(integrations): co-locate integration command handlers in `integrations/` domain dir — ~1400 lines of CLI handlers moved out of `__init__.py` into `_helpers.py`, `_install_commands.py`, `_migrate_commands.py`, `_query_commands.py`, `_commands.py`; `__init__.py` now calls `register()`. Fork theming (`accent`/`accent_style`) re-applied to the moved `_query_commands.py`, `_install_commands.py`, `_migrate_commands.py`.
  - `d79a514` fix(copilot): remove unsupported `mode:` frontmatter from Copilot skills (issue #2799) — fork adopted upstream removal; `post_process_skill_content` no longer injects `mode:`. Fork's `spec-` invocation-prefix logic preserved.
  - `442a581` fix(cli): pin UTF-8 encoding on init-options and `.extensionignore` I/O.
  - `14da893` fix(copilot): resolve active spec template.
  - `c9c02ae` fix: resolve GitHub release asset API URL for private-repo extension downloads (new `_github_http.py`).
  - `7bab056` feat(workflows): add `continue_on_error` step field for non-halting failures.
  - `39921dd` fix(shared-infra): record skipped files in `speckit.manifest.json`.
  - `39925ac` fix: add agent-context extension entries to Cline `_expected_files`.
  - `a1b8de6` Product Forge extension v1.6.0; `9768b1e` agent parity governance preset catalog; `7c558ab` add `.editorconfig`; `ed10b32` docs: list Hermes.
  - Removed upstream command stubs deleted by the refactor: `commands/{extension,integration,preset,workflow}.py`.

### Fixed

- **Fork prefix adaptation in upstream tests**: new/updated upstream tests hardcoded the `speckit` prefix where the fork emits `spec`. Adapted to fork-aware helpers:
  - `tests/integrations/test_integration_copilot.py::test_specify_agent_resolves_active_spec_template` — use `_cmd_prefix()` for the agent filename.
  - `tests/test_agent_config_consistency.py::test_skills_agent_command_token_resolves_with_hyphen` — corrected skill dir to `git-feature` (extension command, no prefix).
  - `tests/test_extensions.py` (4 tests: codex unregister, kimi/codex hook invocation, init-options cache) — use `HookExecutor._skill_name_from_command()` and the `PKG_NAMES` fork-prefix guard to match `spec-`/`$spec-`/`/skill:spec-` output.

# [0.9.0+adlc5] - 2026-06-03

### Fixed

- **CI: 61 integration test failures from v0.9.0+adlc4 (TestAgyIntegration.test_setup_creates_files and 60 peers)**: `_skill_prefix(command)` and `_skill_dir_name(command)` in `tests/conftest.py` called `resolve_command_alias(...)` without passing `project_root`, defaulting to `Path.cwd()`. Tests that install the bundled preset to `tmp_path` (not cwd) got `"speckit"` prefix when the actual skill directory on disk was `spec-analyze` (etc). Both helpers now accept an optional `project_root` parameter that is forwarded to `resolve_command_alias`; 30+ test call sites updated to pass `project_root=tmp_path` / `project_root=project` / `project_root=home`. Copilot's skills tests (`test_skills_creates_skill_files`, `test_skills_directory_structure`) additionally now call `install_preset_to(tmp_path)` so the alias map can be resolved at the test's project root.
- **Hermes `setup()` production bug**: `resolve_command_alias(f"speckit.{command_name}")` at line 130 was using `Path.cwd()` instead of the `project_root` parameter already in scope, causing Hermes to create `speckit-*` skill directories on CI (fresh checkout without `.specify/` at cwd) instead of `spec-*`. Fixed by passing `project_root`.
- **Test assertions that depend on cwd alias resolution** (copilot `build_command_invocation`, claude `format_hook_message`, forge `format_forge_command_name`, forge extension registrar): these functions use `resolve_command_alias()` without `project_root`, so their output depends on whether `.specify/` exists at `Path.cwd()`. Test assertions were changed to use `_skill_prefix("cmd")` (which also resolves via cwd) or `format_forge_command_name()` directly, ensuring they match the production code in both local dev (cwd has `.specify/`) and CI (cwd is clean) environments.
- **Kimi `test_setup_with_migrate_legacy_option`**: added missing `project_root=tmp_path` to `_skill_prefix('specify')` call so it matches the `setup()` output which uses `project_root=tmp_path`.

### Changed

- **Theming**: wrapped 10 `specify <preset|extension> ...` command-hint strings in `accent()` across `preset_*` and `extension_*` commands in `src/specify_cli/__init__.py` (lines 2683, 2986, 3287, 3440, 3469, 3515, 3598, 3607, 3697, 4299). Two sites with dict-key f-strings (`ext['id']`, `ext_info['id']`) were extracted to local variables first to avoid nested-quote complexity.

# [0.9.0+adlc4] - 2026-06-02

### Fixed

- **CI: 32 remaining integration test failures from v0.9.0+adlc3**:
  - **Root cause**: `build_alias_map()` in `cli_customization.py` was missing `replaces -> aliases[0]` entries, so `resolve_command_alias("speckit.plan")` returned `"speckit.plan"` instead of `"spec.plan"`. This cascaded into 8 `@skip_on_fork` decorators and 21 file-inventory skips.
  - `build_alias_map()` now adds `replaces -> alias[0]` entries in both extension and preset scanning loops.
  - Added `_resync_integration_manifest(project_path, selected_ai)` called at end of `post_init()` to fix file inventory drift from preset installation — drops entries for deleted files, re-hashes changed content (e.g., `.agent.md` overwrites), adds new files discovered in `agent_dir/commands_subdir`.
  - 55 subcommand tests unblocked via per-command `_skill_prefix(command)` conftest helper.
  - 21 file-inventory tests unblocked via `_expected_files(..., project=project)` fork-scan block — dynamically picks up any fork-specific files instead of hardcoding paths.
  - 14 base-skills tests now pre-load bundled presets via new `install_preset_to(tmp_path)` conftest helper.
  - Per-agent fixes: agy, codex, hermes, kimi (use `_skill_prefix`); forge (2 assertions updated to `spec-*` for aliased core commands; extension commands without aliases keep `speckit-*`); copilot (`mode: git-feature` not `git.feature`); cursor_agent and devin (use `_skill_prefix()`).
  - Removed 8 `@skip_on_fork` decorators from `test_integration_subcommand.py` and the now-unused `skip_on_fork` marker from `tests/conftest.py`.

- **PowerShell Unicode→ASCII** (Windows encoding robustness in CI): replaced `→`, `✓`, `⚠` with `->`, `[OK]`, `[!]` in `extensions/git/scripts/powershell/setup-gitignore.ps1` and `workspace-submodules.ps1`.

- **Upstream v0.9.0 script format change**: relaxed `test_check_prerequisites_risks` and `test_setup_plan` assertions to verify presence of expected keys instead of exact payload equality.

# [0.9.0+adlc3] - 2026-06-02

### Fixed

- **Theming consistency**: Fixed 91 hardcoded `[cyan]` instances across all source files to use fork's `accent()`/`accent_style()` helpers
  - `src/specify_cli/__init__.py`: 64 cyan instances replaced with `accent()`/`accent_style()`
  - `src/specify_cli/commands/init.py`: 24 cyan instances replaced with `accent()`/`accent_style()`
  - `src/specify_cli/_console.py`: 4 cyan instances replaced with `ACCENT_STYLE`
  - `src/specify_cli/_utils.py`: 2 cyan instances replaced with `accent()`
  - `src/specify_cli/shared_infra.py`: 2 cyan instances replaced with `accent()`
  - `src/specify_cli/integrations/base.py`: 1 cyan instance replaced with `accent()`
  - `src/specify_cli/integrations/hermes/__init__.py`: 2 lines fixed for fork-aware skill naming and cleanup
  - All CLI output now consistently uses the fork's orange `#f47721` accent color instead of upstream cyan

# [0.9.0+adlc2] - 2026-06-02

### Fixed

- **Fork prefix naming consistency**: Fixed inconsistent `spec-` vs `speckit-` prefixes across all skill/command generation paths
  - Alias-aware rule: commands WITH fork aliases use `spec-` prefix; commands WITHOUT aliases keep upstream `speckit-` prefix
  - Fixed `SkillsIntegration.setup()` to use per-template alias detection
  - Fixed `compute_skill_output_name()` to apply `format_name` for non-skill agents and alias-aware logic for skill agents
  - Fixed `_register_extension_skills()` and `_skill_name_from_command()` in extensions to use alias-aware naming
  - Fixed `agents.py` to skip primary file writes when aliases exist (aliases-only registration for fork)
  - Fixed Cline `format_cline_command_name()` double-prefix bug
  - Fixed duplicate tracker output during init
  - Added `tests/conftest.py` helpers `_cmd_prefix()` / `_skill_prefix()` for fork-aware test assertions
  - Fixed 7 previously-skipped tests with dynamic prefix assertions

# [0.9.0+adlc1] - 2026-06-01

### Changed

- **Upstream merge**: Synced with github/spec-kit (73 commits from v0.8.12 to v0.9.0)
  - **NEW**: Cline integration (autonomous coding agent)
  - **NEW**: Hermes Agent integration (Nous Research)
  - **NEW**: agent-context bundled extension (manages agent context files)
  - **NEW**: `_agent_config.py` module (agent configuration extraction)
  - **NEW**: `_github_http.py` module (shared GitHub HTTP helpers)
  - **NEW**: `commands/` package with init handler extraction from `__init__.py`
  - feat: `SPECKIT_WORKFLOW_RUN_ID` override support
  - feat: `SPECKIT_INTEGRATION_<KEY>_EXECUTABLE` env var for CLI binary override
  - feat: `SPECIFY_<KEY>_EXTRA_ARGS` env var for agent subprocess flags
  - feat: Google Antigravity CLI integration enhancements
  - feat: `{{ context.run_id }}` workflow template variable
  - feat: URL-based extension install confirmation prompt
  - fix: PowerShell 5.1 compatibility (non-ASCII char replacement)
  - fix: Skills directory creation on demand during extension/preset install
  - fix: Shared script command hints for integration separators
  - fix: `__SPECKIT_COMMAND_*__` refs in preset skill rendering
  - fix: while/do-while loop stale iteration-0 step output
  - Multiple community catalog updates

# [0.8.12+adlc39] - 2026-05-30

### Changed

- **Architect extension v2.1.3**: Viewpoint-organized aggregation & Mermaid enforcement
  - **Constraint 8**: AD.md MUST be organized by viewpoint (3.1 Context, 3.2 Functional, etc.), NOT by subsystem
  - **Constraint 9**: All architectural diagrams MUST use Mermaid syntax -- ASCII box-drawing art prohibited
  - Step 3.4 expanded with per-viewpoint aggregation recipe (Context, Functional, Information, Development, Deployment)
  - Phase 2-3 gate now scans for ASCII box-drawing characters and warns
  - Final verification checklist expanded to 10 checks (viewpoint structure + Mermaid compliance)
  - Added validation checklists to `information.md` and `deployment.md` view templates
  - Added Mermaid-only check to `context.md` and `development.md` validation checklists

# [0.8.12+adlc38] - 2026-05-30

### Added

- **Architect extension v2.1.2**: Subsystem view links in AD.md
  - Inline links after each view section when 2+ subsystems detected
  - Single subsystem case: links skipped (unified view sufficient)
  - Missing view handling: subsystems without specific view excluded from links
  - Document hierarchy updated: subsystem views now marked as "Reference" (not "Intermediate")

# [0.8.12+adlc37] - 2026-05-30

### Changed

- **LevelUp extension v1.7.0**: Constitution changes now follow CDR lifecycle
  - **BREAKING**: `/levelup.init` Phase 8 creates Constitution CDRs instead of writing to team-ai-directives
  - Constitution changes require review via `/levelup.clarify` and acceptance before publication
  - `/levelup.implement` handles both Constitution Creation and Amendment CDRs
  - Ensures team review and validation of all constitution changes
  - Added `Constitution Creation` and `Constitution Amendment` CDR types
  - Added Constitution Strategy section to CDR template

# [0.8.12+adlc36] - 2026-05-29

### Added

- **LevelUp extension v1.6.4**: Constitution Generation phase in `/levelup.init`
  - New Phase 8 generates/enhances team constitution from discovered patterns
  - Derives principles from cross-cutting patterns and inconsistencies
  - `--skip-constitution` flag to disable
  - Fixed Pattern Agent input to include `constitution` in `team_directives`

# [0.8.12+adlc35] - 2026-05-29

### Changed

- **LevelUp extension v1.6.3**: Moved `/levelup.repair` command to team-ai-directives extension as `/team.repair`
  - Repair is a team-admin maintenance command, better paired with `/team.verify`
  - `agents-template.md` moved to `extensions/team-ai-directives/templates/`
  - `implement.md` updated to cross-reference template from team-ai-directives extension
- **Team AI Directives extension v1.7.8**: New `/team.repair` command, fixed `/team.skills` broken script path
  - New `setup-team.sh` / `setup-team.ps1` scripts for team-ai-directives path resolution
  - Fixed `team.skills` referencing non-existent script path

### Removed

- **LevelUp orphan scripts**: Deleted `analyze-context.sh` and `analyze-context.ps1` (not referenced by any command)

# [0.8.12+adlc34] - 2026-05-29

### Fixed

- **ADLC preset v1.0.7: Hardened `tasks_meta.json` creation in implement and tasks commands**:
  - `adlc.spec.implement.md`: Added MANDATORY step 2 to run `tasks-meta-utils.sh init` with verification before implementation begins; added per-task metadata update instructions after each task completion; added step 10 completion verification safety net that creates `tasks_meta.json` retroactively if missing
  - `adlc.spec.tasks.md`: Hardened step 2 with MANDATORY marker, code block format, and explicit verification for `tasks_meta.json` creation; reformatted per-task `add-task` call as code block for agent reliability
  - Root cause: AI agents were following prose instructions and skipping the shell script calls that create `tasks_meta.json`, breaking downstream `/spec.trace` and quality gate tracking

- **LevelUp extension: Fixed `common.sh` path resolution in `generate-trace.sh` and `validate-trace.sh`**:
  - Both scripts used `source "$SCRIPT_DIR/common.sh"` which fails because `common.sh` lives in `.specify/scripts/bash/`, not in the extension's script directory
  - Applied project-root-discovery pattern (walk up to `.specify/` or `.git/`) already used by `setup-levelup.sh` and `analyze-context.sh`

# [0.8.12+adlc33] - 2026-05-29

### Removed

- **`specify skill` CLI subcommand removed**: The Skills Package Manager CLI (`specify skill search/install/list/eval/update/remove/sync-team/check-updates/config`) has been removed along with the entire `src/specify_cli/skills/` package (~2048 lines). Team-ai-directives required skills are still auto-installed during `specify init --team-ai-directives`. For browsing and installing additional team skills, use the new `/team.skills` agent command.

### Added

- **`/team.skills` agent command**: New team-ai-directives extension command (`team.skills`) that reads `.skills.json` from the knowledge base, shows available skills grouped by category (required, recommended, internal), and installs selected skills to the agent's skills directory. Team-ai-directives extension v1.7.7.

# [0.8.12+adlc32] - 2026-05-29

### Fixed

- **Team AI Directives skills installation now uses correct directory for each agent type**:
  - For `SkillsIntegration` subclasses (claude, codex, cursor-agent, etc.): skills go to `skills_dest()` which is the same as commands directory since commands ARE skills
  - For `MarkdownIntegration` and other subclasses (opencode, windsurf, qwen, etc.): skills go to `folder + "skills"` per agentskills.io convention
  - Previously, all agents incorrectly used `skills_dest()` which returned commands directory for non-SkillsIntegration agents (e.g., `.opencode/commands/` instead of `.opencode/skills/`)
  - Fix is isolated to `_install_skills_from_path()` in `cli_customization.py` (fork-only code)

# [0.8.12+adlc31] - 2026-05-29

### Changed

- **Team AI Directives extension v1.7.6**: Renamed `{KNOWLEDGE_BASE}` placeholder to `{TEAM_AI_DIRECTIVES}` across all command files (verify.md, discover.md, constitution.md) for consistency with extension naming

# [0.8.12+adlc30] - 2026-05-29

### Changed

- **LevelUp extension: `levelup.skills` renamed to `levelup.skill`, command rewritten**:
  - Renamed command from plural `skills` to singular `skill` to reflect that it builds exactly one skill per invocation
  - Rewrote `commands/skill.md` from 422 lines to ~120 lines: removed verbose phase -1, out-of-scope, role & context, notes, and related commands sections; kept essential flow (setup → build → validate → register)
  - Updated all references across `extension.yml`, `README.md`, `QUICKSTART.md`, `clarify.md`, `implement.md`, `specify.md`, `trace.md`
  - LevelUp extension version bumped to `1.6.2`

# [0.8.12+adlc29] - 2026-05-29

### Changed

- **Team AI Directives extension is now bundled with the CLI**: The extension (`extension.yml` + commands) is now bundled in `extensions/team-ai-directives/` and installed from the CLI package, not from the external repository.
  - Removed all reference extension code (`register_reference_extension`, `copy_reference_extension_commands`, `check_reference_extension_update`, `apply_reference_extension_update`, `resolve_extension_dir`, `get_reference_extension_paths`)
  - The `--team-ai-directives` flag now points to a **knowledge base** (directory with `context_modules/`, `skills/`, `.skills.json`, `CDR.md`) rather than an extension source
  - The bundled extension commands read team content from the knowledge base path stored in `.specify/init-options.json`
  - Extension version bumped to `1.7.5`
  - Preset version bumped to `1.0.6`

# [0.8.12+adlc28] - 2026-05-28

### Fixed

- **Preset hook command resolution**: All 8 preset command files now instruct agents to resolve hook command filenames via the extension's `extension.yml` manifest (`provides.commands[].file`) rather than guessing by appending `.md` to the command name. This fixes hook failures for all extensions using short command filenames (architect, product, levelup, team-ai-directives). Git extension hooks were already working because git uses full command names as filenames.
  - Preset version bumped to `1.0.5`

# [0.8.12+adlc27] - 2026-05-28

### Fixed

- **Reference extension hook resolution**: `register_reference_extension()` now copies command files to `.specify/extensions/<ext>/commands/` so preset hook execution can find them. Previously, reference extensions only registered agent command files but left `.specify/extensions/<ext>/commands/` empty, causing `before_constitution` hooks to fail with "File not found".
  - New helper `copy_reference_extension_commands()` in `cli_customization.py`
  - Called after `register_reference_extension()` in both initial setup (`sync_team_ai_directives`) and updates (`apply_reference_extension_update`)

### Changed

- **Team AI Directives extension v1.7.4**:
  - Command files renamed to align with architect naming convention (`commands/constitution.md`, `commands/discover.md`, etc.)
  - `constitution.md` now dynamically reads `context_modules/constitution.md` instead of hardcoding 12 stale principles
  - `discover.md` replaced non-existent `${SPECIFY_TEAM_DIRECTIVES}` env var with registry-based extension root resolution
  - `verify.md` removed hardcoded principle count; now dynamically checks project constitution alignment

# [0.8.12+adlc26] - 2026-05-28

### Fixed

- **Architect extension v2.1.1**: Hardened `/architect.implement` DAG orchestration
  - Sub-system threshold enforcement: 4–6 MUST ask confirmation; >6 MUST suggest grouping
  - DAG-guarded view generation: views outside sub-system DAG are skipped (prevents orphaned views)
  - Per-view state updates: state.json updated after EACH view, not batched per-subsystem
  - Accepted-only ADR promotion: Proposed/Discovered ADRs no longer promoted to memory
- **AD-template.md**: Fixed constitution link path (`memory/` → `.specify/memory/`)

# [0.8.12+adlc25] - 2026-05-28

### Fixed

- **Hook execution hardening in all preset command files**: Extension hooks were buried after `## User Input` sections, causing agents to skip them and jump straight to the main workflow. Fixed in all 8 `presets/agentic-sdlc/commands/adlc.spec.*.md` files:
  - **Pre-execution hooks moved to absolute top**: Now appear immediately after frontmatter, before `## User Input` (or before `## Mission Brief` in `specify.md`)
  - **Compact imperative format**: Replaced ~25-line verbose instructions with ~12-line numbered steps starting with explicit **STOP** language
  - **Post-execution hooks extracted and standardized**: Removed from inside numbered workflow lists (where they were ignored) into standalone `## Post-Execution Hooks` sections at file end
  - **Broken indentation fixed** in `implement.md`, `plan.md`, and `tasks.md` post-execution blocks
  - Added missing `## Post-Execution Hooks` section to `checklist.md` (was completely absent)

# [0.8.12+adlc24] - 2026-05-28

### Added

- **Reference extension auto-update**: `specify extension update` now detects and applies updates for reference extensions (`source: "reference"`):
  - Detection: Reads local `extension.yml` at the stored `path` and compares version against registry
  - Application: `remove()` old registration + `register_reference_extension()` from local path, preserving original priority
  - Rollback: Existing backup framework handles failures automatically (registry, command files, hooks)
  - All logic lives in `cli_customization.py` (`check_reference_extension_update()`, `apply_reference_extension_update()`) per fork philosophy
  - `__init__.py` gets only 3 minimal call sites with `try/except ImportError` fallbacks

### Tests

- Added 4 tests in `tests/test_team_directives.py`:
  - `test_check_reference_extension_update_success`
  - `test_check_reference_extension_update_no_change`
  - `test_check_reference_extension_update_not_reference`
  - `test_apply_reference_extension_update_success`

# [0.8.12+adlc23] - 2026-05-28

### Fixed

- **Windows test failures**: Replaced f-string JSON construction with `json.dumps()` in `tests/test_team_directives.py` to properly escape Windows paths containing backslashes. This fixes corrupted `.registry` JSON on Windows that caused `resolve_extension_dir()`, `get_reference_extension_paths()`, and `build_alias_map()` to fail.

# [0.8.12+adlc22] - 2026-05-28

### Fixed

- **PresetResolver reference extension path resolution**: `resolve_extension_command_via_manifest()`, `collect_all_layers()`, `_get_source_info()`, and `resolve()` in `presets.py` all hardcoded `self.extensions_dir / ext_id`, breaking reference extensions living outside `.specify/extensions/` (e.g., `./team-ai-directives/`). All four locations now call `resolve_extension_dir()` from `cli_customization.py` with the standard `try/except ImportError` fallback pattern.

### Tests

- Added `test_preset_resolver_finds_reference_extension_commands` in `tests/test_team_directives.py` to verify `PresetResolver` can locate commands in reference extensions via both manifest-based and layer-based resolution.

# [0.8.12+adlc21] - 2026-05-28

### Added

- **Reference extension support**: Extensions registered with `source: reference` and a top-level `path` (e.g., `./team-ai-directives/`) are now fully supported across the CLI:
  - Extension directory resolution (`resolve_extension_dir()` in `cli_customization.py`)
  - Config file loading (`ConfigManager` in `extensions.py`)
  - Command/skill re-registration (`register_enabled_extensions_for_agent()` in `extensions.py`)
  - Script permission setting (`ensure_executable_scripts()` in `__init__.py`)
  - Alias map building (`build_alias_map()` in `cli_customization.py`)
  - All logic centralized in `cli_customization.py` per fork philosophy; upstream files get minimal call-site delegations

### Tests

- Added 4 tests for reference extension path resolution in `tests/test_team_directives.py`

# [0.8.12+adlc20] - 2026-05-26

### Fixed

- **Extension download URL**: Fixed `{{VERSION}}` placeholder not being substituted in extension download URLs
  - The `download_extension` method in `ExtensionCatalog` now replaces `{{VERSION}}` with the actual version (with 'v' prefix)
  - Fixes HTTP 404 errors when updating extensions like `team-ai-directives` that use version placeholders in their download URLs
  - Example: `.../archive/refs/tags/{{VERSION}}.zip` → `.../archive/refs/tags/v1.7.2.zip`

# [0.8.12+adlc18] - 2026-05-23

### Fixed

- **team-ai-directives reference mode**: Extension is now properly registered in `.specify/extensions/.registry` when using `--team-ai-directives` with a local directory path. Previously, the extension was not registered, causing `specify extension list` and `specify extension remove` to not recognize it, and hooks/commands were not registered with AI agents.

# [0.8.12+adlc17] - 2026-05-22

### Added

- **LevelUp extension v1.6.0**: Repair command for index reindexing
  - New `/levelup.repair` command to re-index CDR.md, .skills.json, and AGENTS.md
  - Auto-detects orphan context modules (missing YAML frontmatter)
  - Auto-detects orphan skills (missing .skills.json entries)
  - Auto-generates missing metadata from file content
  - Supports `--dry-run`, `--cdr-only`, `--skills-only`, `--agents-only` flags
  - AGENTS.md validation and auto-repair from template

# [0.8.12+adlc16] - 2026-05-21

### Added

- **LevelUp extension v1.5.0**: LLM-based functional categorization and Tikal template alignment
  - LLM semantic analysis categorizes patterns into 6 functional categories (style-guides, framework, security, testing, devops, data)
  - AGENTS.md auto-creation in team-ai-directives (if missing)
  - CDR.md location moved from `context_modules/` to ROOT
  - New path structure: `rules/{category}/{tech}_{pattern}.md`
  - Confidence scoring with user fallback for ambiguous categorizations

# [0.8.12+adlc14] - 2026-05-19

### Changed

- **Product extension v1.5.6**: In-section diagrams, remove Visual Summary
  - Diagrams embedded directly in their home sections (Overview, Personas, Requirements, Roadmap)
  - Visual Summary section removed -- Section 1 is now Document Information
  - All sections renumbered (old 1-13 -> new 1-12)
  - Visual template files deleted (`templates/visuals/` directory)
  - `user-flows.md` and `state-machine.md` section templates absorbed
  - Step 2.8 (visual generation) and Step 3.2.5 (embed Visual Summary) removed
  - No `.specify/product/visuals/` directory generated

# [0.8.12+adlc13] - 2026-05-19

### Fixed

- **Product extension v1.5.5**: PDR lifecycle management enforcement
  - Step 3.4 hardened with DO NOT SKIP warning and gate failure explanation
  - `pdr_lifecycle` object added to state.json schema (pdrs_promoted, memory_pdr_written, etc.)
  - Final Completion Verification: 7 → 9 checks (self-contained check, memory written check, lifecycle object check)
  - State schema version 1.2.0 with business section slugs in DAG

# [0.8.12+adlc12] - 2026-05-19

### Fixed

- **Product extension v1.5.4**: Self-contained PRD enforcement
  - Step 3.3 structure template updated from stale 1-12 to v1.5.3 numbering with all business sections
  - Embedding Rules rewritten to use in-document anchors (removed contradicting "link to file" instructions)
  - prd-template.md: removed 3 reader-facing `.specify/` references
  - Self-contained cross-reference rules added (PDR as text, visuals as anchors, constitution as text)

# [0.8.12+adlc11] - 2026-05-19

### Added

- **Product extension v1.5.3**: Business stakeholder sections and self-contained PRD
  - **4 new section templates** for business decision-makers:
    - `executive-summary.md` (Section 2.5): One-page business case with ROI and recommendation
    - `market-opportunity.md` (Section 4.5): TAM/SAM/SOM, competitive landscape, ICP, positioning
    - `investment.md` (Section 11.5): Team composition, budget, risk-adjusted ROI, go/no-go criteria
    - `gtm.md` (Section 12.5): Launch phases, pricing tiers, messaging, channel strategy
  - **Business Outcome Metrics** (Section 6.5): Efficiency, quality, and financial metrics
  - **Business Risks** (Section 11.4): Adoption, competitive, and financial risk categories
  - **Financial Metrics** (Section 6.6): Cost per user, ROI, payback period

### Changed

- **Self-Contained PRD Rule**: PRD.md now fully self-contained
  - All Mermaid diagrams embedded inline in Visual Summary (Section 1)
  - No reader-facing links to `.specify/` files
  - Section files remain as build artifacts only
  - Cross-references use in-document anchors
- **DAG expanded**: 11 → 15 sections (4 business sections added to dependency graph)
- **Validation script v1.5.3**: 7 → 9 checks (business sections, self-contained links)
- **Sub-numbering**: Business sections use 2.5, 4.5, 11.5, 12.5 to preserve existing numbering

# [0.8.12+adlc8] - 2026-05-18

### Added

- **Product extension v1.5.0**: Comprehensive Mermaid diagram support
  - **8 diagram types**: Feature hierarchy, user flows, dependencies, cross-area map, roadmap Gantt, impact map, decision flow, state machine
  - **Visual Summary section** in PRD with quick navigation to all diagrams
  - **Separate diagram files** in `visuals/` and `sections/` directories
  - **Cross-feature-area visualization** showing inter-area interactions
  - **Prompt-based MCP/CLI integration** for roadmap sync (GitHub/GitLab/Jira/Linear)
  - **Warning-level validation** (non-blocking) for diagram quality
  - Diagram generation during implement phase
  - Diagram quality checks in analyze command
  
- **New Visual Templates**:
  - `visuals/feature-hierarchy.md`: Product structure tree diagram
  - `visuals/feature-deps.md`: Requirement dependencies with status indicators
  - `visuals/cross-area-map.md`: Inter-feature-area interactions
  - `visuals/roadmap-timeline.md`: Gantt chart with MCP sync instructions
  - `visuals/impact-map.md`: Decision impact mind map
  - `sections/user-flows.md`: Persona journey flowcharts
  - `sections/state-machine.md`: Feature state diagrams
  
- **Template Enhancements**:
  - PRD template: Visual Summary section with diagram links
  - PDR template: Inline decision flow diagram and impact map reference
  - Requirements section: Checkpoint note for cornerstone validation

# [0.8.12+adlc7] - 2026-05-18

### Added

- **Product extension v1.5.0**: Multi-agent feature-area analysis with cross-area pattern detection
  - Three-phase agent pipeline: Discovery → Pattern Analysis → Synthesis
  - Comprehensive feature-area detection (directory + docs + pricing)
  - Cross-feature-area pattern detection (≥2 areas)
  - Inconsistency flagging for clarify resolution
  - State persistence with `--resume` support
  - **Mandatory Requirements checkpoint** in implement (cornerstone section)
  - Pre-flight validation with hard enforcement
  - Placeholder validation per section
  - 7-point final verification checklist
  
- **New Sub-Agent Templates** (Product):
  - `discovery-prompt.md`: Comprehensive scanning (3 sources)
  - `pattern-prompt.md`: Strategic scoring and TPD comparison
  - `synthesis-prompt.md`: Cross-feature-area analysis
  
- **Enhanced PDR Template**:
  - Cross-Feature-Area Metadata section
  - Inconsistency Flags section
  - Team-Product-Directives Comparison

# [0.8.12+adlc6] - 2026-05-18

### Added

- **LevelUp extension v1.4.0**: Multi-agent sub-system analysis with cross-system pattern detection
  - Three-phase agent pipeline: Discovery → Pattern Analysis → Synthesis
  - Sequential sub-agent execution per sub-system
  - Cross-sub-system pattern detection (patterns in ≥50% of sub-systems)
  - Automatic inconsistency detection and CDR generation
  - Team-directives comparison for gap analysis
  - State persistence with checkpoint support (`--resume` flag)
  - Cross-sub-system conflict validation in `/levelup.implement`
  
- **New Sub-Agent Templates**:
  - `discovery-prompt.md`: Scans sub-systems for raw patterns
  - `pattern-prompt.md`: Classifies and scores patterns for reusability  
  - `synthesis-prompt.md`: Performs cross-sub-system analysis
  
- **Enhanced CDR Template**:
  - Cross-System Metadata section (appears_in, cross_system_score, consistency)
  - Cross-System Analysis table per sub-system
  - Team-Directives Comparison section
  - Inconsistency Resolution workflow
  - New "Inconsistency" context type

# [0.8.12+adlc5] - 2026-05-18

### Added

- **LevelUp extension v1.2.0**: Complete rewrite of `/levelup.skills` command following 6 patterns from best practices:
  - Enhanced description with trigger keywords for better AI agent routing
  - Imperative verb instructions throughout
  - Explicit output format specification
  - "Read Existing Skills" phase for pattern matching
  - "Out of Scope" section for clear boundaries
  - Merged templates and condensed to <500 lines (422 lines)

# [0.8.12+adlc2] - 2026-05-16

### Fixed

- **Architect extension command hardening** (v2.0.6):
  - Hardened `/architect.implement` with mandatory constraints to prevent phase skipping:
    - Pre-flight ADR validation (must have "Accepted" status)
    - Phase 2→3 verification gate (all view files must exist on disk)
    - Disk-read enforcement for Phase 3 (no memory shortcuts)
    - Final completion verification (7-point checklist)
  - Hardened `/architect.init` and `/architect.specify`:
    - Enforce correct ADR status ("Discovered"/"Proposed", never "Accepted")
    - Prevent skipping the approval workflow
  - Hardened `/architect.clarify`:
    - Made Phase 5.5 approval gateway explicit
    - Added post-approval verification with status distribution report
  - Enhanced `/architect.analyze`:
    - Added detection for empty/missing view files (catches state.json inconsistency)

# [0.8.8+adlc22] - 2026-05-15

### Fixed

- **Git extension PowerShell common functions** (v1.2.6):
  - Added missing `Find-SpecifyRoot`, `Get-RepoRoot`, and `Has-Git` functions
  - These functions are required by `workspace-submodules.ps1` but were missing
  - Fixed PowerShell compatibility with workspace command

# [0.8.8+adlc21] - 2026-05-15

### Added

- **New command: `speckit.git.setup-ignore`** (Git extension v1.2.5):
  - Configures `.gitignore` with proper rules for Spec Kit projects
  - Manages exclusions (cache, backup, local files) and protections (templates, scripts)
  - Options: `--check`, `--fix` (default), `--dry-run`
  - Aliases: `git.setup-ignore`, `git.ignore`
  - Automatically called by `speckit.git.workspace` before submodule setup
  - Ensures `.specify/` and `.opencode/` directories are properly handled

### Fixed

- **Git extension workspace brownfield workflow** (v1.2.3):
  - Fixed safety check to allow `--force` conversion of tracked child repos
  - When using `--force`, uncommitted changes in child repos are allowed (they'll be converted)
  - Still blocks if there are uncommitted changes outside child repos (safety preserved)
  - Makes brownfield conversion truly automated - no manual pre-work needed

# [0.8.8+adlc18] - 2026-05-15

### Added

- **Git extension workspace command enhancements** (v1.2.2):
  - New `--force` flag for brownfield conversion of already-tracked directories
  - New `--ignore-only` flag to add repos to `.gitignore` instead of submodules
  - Safety check: Aborts if parent working tree has uncommitted changes
  - `--ignore-only` removes from parent index and appends to `.gitignore`
  - Consistent JSON output across all modes with `MODE` and `IGNORED_COUNT` fields

# [0.8.8+adlc17] - 2026-05-15

### Fixed

- **Git extension**: Added missing `find_specify_root()` and `get_repo_root()` functions to `git-common.sh`
  - These functions are required by `workspace-submodules.sh` but were not included in the git extension
  - Functions copied from main `scripts/bash/common.sh`
  - Git extension bumped to v1.2.1

# [0.8.8+adlc16] - 2026-05-15

### Fixed

- **Git extension workspace command**: Corrected script path in `speckit.git.workspace` command
  - Removed non-functional `scripts:` frontmatter section that wasn't resolving correctly
  - Use explicit full paths in command body matching other git extension commands

# [0.8.8+adlc14] - 2026-05-15

### Added

- **Per-task extension hooks**: New `before_task_execute` / `after_task_execute` hook events enable extensions to run before/after each individual task during implementation
  - Git extension registers for both events with `enabled: false` by default (opt-in)
  - `quick.implement` now dispatches these hooks instead of hardcoding `git add/commit`
  - ADLC preset `adlc.spec.implement` also dispatches per-task hooks in its execution loop
  - Any extension can register for per-task hooks (auto-commit, lint, test, etc.)

### Changed

- **BREAKING: `quick.implement` no longer auto-commits by default**: Per-task commits are now opt-in via the git extension's `after_task_execute.enabled` config. To restore previous behavior, set `after_task_execute.enabled: true` in `.specify/extensions/git/git-config.yml`
- Git extension bumped to v1.1.0 with new hook events and config keys
- Quick extension bumped to v1.1.0 with hook-driven per-task architecture

# [0.8.8+adlc13] - 2026-05-11

### Fixed

- **Hook execution in quick.implement template**: Restructured hook instructions in `extensions/quick/commands/implement.md` to use "Pre-Execution Checks" pattern with numbered steps, explicit MUST/CRITICAL language, and visual indicators (🔴 MANDATORY, ⚠️ WARNING)
  - Root cause: Agents were skipping prose hook instructions because they treated them as informational text rather than actionable steps
  - Applied same framing pattern used in preset commands (adlc.spec.*.md) that have better agent compliance
  - Updated both before_hooks and after_hooks sections

### Changed

- **Quick extension**: v1.0.3 → v1.0.4 (hook execution template improvement)

# [Unreleased]

### Added

- **Git extension workspace submodule management**: New `speckit.git.workspace` command for multi-repo workspace coordination
  - Discovers child git repositories at depth 1 from the project root
  - Registers discovered repos as Git submodules for safe git isolation
  - Prevents accidental commits of child repo files into the parent workspace
  - Supports `--dry-run` mode to preview changes
  - Available in both bash and PowerShell scripts
  - Git extension bumped to v1.2.0

- **Quick extension hook support**: `quick.implement` now checks `before_implement` and `after_implement` extension hooks
  - Enables TDD and other extensions to integrate with quick workflow
  - Supports both mandatory (auto-execute) and optional (display) hooks
  - Deadlock-free execution pattern - no EXECUTE_COMMAND + "wait" patterns
  - Maintains quick's session-only philosophy (no file artifacts)

- **TDD extension in-session flow**: `tdd.implement` now detects context and runs appropriate mode
  - Quick mode: Runs entirely in-session when no spec artifacts exist (from `/quick.implement`)
  - Spec mode: Loads state from `increment-state.json` when artifacts present
  - Condensed planning (3 questions vs 5 in full tdd.plan) for quick mode
  - Full RED→GREEN→REFACTOR cycle in both modes
  - State tracked in conversation in quick mode, files in spec mode

- **15 new LLM eval tests**: Comprehensive test coverage for hook support and context detection
  - 7 tests for quick.implement hook execution (mandatory, optional, deadlock prevention)
  - 8 tests for tdd.implement context detection (quick vs spec mode)
  - New graders: `check_quick_implement_hooks`, `check_tdd_in_session_flow`
  - Updated evals README with new test suites

### Fixed

- **Clarify commands now explicitly state questions**: Fixed all clarify commands (spec, product, architect, levelup) to explicitly output the question text before showing recommendations and options, resolving confusion where only options were shown without context.

- **Improved error message for private repository authentication**: `sync_team_ai_directives()` now detects when a downloaded "ZIP" file is actually an HTML authentication page (common with private GitLab repositories)
  - Validates downloaded content starts with ZIP magic bytes (`PK`)
  - Detects HTML content and provides clear error message about authentication requirement
  - Guides users to configure `~/.specify/auth.json` for private repositories
  - Fixes cryptic "File is not a zip file" error when accessing private repos without auth

### Changed

- **Merged upstream/main**: Integrated latest upstream changes (v0.8.8.dev0+)
  - Updated community catalog with latest extension versions
  - Bumped GitHub Actions dependencies:
    - actions/setup-dotnet: 4.3.1 → 5.2.0
    - actions/github-script: 7 → 9
    - DavidAnson/markdownlint-cli2-action (latest)
    - github/codeql-action: 4.35.3 → 4.35.4

- **Refactored team-ai-directives code isolation**: Moved 5 fork-specific functions from `__init__.py` to `cli_customization.py`
  - `sync_team_ai_directives()` - Main installation function for team-ai-directives
  - `_store_extension_source_url()` - Registry metadata storage helper
  - `_derive_target_repo_from_url()` - URL parsing for archive URLs
  - `_register_bundled_catalog()` - Bundled catalog registration
  - `get_team_directives_path()` - Path resolution for team-ai-directives
  - Reduces `__init__.py` by ~220 lines for better code organization
  - Maintains backward compatibility with fallback implementations in ImportError block

# [0.8.7+adlc13] - 2026-05-08

### Fixed

- **Team skills name field now includes prefix**: During installation of team-ai-directives skills, the `name:` field in SKILL.md frontmatter is now updated to include the `team-` prefix
  - This ensures compliance with agentskills.io specification (name field must match parent directory name)
  - Example: skill installed to `team-dbt-template/SKILL.md` now has `name: team-dbt-template` (not `name: dbt-template`)
  - Fixes mismatch between directory name and frontmatter name field

# [0.8.7+adlc12] - 2026-05-08

### Fixed

- **Version bump**: Updated to 0.8.7+adlc12

# [0.8.7+adlc11] - 2026-05-08

### Fixed

- **Extension catalog not bundled in wheel**: Added `extensions/catalog.json` to `pyproject.toml` force-include section
  - The catalog.json file was missing from the Python wheel package, causing a fallback that installed ALL bundled extensions
  - Now properly respects the `preinstall` flags in catalog.json
  - Architect, evals, product, and tdd extensions are correctly excluded from auto-installation

# [0.8.7+adlc10] - 2026-05-08

### Changed

- **Disabled auto-install for selected extensions**: The following extensions are no longer auto-installed during `specify init`:
  - `architect` - Can be installed manually via `specify extension install architect`
  - `evals` - Can be installed manually via `specify extension install evals`
  - `product` - Can be installed manually via `specify extension install product`
  - `tdd` - Can be installed manually via `specify extension install tdd`
  
  Extensions that remain auto-installed:
  - `levelup` - Team AI Directives contributor
  - `quick` - Quick implementation shortcuts

# [0.8.7+adlc9] - 2026-05-08

### Added

- **Command name resolution to aliases**: Template processing now resolves canonical command names to their alias forms
  - `adlc.spec.*` commands display as `spec.*` in templates and AI traces
  - `speckit.git.*` commands display as `git.*` in extension hooks
  - Handoffs section in command files now uses alias forms (e.g., `agent: spec.tasks` not `adlc.spec.tasks`)
  - Extension hook display shows `/git.initialize` instead of `/speckit.git.initialize`

### Fixed

- **`resolve_handoff_agents()`**: Fixed to properly handle YAML list items in handoffs section
  - No longer exits handoffs section prematurely when encountering `- ` list items
  - Correctly processes all handoff entries including their agent references

### Changed

- **`process_template()`**: Now accepts `project_root` parameter and calls `resolve_command_names()`
- **All integration `setup()` methods**: Updated to pass `project_root` to `process_template()`
- **`register_commands()`**: Processes full content (including frontmatter) before parsing to enable resolution
- **Copilot integration**: 
  - `command_filename()` now uses `_get_command_prefix()` for correct prefix (spec vs speckit)
  - `post_process_skill_content()` handles `spec-` prefix for mode field
  - Prompt files use correct prefix

# [0.8.7+adlc8] - 2026-05-07

### Fixed

- **Extended alias-only to speckit.* commands**: Skip primary speckit.* files when aliases exist
  - Git extension commands now only install alias form (`git.feature.md`) without duplicate primary (`speckit.git.feature.md`)
  - Applies to all bundled extensions that have aliases defined
  - Completes the alias-only installation pattern for all command types

# [0.8.7+adlc7] - 2026-05-07

### Fixed

- **Alias-only installation for non-skill agents**: Extended the skip-primary logic to ALL agent types (not just skill agents)
  - Non-skill agents (opencode, cursor, etc.) now only install alias form (`spec.constitution.md`) without duplicate primary (`adlc.spec.constitution.md`)
  - Cleanup function now removes `speckit.*.md` files for non-skill agents when preset declares `replaces`
  - Fixes issue where opencode/cursor showed both `adlc.spec.*` and `spec.*` command files

# [0.8.7+adlc6] - 2026-05-07

### Fixed

- **Unified `spec` command prefix**: Fork now uses consistent `spec` prefix for all agents instead of `speckit`
  - Display shows `/spec-constitution`, `/spec.specify` etc. (skill and non-skill agents)
  - Preset commands use `__SPECKIT_COMMAND_*__` placeholders, resolved dynamically per agent type
  - Handoff agent references resolved automatically for skill vs non-skill agents
  - `_display_cmd()`, `resolve_command_refs()`, `build_command_invocation()` all fork-aware
- **Preset `replaces` field now functional**: Core `speckit-*` skill directories are removed when a preset declares `replaces`
- **Alias-only skill installation**: Fork skill agents only install the `spec-*` alias form (no duplicate `adlc-spec-*` primary)
- **Extension skill naming**: `adlc.*` extension commands create `adlc-*` skill directories (not `speckit-adlc-*`)
- **Placeholder resolution in preset skills**: `_register_skills()` now resolves `__SPECKIT_COMMAND_*__` and handoff agents
- **ARGUMENT_HINTS injection**: Claude skill argument hints now work with fork-prefixed skills (`spec-*`, `adlc-spec-*`)
- **`_skill_names_for_command()`**: Handles all `adlc.*` prefixes (not just `adlc.spec.*`)

### Changed

- Added `COMMAND_PREFIX = "spec"` to `cli_customization.py`
- Replaced 15 hardcoded `/spec.*` references in preset commands with `__SPECKIT_COMMAND_*__` placeholders

# [0.8.7+adlc5] - 2026-05-07

### Fixed

- **Hook execution deadlock**: Replace `EXECUTE_COMMAND` + "wait for the result" pattern with self-executing hook instructions. The old pattern caused non-deterministic agent deadlocks when mandatory hooks were present. Now uses explicit instructions to read and execute the hook command immediately, with graceful fallback on failure.
- **Graceful hook failure**: Mandatory hooks now warn and proceed if the hook command file is not found or execution fails, preventing workflow blockage.

### Changed

- Updated 9 command templates in `templates/commands/` with new hook execution semantics
- Updated 8 preset commands in `presets/agentic-sdlc/commands/` with new hook execution semantics and aligned paths (`{REPO_ROOT}/` prefix removal)
- Updated `format_hook_message()` in `extensions.py` to emit actionable instructions instead of `EXECUTE_COMMAND` tokens
- Updated TDD extension command files with same hook pattern fix
- Added behavioral trace eval for hook deadlock detection

### Added

- **Behavioral eval**: New PromptFoo eval suite (`evals/configs/promptfooconfig-hook.js`) to detect hook deadlock regression
- **Grader**: `check_hook_execution_flow()` in `evals/graders/custom_graders.py` to verify LLM output doesn't contain deadlock signals

# [0.8.7+adlc4] - 2026-05-07

### Fixed

- **CLI Version detection**: Move `get_speckit_version()` to `cli_customization.py` to properly support fork's package name (`agentic-sdlc-specify-cli`)

# [0.8.7+adlc3] - 2026-05-07

### Fixed

- **CLI Version detection**: Fix `get_speckit_version()` to check all package names in `PKG_NAMES` (supports fork's `agentic-sdlc-specify-cli` package name)

# [0.8.7+adlc2] - 2026-05-07

### Fixed

- **Align preset commands with upstream**: Add constitution.md context loading to `adlc.spec.implement.md`
- **Remove taskstoissues from preset**: The taskstoissues command is not part of the core agentic-sdlc preset

# [0.8.7+adlc1] - 2026-05-07

### Changed

- **Upstream merge**: Synced with github/spec-kit main branch (0.8.6 release + 0.8.7.dev0)
  - Add lingma support (lingma CLI integration)
  - Add uv installation guide and inline callouts
  - Add fx-to-dotnet to community extension catalog
  - Default non-interactive init to copilot integration
  - Fix forge integration to use hyphen notation for command refs
  - Add Cost Tracker (cost) community extension
  - Load constitution context in `/speckit.implement` to enforce governance during implementation
  - Improve catalog submission templates and CODEOWNERS
  - Validate URL scheme in build_github_request
  - Add Architecture Guard to community catalog
  - Add multi-model-review extension to community catalog

# [0.8.6+adlc3] - 2026-05-07

### Fixed

- **specify init final messaging**: Move success-message logic into `cli_customization.py` and avoid printing "Project ready." when any init step ends in error.

# [0.8.6+adlc2] - 2026-05-07

### Fixed

- **specify init team-ai-directives reporting**: Prevent `Team AI Directives setup` from being incorrectly marked as "done" when team directives sync fails (e.g. bad ZIP/URL). The init command no longer force-completes this step; the hook now reports accurate status.
- **specify init bundled catalog error visibility**: Stop silently swallowing exceptions when registering the bundled extension catalog; failures now emit a warning.

# [0.8.6+adlc1] - 2026-05-05

### Changed

- **Upstream merge**: Synced with github/spec-kit main branch (0.8.5 release + 0.8.6.dev0)
  - Pin GitHub Actions by SHA for security
  - Fix workflow catalog list to require project context
  - Add agent-parity-governance to community catalog
  - Add Spec2Cloud preset to community catalog
  - Update Ralph Loop to v1.0.2
  - Update security-review and memory-md extensions

# [0.8.5+adlc5] - 2026-05-05

### Fixed

- **Use correct CommandRegistrar for bundled extension registration**: `_install_bundled_extensions()` was calling `manager.register_commands_for_all_agents()` on `ExtensionManager` which doesn't have that method. Changed to use `extensions.CommandRegistrar` which wraps the agents registrar and accepts `ExtensionManifest` objects. The `AttributeError` was silently caught by a broad `except Exception`, causing all extension commands to be skipped.
- **Pass `--force` flag to bundled extension/preset installers**: When reinitializing an existing project with `--force`, bundled extensions and presets were skipped because their version/hash matched the registry. Now `--force` bypasses the version/hash check, ensuring command files are always written to the agent directory.

# [0.8.5+adlc4] - 2026-05-04

### Fixed

- **Remove unnecessary agent directory pre-creation**: Reverted the directory pre-creation added in adlc3 — the integration's `setup()` already creates the correct agent directory before `post_init()` runs. The pre-creation was causing a regression where Copilot `--skills` mode would incorrectly create `.github/agents/` alongside `.github/skills/`.

# [0.8.5+adlc3] - 2026-05-04

### Fixed

- **Pre-create agent directory during init**: Added code in `post_init()` to create the selected agent's directory before installing bundled extensions/presets. This ensures extension commands are properly registered in the agent's command directory during init.

# [0.8.5+adlc2] - 2026-05-04

### Fixed

- **Bundled extension command registration**: Fixed incorrect method call in `_install_bundled_extensions()` that prevented extension commands from being registered during init. Changed from `registrar.register_commands_for_all_agents()` to `manager.register_commands_for_all_agents()` to properly handle ExtensionManifest objects.

# [0.8.5+adlc1] - 2026-05-03

### Changed

- **Upstream merge**: Synced with github/spec-kit main branch
  - Migrated to new integration-based architecture with `INTEGRATION_REGISTRY`
  - Added support for controlled multi-install for safe AI agent integrations
  - Added token-analyzer to community catalog
  - Added git extension default change notice at init time
  - Added Spec2Cloud extension for Azure deployment workflow
  - Added multiple governance extensions (security, cross-platform, architecture, a11y)
  - Fixed migration of extension commands on integration switch
  - Fixed self-referencing step number in validation flow
  - Fixed template override support for tasks-template
  - Added `setup-tasks` script to file inventory tests

### Fixed

- **Restored fork-specific features lost in upstream merge**:
  - Restored `--team-ai-directives` CLI option for specifying custom team directives repository
  - Restored `sync_team_ai_directives()` function for installing/syncing team directives
  - Restored `get_team_directives_path()` function for resolving team directives path
  - Restored `pre_init()` and `post_init()` hook calls in init flow
  - Restored tracker steps: team-directives, extensions, presets
  - Fixed file inventory tests to include fork-specific bundled files instead of skipping

# [0.8.4+adlc7] - 2026-04-30

### Fixed

- **specify command (preset)**: Reverted `__SPECKIT_COMMAND_*__` placeholders to hardcoded `/spec.*` commands
  - Placeholders require upstream `CommandRegistrar` pipeline changes to resolve
  - Hardcoded commands ensure correct user-facing output without unresolved placeholders

# [0.8.4+adlc6] - 2026-04-30

### Changed

- **specify command (preset)**: Aligned Mission Brief with Quick extension pattern
  - Structured collect/display/confirm flow (extract from substantial input, ask 3 questions for minimal)
  - Explicit `(yes / no / adjust)` approval prompt with defined behavior for each response
  - Approved Mission Brief values written into spec header fields
- **specify command (preset)**: Added explicit hook output display (Branch created / Feature #)

### Fixed

- **specify template**: Fixed duplicate step 8 numbering (now correctly 8 and 9)

# [0.8.4+adlc5] - 2026-04-30

### Fixed

- **Critical preset auto-upgrade bug**: Fixed a logic error that prevented presets from being upgraded.
  - The bare `continue` statement in `_scaffold_presets_to_project()` was outside the version check block
  - This caused presets to never be re-scaffolded, even when bundled version > installed version
  - Fixed by removing the bare `continue` and adding `shutil.rmtree()` to properly replace old preset files

# [0.8.4+adlc4] - 2026-04-30

### Added

- **Preset auto-upgrade**: Presets now auto-upgrade when CLI version bumps.
  - Add version comparison at two gates: file scaffolding + registry re-registration
  - Bundled version > installed version triggers re-scaffold/re-register
  - Bundled version <= installed version skips (preserves manual edits)

### Changed

- **constitution command**: Major alignment with templates/commands/constitution.md
  - Output to `.specify/memory/constitution.md` (path consistency)
  - Added full Pre/Post-Execution Checks
  - Added consistency propagation checklist
  - Added Sync Impact Report generation
  - Uses `spec.specify` alias for handoffs

- **Private team-ai-directives support**: Added GitHub token authentication (`GH_TOKEN`/`GITHUB_TOKEN` env vars) to `sync_team_ai_directives()` for downloading from private repositories. Also added better error messages for 401/403/404 HTTP errors.

# [0.8.4+adlc2] - 2026-04-30

### Fixed

- **Private team-ai-directives support**: Added GitHub token authentication (`GH_TOKEN`/`GITHUB_TOKEN` env vars) to `sync_team_ai_directives()` for downloading from private repositories. Also added better error messages for 401/403/404 HTTP errors.

# [0.8.4+adlc1] - 2026-04-30

### Changed

- **Upstream merge**: Synced with github/spec-kit v0.8.3 → v0.8.4.dev0 (4 commits)
  - `da1bf02` feat: add Squad Bridge extension to community catalog (#2417)
  - `7cedd85` chore: release 0.8.3, begin 0.8.4.dev0 development (#2418)
  - `2cb848f` Add Work IQ extension to community catalog (#2415)
  - `237e918` feat(integrations): add Devin for Terminal skills-based integration (#2364)

### Added

- **Devin for Terminal**: New skills-based integration from upstream (`.devin/skills/`)

# [0.8.3+adlc3] - 2026-04-30

### Fixed

- **team-ai-directives resolution**: Added `load_team_directives_config()` function to `scripts/bash/common.sh` to properly resolve team-ai-directives path from init-options.json at runtime (not just during init).
- **Fragile path sourcing in scripts**: Fixed bash and PowerShell scripts in levelup, product, and architect extensions that used fragile relative paths (`../../../../`) to source common.sh. Now uses robust project-root-finding pattern that works regardless of script location.

### Changed

- **levelup**: v1.1.7 → v1.1.8
- **product**: v1.1.10 → v1.1.11
- **architect**: v2.0.3 → v2.0.4

# [0.8.3+adlc2] - 2026-04-29

### Fixed

- **team-ai-directives option**: Fixed `--team-ai-directives` option not being processed during `specify init`. Added persistence to init_opts, the pre_init hook in cli_customization.py now properly handles installation for both local directories (reference mode) and URLs (install mode).

# [0.8.3+adlc1] - 2026-04-29

### Changed

- **Upstream merge**: Synced with github/spec-kit v0.8.2 → v0.8.3.dev0 (22 commits)
  - fix: include --from git+... in upgrade hint to avoid PyPI squat package (#2411)
  - fix: dispatch opencode commands via run (#2410)
  - feat: add catalog discovery CLI commands (#2360)
  - fix(extensions): use explicit UTF-8 encoding when reading manifest YAML (#2370)
  - feat: Speckit preset fiction book v1.7 - Support for RAG (Chroma DB) offline semantic search (#2367)
  - chore: release 0.8.2, begin 0.8.3.dev0 development (#2397)
  - Catalog updates: security review v1.3.0, v-model v0.6.0, threatmodel, isaqb-architecture-governance, m365, MarkItDown

# [0.8.2+adlc3] - 2026-04-29

### Added

- **GitLab authentication support**: Added new `_gitlab_http.py` module for authenticating with GitLab private repositories. Uses `Private-Token` header for API requests and supports both GitHub and GitLab.
- Updated `extensions.py` and `presets.py` to detect GitLab URLs and use appropriate authentication

### Changed

- **GitLab raw URL pattern**: Now uses `/-/raw/main/` path pattern for GitLab raw file access (vs `raw.githubusercontent.com` for GitHub)

# [0.8.2+adlc2] - 2026-04-29

### Added

- **Auto-register bundled catalogs**: When using `--team-ai-directives`, the CLI now automatically registers the extension's bundled catalog (`extensions/catalog.json`) for updates. This enables custom forks to distribute their own extensions seamlessly.
- New helper function `_register_bundled_catalog()` to manage catalog registration in `extension-catalogs.yml`

# [0.8.2+adlc1] - 2026-04-25

### Changed

- **Upstream merge**: Synced with github/spec-kit v0.8.1 → v0.8.2.dev0
  - feat: GitHub token auth for catalog/download requests (new `_github_http.py` module)
  - feat: deprecate `--no-git` flag (gate at v0.10.0)
  - feat: Vibe → SkillsIntegration migration (requires Mistral Vibe v2.0.0+)
  - fix: plan on custom git branches via `feature.json`
  - fix: command references per integration type (dot vs hyphen separator)
  - fix: replace xargs trim with sed for quoted descriptions
  - docs: deprecate `--ai` → `--integration` in documentation

### Fixed

- **Integration options parsing**: Fixed `--integration-options "--skills"` not being parsed before `_install_shared_infra` call, causing incorrect invoke separator for page templates

# [0.8.0+adlc1] - 2026-04-24

### Changed

- **Upstream sync**: Merged upstream v0.8.0 with fork customizations preserved
  - `specify self check` now uses fork's GitHub API (`tikalk/agentic-sdlc-spec-kit`)
  - `specify self upgrade` shows fork's install command
  - Added `FORK_GITHUB_API_LATEST` and `FORK_INSTALL_COMMAND` to `cli_customization.py`

### Fixed

- **_install_shared_infra force parameter**: Added `force` parameter to allow overwriting existing shared files
- **InvalidMetadataError handling**: `_get_installed_version()` now handles `InvalidMetadataError` for corrupted package metadata
- **YAML mapping validation**: `ExtensionManifest._load_yaml()` now properly rejects non-mapping YAML (scalars, lists)

### Added

- **Upstream features from v0.8.0**:
  - `specify self check` command to check for updates
  - `specify self upgrade` stub command
  - New agent integrations and improvements

# [0.5.17] - 2026-04-24

### Changed

- **Aligned preset commands to templates**: All agentic-sdlc preset commands now aligned with template structure
  - plan.md: -118 lines, kept Triage Framework [SYNC]/[ASYNC]
  - analyze.md: -170 lines, kept Auto-Detection Pre/Post-Implementation
  - clarify.md: -141 lines, kept Mission Brief validation
  - checklist.md: -21 lines, kept Path Validation section
  - implement.md: -11 lines, kept Dual Execution Mode
  - specify.md: -73 lines, kept Mission Brief Enforcement

### Added

- **Product extension clarify hooks**: Added `before_clarify` and `after_clarify` hooks
  - Uses existing `adlc.product.link` command for PDR context loading
  - Aligns with architect extension pattern (plan hooks)

### Fixed

- **team-ai-directives override**: `sync_team_ai_directives()` now auto-overrides existing installation
  - Added `force` parameter to allow reinstalling over existing team-ai-directives
  - Matches pre-installed extension behavior (unconditionally overwrites)
  - Removes need to manually run `specify extension remove team-ai-directives` first

# [0.5.15] - 2026-04-23

### Changed

- **Removed TEAM_DIRECTIVES from core scripts**: setup-plan no longer resolves team-ai-directives path
  - Removed `load_team_directives_config()` from common.sh
  - Removed `Load-TeamDirectivesConfig()` from common.ps1
  - setup-plan output no longer includes `TEAM_DIRECTIVES` or `TEAM_AGENTS_MD`
- **Removed team-ai-directives from extensions**: architect and product extensions no longer copy ADRs/PDRs to team-ai-directives
  - ADRs remain in `.specify/drafts/` and `.specify/memory/`
  - PDRs remain in `.specify/drafts/` and `.specify/memory/`
  - AD.md and PRD.md always output to project root

### Fixed

- **Removed ADR from setup-plan scripts**: ADR resolution code removed from bash and PowerShell scripts
- **Removed PDR from setup-plan scripts**: PDR resolution code removed from bash and PowerShell scripts

# [0.5.14] - 2026-04-23

### Fixed

- **setup-plan.sh syntax error**: Fixed broken if/fi structure after upstream alignment
  - Removed context.md and AD.md checks but left orphaned `else` causing syntax errors
  - Scripts now work correctly without context.md and AD.md dependencies

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

## [0.9.5] - 2026-06-05

### Changed

- feat(extensions): add bundled bug triage workflow extension (#2871)
- fix: resolve GitHub release asset API URL for private repo preset and workflow downloads (#2855)
- chore(deps): bump github/gh-aw-actions from 0.77.0 to 0.78.1 (#2860)
- chore(deps): bump actions/checkout from 6.0.2 to 6.0.3 (#2859)
- chore(deps): bump astral-sh/setup-uv from 8.1.0 to 8.2.0 (#2858)
- chore(deps): bump github/codeql-action from 4.36.0 to 4.36.2 (#2857)
- fix(workflows): render gate show_file contents in the interactive prompt (#2810)
- feat: add support for rovodev (#2539)
- chore: release 0.9.4, begin 0.9.5.dev0 development (#2853)

## [0.9.4] - 2026-06-04

### Changed

- feat(workflows): add JSON output for workflow run resume and status (#2814)
- Update workflow-preset community catalog to v1.3.2 (#2841)
- fix: recover active skills registration for extensions (#2803)
- fix(cursor-agent): enable headless CLI dispatch end-to-end (-p --trust --approve-mcps --force + Windows .cmd shim resolution) (#2631)
- Update Superpowers Implementation Bridge extension to v1.0.2 (#2852)
- docs(agents): add PR review response guidance to AGENTS.md (#2850)
- Allow `specify workflow run` to execute YAML files without a project (#2825)
- feat(extensions): add --force flag to extension add for overwrite reinstall (#2530)
- chore: release 0.9.3, begin 0.9.4.dev0 development (#2836)

## [0.9.3] - 2026-06-03

### Changed

- fix: render script command hints with active agent separator (#2649)
- chore(tests): fix ruff lint violations in tests/ (#2827)
- fix(workflows): validate run_id in RunState.load before touching the … (#2813)
- feat(cli): implement specify self upgrade (#2475)
- feat(workflows): allow resume to accept updated workflow inputs (#2815)
- catalog: rename "superpowers-bridge" to "superspec" (v1.0.1) (#2772)
- fix(cli): force UTF-8 stdout/stderr on Windows to prevent UnicodeEncodeError (#2817)
- fix(plan): clarify quickstart validation guide scope (#2805)
- chore: release 0.9.2, begin 0.9.3.dev0 development (#2823)

## [0.9.2] - 2026-06-02

### Changed

- Update agent parity governance preset catalog entry (#2777)
- fix: resolve GitHub release asset API URL for private repo extension downloads (#2792)
- fix: remove unsupported mode: frontmatter from Copilot skills mode (fixes #2799) (#2819)
- refactor(integrations): co-locate integration commands in integrations/ domain dir (PR-5/8) (#2720)
- Update Product Forge extension to v1.6.0 (#2820)
- feat(workflows): add continue_on_error step field for non-halting failures (#2663)
- chore: add .editorconfig for consistent code formatting (#2366)
- fix(shared-infra): record skipped files in speckit.manifest.json (#2483)
- chore: release 0.9.1, begin 0.9.2.dev0 development (#2818)

## [0.9.1] - 2026-06-02

### Changed

- fix(cli): pin UTF-8 encoding on init-options and .extensionignore I/O (#2686)
- docs: list Hermes in supported integrations table (#2768)
- fix(copilot): resolve active spec template (#2765)
- fix: add missing agent-context extension entries to Cline _expected_files (#2797)
- Add spec-kit-linear extension to community catalog (#2795)
- feat: add native Cline integration (#2508)
- Update workflow-preset community catalog entry (#2756)
- chore: release 0.9.0, begin 0.9.1.dev0 development (#2794)
- Add RAG Azure Builder extension to community catalog (#2793)

## [0.9.0] - 2026-06-01

### Changed

- chore: recompile workflow lock files (#2774)
- Add Multi-Sites Spec Kit extension to community catalog (#2791)
- Update Product Spec Extension to v0.8.3 (#2790)
- Publish May 2026 Newsletter (#2787)
- fix: move URL install confirmation prompt before spinner (#2783) (#2784)
- Update Reqnroll BDD extension to v1.1.0 (#2775)
- Extract agent context updates into bundled agent-context extension (#2546)
- chore(deps): bump actions/setup-dotnet from 5.2.0 to 5.3.0 (#2755)
- chore: release 0.8.18, begin 0.8.19.dev0 development (#2766)

## [0.8.18] - 2026-05-29

### Changed

- Add support for SPECKIT_WORKFLOW_RUN_ID override (#2742)
- feat: support SPECKIT_INTEGRATION_<KEY>_EXECUTABLE env var (#2743)
- chore(deps): bump github/gh-aw-actions from 0.74.8 to 0.77.0 (#2754)
- chore(deps): bump github/codeql-action from 4.35.5 to 4.36.0 (#2753)
- fix: disable no-op issue reporting for catalog submission workflows (#2748)
- Add confirmation prompt for URL-based extension installs (#2745)
- fix: restrict community submission workflows to labeled event only (#2741)
- feat(integrations): support SPECIFY_<KEY>_EXTRA_ARGS env var for agent subprocess flags (#2596)
- chore: release 0.8.17, begin 0.8.18.dev0 development (#2737)

## [0.8.17] - 2026-05-28

### Changed

- docs: consolidate Community sections in README (#2736)
- Fix shared script command hints for integration separators (#2627)
- docs: update security-governance preset to v0.4.0 (#2703)
- feat(agy): enhance Google Antigravity CLI integration (#2689)
- Fix --dev extension agent symlinks (#2554)
- Share skills hook note post-processing (#2679)
- feat: add Hermes Agent integration (with review fixes) (#2651)
- Update Superpowers Implementation Bridge to v0.7.0 (#2732)
- chore: release 0.8.16, begin 0.8.17.dev0 development (#2729)

## [0.8.16] - 2026-05-27

### Changed

- docs: update landing page stats and branch naming convention (#2727)
- feat(workflows): expose {{ context.run_id }} template variable (#2664)
- fix: resolve __SPECKIT_COMMAND_*__ refs in preset skill rendering (#2717) (#2718)
- Add Workflow Preset to community catalog (#2725)
- fix: paths-only skips branch validation, setup-plan preserves existing plan (#2672)
- docs: fix broken pipx homepage URLs to point to pipx.pypa.io (#2670)
- Update Architecture Guard extension to v1.8.9 (#2723)
- Re-validate spec quality checklist after clarify updates spec (#2715)
- chore: release 0.8.15, begin 0.8.16.dev0 development (#2722)

## [0.8.15] - 2026-05-27

### Changed

- Update Fiction Book Writing preset to v1.8.1 (#2714)
- chore: update memorylint and superb to 1.4.0 (#2690)
- fix: promote post-execution hook dispatch to H2 with directive language (#2713)
- Add Token Budget extension to community catalog (#2712)
- fix: create skills directory on demand during extension/preset install (#2711)
- fix: PS 5.1 compat — replace non-ASCII chars in shipped PowerShell scripts (#2709)
- docs: update security-governance preset to v0.3.0 (#2676)
- Update README.md (#2675)
- chore: release 0.8.14, begin 0.8.15.dev0 development (#2706)

## [0.8.14] - 2026-05-26

### Changed

- Add util for windows sub-process (#2598)
- refactor: create commands/ package and move init handler (PR-4/8) (#2615)
- Add Product Spec Extension to community catalog (#2705)
- fix init-options speckit version refresh (#2647)
- chore(deps): bump github/gh-aw-actions from 0.74.8 to 0.74.9 (#2658)
- docs: add branch naming convention to AGENTS.md and CONTRIBUTING.md (#2678)
- chore(deps): bump actions/stale from 10.2.0 to 10.3.0 (#2657)
- chore(deps): bump github/codeql-action from 4.35.4 to 4.35.5 (#2656)
- chore: release 0.8.13, begin 0.8.14.dev0 development (#2669)

## [0.8.13] - 2026-05-21

### Changed

- fix: while/do-while loop condition reads stale iteration-0 step output (#2662)
- docs: fix directory hierarchy in README examples (#2639)
- fix(catalogs): reject boolean priority in extension and preset catalog readers (#2589)
- Update Agent Governance extension to v1.2.0 (#2659)
- Add agentic workflows for community catalog submissions (#2655)
- feat: add self-check tip to check output (#2574)
- fix(cli): clarify exception diagnostics (#2602)
- ci: add diff whitespace check (#2572)
- chore: release 0.8.12, begin 0.8.13.dev0 development (#2648)

## [0.8.12] - 2026-05-20

### Changed

- fix(codex): inject dot-to-hyphen hook command note in Codex skills (#2503)
- Update Squad Bridge extension to v1.3.0 (#2645)
- Update Superpowers Implementation Bridge extension to v0.5.0 (#2644)
- Add Team Assign extension to community catalog (#2642)
- refactor: migrate extension catalog stack parsing to shared base (#2576)
- Update Architecture Workflow extension to v1.1.0 (#2588)
-  fix(workflow): support integration: auto to follow project's initialized AI (#2421)
- Add Superpowers Implementation Bridge extension to community catalog (#2586)
- Add Interactive HTML Preview extension to community catalog (#2585)
- chore: release 0.8.11, begin 0.8.12.dev0 development (#2584)
- Update Agent Governance extension to v1.1.0 (#2583)

## [0.8.11] - 2026-05-15

### Changed

- refactor: extract _version.py from __init__.py (PR-3/8) (#2550)
- Add Time Machine extension to community catalog (#2580)
- fix(powershell): ensure UTF-8 templates are written without BOM (#2280)
- docs: document high-assurance spec workflow (#2518)
- docs: fix script name in directory tree examples (#2555)
- Fix preset skill description precedence (#2538)
- fix(integration): clarify multi-install guidance (#2549)
- feat: add version feature reporting (#2548)
- Add Architecture Workflow extension to community catalog (#2565)
- chore: release 0.8.10, begin 0.8.11.dev0 development (#2562)

## [0.8.10] - 2026-05-14

### Changed

- docs: streamline install section and add community overview (#2561)
- Move community extensions table from README to docs site (#2560)
- Add Agent Governance extension to community catalog (#2559)
- Add Reqnroll BDD extension to community catalog (#2545)
- fix(cli): harden extension registration and discovery workflows (#2499)
- refactor: extract _assets.py and _utils.py from __init__.py (PR-2/8) (#2543)
- fix(opencode): use commands/ directory (plural) to match OpenCode docs (#2453)
- refactor: extract _console.py from __init__.py (PR-1/8) (#2474)
- Fix constitution reference in README (#2491)
- chore: release 0.8.9, begin 0.8.10.dev0 development (#2532)

## [0.8.9] - 2026-05-12

### Changed

- docs: revamp landing page with four-pillar card layout (#2531)
- feat(extensions): update governance ecosystem extensions to latest versions (#2514)
- Add changelog extension (#2177)
- Add install directory to docfx.json file references (#2522)
- feat(catalog): add BrownKit (brownkit) community extension (#2510) (#2520)
- fix(kiro-cli): replace literal $ARGUMENTS with prose fallback (#2482)
- Preset: Add game-narrative-writing  preset to community catalog (#2454)
- docs: clarify CLI upgrade discovery (#2519)
- fix: make template metadata line breaks markdownlint-safe (#2505)
- refactor(catalogs): extract integration catalog config loading (#2497)
- test(presets): silence expected UserWarnings in self-test composition… (#2373)
- chore: release 0.8.8, begin 0.8.9.dev0 development (#2516)

## [0.8.8] - 2026-05-11

### Changed

- chore(deps): bump actions/checkout from 4.3.1 to 6.0.2 (#2486)
- feat(catalog): add Spec Kit Schedule (schedule) community extension (#2473)
- fix(integration): refresh shared infra on `integration switch` (#2375)
- Add MDE preset to community catalog (#2513)
- Add MDE extension to community catalog (#2512)
- chore: update community catalog with latest extension versions (#2490)
- chore(deps): bump actions/setup-dotnet from 4.3.1 to 5.2.0 (#2489)
- chore(deps): bump actions/github-script from 7 to 9 (#2488)
- chore(deps): bump DavidAnson/markdownlint-cli2-action (#2487)
- chore(deps): bump github/codeql-action from 4.35.3 to 4.35.4 (#2485)
- feat(catalog): add API Evolve (api-evolve) community extension (#2479)
- feat: Config-driven opt-in authentication registry with multi-platform support (#2393)
- chore: release 0.8.7, begin 0.8.8.dev0 development (#2480)

## [0.8.7] - 2026-05-07

### Changed

- feat: add agent-orchestrator to community extension catalog (#2236)
- chore: update extension versions in community catalog (#2468)
- fix(goose): Declare args parameter in generated recipes (#2402)
- feat: Add lingma support (#2348)
- docs: Add uv installation guide and inline callouts (#2465)
- Add fx-to-dotnet to community extension catalog (#2471)
- fix: default non-interactive init to copilot integration (#2414)
- fix(forge): use hyphen notation for command refs in Forge integration (#2462)
- feat(catalog): add Cost Tracker (cost) community extension (#2448)
- chore: release 0.8.6, begin 0.8.7.dev0 development (#2463)

## [0.8.6] - 2026-05-06

### Changed

- Load constitution context in `/speckit.implement` to enforce governance during implementation (#2460)
- feat: improve catalog submission templates and CODEOWNERS (#2401)
- fix: validate URL scheme in build_github_request (#2449)
- Add Architecture Guard to community catalog (#2430)
- Add multi-model-review extension to community catalog (#2446)
- Update Ralph Loop to v1.0.2 (#2435)
- Pin GitHub Actions by SHA (#2441)
- fix(workflows): require project for catalog list (#2436)
- Add agent-parity-governance to community catalog (#2382)
- chore: release 0.8.5, begin 0.8.6.dev0 development (#2447)

## [0.8.5] - 2026-05-04

### Changed

- feat(presets): add Spec2Cloud preset for Azure deployment workflow (#2413)
- update security-review and memory-md extensions to latest versions (#2445)
- fix: honor template overrides for tasks-template (#2278) (#2292)
- Add token-analyzer to community catalog (#2433)
- docs: add April 2026 newsletter (#2434)
- feat: emit init-time notice for git extension default change (#2165) (#2432)
- Update DyanGalih(Memory Hub and Security Review) community extensions (#2429)
- Support controlled multi-install for safe AI agent integrations (#2389)
- chore(integrations): clean up docs and project guard (#2428)
- chore: release 0.8.4, begin 0.8.5.dev0 development (#2431)

## [0.8.4] - 2026-05-01

### Changed

- fix(specify): correct self-referencing step number in validation flow (#2152)
- chore(deps): bump DavidAnson/markdownlint-cli2-action (#2425)
- Add security-governance to community catalog (#2386)
- Add cross-platform-governance to community catalog (#2384)
- Add architecture-governance to community catalog (#2383)
- Add a11y-governance to community catalog (#2381)
- feat(extensions): add Spec2Cloud extension for Azure deployment workflow (#2412)
- fix: migrate extension commands on integration switch (#2404)
- feat: add Squad Bridge extension to community catalog (#2417)
- chore: release 0.8.3, begin 0.8.4.dev0 development (#2418)

## [0.8.3] - 2026-04-29

### Changed

- Add Work IQ extension to community catalog (#2415)
- feat(integrations): add Devin for Terminal skills-based integration (#2364)
- fix: include --from git+... in upgrade hint to avoid PyPI squat package (#2411)
- fix: dispatch opencode commands via run (#2410)
- feat: add catalog discovery CLI commands (#2360)
- update security review extension catalog to v1.3.0 (#2374)
- chore(catalog): bump v-model extension to v0.6.0 (#2399)
- feat: add threatmodel extension to community catalog (#2369)
- Add isaqb-architecture-governance to community catalog (#2385)
- chore: release 0.8.2, begin 0.8.3.dev0 development (#2397)

## [0.8.2] - 2026-04-28

### Changed

- Add MarkItDown Document Converter extension to community catalog (#2390)
- feat: Speckit preset fiction book v1.7 - Support for RAG (Chroma DB) offline semantic search (#2367)
- fix(extensions): use explicit UTF-8 encoding when reading manifest YAML (#2370)
- catalog: add m365 community extension
- docs: replace deprecated --ai flag with --integration in all documentation (#2359)
- feat(extensions,presets): authenticate GitHub-hosted catalog and download requests with GITHUB_TOKEN/GH_TOKEN (#2331)
- Update extensify to v1.1.0 in community catalog (#2337)
- feat(init): deprecate --no-git flag, gate deprecations at v0.10.0 (#2357)
- Add Spec Orchestrator extension to community catalog (#2350)
- chore: release 0.8.1, begin 0.8.2.dev0 development (#2356)

## [0.8.1] - 2026-04-24

### Changed

- fix(plan): use .specify/feature.json to allow /speckit.plan on custom git branches (#2305) (#2349)
- feat(vibe): migrate to SkillsIntegration from the old prompts-based MarkdownIntegration (#2336)
- docs: move community presets table to docs site, add missing entries (#2341)
- docs(presets): add lean preset README and enrich catalog metadata (#2340)
- fix: resolve command references per integration type (dot vs hyphen) (#2354)
- Update product-forge to v1.5.1 in community catalog (#2352)
- chore(deps): bump astral-sh/setup-uv from 8.0.0 to 8.1.0 (#2345)
- fix: replace xargs trim with sed to handle quotes in descriptions (#2351)
- feat: register jira preset in community catalog (#2224)
- feat: Preset screenwriting (#2332)
- chore: release 0.8.0, begin 0.8.1.dev0 development (#2333)

## [0.8.0] - 2026-04-23

### Changed

- feat(presets): Composition strategies (prepend, append, wrap) for templates, commands, and scripts (#2133)
- feat(copilot): support `--integration-options="--skills"` for skills-based scaffolding (#2324)
- docs(install): add pipx as alternative installation method (#2288)
- Add Memory MD community extension (#2327)
- Update version-guard to v1.2.0 (#2321)
- fix: `--force` now overwrites shared infra files during init and upgrade (#2320)
- chore: release 0.7.5, begin 0.7.6.dev0 development (#2322)

## [0.7.5] - 2026-04-22

### Changed

- fix: resolve skill placeholders for all SKILL.md agents, not just codex/kimi (#2313)
- feat(cli): add specify self check and self upgrade stub (#2316)
- Update version-guard to v1.1.0 (#2318)
- docs: move community presets from README to docs/community (#2314)
- catalog: add wireframe extension (v0.1.1) (#2262)
- Move community walkthroughs from README to docs/community (#2312)
- docs(readme): list red-team in community-extensions table (#2311)
- feat(catalog): add red-team extension to community catalog (#2306)
- Add superpowers-bridge community extension (#2309)
- feat: implement preset wrap strategy (#2189)
- fix(agents): block directory traversal in command write paths (#2229) (#2296)
- chore: release 0.7.4, begin 0.7.5.dev0 development (#2299)

## [0.7.4] - 2026-04-21

### Changed

- fix(copilot): use --yolo to grant all permissions in non-interactive mode (#2298)
- feat: add CITATION.cff and .zenodo.json for academic citation support (#2291)
- Add spec-validate to community catalog (#2274)
- feat: register Ripple in community catalog (#2272)
- Add version-guard to community catalog (#2286)
- Add spec-reference-loader to community catalog (#2285)
- Add memory-loader to community catalog (#2284)
- fix(integrations): strip UTF-8 BOM when reading agent context files (#2283)
- Preset fiction book writing1.6 (#2270)
- fix(integrations): migrate Antigravity (agy) layout to .agents/ and deprecate --skills (#2276)
- chore: release 0.7.3, begin 0.7.4.dev0 development (#2263)

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
