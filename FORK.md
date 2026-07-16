# Fork Maintenance Guide

This document describes how the tikalk fork (`tikalk/agentic-sdlc-spec-kit`) maintains customizations while staying synced with upstream `github/spec-kit`.

## Philosophy

The fork isolates customizations into a small set of focused modules under `src/specify_cli/` to minimize merge conflicts. When syncing with upstream:

1. The import block in `__init__.py` may conflict
2. All customization logic lives in the `_*_fork.py` modules
3. Upstream changes to other parts of `__init__.py` merge cleanly

### Fork module layout

| Module | Purpose | Imports from |
|---|---|---|
| `_assets_fork.py` | Leaf — bundled-asset helpers (`get_bundled_*_version`/`_path`, fork `_locate_bundled_preset`) | `_assets` (clean upstream) |
| `_base_fork.py` | Leaf — fork-level helpers on `IntegrationBase` (e.g. `detect_native_worktree()` worktree-detection shim) | (none) |
| `_core_fork.py` | Leaf — fork-level extension constants (`EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`), alias resolution, MCP config, skill naming, preinstalled extension queries | (none) |
| `_workflows_fork.py` | Leaf — fork-level workflow constants and helpers (workflow catalog/app theming hooks) | (none) |
| `_hooks_fork.py` | Leaf — agent runtime hooks for integrations (HookAdapter ABC + Claude/Cursor/Codex/opencode adapters, bridge script template, JSON/TOML merge, `resolve_hooks`/`collect_extension_runtime_hooks`/`install_integration_hooks`/`remove_integration_hooks`) | (none) |
| `_init_fork.py` | Theming, package identity, init hooks (`pre_init`/`post_init`), scaffolding, skill installation | `_core_fork`, `_assets_fork` |
| `extensions_fork.py` | Constants and schemas for fork-specific extension features (e.g. worktree config) | (none) |

> **Historical note**: the fork previously shipped a `base_fork.py` module. It was renamed to `_base_fork.py` in `0.12.6+adlc1` (commit `d78fe764`) to align with the underscore-prefixed fork-module naming convention. Stale references to `base_fork.py` in older commits and older FORK.md revisions are historical.

> **Consolidation note (`0.11.9+adlc9`)**: The former leaf module `_extension_fork.py` (pure constants) was merged into `_core_fork.py` to simplify the dependency graph from three tiers to two. `_init_fork.py` now imports extension constants from `_core_fork.py` instead of `_extension_fork.py`. The `_extension_fork.py` file was deleted; any stale references to it in older commits are historical.

**Dependency direction (locked):**

```
_assets_fork.py      (leaf)
_base_fork.py        (leaf - IntegrationBase helpers)
_core_fork.py        (leaf - constants + alias/MCP/skill)
_workflows_fork.py   (leaf - workflow constants)
_hooks_fork.py       (leaf - agent runtime hooks)
        ^
        |
_init_fork.py
```

Anything added to a higher-tier module must not be imported by a lower-tier module. This rule prevents circular imports.

## Fork Versioning Scheme

The fork uses a suffix-based versioning system to track both upstream and fork-specific changes:

### Version Format
`<upstream-version>+adlc<N>`

Examples:
- `0.8.2+adlc1` - Fork based on upstream 0.8.2, first fork release
- `0.8.2+adlc2` - Same upstream base, second fork release with new features
- `0.9.0+adlc1` - After upstream merge to 0.9.0, reset fork counter

### When to Bump

| Scenario | Version Change | Example |
|----------|---------------|---------|
| Fork adds new feature | Increment adlc suffix | `0.8.2+adlc1` → `0.8.2+adlc2` |
| Merge upstream release | Update base, reset suffix | `0.8.2+adlc5` → `0.9.0+adlc1` |
| Hotfix/patch | Increment adlc suffix | `0.8.2+adlc1` → `0.8.2+adlc2` |

### Tag Format
Use `agentic-sdlc-v<version>` with plus:
- Version: `0.11.9+adlc4`

- Tag: `agentic-sdlc-v0.11.9+adlc4`
When a fork release changes only bundled extension behavior, keep the CLI version on the upstream base (for example `0.10.0+adlc3`) and bump the affected extension manifest version independently (for example `extensions/git/extension.yml` to `1.5.0`).

### Version History

| Version | Date | Base Upstream | Changes |
|---------|------|---------------|---------|
| 0.12.15+adlc9 | 2026-07-17 | 0.12.15 (`ad601e5d`) | Bug fixes in team-boot and team-discover model-invocation commands: (1) team-boot Step 2 used glob to find constitution — `{TEAM_AI_DIRECTIVES}` was treated as a search target, not a resolved value; added explicit definition after Step 1 and direct-read instruction in Step 2. (2) team-discover Step 2 had no plain-message fallback — expected `{REPO_ROOT}/specs/${SPECIFY_FEATURE}/context.md` which doesn't exist when invoked as a skill from team-boot; added fallback to extract feature context from user's message. (3) team-discover mode detection missing skill-invocation case — all 4 rules depended on `$ARGUMENTS`/env vars/hook context; added rule 5: skill invocation defaults to no-write mode with inline output. (4) team-discover Step 4 didn't surface external skills — `.skills.json` `external` map entries never matched against feature context; expanded matching to cover both `default` and `external` lists with category-based matching. (5) team-discover Step 1 `{TEAM_AI_DIRECTIVES}` undefined — same bare-variable pattern as team-boot; added clarifying note. team-ai-directives extension 4.3.2 → 4.3.3. |
| 0.12.15+adlc8 | 2026-07-17 | 0.12.15 (`ad601e5d`) | Canonical runtime event unification + 4 new hook-capable integrations. Extensions now use unified canonical event names (`PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`) in `runtime_hooks:`; each adapter translates to agent-native names via `CANONICAL_TO_NATIVE` mapping. New adapters: `QwenHookAdapter` (`.qwen/settings.json`), `GeminiHookAdapter` (`.gemini/settings.json`, `BeforeTool`/`AfterTool`), `DevinHookAdapter` (`.devin/hooks.v1.json`), `TabnineHookAdapter` (`.tabnine/agent/settings.json`). `validate_runtime_hooks()` rejects unknown event names. Adapters warn+skip unsupported events. `JSONHookAdapter` refactored with shared `_build_nested_fragment()` + `bridge_path_prefix`. Hook callout added to `TomlIntegration.setup()` + `YamlIntegration.setup()`. `--hooks` option added to gemini/qwen/devin/tabnine. 56 tests (22 new). |
| 0.12.15+adlc7 | 2026-07-16 | 0.12.15 (`ad601e5d`) | Bug fix: team-* model-invocation commands (`team.boot`, `team.discover`, `team.skills`) silently no-op on dotfile paths. Step 1 "Locate Knowledge Base" used ambiguous "Read `.specify/init-options.json`" instruction — agents interpreted as "search first" and used glob/find tools, which silently skip dotfile-prefixed path segments (`.specify/`). team-boot's Step 1 exit handler fired, skipping constitution load and team-discover invocation entirely, leaving the full team-ai-directives knowledge base invisible for the session. Replaced with explicit agent-agnostic instruction: "Read the file directly. Do NOT use glob, find, or any file-search tool." Adds walk-up fallback via successive direct reads (`../.specify/`, `../../.specify/`) for CWD resilience. team-ai-directives extension 4.3.1 → 4.3.2. |
| 0.12.15+adlc6 | 2026-07-16 | 0.12.15 (`ad601e5d`) | Integration runtime hooks: new `_hooks_fork.py` leaf module with `HookAdapter` ABC + Claude/Cursor/Codex/opencode adapters. Extensions can declare `runtime_hooks:` (separate from workflow `hooks:`) in `extension.yml` (validation via fork callout). 4-layer hook resolution: `--hooks` CLI flag → `.specify/integration-hooks.yml` user override → extension-declared runtime_hooks → built-in `config["hooks"]`. Bridge script (`.specify/hooks/bridge.py`) resolves slash commands to underlying scripts via extension registry. opencode adapter generates TS plugin. `IntegrationBase.setup()`/`teardown()` get thin callouts. `stale_cleanup_exclusions()` delegates to fork helper. `ExtensionManifest` accepts `runtime_hooks:` key via fork validation callout. Bug fix: stale events removed on upgrade (remove-before-install). 34 tests in `test_hooks_fork.py`. Docs: EXTENSION-API-REFERENCE, EXTENSION-DEVELOPMENT-GUIDE, integrations/README, AGENTS.md. TDD `runtime_hooks:` example removed (extensions opt in when ready). |
| 0.12.15+adlc2 | 2026-07-15 | 0.12.15 (`ad601e5d`) | Upstream merge (2 commits, post-0.12.15): while/do-while non-list steps guard #3519 (returns FAILED instead of crashing on non-list `steps` on unvalidated run, mirrors if/switch/fan-out pattern); PyPI install docs #3425/#3516 (adopted docs additions, kept fork README install section). 1 conflict resolved: `README.md` (kept fork tikalk install instructions, dropped upstream PyPI block). All other files auto-merged. 613 tests pass. |
| 0.12.15+adlc1 | 2026-07-15 | 0.12.15 (`faeb9566`) | Upstream merge (12 commits, 1 release 0.12.15): git extension Python port #3400 (adopted 4 basic Python scripts: `auto_commit.py`, `create_new_feature_branch.py`, `git_common.py`, `initialize_repo.py`; fork retains enhanced bash/PS1 scripts for fork-only commands; parity tests skipped via `PKG_NAMES` guard); workflow CLI / extension command surface alignment #3419 (atomic install transaction with rollback in `_commands.py`, fork `accent()` theming applied); Goose YAML control-char escaping #3384; env-var config leak fix across prefix-colliding extension IDs #3497; `init-options.json` trailing newline #3509; workflow engine fixes (non-iterable right operand in `in`/`not in` #3447/#3468, malformed catalog URL raises catalog error not raw `ValueError` #3484); community catalog additions (Multi-Repo Branch Sync #3411, PatchWarden Evidence Pack #3514); community catalog updates (DocGuard v0.32.0 #3489, Autonomous Run Governance v0.1.4 #3511). 2 conflicts resolved: `pyproject.toml` (preserved fork metadata, version → `0.12.15+adlc1`), `workflows/_commands.py` (adopted upstream atomic install transaction + fork `accent()` theming). All other files auto-merged cleanly. All tests pass. Smoke test confirms `0.12.15+adlc1`. |
| 0.12.14+adlc1 | 2026-07-14 | 0.12.14 (`654793b6`) | Upstream merge (29 commits, 3 releases 0.12.12–0.12.14): workflow engine hardening (fail-fast on non-list `wait_for` #3482, non-mapping `switch` cases #3481, non-iterable membership #3448, falsy non-list `else` #3264, bool `max_iterations` #3270, mis-shaped catalog #3375, command-step `input`/`options` must be mappings #3262); configurable shell-step timeout consolidation #3327 (replaces fork's simpler #3404 baseline with shared `_timeout_error()` helper used by both `execute()` and `validate()`, returns FAILED instead of silent reset, rejects non-finite floats); adopted upstream `CommandRegistrar.rewrite_extension_paths()` #3444 for extension-relative subdir path rewriting; preset manifest-authoritative template resolution #3351 (`_manifest_declared_template()` helper, no convention fallback when declared file missing); bundle `file://` URL rejection #3344; `set-priority` corrupted bool repair #3268/#3269; prefix-colliding env vars #3350; kiro-cli multi-install safe #3471/#3472/#3485; unbalanced `--integration-options` quote #3457; `init --here` no-TTY #3236 (merged with fork `accent()` theming); constitution sync checklist #3418; agent-file-template cleanup #2579; community catalog additions (Quality Gates #3431, Verify Review Ship #3450, Spec Kit Memory #3455, Test-First Governance #3504, Autonomous Run Governance #3501); docs (bundle `--integration` #3271, copilot skills mode #3313, release tag `v` prefix #3463). 4 conflicts resolved: `pyproject.toml` (preserved fork name/description/httpx/force-include, version → `0.12.14+adlc1`), `commands/init.py` (combined fork `accent()` theming with upstream merge-overwrite warning), `tests/test_presets.py` (kept fork "Speckit " skill-title prefix assertion + adopted upstream subdir-path-rewrite #2101 assertions), `README.md` (kept fork tikalk install instructions + `agentic-sdlc-v*` tag prefix). All other modified files auto-merged cleanly. Accepted legitimate upstream deletions (`workflows/feature-squad.yml`, `tests/test_timestamp_branches.py`, `presets/self-test/templates/agent-file-template.md`); rejected deletion of `workflows/impl-converge-loop/workflow.yml` (fork keeps per `0.12.4+adlc8`). 4335 tests pass. FORK.md module-layout table updated to include `_base_fork.py` and `_workflows_fork.py`; fork-only test inventory refreshed. |
| 0.12.11+adlc3 | 2026-07-13 | 0.12.11 (`1be42992`) | Multi-provider taskstoissues: removed `speckit.taskstoissues` special case from `command_filename()` in `base.py` (file now `spec.taskstoissues.md`). Registered `adlc.spec.taskstoissues` in agentic-sdlc preset (alias `spec.taskstoissues`, replaces `speckit.taskstoissues`). Added `shared_configs_dir()` to `IntegrationBase`; `_install_taskstoissues_config()` in `_init_fork.py` scaffolds `.specify/taskstoissues-provider.yml` from template during init. Added `templates/configs` to wheel force-include. Updated 10 test files (test_base, test_integration_generic, test_integration_base_markdown/yaml/toml, test_integration_forge, test_integration_rovodev, test_extensions, test_presets). Preset command file includes provider dispatch (GitHub/GitLab/Linear/Jira), tool discovery step (MCP/CLI/env), and per-provider pagination guidance. agentic-sdlc preset 1.6.4→1.6.5. |
| 0.12.11+adlc2 | 2026-07-12 | 0.12.11 (`1be42992`) | agent-context managed section parity + coverage: ported Team Directives & Constitution block to Python `update_agent_context.py` (was missing — bash/PS1 twins had it since adlc6, Python only wrote plan path). Added `_resolve_team_directives()` to read `team_ai_directives` from `.specify/init-options.json`. Broadened managed section text in all 3 scripts: "team-* skill" → "skill" (covers domain skills installed during init, not just governance team-* skills), "rules or personas" → "rules, personas, or examples" (matches `team.discover` actual scope: personas, rules, examples, skills). Bumped agent-context extension 1.1.0 → 1.2.0. |
| 0.12.11+adlc1 | 2026-07-11 | 0.12.11 (`1be42992`) | Upstream merge (30 commits, 3 releases 0.12.9–0.12.11): invoke_separator parse-success fix (#3304), Windows Store python3 stub skip + `_interpreter_runs()` probe (#3385), SKILL.md frontmatter control char escape via `yaml_quote()` (#3399), chained expression filters left-to-right refactor (#3339), `refresh_shared_templates` preserves recovered files (#3378), Goose yaml skill placeholder resolution (#3374), bundled version pin enforcement (#3377), integration test home isolation (#3144), `py:` script type in command templates (#3403), configurable shell step timeout (#3404), find plans in nested spec directories (#3405), plan.md phase numbering fix (#3416), PowerShell `-Number 0` honor via `ContainsKey` (#3412), workflow.yml non-string scalar validation (#3421), plan-template.md self-referencing path fix (#3417), pre-commit config + trailing whitespace cleanup (#3430), malformed URL error handling (#3433/#3435/#3437), agent-context nested plan.md discovery (#3301), community catalog additions (EARS, Figma). 9 conflicts resolved: `pyproject.toml` (version), `integrations/base.py` (fork `_get_command_prefix`/`_build_preset_command_placeholder_map` + upstream `yaml_quote`/`_interpreter_runs`), `agents.py` (fork `_skip_primary` restructure + upstream Goose yaml `resolve_skill_placeholders`/`_convert_argument_placeholder`), `forge/__init__.py` (fork `spec-` prefix + alias resolution vs upstream `speckit-`), `hermes/__init__.py` (fork `resolve_command_alias` import + upstream `yaml_quote` import), `create-new-feature-branch.ps1` (fork `-IssueToken` param + upstream `ContainsKey('Number')` fix), `test_git_extension.py` (fork e2e Jira tests + upstream `--number 0` test), `test_base.py` (platform pin comments), `test_integration_devin.py` (fork `_skill_prefix()` vs upstream `speckit-`). Template-to-preset alignment: added `py:` script lines to 6 preset commands (analyze, checklist, clarify, converge, implement, tasks), removed stale "Phase 1: Update agent context" from `adlc.spec.plan.md`, fixed "Phase 2 planning" → "Phase 1 design". Pre-merge fix: wrapped bare `make_typer` import in `integrations/_commands.py` with try/except fallback. Test fixes: agent-context config template path (`.yml` → `.yml.template`), bundler pin version (1.0.0 → 1.1.0), python parity error message assertion. |
| 0.12.8+adlc6 | 2026-07-11 | 0.12.9.dev0 (`a7b43917`) | agent-context config lifecycle: renamed `agent-context-config.yml` → `.template` (CLI scaffolds template, not config); update scripts (bash/ps1/python) self-create config from template on first run; `post_init()` calls `_update_agent_context()` to seed AGENTS.md with managed section (team-discover instruction) during init. Auto-generate skills from `model-invocation: true` commands: `_register_extension_skills()` now creates skills for opted-in commands on all agent types (including non-skills agents like opencode). Replaced thin command wrappers with full-logic command files in `extensions/team-ai-directives/commands/`. Deleted `skills/` directory and `.skills.json` — single source of truth in commands. Removed governance skill installation from `pre_init()` (auto-generated in `post_init()`). Bumped agent-context extension 1.0.0 → 1.1.0, team-ai-directives extension 4.0.0 → 4.1.0. Fixed 12 CI test failures. |
| 0.12.8+adlc5 | 2026-07-10 | 0.12.9.dev0 (`a7b43917`) | `team-discover` skill now user-invocable. `agent-context` extension pre-installed (`preinstall: true` in catalog.json). `--help` theming: patched Typer's `rich_utils._get_rich_console` to return fork Console + overrode `STYLE_*` constants with accent color. Renamed "Team AI mcp setup" → "Team AI MCP setup". |
| 0.12.8+adlc4 | 2026-07-09 | 0.12.9.dev0 (`a7b43917`) | UI polish: merged `team-governance-skills` and `team-domain-skills` tracker steps into single `Install Team AI skills` step with `governance: N, domain: M` detail. Removed trailing whitespace in `tests/integrations/test_cli.py`. |
| 0.12.8+adlc3 | 2026-07-09 | 0.12.9.dev0 (`a7b43917`) | Team AI Directives architecture: governance repackaged as the bundled `extensions/team-ai-directives/` extension (v4.0.0) with commands (`team.discover`, `team.curate`, `team.evolve`, `team.repair`, `team.skills`, `team.verify`) and static governance skills; domain skills stay in the external KB. `_install_skills_from_path()` rewritten for `.skills.json` schema 2.0.0 `default` list (no `team-` prefixing). `sync_team_ai_directives()` installs the bundled extension via `ExtensionManager`, resolves the KB path, and triggers agent-context refresh. Added `extensions/team-ai-directives/.skills.json` v2.0.0; registered in `extensions/catalog.json` and `pyproject.toml` force-include. No `team.constitution` command/skill — constitution handled by `agent-context` bootstrap. Preset hooks cleaned (`team-ai-directives.discover`/`.constitution` removed from `adlc.spec.specify` and `adlc.change.specify`); `/team.discover`->`team-discover` and `/team.repair`->`team-repair` refs updated in levelup commands; `extensions/levelup/commands/implement.md:327` template path fixed to `{TEAM_DIRECTIVES}/templates/agents-template.md`. Preset bumps: agentic-sdlc 1.6.3->1.6.4, agentic-change 1.5.4->1.5.5, agentic-quick 1.2.2->1.2.3. |
| 0.12.8+adlc2 | 2026-07-08 | 0.12.9.dev0 (`a7b43917`) | Preset command alignment: per-preset `__SPECKIT_COMMAND_*__` placeholder resolution via `_build_preset_command_placeholder_map()` in `base.py`; converted `/change.*` and `/spec.*` handoff suggestions in `agentic-change`, `agentic-quick`, and additional `agentic-sdlc` commands; added `## Done When` exit criteria to all `agentic-change` and `agentic-quick` command files; added regression tests in `tests/integrations/test_base.py`. |
| 0.12.8+adlc1 | 2026-07-08 | 0.12.9.dev0 (`a7b43917`) | Upstream merge (7 commits): port update-agent-context to Python (#3387), escape TOML control chars (#3341), fix feature.json parser on Windows (#3312), docs updates (#3182, #3184), LLM Wiki community extension (#3361), release (#3410). New file: `_toml_string.py`. 2 conflicts (`pyproject.toml` trivial version; `base.py` import block — combined accent + _toml_string imports). |
| 0.12.7+adlc1 | 2026-07-08 | 0.12.8.dev0 (`882e1e90`) | Upstream merge (9 commits): agy extra-args (#3347), shell step validation (#3348), fan-in validation (#3349), workflow stderr routing under --json (#3352), bundle update uninstalls dropped components (#3353), manifest `_sha256` guard (#3376), GHES port fix (#3379), IPv6 URL fix in add commands (#3369), auth redirect guard (#3379). 1 conflict (`presets/_commands.py`): combined IPv6 try/except + `_esc()` with fork `accent()`. |
| 0.12.6+adlc8 | 2026-07-08 | 0.12.7.dev0 (`6b9463fd`) | `ACCENT_STYLE` runtime patch: `apply_theming_patches()` was imported but never called — `_console.py` stayed `"cyan"`. Now invoked after `show_banner` monkey-patch, so `select_with_arrows`, `StepTracker.render()`, and `BannerGroup.format_help` all render orange. |
| 0.12.6+adlc7 | 2026-07-08 | 0.12.7.dev0 (`b557f8cc`) | Delegation template fallback: `tasks-meta-utils.sh` now uses an inline default template when `resolve_template` fails, fixing test failures in bare environments after `templates/delegation-template.md` was removed. |
| 0.12.6+adlc6 | 2026-07-08 | 0.12.7.dev0 (`88886d60`) | Wheel build fix: removed stale `templates/agent-file-template.md` entry from `pyproject.toml` force-include (file deleted in adlc5, only self-test preset uses it via its own copy). |
| 0.12.6+adlc5 | 2026-07-08 | 0.12.7.dev0 (`55938e65`) | `templates/` reverted to upstream — all fork modifications removed from core command templates, vscode-settings.json, and fork-only template files. Fork-specific behavior lives exclusively in `presets/agentic-*/commands/`. FORK.md policy added: `templates/` stays upstream-aligned. |
| 0.12.6+adlc4 | 2026-07-08 | 0.12.7.dev0 (`dc6eafd3`) | Fixed Forge dot-notation test: replaced literal `/spec.implement` and `/spec.trace` in tasks command files with `__SPECKIT_COMMAND_*__` placeholders. Removed "Do NOT suggest" guard lines. |
| 0.12.6+adlc3 | 2026-07-08 | 0.12.7.dev0 (`02d548c6`) | Panel title theming (`select_with_arrows`, Next Steps, Enhancement Skills, Matching extensions), hook invocation prefix `speckit-...` → `spec-...` across 24 command files, tasks handover block directing to `/spec.implement` (not `/quick.implement` or `/spec.trace`), E701 lint fixes in ImportError fallback blocks. |
| 0.12.6+adlc2 | 2026-07-07 | 0.12.7.dev0 (`4d7eb07a`) | Theming sweep: replaced ~114 hardcoded `[green]`/`[cyan]` Rich markup across 10 CLI files with `accent()`/`accent_style()`. Introduced warm-toned semantic palette: `dark_sea_green` (success/active), `indian_red` (disabled/inactive), `gold1` (warning in status_colors). New constants `SUCCESS_COLOR`/`DISABLED_COLOR`/`WARNING_COLOR`/`ERROR_COLOR` + `success_style()`/`disabled_style()` helpers in `_init_fork.py`. Closes theme gaps from upstream merges that brought `workflows/`, `presets/`, `extensions/`, `bundle/` command modules without fork theming. |
| 0.12.6+adlc1 | 2026-07-07 | 0.12.7.dev0 (`f764270d`) | Upstream merge (9 commits): extension-local script path rewriting (`extension_id` threading through `register_commands`/`_adjust_script_paths`/`resolve_skill_placeholders`), generalized `post_process_command_content()` hook on `IntegrationBase` for non-skills agents, catalog URL validation (HTTPS-only, require host), community catalog additions (Charter, Orchestration Task Context Management) and updates (Ralph Loop v1.2.1, Ripple v1.1.0, DocGuard v0.30.0). 3-way merge of `agents.py` combined fork's `_skip_primary` alias-only restructure with upstream's `extension_id` threading and post-process hook. |
| 0.12.5+adlc3 | 2026-07-07 | 0.12.6.dev0 (`08cfa68b`) | PowerShell `{prefix}` template substitution fix: `Expand-BranchTemplate` was missing the `{prefix}` → `branch_prefix` replacement (bash twin had it). Added missing `.Replace()`, script-level `$branchPrefix` variable, and `{prefix}` validation guard. |
| 0.12.5+adlc2 | 2026-07-07 | 0.12.6.dev0 (`932264d5`) | Post-merge fixes for `0.12.5+adlc1`: PowerShell branch-number format crash (`-f` → `.PadLeft()`), test helper and assertions migrated from removed `branch_pattern` block to top-level `branch_template`/`branch_prefix`/`issue_format`/`number_padding`, doc references updated in core `specify.md` and both ADLC presets. |
| 0.12.5+adlc1 | 2026-07-07 | 0.12.6.dev0 (`73f77c20`) | Upstream merge (12 commits): namespaced git feature-branch templates (`branch_template`, `branch_prefix`, scope-prefix-aware numbering), workflow expression fixes (quote-aware interpolation, lexicographic string compare, case-insensitive gate reject), bundler catalog source-precedence + host-less URL hardening, ConfigManager non-mapping YAML coercion, Hermes `SPECKIT_INTEGRATION_HERMES_EXTRA_ARGS`, Goose `|2` block-scalar, Python `check_prerequisites` PoC. Migrated fork's Jira/numeric issue support onto upstream template mechanism as `{issue}` token with `issue_format`/`number_padding`; removed old `branch_pattern` block. Preserved worktree/isolation logic. Git extension `1.7.0`→`1.8.0`. |
| 0.12.4+adlc11 | 2026-07-06 | 0.12.5.dev0 (`4cd456d8`) | Workflow extension `2.2.0`→`2.6.1`: split `/workflow.mission` into planner + executor — new `/workflow.run` command reads workflow YAML and walks its `steps:` list as a generic interpreter (command/if/gate/do-while/shell/prompt/switch/fan-out/fan-in). `/workflow.mission` generates YAML and delegates to `/workflow.run`; `/workflow.resume` delegates to `/workflow.mission` for resume (gets Step 8 sign-off + audit trail). Safety layer aligned with Loop Engineering and Harness Engineering articles: supervision modes (`gated`/`autonomous`/`hybrid`), circuit breaker (3 consecutive `tasks_appended`), converge independence hint, iterations audit trail (`iterations.md`), audit trail persistence (`mission-log.json` instead of deleting state), verifiable done-criteria (refuses "TBD" Success Criteria), converge scope guard (no pre-existing issues), autonomous mode validation. Fixed `$ARGUMENTS` leakage, stale feature name, orchestrator reading command files, mission state not updated. agentic-change preset `1.5.0`→`1.5.4`: cross-preset handoff removal, Phase A hook alignment, converge scope guard, post-write done-criteria validation. agentic-sdlc preset `1.6.0`→`1.6.3`: Phase A hook alignment, converge scope guard, post-write done-criteria validation. agentic-quick preset `1.2.0`→`1.2.2`: done-criteria enforcement. Also merged upstream `0.12.5.dev0` (4 commits). |
| 0.12.4+adlc10 | 2026-07-04 | 0.12.4.dev0 (`bbe86310`) | Fixed extension namespace preservation in command invocation (`change.specify`, `quick.implement` keep their own namespace). Added workflow optional-phase selection (brainstorm, clarify, analyze, trace) with `command-catalog.md` reference. Workflow extension `2.0.0`→`2.1.0`. |
| 0.12.4+adlc9 | 2026-07-03 | 0.12.4.dev0 (`bbe86310`) | Major refactor: replaced `loop` extension (v1.2.0) with `workflow` extension (v2.0.0). Three commands: `mission` (assess prompt → generate workflow YAML → run; LLM-as-judge routes to spec.*/change.*/quick.* pipelines; no-args collects Mission Brief), `resume` (scan runs for PAUSED/FAILED matching current feature → `specify workflow resume <run_id>`), `persist` (copy run's workflow.yml to permanent location + register). Per-step model selection via config (`models.strong`/`models.fast`). EDD `next-spec.md` spec-correction routing handled at agent level (not nested in YAML) with `.mission-state.json` state file preventing infinite loops (`max_spec_corrections: 2`). No drafts directory — run directory stores workflow.yml. Deleted `extensions/loop/`, `workflows/sdd-loop/`. Kept `workflows/impl-converge-loop/` for direct impl↺converge. Removed `sdd-loop` from `workflows/catalog.json`. CLI `0.12.4+adlc8`→`0.12.4+adlc9`. |
| 0.12.4+adlc8 | 2026-07-03 | 0.12.4.dev0 (`bbe86310`) | Loop extension v1.2.0: Fixed `impl-converge-loop` workflow — command names `adlc.spec.implement`/`adlc.spec.converge` → `spec.implement`/`spec.converge` (CLI was resolving `adlc.spec.implement` to `spec.spec.implement`, causing "Command not found"). Replaced literal command names in `adlc.loop.goal.md` with `__SPECKIT_COMMAND_*__` placeholders (resolved to `/spec.specify` etc. at init by `resolve_command_refs`). Added CLI fallback to `adlc.loop.run.md` — if `specify workflow run impl-converge-loop` fails, manually iterate `__SPECKIT_COMMAND_IMPLEMENT__` → `__SPECKIT_COMMAND_CONVERGE__` (max 5). Extension `1.1.0`→`1.2.0`. |
| 0.12.4+adlc7 | 2026-07-03 | 0.12.4.dev0 (`bbe86310`) | Clean up dangling verify references after merge into converge: `change.implement` handoff `adlc.change.verify` → `adlc.change.converge`, agentic-change README `/change.verify` → `/change.converge`, EXTENSION-API-REFERENCE `before_verify`/`after_verify` → `before_converge`/`after_converge`. CLI `0.12.4+adlc6`→`0.12.4+adlc7`. |
| 0.12.4+adlc6 | 2026-07-03 | 0.12.4.dev0 (`bbe86310`) | `change.converge` full verification parity with `spec.converge` — append-only convergence assessment for change proposals, test gate, 4-pillar quality assessment, outcome token (`converged`/`tasks_appended`). Agentic-change preset `1.3.0`→`1.4.0`. CLI `0.12.4+adlc5`→`0.12.4+adlc6`. |
| 0.12.4+adlc5 | 2026-07-02 | 0.12.4.dev0 (`bbe86310`) | Loop extension v1.1.0: `adlc.loop.goal` rewritten to arg-based flow — with args: `spec.specify`→`spec.plan`→`spec.tasks`→`loop.run` (regenerates artifacts, passes spec_description to spec.specify); without args: hard error if spec/plan/tasks missing, else resumes `loop.run`. Command invocations changed from `specify <cmd>` CLI syntax to bare command names (agent-resolved, like hooks). `loop.run` alias used instead of full `adlc.loop.run`. Added outer loop cap (`max 2 spec-level corrections`) to prevent unbounded recursion in loop routing. Added exit conditions, design philosophy, and examples sections. New `sdd-loop` workflow (constitution → loop.goal, passes `{{ inputs.spec }}` as args). Registered `sdd-loop` in `workflows/catalog.json`. Extension `1.0.0`→`1.1.0`. |
| 0.12.4+adlc4 | 2026-07-02 | 0.12.4.dev0 (`bbe86310`) | EDD v1.1.0: appends actionable verification gaps to tasks.md, writes next-spec.md for spec-level corrections, fills EDD placeholder sections in converge's verify.md. Fixes loop disconnect (next-prompt targeted spec.specify while loop ran implement). Converge verify.md now includes Intent, Verification Summary, What Was Checked/Not Checked, Residual Risks, Provenance — the unified evidence bundle. Loop routing added to `adlc.loop.goal` (steps 6-7) and `adlc.loop.run` (detailed section with `__SPECKIT_COMMAND_*__` placeholders). EDD extension `1.0.0`→`1.1.0`. CLI `0.12.4+adlc3`→`0.12.4+adlc4`. |
| 0.12.4+adlc3 | 2026-07-02 | 0.12.4.dev0 (`bbe86310`) | New `loop` extension (v1.0.0): `adlc.loop.run` + `adlc.loop.goal` commands, `impl-converge-loop` engine workflow (do-while, max 5 iterations, condition: `contains('tasks_appended')`). Merged `spec.verify` into `spec.converge` (test gate + diff analysis + 4-pillar assessment now part of converge; converge outputs outcome token as first stdout line). Merged `change.verify` into `change.converge` (parallel merge in agentic-change preset). EDD hook moved `after_implement` → `after_converge`. Deleted broken `sdd-loop.yml` (non-functional Jinja2 expressions, unregistered, untested). Updated README.md (6 locations), QUICKSTART.md, EDD README/CHANGELOG. CLI `0.12.4+adlc2`→`0.12.4+adlc3`. |
| 0.12.4+adlc2 | 2026-07-02 | 0.12.4.dev0 (`bbe86310`) | Preset hook fix: removed manual `extension.yml` manifest resolution from all 15 preset command files — replaced with upstream-aligned `EXECUTE_COMMAND` blocks (pre-hook → `**Automatic Pre-Hook**`, post-hook → `**Automatic Hook**`). Fork regression fixes: PS `Get-CurrentBranch` git lookup removed for bash parity (branch fallback to feature dir basename); `_INSTALLER_PATH_PREFIXES` extended with `agentic-sdlc-specify-cli` fork tool-dir names for `specify self upgrade` detection. CLI `0.12.4+adlc1`→`0.12.4+adlc2`. Preset bumps: agentic-sdlc `1.5.0`→`1.6.0`, agentic-quick `1.1.0`→`1.2.0`, agentic-change `1.2.0`→`1.3.0`. |
| 0.12.4+adlc1 | 2026-07-02 | 0.12.4.dev0 (`bbe86310`) | Merge upstream 15 commits: py script type + Python interpreter resolution, private-repo release asset URL fix, Analytics extension catalog, multi-expression template fix, `SPECIFY_INIT_DIR`, core-command dir helpers, `CURRENT_BRANCH` fallback, bug-fix/bug-test workflows, Copilot pre-rollout warning, newsletter, zed integration, cline hook fix. 4 conflicts resolved (pyproject.toml, common.sh, base.py, test_base.py). Also: fixed banner theming regression — converted all 8 remaining sub-apps (bundle/extension/preset/workflow-step) from plain `typer.Typer()` to `make_typer()`. |
| 0.12.2+adlc2 | 2026-07-01 | 0.12.2 (`810d6fcf`) | Merge upstream PR-8/8: workflow command handlers moved from `__init__.py` to new `workflows/_commands.py`. Re-applied fork import block (`_init_fork`/`_core_fork`/`_assets_fork`, `_upstream_`-aliased version fns, `show_banner` override) on top of upstream's compact `register()` region; scoped `from typing import Any` into fallback. Patched `_commands.py` so `workflow_app`/`workflow_catalog_app` use `make_typer()` theming (step apps stay plain). Fixed bash 3.2 portability (`${var,,}` → `tr`) in fork extension scripts setup-architect/levelup/product.sh. 1 real conflict (`__init__.py`); `test_workflows.py` auto-merged. |
| 0.12.2+adlc1 | 2026-06-30 | 0.12.2 | Merge upstream 0.12.2 (19 commits): retired iflow/roo/windsurf integrations, moved `version_satisfies` to `_utils.py` (allows prereleases), workflow fan-out `max_concurrency`, bool `max_iterations` rejection, bash 3.2 portability fixes, `--no-persist` in common.sh, extension catalog updates (Intake v0.1.3, Architecture Workflow v1.2.2, Repository Governance, Workflow Preset v1.3.11). 2 conflicts resolved (pyproject.toml, AGENTS.md). |
| 0.11.9+adlc9 | 2026-06-30 | 0.11.9 | Fixed F811 ruff lint (duplicate `_locate_bundled_preset` import). Consolidated `_extension_fork.py` into `_core_fork.py` (three-tier → two-tier dependency graph). Agent-context opt-in alignment in `adlc.spec.plan` (conditional context-file update). |
| 0.11.9+adlc4 | 2026-06-29 | 0.11.9 | Fixed 4 remaining CI test failures: Generic integration converge prefix mismatch (3 tests), eval.yml action SHA pinning (1 test). Pinned all 6 GitHub Actions to commit SHAs. All CI tests now pass. |
| 0.11.9+adlc3 | 2026-06-29 | 0.11.9 | Merge upstream 2 new commits: community bundle submission issue template + docs (#3162), docs for /speckit.converge (#3181). All doc files already identical; only README.md required merge. Added new **Community Bundles** section to README with contribution link. Fixed 6 CI test failures: converge command keeps `speckit.` prefix (like taskstoissues); Firebender `_expected_files` accepts `project` kwarg + dedup; setup-plan test uses `SPECIFY_FEATURE_DIRECTORY`; PS `create-new-feature.ps1` null `$featureDir` fix; PS test uses correct extension script path. |
| 0.11.9+adlc2 | 2026-06-29 | 0.11.9 | Re-added `specify preset update` CLI command (registration lost during upstream merge). Fixed `test_e2e_branch_pattern_with_issue_config` to source `git-common.sh` (core `common.sh` no longer has `check_feature_branch`). |
| 0.11.9+adlc1 | 2026-06-28 | 0.11.9 | Merge upstream 0.11.9 (15 commits): mandatory hook invocation enforcement (#2901), PowerShell branch-name acronym case-sensitivity fix (#3129), GHES private release asset resolution (#3157), community bundle submission path (#3162), docs for --force and --refresh-shared-infra (#3179). Fork fixes: relative imports in extensions/ and presets/ __init__.py, registered.append guard in agents.py, bundled extension update uses install_from_directory not catalog download. |
| 0.11.8+adlc1 | 2026-06-28 | 0.11.8 | Merge upstream 0.11.8 (19 commits): standardized EXECUTE_COMMAND hook format across all core command templates; git extension aligned to upstream opt-in (removed --no-git flag); forked core and preset commands split their hook strategies (upstream's EXECUTE_COMMAND for core, fork's manifest-lookup dispatcher for presets); script delegation paths fixed (core -> git extension); workflow tests adapted to fork's run_and_tee streaming; bundled-extension update checks bundled version first. |
| 0.10.0+adlc33 | 2026-06-22 | 0.10.0 | Orange accent theming sweep: replaced all 54 `[green]` Rich markup references with `accent()` across 8 files — every success message, checkmark symbol, and status indicator now uses `#f47721` orange instead of green. Affects `__init__.py`, `_init_fork.py`, `_version.py`, `_utils.py`, `_console.py`, `commands/init.py`, integrations/_install_commands.py, integrations/_migrate_commands.py, integrations/_query_commands.py. |
| 0.10.0+adlc32 | 2026-06-22 | 0.10.0 | Fixed broken `/memory/constitution.md` paths in agentic-sdlc preset (analyze, plan, implement, verify) — now uses `{REPO_ROOT}/.specify/memory/constitution.md`. Added constitution alignment to agentic-quick (implement) and agentic-change (specify, implement, verify) via IF EXISTS pattern. Bumped agentic-sdlc v1.4.0→v1.5.0, agentic-quick v1.0.0→v1.1.0, agentic-change v1.0.0→v1.1.0, team-ai-directives v3.1.0→v3.2.0, CLI 0.10.0+adlc31→0.10.0+adlc32. |
| 0.10.0+adlc31 | 2026-06-20 | 0.10.0 | Added `make_typer()` helper to `_init_fork.py` — creates `typer.Typer` with `cls=BannerGroup` by default. Converted 9 sub-app definitions to use `make_typer()` or `cls=BannerGroup` (extension_app, catalog_app, preset_app, preset_catalog_app, workflow_app, workflow_catalog_app, integration_app, integration_catalog_app, self_app). Replaced 4 hardcoded `[cyan]` markup with `accent()` in init/install flows. Bumped CLI 0.10.0+adlc30→0.10.0+adlc31. |
| 0.10.0+adlc30 | 2026-06-20 | 0.10.0 | Extracted project-root `.skills.json` and `.specify/skills/` install from `_install_skills_from_path()` into new standalone `install_project_skills()` function. Project skills now install during every init as a dedicated fork step (not only with `--team-ai-directives`). Added `("project-skills", "Install Projects skills")` tracker step. |
| 0.10.0+adlc29 | 2026-06-20 | 0.10.0 | Removed extensions/quick. Added agentic-change and agentic-quick bundled presets (force-included in wheel, catalog entries with preinstall:true). agentic-change provides 4 commands (change.specify/implement/verify/levelup) for lightweight OpenSpec-inspired change proposals; agentic-quick provides 2 commands (quick.implement/levelup) replacing the deleted quick extension with identical content. pyproject.toml, README.md, QUICKSTART.md, CHANGELOG.md, FORK.md, catalog.json updated. |
| 0.10.0+adlc28 | 2026-06-20 | 0.10.0 | Added brainstorm lifecycle stage (adlc.spec.brainstorm) — structured exploration before specification, outputs .specify/drafts/brainstorm-context.md, consumed by adlc.spec.specify (Mission Brief seeding + promotion). Added verify lifecycle stage (adlc.spec.verify) — hard test gate + 4-pillar compliance assessment (Spec Compliance, Code Quality, Test Adequacy, Risk & Evidence), outputs SPECIFY_FEATURE_DIRECTORY/verify.md. 8 new hook events: before_brainstorm/after_brainstorm, before_verify/after_verify, before_levelup/after_levelup, before_trace/after_trace. Agentic SDLC preset v1.3.0→v1.4.0. README updated (4 locations). |
| 0.10.0+adlc27 | 2026-06-20 | 0.10.0 | Fixed TEAM_DIRECTIVES sentinel bug in quick.levelup (boolean flag guard). Replaced raw git with git extension commands (git.commit --message, git.publish --draft). Aligned CDR ID format to CDR-{NNN} (year-scoped, no year prefix). Added OKF v0.1 frontmatter (type, title, description, tags, timestamp). Structured evidence as YAML list. Added constitution amendment safety instruction. Quick extension v1.4.0→v1.5.0. |
| 0.10.0+adlc26 | 2026-06-20 | 0.10.0 | Model-invocation opt-in for skills agents (`model-invocation: true` on `quick.implement`, `quick.levelup`, `team.discover`, `team.skills`). Removed Claude's unconditional `disable-model-invocation: false`. Added project-root `.skills.json` support in init and `team.skills`. |
| 0.10.0+adlc25 | 2026-06-20 | 0.10.0 | Fixed per-task metadata lifecycle in `adlc.spec.implement.md` (start-task/complete-task/fail-task instead of stale add-task with SYNC_OR_ASYNC placeholder). Downstream workflow steps (plan/tasks/implement) no longer receive full raw prompt as args. |
| 0.10.0+adlc22 | 2026-06-19 | 0.10.0 | Decoupled worktree cd from specify (git extension handles entry). Removed stale `git.task-merge`/`delegate_merge_conflicts` refs from `adlc.spec.implement.md`. Fixed 24 CI test failures — updated idempotency tests, removed task-branch test classes, deleted `test_merge_task_branch.py`. |
| 0.10.0+adlc20 | 2026-06-19 | 0.10.0 | Git extension v1.6.0: simplified worktree model to feature-only isolation (removed per-task branches), added `git.worktree-list` and `git.worktree-cleanup` commands, idempotent worktree creation with `origin/main` default base, hardened cd instruction for agents. Removed task-mode auto-commit prefixes. |
| 0.10.0+adlc17 | 2026-06-18 | 0.10.0 | Agentic SDLC preset v1.2.1: fixed constitution handoff agent naming (`speckit.specify` → `adlc.spec.specify`), registered missing `delegation-template` in preset manifest, refactored `tasks-meta-utils.sh` to use `resolve_template` for preset override support, aligned preset delegation-template placeholders with core version. |
| 0.10.0+adlc15 | 2026-06-14 | 0.10.0 | OKF v0.1 conformance: Added `type`, `title`, `description`, `tags`, `timestamp` fields to all context module frontmatter (constitution, personas, rules, examples, skills). Updated LevelUp templates (rule, persona, example, skill) and command docs (implement, validate, init) to generate OKF-compliant frontmatter. Updated team-ai-directives extension commands (repair, verify) for OKF field validation and orphan repair. Bumped LevelUp extension to v1.9.0 and team-ai-directives extension to v1.9.0. |
| 0.10.0+adlc14 | 2026-06-14 | 0.10.0 | Agentic SDLC preset v1.2.0: token compression across all 9 preset commands (~236 lines, ~9.4% reduction). Quick extension v1.3.0: hook execution aligned to preset protocol (manifest resolution + condition filtering) + non-hook compression (~95 lines). |
| 0.10.0+adlc13 | 2026-06-14 | 0.10.0 | EDD Extension v1.0.0 (`extensions/edd/`): unified `edd.verify` command with deterministic auto-detect + AI evaluation, guardrails (no-progress/budget/regression/escalation), `.eval/loop-state.yml` spine, `sdd-loop.yml` workflow with hook-driven verify (`after_implement`, optional: false). Review bugs fixed: {SCRIPT} overload, script paths, workflow grade step, double-run, coverage, smoke parsing. Agentic SDLC preset v1.1.0: removed `adlc.spec.verify`, implement step 3, handoffs updated. |
| 0.10.0+adlc12 | 2026-06-14 | 0.10.0 | Fork `_assets_fork.py` module: consolidates bundled-asset helpers into leaf module, restores `_assets.py` to clean-upstream. `specify preset update` command: atomic updates with backup/rollback for bundled presets. Fuzzy-match suggestions on preset typos. |
| 0.10.0+adlc11 | 2026-06-13 | 0.10.0 | Agentic SDLC preset v1.0.11: added `mission-brief` checklist domain to `spec.checklist` for Oracle Adequacy validation — 6-item checklist auto-evaluates whether the Mission Brief (Goal, Success Criteria, Constraints) is sufficient to serve as its own verification oracle. Added `spec.specify` handoff to `spec.checklist mission-brief` and `spec.implement` pre-flight adequacy warning when score < 80%. |
| 0.10.0+adlc10 | 2026-06-13 | 0.10.0 | Quick extension v1.2.0: added `quick.levelup` command for low-friction directive contribution to team-ai-directories — 6 verifiable phases with automated gates (Signal Gate, Cross-System Conflict Detection, Output Artifact Verification), CDR schema completeness check, Descriptor generation matching `levelup.implement` format, companion skill auto-detection, and handoff to `/levelup.validate`. |
| 0.10.0+adlc9 | 2026-06-13 | 0.10.0 | CDR.md becomes the context module search surface for /team.discover. New `Descriptor` column in CDR.md index table enables LLM-driven relevance matching without full-file scans. LevelUp extension v1.8.0: implement.md emits Descriptor column. Team AI Directives extension v1.8.0: discover.md uses CDR index as primary search surface (skills-style), repair.md re-indexer updated for Descriptor column, agents-template.md documents CDR.md as context index. Falls back to legacy context_modules/ scan when CDR.md unavailable. |
| 0.10.0+adlc8 | 2026-06-12 | 0.10.0 | Fixed `_locate_bundled_preset()` to resolve `agentic-sdlc` from `bundled_presets/` in wheel/uv-tool installs, matching the pyproject.toml wheel path. |
| 0.10.0+adlc7 | 2026-06-12 | 0.10.0 | Agentic SDLC preset v1.0.10: trimmed duplicate `[SYNC]`/`[ASYNC]` taxonomies in `adlc.spec.plan.md` and `adlc.spec.tasks.md`; references canonical `templates/plan-template.md` and `templates/tasks-template.md` instead of inline duplication. ~340 tokens saved, behavior-identical. |
| 0.10.0+adlc6 | 2026-06-08 | 0.10.0 | Repaired the bundled evals extension (PowerShell lifecycle parity, validation path fixes, non-interactive robustness) and promoted feature-local trace/verification into the preset surface: `spec.trace` owns `specs/{branch}/trace.md`, `spec.verify` defines `specs/{branch}/evidence.md`, and the Agentic SDLC preset now suggests trace/verify after implement. Evals extension bumped to v1.1.1, LevelUp stays at v1.7.1, preset bumped to v1.0.9. |
| 0.10.0+adlc5 | 2026-06-08 | 0.10.0 | Added configurable git extension `branch_pattern` support with Jira issue keys, expanded git extension docs, added installed-extension end-to-end coverage for configured Jira branch names, bumped the bundled git extension to v1.5.0, and bumped the fork CLI release to capture the shipped behavior. |
| 0.10.0+adlc4 | 2026-06-08 | 0.10.0 | Follow-up fork release after `0.10.0+adlc3`: fixed the PowerShell `merge-task-branch` regression test to execute from the primary checkout script path while preserving worktree `cwd`, so the release tag includes the CI fix as well. Git extension remains at v1.4.0. |
| 0.10.0+adlc3 | 2026-06-08 | 0.10.0 | Kept the CLI on the upstream 0.10.0 base while shipping the real async/[P] execution backend: script-backed `tasks-meta-utils` CLI (bash + PowerShell), feature-scoped async state, explicit `[SYNC]/[ASYNC]` parsing in `tasks-dag.{sh,ps1}`, real `implement.{sh,ps1}` executors, and `merge-task-branch` support in `worktree-utils.{sh,ps1}`. Bumped the bundled git extension to v1.4.0 for these capabilities. |
| 0.10.0+adlc2 | 2026-06-08 | 0.10.0 | Hook command id normalization: `.specify/extensions.yml` now stores alias-normalized hook command ids; added normalization helpers in `_core_fork.py`, normalized bundled-install hook configs in init/install flows, and fixed skill-name resolution for alias-form command ids. |
| 0.10.0+adlc1 | 2026-06-07 | 0.10.0 | Upstream merge: adopted upstream `0.10.0` removal of legacy `--ai`, `--ai-commands-dir`, and `--ai-skills` init flags; merged bundled `bug` triage extension, private-repo preset/workflow release-asset URL hardening, and workflow gate prompt rendering updates. Preserved fork identity, theming, `spec-*` alias guidance, team-directives hooks, and fork package metadata/versioning. |
| 0.9.5+adlc1 | 2026-06-04 | 0.9.5 | Merge upstream 0.9.5 (3 commits): rovodev Atlassian Rovo Dev integration (`acli rovodev`); `--json` output for `workflow run`/`resume`/`status`; upversion to 0.9.5.dev0. Preserved fork identity and theming. Fixed upstream rovodev integration for fork: added `_reconcile_rovodev_prompts` in `post_init` so prompt wrappers + prompts.yml follow alias-aware skill names (`spec-*`); updated tests to reflect alias-aware contract |
| 0.9.2+adlc5 | 2026-06-04 | 0.9.2 | Hotfix: made `specify self check` and `specify self upgrade` fork-aware by detecting `agentic-sdlc-specify-cli`, accepting fork tags like `agentic-sdlc-v0.9.2+adlc4`, and emitting fork-correct reinstall/rollback commands |
| 0.9.2+adlc4 | 2026-06-03 | 0.9.2 | Follow-up fork release after upstream main merge: self-upgrade/rollback guidance now points to `tikalk/agentic-sdlc-spec-kit`, themed `specify --help`, fixed generic integration quickstart test, and cleaned targeted Ruff/test issues while excluding eval Python template assets from Ruff |
| 0.9.2+adlc3 | 2026-06-03 | 0.9.2 | Upstream main merge after 0.9.2: adopted `bb2b49d` workflow run-state hardening so `RunState.load()` validates `run_id` before path construction, plus new traversal/validation regression tests; kept fork release/version identity |
| 0.9.2+adlc2 | 2026-06-03 | 0.9.2 | Hotfix: project-scoped alias resolution for HookExecutor skill names and CommandRegistrar output names (uses project_root instead of cwd), fixing fork CI failures where core commands should render `spec-*` but git / agent-context / tasktoissues remain `speckit-*` |
| 0.9.2+adlc1 | 2026-06-03 | 0.9.2 | Upstream merge: 14 commits (v0.9.0-v0.9.2). Major: ee17b04 co-locates integration CLI handlers into integrations/_*.py (fork theming re-applied); d79a514 drops unsupported Copilot mode: frontmatter (fork adopted); UTF-8 I/O pinning, workflows continue_on_error, private-repo asset URL fix. Removed deleted command stubs |
| 0.8.12+adlc39 | 2026-05-30 | 0.8.12 | Architect v2.1.3: Viewpoint-organized aggregation enforcement, Mermaid-only diagram constraint |
| 0.8.12+adlc38 | 2026-05-30 | 0.8.12 | Architect v2.1.2: Subsystem view links in AD.md - inline links after each view when 2+ subsystems detected |
| 0.8.12+adlc37 | 2026-05-30 | 0.8.12 | LevelUp v1.7.0: Constitution CDR lifecycle - constitution changes now require review before publication |
| 0.8.12+adlc36 | 2026-05-29 | 0.8.12 | LevelUp v1.6.4: Constitution Generation phase in /levelup.init - derives principles from cross-cutting patterns and inconsistencies |
| 0.8.12+adlc35 | 2026-05-29 | 0.8.12 | LevelUp v1.6.3: Moved /levelup.repair to team-ai-directives as /team.repair, deleted orphan scripts; Team AI Directives v1.7.8: team.repair command, team.skills script fix, setup-team.sh/ps1 |
| 0.8.12+adlc34 | 2026-05-29 | 0.8.12 | ADLC preset v1.0.7: Hardened tasks_meta.json creation (MANDATORY init step, per-task metadata updates, completion verification); LevelUp extension: fixed common.sh path resolution in generate-trace.sh and validate-trace.sh |
| 0.8.12+adlc31 | 2026-05-29 | 0.8.12 | Team AI Directives extension v1.7.6: Renamed {KNOWLEDGE_BASE} to {TEAM_AI_DIRECTIVES} placeholder |
| 0.8.12+adlc26 | 2026-05-28 | 0.8.12 | Architect extension v2.1.1: Hardened DAG orchestration (threshold enforcement, DAG-guarded views, per-view state updates, Accepted-only ADR promotion), AD-template.md link fix |
| 0.8.12+adlc25 | 2026-05-28 | 0.8.12 | Hook execution hardening in all preset command files: pre-execution hooks moved to absolute top, compact imperative format, post-execution hooks extracted and standardized |
| 0.8.12+adlc24 | 2026-05-28 | 0.8.12 | Reference extension auto-update: specify extension update detects and applies updates for source: reference extensions with rollback support |
| 0.8.12+adlc23 | 2026-05-28 | 0.8.12 | Windows test failures: Replaced f-string JSON construction with json.dumps() to properly escape Windows paths |
| 0.8.12+adlc22 | 2026-05-28 | 0.8.12 | PresetResolver reference extension path resolution: resolve_extension_dir() for reference extensions living outside .specify/extensions/ |
| 0.8.12+adlc21 | 2026-05-28 | 0.8.12 | Reference extension support: full support for extensions registered with source: reference and a top-level path across CLI commands and config loading |
| 0.8.12+adlc20 | 2026-05-26 | 0.8.12 | Fix extension download URL {{VERSION}} placeholder substitution in download_extension method |
| 0.8.12+adlc19 | 2026-05-23 | 0.8.12 | LevelUp extension v1.6.1: Fix redundant ID generation, CDR ref preservation, AGENTS.md grep pattern, validate-directives.sh jq error |
| 0.8.12+adlc18 | 2026-05-23 | 0.8.12 | Fix team-ai-directives reference mode registration in extension registry |
| 0.8.12+adlc17 | 2026-05-22 | 0.8.12 | LevelUp extension v1.6.0: Repair command for CDR.md, .skills.json, and AGENTS.md reindexing |
| 0.8.12+adlc16 | 2026-05-20 | 0.8.12 | Architect extension v2.1.0: Technology neutrality in Functional View, Functional-Development view parity, analyze Pass E.6/E.7 |
| 0.8.12+adlc14 | 2026-05-19 | 0.8.12 | Product extension v1.5.6: In-section diagrams, remove Visual Summary, sections renumbered 1-12, delete visual templates, no .specify/product/visuals/ |
| 0.8.12+adlc13 | 2026-05-19 | 0.8.12 | Product extension v1.5.5: PDR lifecycle enforcement - mandatory memory promotion, state schema lifecycle fields, 9-check final gate |
| 0.8.12+adlc12 | 2026-05-19 | 0.8.12 | Product extension v1.5.4: Fix self-contained PRD enforcement - Step 3.3 structure, embedding rules, prd-template .specify/ references |
| 0.8.12+adlc11 | 2026-05-19 | 0.8.12 | Product extension v1.5.3: Business stakeholder sections (Executive Summary, Market Opportunity, Investment, GTM), self-contained PRD generation, enhanced validation |
| 0.8.12+adlc10 | 2026-05-19 | 0.8.12 | Product extension v1.5.2: Hardened implement command with compliance checklist, validation scripts, strict template enforcement, ASCII→Mermaid conversion |
| 0.8.12+adlc9 | 2026-05-19 | 0.8.12 | Product extension v1.5.1: Mermaid v10 syntax fixes, new diagram types (architecture, journey, gantt), mandatory visual generation |
| 0.8.12+adlc4 | 2026-05-17 | 0.8.12 | CLI bundled extension update support: specify extension update now checks CLI wheel for bundled extension updates |
| 0.8.12+adlc3 | 2026-05-17 | 0.8.12 | Architect extension v2.0.8 hardening: clarify→implement workflow enforcement, placeholder validation, --force flag |
| 0.8.12+adlc2 | 2026-05-16 | 0.8.12 | Architect extension comprehensive hardening: Phase execution enforcement, view file generation, sub-system detection with mandatory interactive proposal |
| 0.8.12+adlc1 | 2026-05-15 | 0.8.12 | Git extension enhancements (workspace command with force flag, setup-ignore command) |

## Customization Modules

The fork's customizations are split across the modules listed in [Fork module layout](#fork-module-layout). Historically these were all in a single `cli_customization.py` file; that file has been split into focused modules (as of release `0.9.5+adlc2`).

The split assigns each concern to the lowest tier that owns it:

- `_core_fork.py` — fork-level extension constants (`EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`), `COMMAND_PREFIX`, `build_alias_map`, `resolve_command_alias`, `compute_skill_output_name`, MCP config helpers, `get_preinstalled_extensions`
- `_init_fork.py` — `ACCENT_COLOR`, `BANNER_COLORS`, `TAGLINE`, `PKG_NAMES`, `TEAM_DIRECTIVES_DIRNAME`, `accent`, `accent_style`, `apply_theming_patches`, `pre_init`, `post_init`, `get_team_directives_path`, `sync_team_ai_directives`, `get_speckit_version`, `GITHUB_API_LATEST`, `_update_agent_context`
- `_base_fork.py` — `detect_native_worktree()`
- `_workflows_fork.py` — workflow catalog/app theming hooks
- `extensions_fork.py` — worktree constants and config schema

Feature / override table:

| Feature | Upstream Default | Fork Override | Module |
|---------|------------------|---------------|--------|
| ACCENT_COLOR | "cyan" | "#f47721" (tikalk orange) | `_init_fork` |
| BANNER_COLORS | cyan gradient | orange gradient | `_init_fork` |
| accent() | N/A | Helper function for theming | `_init_fork` |
| accent_style() | N/A | Helper for Rich style= params | `_init_fork` |
| PKG_NAMES | ("specify-cli",) | ("agentic-sdlc-specify-cli", "specify-cli") | `_init_fork` |
| TEAM_DIRECTIVES_DIRNAME | N/A | "team-ai-directives" | `_init_fork` |
| EXTENSION_NAMESPACES | ["speckit"] | ["speckit", "adlc"] | `_core_fork` |
| EXTENSION_ALIAS_PATTERN_ENABLED | False | True | `_core_fork` |
| COMMAND_PREFIX | "speckit" | "spec" | `_core_fork` |

## Import Block

The `__init__.py` file starts with this import block that you should preserve during merges:

```python
# Tikalk fork customizations - import with fallback to upstream defaults
try:
    from ._init_fork import (
        ACCENT_COLOR,
        BANNER_COLORS,
        TAGLINE,
        accent,
        accent_style,
        TEAM_DIRECTIVES_DIRNAME,
        PKG_NAMES,
        pre_init,
        post_init,
    )
    from ._core_fork import compute_skill_output_name
except ImportError:
    ACCENT_COLOR = "cyan"
    BANNER_COLORS = ["#00ffff", "#00cccc", "cyan", "#009999", "white", "bright_white"]
    TEAM_DIRECTIVES_DIRNAME = "team-ai-directives"
    PKG_NAMES = ["specify-cli"]

    def accent(
        text: str, bold: bool = False, italic: bool = False, dim: bool = False
    ) -> str:
        style = ACCENT_COLOR
        if bold:
            style = f"bold {style}"
        if italic:
            style = f"italic {style}"
        if dim:
            style = f"dim {style}"
        return f"[{style}]{text}[/]"

    def accent_style() -> str:
        return ACCENT_COLOR

    def pre_init(project_path, selected_ai, team_ai_directives, tracker=None):
        pass

    def post_init(project_path, selected_ai, tracker=None, no_git=False):
        pass

    def compute_skill_output_name():
        return None
```

**Critical**: This block must include ALL fork customizations with fallbacks, not just partial imports. The import block is the SINGLE SOURCE OF TRUTH for fork customizations - all theming, hooks (pre_init, post_init), and helper functions must be defined here.

## Extension Namespace Configuration

In `extensions.py`, the fork configures command name patterns:

```python
# Get namespaces from customization module (supports speckit and adlc)
try:
    from ._core_fork import EXTENSION_NAMESPACES, EXTENSION_ALIAS_PATTERN_ENABLED
except ImportError:
    EXTENSION_NAMESPACES = ["speckit"]
    EXTENSION_ALIAS_PATTERN_ENABLED = False

EXTENSION_COMMAND_NAME_PATTERN = re.compile(
    rf"^(?:{'|' . join(EXTENSION_NAMESPACES)})\.([a-z0-9-]+)\.([a-z0-9-]+)$"
)

if EXTENSION_ALIAS_PATTERN_ENABLED:
    EXTENSION_ALIAS_NAME_PATTERN = re.compile(r"^([a-z0-9-]+)\.([a-z0-9-]+)$")
else:
    EXTENSION_ALIAS_NAME_PATTERN = None
```

## Merging Upstream

This section documents the complete workflow for merging upstream changes from `github/spec-kit`.

### Pre-Merge: Check for New Upstream Commits

```bash
# Fetch latest upstream changes
git fetch upstream

# Check what commits are new in upstream (not in origin)
git log origin/main --not upstream/main
git log upstream/main --not origin/main
```

### Complete Merge Workflow

#### Step 1: Create Backup Branch

```bash
git checkout main
git branch backup-before-upstream-merge-$(date +%Y%m%d)
```

#### Step 2: Fetch and Merge

```bash
git fetch upstream
git merge upstream/main
```

#### Step 3: Resolve Conflicts

**CRITICAL: Never use `git checkout --theirs` for __init__.py or pyproject.toml**

**Correct Strategy**: Use upstream as clean base, then ADD fork customizations on top.

##### New Upstream Module Structure (v0.8.9+)

Upstream has extracted code from `__init__.py` into separate modules:

| Module | Contents | Fork Action |
|--------|----------|-------------|
| `_console.py` | BANNER, TAGLINE, StepTracker, console | Keep upstream, fork theming overrides in `show_banner()` |
| `_version.py` | Version checking, self-update | Override GITHUB_API_LATEST via `_init_fork` |
| `_assets.py` | Bundled asset location | Accept as-is |
| `_utils.py` | Utility functions | Accept as-is |
| `catalogs.py` | Catalog config loading | Accept as-is |
| `integration_state.py` | Integration state management | Accept as-is |

##### __init__.py Resolution

1. Keep upstream imports from extracted modules (`_console`, `_assets`, `_utils`, `_version`)
2. Keep fork's `_init_fork` and `_core_fork` import blocks AFTER upstream imports
3. Keep fork's custom functions that depend on the fork modules:
   - `show_banner()` (overrides upstream to apply theming)
   - `TEAM_DIRECTIVES_DIRNAME` (from `_init_fork`)
   - `sync_team_ai_directives()` (imported from `_init_fork`)
   - `get_team_directives_path()` (imported from `_init_fork`)

##### pyproject.toml Resolution

NEVER use `--theirs`. Manually edit to preserve fork values:
- `name = "agentic-sdlc-specify-cli"`
- `version = "0.8.X+adlcN"` (fork version)
- `description` (fork description)
- Wheel paths: keep bundled extensions/presets paths
- Keep `httpx>=0.27.0` dependency

##### Test Files Resolution

See [Test Merge Strategy](#test-merge-strategy) section. Do NOT use `git checkout --theirs tests/`.

**Why this works**:
- Upstream refactoring isolates code into stable modules
- Fork customizations stay in `_init_fork.py` / `_core_fork.py` and the `__init__.py` import block
- Clear separation of concerns reduces future conflicts
- pyproject.toml needs manual edit to preserve fork version (never use --theirs)

#### Step 4: Verify

```bash
python3 -m pytest tests/ -v
```

#### Step 5: Bump Version

Update `pyproject.toml`:
```toml
version = "0.3.X"  # Increment from current version
```

#### Step 6: Update CHANGELOG

Add new entry at top of changelog (after ## [Unreleased] or before latest release):

```markdown
## [0.3.X] - YYYY-MM-DD

### Changed

- **Upstream merge**: Synced with github/spec-kit
  - [List upstream commits merged]
```

#### Step 7: Commit and Push

```bash
git add -A
git commit -m "chore: merge upstream and bump to v0.3.X"
git push origin main
```

#### Step 8: Create Tag

```bash
git tag -a agentic-sdlc-v0.3.X -m "Release agentic-sdlc-v0.3.X"
git push origin agentic-sdlc-v0.3.X
```

Example for this release:

```bash
git tag -a agentic-sdlc-v0.10.0+adlc6 -m "Release agentic-sdlc-v0.10.0+adlc6"
git push origin agentic-sdlc-v0.10.0+adlc6
```

### SDD-Guided Upgrade Verification

The fork dogfoods its own SDD tooling to verify upstream merges. After the git merge
and conflict resolution (Steps 1-3) and before tagging (Step 8), treat the upgrade as
a change proposal and run it through the full verification pipeline.

#### Step 7a: Document the Upgrade as a Change Spec

Create a change proposal that captures what the upstream merge changed:

```
/change.specify "Upgrade from upstream <old> to <new>"
```

The spec should capture:
- **Breaking changes** — from upstream CHANGELOG / release notes
- **New features adopted** — new commands, hooks, extension capabilities
- **Affected extensions/presets** — diff `extension.yml` / `preset.yml` versions before and after merge
- **Constitution drift** — compare `.specify/memory/constitution.md` against the upstream template for new/changed governance principles

To gather this context, run:

```bash
# What extension/preset versions changed
git diff HEAD~1 -- extensions/*/extension.yml presets/*/preset.yml

# What constitution principles changed upstream
git diff upstream/main -- .specify/memory/constitution.md 2>/dev/null || \
  git diff HEAD~1 -- templates/constitution-template.md

# Upstream changelog entries for this merge range
git log --oneline origin/main..upstream/main
```

Feed the output as context to `/change.specify`.

#### Step 7b: Verify with Converge

After tests pass (Step 4), run:

```
/change.converge
```

This runs the full verification machinery on the upgrade:
- **Test Gate** — tests must pass before assessment (same as Step 4, but formalized)
- **4-Pillar Assessment** — Spec Compliance (did the merge cover all upstream changes?), Code Quality (conflict resolution quality), Test Adequacy (are new features tested?), Risk & Evidence (what could break in existing projects?)
- **Evidence bundle** — writes `changes/NNN-upgrade/verify.md` with What Was Checked / What Was NOT Checked / Residual Risks
- **EDD hook** (if installed) — deterministic checks (lint, tests, smoke) + AI evaluation (oracle adequacy, quality gates)

If converge finds gaps → tasks appended to `tasks.md` → fix → re-converge.

#### Step 7c: Review Evidence Bundle

Read `changes/NNN-upgrade/verify.md`:

- **What Was Checked** — confirms tests, lint, 4-pillar all ran
- **What Was NOT Checked** — flags blind spots (e.g., "EDD not installed", "no trace for this change")
- **Residual Risks** — upgrade-specific risks (e.g., "constitution not updated for new governance model", "extension compatibility not verified")

If all pillars >= 70 and no CRITICAL residual risks → upgrade is verified. Proceed to Step 8 (commit/tag/push).

If any pillar < 70 or CRITICAL risks exist → fix the issues, re-run `/change.converge` until verified.

#### Why This Matters

This is the fork's answer to the "self-evolving harness" open problem from the SDD
academic literature: the framework applies its own spec-driven verification discipline
to its own upgrades, rather than relying on manual CHANGELOG reading and ad-hoc testing.
The `agentic-change` preset provides the lifecycle; `converge` provides the verification;
the evidence bundle provides the audit trail.

### Conflict Resolution Strategy

When conflicts occur during merge:

1. **Keep origin changes as base** - Our customizations in `_init_fork.py`, `_core_fork.py`, `_base_fork.py`, `_workflows_fork.py`, `extensions_fork.py` and the `__init__.py` import block must be preserved
2. **Adapt upstream changes** - Integrate upstream improvements to work with our customizations
3. **Test after resolving** - Always run tests before committing

### Common Conflict Points

| File | Why It Conflicts | Resolution |
|------|-----------------|------------|
| `__init__.py` | Import block at top | Use our try/except import pattern with fallback |
| `pyproject.toml` | Version number | Increment version after merge |
| `CHANGELOG.md` | New entries | Add fork-specific entries, preserve upstream section |

### What NOT to Change During Merge

These fork customizations should NEVER be modified unless intentionally updating them:

- `_init_fork.py`, `_core_fork.py`, `_assets_fork.py`, `_base_fork.py`, `_workflows_fork.py`, `extensions_fork.py` - Fork customization modules
- `extensions.py` - Extension namespace configuration
- Bundled extensions in `pyproject.toml` - levelup, evals, architect, product, tdd, edd
- Bundled presets in `pyproject.toml` - agentic-sdlc, agentic-change, agentic-quick

### `templates/` Directory — Always Upstream

The `templates/` directory (core command templates, spec/plan/tasks templates, vscode-settings.json) **stays aligned with upstream**. The fork does NOT customize files under `templates/`.

**Rationale**: All fork-specific command behavior (Phase A/B hooks, Mission Brief approval, branch_template integration, Next Step handovers, semantic theming) lives in the **preset** command files under `presets/agentic-*/commands/`. The core `templates/commands/*.md` files are the upstream baseline installed for all users; fork features layer on top via presets.

**During upstream merges**: Accept all upstream changes to `templates/` without modification. Do not apply fork-specific changes (hook prefix `spec-...`, double-brace escaping, Phase A/B rewrites, Next Step blocks) to `templates/` — those belong only in `presets/agentic-*/commands/`.

#### Template-to-Preset Alignment

Since `agentic-sdlc` preset commands are **full textual copies** (not deltas) of upstream templates, upstream template changes do NOT auto-propagate to presets. After accepting upstream `templates/` changes, port relevant changes to the corresponding preset command files.

**Alignment map** (upstream template → preset command that `replaces:` it):

| Upstream template | Preset command |
|---|---|
| `templates/commands/analyze.md` | `presets/agentic-sdlc/commands/adlc.spec.analyze.md` |
| `templates/commands/checklist.md` | `presets/agentic-sdlc/commands/adlc.spec.checklist.md` |
| `templates/commands/clarify.md` | `presets/agentic-sdlc/commands/adlc.spec.clarify.md` |
| `templates/commands/constitution.md` | `presets/agentic-sdlc/commands/adlc.spec.constitution.md` |
| `templates/commands/converge.md` | `presets/agentic-sdlc/commands/adlc.spec.converge.md` |
| `templates/commands/implement.md` | `presets/agentic-sdlc/commands/adlc.spec.implement.md` |
| `templates/commands/plan.md` | `presets/agentic-sdlc/commands/adlc.spec.plan.md` |
| `templates/commands/specify.md` | `presets/agentic-sdlc/commands/adlc.spec.specify.md` |
| `templates/commands/tasks.md` | `presets/agentic-sdlc/commands/adlc.spec.tasks.md` |
| `templates/plan-template.md` | `presets/agentic-sdlc/templates/plan-template.md` |
| `templates/spec-template.md` | `presets/agentic-sdlc/templates/spec-template.md` |
| `templates/tasks-template.md` | `presets/agentic-sdlc/templates/tasks-template.md` |
| `templates/checklist-template.md` | `presets/agentic-sdlc/templates/checklist-template.md` |
| `templates/constitution-template.md` | `presets/agentic-sdlc/templates/constitution-template.md` |

**Key areas to port**:
- **`scripts:` frontmatter** — new script types (`py:`), flag changes
- **Phase structure** — added/removed/renamed phases
- **Hook invocation format** — `EXECUTE_COMMAND` block changes
- **Path conventions** — `__SPECKIT_COMMAND_*__` placeholder additions/removals
- **Handoff agents** — `speckit.*` agent references (fork renames to `adlc.spec.*`)

**Verification command** (run after porting):
```bash
for cmd in analyze checklist clarify constitution converge implement plan specify tasks; do
  echo "=== $cmd ==="
  diff <(grep -v '^$\|^[[:space:]]*#' templates/commands/$cmd.md) \
       <(grep -v '^$\|^[[:space:]]*#' presets/agentic-sdlc/commands/adlc.spec.$cmd.md) | head -20
done
```

## What Lives in the Fork Modules

The following customization categories live in the fork modules listed in [Fork module layout](#fork-module-layout). The mapping is:

1. **Theming** (`_init_fork.py`): `ACCENT_COLOR`, `BANNER_COLORS`, `accent()`, `accent_style()`
2. **Package Identity** (`_init_fork.py`): `PKG_NAMES`, `TAGLINE`, `get_speckit_version()`, `GITHUB_API_LATEST`
3. **Team Directives** (`_init_fork.py`): `TEAM_DIRECTIVES_DIRNAME`, `sync_team_ai_directives()`, `get_team_directives_path()`
4. **Init hooks** (`_init_fork.py`): `pre_init()`, `post_init()`, `install_project_skills()`
5. **Scaffolding** (`_init_fork.py`): `_scaffold_extensions_to_project()`, `_scaffold_presets_to_project()`, bundled extension/preset installation
6. **Extension Namespaces** (`_core_fork.py`): `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`
7. **Command aliasing** (`_core_fork.py`): `COMMAND_PREFIX`, `build_alias_map()`, `resolve_command_alias()`, `compute_skill_output_name()`, `FORK_COMMAND_NAMESPACES`
8. **MCP config** (`_core_fork.py`): `validate_mcp_config()`, `merge_mcp_configs_report_conflicts()`, `install_mcp_config()`
9. **Native tool detection** (`_base_fork.py`): `detect_native_worktree()` on `IntegrationBase`
10. **Worktree constants** (`extensions_fork.py`): `WORKTREE_DEFAULT_ISOLATION_MODE`, `WORKTREE_VALID_ISOLATION_MODES`, `WORKTREE_MANIFEST_FILENAME`, `WORKTREE_BASE_DIR`, `WORKTREE_TASK_BRANCH_PATTERN`, `WORKTREE_CONFIG_KEY`, `WORKTREE_CONFIG_SCHEMA`
11. **Bundled-asset helpers** (`_assets_fork.py`): `get_bundled_extension_version()`, `get_bundled_extension_path()`, `get_bundled_preset_version()`, `get_bundled_preset_path()`, fork `_locate_bundled_preset()`
12. **Workflow constants** (`_workflows_fork.py`): fork-level workflow catalog/app theming hooks and constants

## What Lives in `__init__.py`

The following tikalk-specific features are still defined directly in `__init__.py` because they require access to internal functions and the central app context:

1. `install_bundled_extensions()` - Installs bundled extensions during init
2. `install_bundled_presets()` - Installs bundled presets during init
3. `sync_team_ai_directives()` - Syncs team-ai-directives repository

These functions are called during init but don't conflict with upstream because they use conditional checks (e.g., `if skip_bundled:`).

The re-export shim `get_preinstalled_extensions()` is also kept here because downstream consumers expect it on the top-level package; the canonical implementation now lives in `_core_fork.py`.

## Fork-Only Files and Directories

The following files and directories exist **only in the fork** and were never present in upstream. During merges, git will show these as "deleted by them" — always reject the deletion.

### `src/specify_cli/_init_fork.py` — Theming, Init Hooks, Scaffolding

**File**: `src/specify_cli/_init_fork.py`

The largest of the fork modules; holds theming, package identity, init hooks, team directives, and bundled extension/preset scaffolding. See [Fork module layout](#fork-module-layout) for the dependency chain.

**Key exports**:
- Theming: `ACCENT_COLOR`, `BANNER_COLORS`, `accent()`, `accent_style()`, `apply_theming_patches()`
- Package Identity: `PKG_NAMES`, `TAGLINE`, `get_speckit_version()`, `GITHUB_API_LATEST`
- Team Directives: `TEAM_DIRECTIVES_DIRNAME`, `sync_team_ai_directives()`, `get_team_directives_path()`
- Init hooks: `pre_init()`, `post_init()`, `install_project_skills()`
- Scaffolding: `_scaffold_extensions_to_project()`, `_scaffold_presets_to_project()`, `_install_bundled_extensions()`, `_install_bundled_presets()`
- Extension Namespaces: `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED` *(defined in `_core_fork.py`)*

**Total**: ~3114 lines of fork-only code, split across six modules:

| Module | Approx. size | Role |
|---|---|---|
| `_init_fork.py` | ~2200 | Theming, init hooks, scaffolding |
| `_core_fork.py` | ~580 | Fork-level extension constants, alias/MCP/skill helpers |
| `_assets_fork.py` | ~130 | Bundled-asset version/path helpers |
| `_base_fork.py` | ~40 | `detect_native_worktree()` |
| `_workflows_fork.py` | ~85 | Workflow catalog/app theming hooks |
| `extensions_fork.py` | ~70 | Worktree constants |

### `src/specify_cli/_assets_fork.py` — Bundled-Asset Fork Helpers

**File**: `src/specify_cli/_assets_fork.py`

Leaf fork module that wraps `_assets.py` (clean upstream) with fork-specific bundled-asset discovery. Moved here in `0.10.0+adlc12` to restore `_assets.py` to clean-upstream.

**Key exports**:
- `_locate_bundled_preset()`: upstream locator + `bundled_presets/` fallback for wheel/uv-tool installs
- `get_bundled_extension_version()`, `get_bundled_extension_path()` (relocated from adlc4)
- `get_bundled_preset_version()`, `get_bundled_preset_path()`

### Test Files

The following test files are fork-only (never present in upstream; during merges they may show as "deleted by them" — always reject the deletion):
- `tests/test_fork_inventory.py` — Fork inventory tests
- `tests/integrations/test_fork_inventory.py` — Integration inventory tests
- `tests/test_bundled_extension_hooks.py` — Bundled extension hook tests
- `tests/test_check_prerequisites_risks.py` — Prerequisite risk tests
- `tests/test_create_new_feature.py` — Feature creation tests
- `tests/auth_helpers.py` — Authentication test helpers
- `tests/test_project_skills.py` — Project skills install tests
- `tests/extensions/git/test_git_worktree.py` — Git worktree lifecycle tests (bash + PowerShell)
- `tests/extensions/git/test_tasks_dag.py` — Tasks DAG generation/validation tests
- `tests/extensions/git/test_tasks_dag_explicit_mode.py` — DAG explicit-mode tests
- `tests/extensions/test_evals_extension.py` — Bundled evals extension tests
- `tests/scripts/bash/test_tasks_meta_utils.py` — Tasks meta-utils script tests
- `tests/test_security_graders.py` — Security grader tests
- `tests/test_trace_command.py` — Trace command tests
- `tests/test_verify_command.py` — Verify command tests
- `tests/test_help_output.py` — Help output theming tests
- `tests/test_quick_extension.py` — Quick extension tests (fork removed the extension but kept the tests)
- `tests/test_setup_plan.py` — Setup-plan script tests
- `tests/test_smart_trace_validation.py` — Smart trace validation tests
- `tests/test_spec_verify_hook_registration.py` — Spec verify hook registration tests

> **Note**: `tests/test_team_directives.py` was deleted by the fork itself in `0.12.8+adlc3` (commit `3d54b432`) when governance was repackaged as the bundled `extensions/team-ai-directives/` extension. It is NOT fork-only in the "reject deletion" sense — the fork intentionally removed it.

## Git Extension Worktree & Task-Execution Feature (0.9.5+adlc2)

The fork adds feature-level git worktree isolation and DAG-aware task execution to the bundled `git` extension. The work follows obra/superpowers `using-git-worktrees` principles (provenance-based cleanup, native tool preference) while staying inside the existing `git` extension rather than shipping a separate one.

### Why enhance `git` rather than add a separate extension

The `git` extension already owns `git.feature`, `git.validate`, `git.commit`, and the related hook pipeline (auto-commit before/after every core command). Feature-level isolation is a natural fit for `git.feature`, and the task-execution commands (`git.task`, `git.task-merge`, `git.task-list`) only make sense as siblings of `git.feature`. Adding a separate `worktrees` extension would have duplicated the `git.feature` hook wiring and forced an inter-extension dependency for the most common path.

### What's new in `git.feature`

`git.feature` now accepts worktree-isolation flags on both bash and PowerShell. Source priority is CLI flag > `SPECIFY_ISOLATION_MODE` env > `git-config.yml` `isolation_mode` key > default `branch`.

| Bash flag | PowerShell param | Meaning |
|---|---|---|
| `--worktree` | `-Worktree` | Force worktree mode (shorthand for `--isolation-mode worktree`) |
| `--branch-mode` | `-BranchMode` | Force branch mode (shorthand for `--isolation-mode branch`) |
| `--isolation-mode <branch\|worktree>` | `-IsolationMode <branch\|worktree>` | Explicit mode selection |
| `--base <branch>` | `-Base <branch>` | Pin the base ref (used by `git worktree add`); defaults to the current branch |

When worktree mode is selected, the script:
1. Calls `worktree-utils.sh create-feature-worktree --feature <branch> [--base <base>]` (or the PowerShell counterpart) instead of `git checkout -b`
2. Writes a `git.worktree-manifest.json` to the worktree root for provenance tracking
3. Returns `ISOLATION_MODE`, `WORKTREE_PATH`, and `MANIFEST_PATH` in the JSON output (in addition to `BRANCH_NAME`/`FEATURE_NUM`)
4. Does **not** `cd` into the worktree — the calling agent must `cd "$WORKTREE_PATH"` separately

Unrecognized isolation mode values are rejected with `Error: --isolation-mode must be 'branch' or 'worktree'`.

### New commands

Three new `git` extension commands were added in this release. They are worktree-mode only and refuse to run in a primary checkout.

| Command | Purpose | Script |
|---|---|---|
| `speckit.git.task` (`git.task`) | Create/resume a task branch in the current feature worktree and dispatch the task to a subagent | `worktree-utils.sh create-task-branch` |
| `speckit.git.task-merge` (`git.task-merge`) | Merge a completed task branch back into the feature branch (`git merge --no-ff`); delegates conflict resolution to a subagent; then unregisters the task branch via `worktree-utils.sh merge-task-branch` | `worktree-utils.sh merge-task-branch` |
| `speckit.git.task-list` (`git.task-list`) | List active task branches in the current worktree (with ahead/behind counts); supports `--json` and `--ids-only` output | `worktree-utils.sh read-manifest` |

These commands are declared in `extensions/git/extension.yml` and reference `.md` files under `extensions/git/commands/`. The `is-in-worktree` script (exit 0 = primary, exit 2 = inside a worktree) is the gate that all three check before proceeding.

### New scripts

Two new dispatcher scripts (one Bash, one PowerShell) were added. They follow the project's single-file dispatcher pattern (matching `auto-commit.sh`): the script name is a subcommand, and `<subcommand> [args...]` is dispatched via a `case` (bash) or `switch` (PS1) block.

| Script | Subcommands | Purpose |
|---|---|---|
| `worktree-utils.{sh,ps1}` | `create-feature-worktree`, `remove-feature-worktree`, `create-task-branch`, `remove-task-branch`, `merge-task-branch`, `is-in-worktree`, `list-worktrees`, `read-manifest`, `finish-feature` | All worktree lifecycle operations, with JSON output to stdout and human-readable status to stderr |
| `tasks-dag.{sh,ps1}` | `generate`, `validate`, `show`, `classify`, `coalesce` | DAG generation from `tasks.md` (wave computation, parallel-marker validation, coalescing suggestions) |

Both scripts are ASCII-only. The PowerShell version uses single-dash params (`-TasksMd`, `-Dag`, `-Feature`, `-TaskId`); the bash version uses double-dash (`--tasks-md`, `--dag`, `--feature`, `--task-id`). The header comment in each PowerShell script documents this divergence.

#### Worktree manifest schema

Each feature worktree has a `git.worktree-manifest.json` at its root. The manifest is gitignored (`tasks_dag.json`, `git.worktree-manifest.json`, and `.worktrees/` are added to `.gitignore` by `git.setup-ignore`). Schema:

```json
{
  "schema_version": "1.0",
  "feature": "003-user-auth",
  "feature_branch": "003-user-auth",
  "worktree_path": ".worktrees/003-user-auth",
  "created_at": "2026-06-07T15:30:00Z",
  "task_branches": [
    {"id": "T007", "branch": "003-user-auth--task-7-add-oauth-provider", "created_at": "2026-06-07T15:35:12Z"}
  ],
  "provenance": {
    "created_by": "worktree-utils.sh create-feature-worktree",
    "version": "1.0"
  }
}
```

`finish-feature` (and `remove-feature-worktree`) use this manifest to clean up: delete all listed task branches, remove the worktree, then delete the feature branch. `--keep-branch` opts out of the final feature-branch deletion; `--force` opts out of the safety checks (manifest missing, task branches remaining, dirty worktree).

#### DAG JSON schema

`tasks-dag.sh generate` writes `tasks_dag.json` alongside `tasks.md` (the same path with a `.dag.json` suffix). Schema:

```json
{
  "schema_version": "1.0",
  "feature": "003-user-auth",
  "tasks": [
    {"id": "T001", "title": "...", "files": ["src/auth.py"], "story": "Setup", "parallel": false, "execution_wave": 0, "depends_on": []}
  ],
  "execution_waves": [[0, 1, 2], [3, 4, 5], ...],
  "stats": {"total_tasks": 12, "parallel_tasks": 8, "total_waves": 5, "stories": 2}
}
```

`execution_wave` is 0-based per task. `execution_waves` is the canonical 1-based wave grouping. The DAG is consumed by the ADLC preset's `adlc.spec.implement` (Phase 0: read `tasks_dag.json`).

### Auto-commit task-mode prefixing

`auto-commit.sh` and `auto-commit.ps1` now accept `--mode <sync|parallel|async>` and `--task-id <TNNN>`. When the mode is `parallel` or `async` and a task-id is supplied, the commit subject is prefixed with `[TNNN] ` (e.g., `[T007] [Spec Kit] Auto-commit after implement`). The prefix is idempotent (re-prefixing an already-prefixed subject is a no-op). Env-var fallback: `SPECKIT_TASK_MODE` / `SPECKIT_TASK_ID` (precedence: flag > env > default `sync`).

This is what makes subagent-dispatched task work show up cleanly in `git log` per-task, without forcing the implementer to construct a custom message.

### Setup-ignore rules

`git.setup-ignore` (and its `.ps1` sibling) was extended with four new ignore rules:

| Rule | What it covers |
|---|---|
| `.worktrees/` | All feature worktrees (ephemeral; not for version control) |
| `tasks_dag.json` | DAG sidecar written by `tasks-dag.sh generate` (ephemeral; rebuilt on every `tasks` run) |
| `git.worktree-manifest.json` | Worktree manifest (ephemeral; rebuilt by `worktree-utils.sh create-feature-worktree`) |
| `.speckit-merge-conflict-*.md` | Merge-conflict resolution prompts (ephemeral; deleted after conflict resolution) |

The existing `setup-gitignore.{sh,ps1}` script was extended (not duplicated) — the markdown command file `speckit.git.setup-ignore.md` was updated in lockstep to keep the user-facing documentation and the script's actual ignore list in sync.

### Configuration

`extensions/git/config-template.yml` was extended with three new top-level sections:

```yaml
isolation_mode: branch                    # branch | worktree

worktrees:
  base_dir: .worktrees
  manifest_filename: git.worktree-manifest.json
  task_branch_pattern: "{feature}--task-{id}-{task-slug}"

task_execution:
  default_mode: sync                       # sync | parallel | async
  parallel_threshold_wave_size: 2
  delegate_merge_conflicts: true

task_generation:
  parallel_marker_default: true
  coalesce_simple_tasks: true
  max_tasks_per_story: 8
```

`isolation_mode` is the only key the `git.feature` script actually reads today (via `grep -E '^[[:space:]]*isolation_mode'`); the other sections are read by the ADLC preset's `adlc.spec.implement` and `tasks` template.

### New tests

Three new test files cover the worktree scripts, DAG scripts, and the new `git.feature` / `auto-commit` / `setup-gitignore` flags:

- `tests/extensions/git/test_git_worktree.py` (55 tests total — bash + PowerShell)
- `tests/extensions/git/test_tasks_dag.py` (33 tests total — bash + PowerShell)
- Additions to `tests/extensions/git/test_git_extension.py`: `TestAutoCommitTaskModeBash/PowerShell` (18 tests), `TestCreateFeatureIsolationModeBash/PowerShell` (17 tests), `TestSetupGitignoreWorktreeBash/PowerShell` (6 tests)

These tests use the existing `_setup_project` harness from `test_git_worktree.py` and require no `PKG_NAMES` skip-guards — the worktree/DAG scripts are designed to run identically upstream and in the fork (no fork-only constants referenced; defaults are hard-coded in the scripts).

## Testing

Run tests to verify customization module works correctly:

```bash
python3 -c "
from src.specify_cli import ACCENT_COLOR, BANNER_COLORS, accent, accent_style
from src.specify_cli.extensions import EXTENSION_COMMAND_NAME_PATTERN

print('ACCENT_COLOR:', ACCENT_COLOR)
print('accent test:', accent('Test', bold=True))
print('Extension pattern:', EXTENSION_COMMAND_NAME_PATTERN.pattern)
"
```

Expected output:
```
ACCENT_COLOR: #f47721
accent test: [bold #f47721]Test[/]
Extension pattern: ^(?:speckit|adlc)\.([a-z0-9-]+)\.([a-z0-9-]+)$
```

## Tag Management

**IMPORTANT**: The fork uses the tag pattern `agentic-sdlc-v*` to distinguish from upstream `v*` tags.

### Why This Matters

Upstream uses tags like `v0.5.0`, `v0.5.1`, etc. These tags from origin trigger GitHub Actions workflows designed for upstream, which causes confusion and wasted CI runs.

### Tag Naming Convention

- **Fork tags**: `agentic-sdlc-v0.3.11` (our releases)
- **Upstream tags**: `v0.5.0` (from upstream/main, don't push these to origin)

### Before Pushing Tags

Always check before pushing to avoid triggering upstream workflows:

```bash
# Check what tags you're about to push
git push origin --dry-run --tags

# List only fork-pattern tags
git tag -l "agentic-sdlc-*"
```

### Re-tagging and GitHub Release State

When a tag is force-replaced (deleted and re-created), the associated GitHub Release becomes a **draft** and must be manually published:

1. After pushing the re-created tag, visit: `https://github.com/tikalk/agentic-sdlc-spec-kit/releases`
2. Find the draft release for the tag
3. Click **Edit** → verify content → **Publish release**

This is required because GitHub does not auto-publish releases on tag re-creation — the release stays in draft state until manually confirmed.

### Removing Stray Tags

If upstream tags get pushed to origin by mistake, remove them:

```bash
# Local cleanup
git tag -l "v*" | xargs -I {} git tag -d {}

# Remote cleanup (example for v0.5.0)
git push origin --delete v0.5.0
```

Or delete multiple at once:
```bash
git push origin --delete v0.0.1 v0.1.0 v0.2.0 v0.5.0
```

## Test Merge Strategy

Tests should be **manually merged** (NOT `git checkout --theirs tests/`):

1. **Accept upstream test refactoring** for new extracted modules (`test_console_imports.py`, `test_version_imports.py`, `test_utils_assets_imports.py`)
2. **Keep fork-only test files** that upstream shows as "deleted" (they were never upstream):
   - `tests/test_fork_inventory.py`
   - `tests/integrations/test_fork_inventory.py`
   - `tests/test_bundled_extension_hooks.py`
   - `tests/test_check_prerequisites_risks.py`
   - `tests/test_create_new_feature.py`
   - `tests/auth_helpers.py`
   - `tests/test_team_directives.py`
3. **Merge and re-apply** `PKG_NAMES` skip guards to upstream tests that expect upstream-only behavior
4. **New fork tests are additive** — they should not conflict with upstream tests

### Skip Guard Pattern

```python
def test_complete_file_inventory_sh(self, tmp_path):
    """Every file produced by specify init --integration <key> --script sh."""
    from specify_cli import PKG_NAMES
    if any("agentic-sdlc" in pkg for pkg in PKG_NAMES):
        import pytest
        pytest.skip("Fork has bundled extensions/presets with different file counts")
    # ... rest of test
```

## _version.py Override

Upstream `_version.py` hardcodes GitHub API URLs pointing to `github/spec-kit`:

```python
GITHUB_API_LATEST = "https://api.github.com/repos/github/spec-kit/releases/latest"
```

The fork should override these via `_init_fork.py`:
- `GITHUB_API_LATEST` → point to `tikalk/agentic-sdlc-spec-kit` releases
- Install instructions → reference fork's repo URL

## CI Troubleshooting

This section documents common CI failures and how to debug them.

### Common Issues

#### 1. Unresolved Merge Conflict Markers

**Symptom**: ruff fails with `invalid-syntax: Expected ,, found <<`

**Example error**:
```
invalid-syntax: Expected `,`, found `<<`
    --> src/specify_cli/__init__.py:1064:1
     |
1064 | <<<<<<< HEAD
     | ^^
```

**Cause**: Merge conflict not fully resolved - `<<<<<<< HEAD` markers remain in code

**Fix**:
```bash
# Find remaining conflict markers
grep -rn "<<<<<< HEAD" src/

# Fix in editor (remove the marker line)
# Verify fix
uvx ruff check src/

# Commit and push
git add -A
git commit -m "fix: remove unresolved merge conflict marker"
git push origin main
```

**Prevention**: Always run `uvx ruff check src/` locally before pushing

#### 2. Test Failures After Merge

**Symptom**: pytest fails after upstream merge

**Fix**:
```bash
# Run tests locally
uv run pytest

# If tests fail, investigate and fix
# Then commit and push
```

#### 3. Python Version Compatibility

**Symptom**: Tests fail on specific Python versions in CI matrix

**Fix**: Ensure code is compatible with Python 3.11, 3.12, and 3.13

### Debugging CI Failures

1. **Check the workflow run**: Look at the GitHub Actions logs for the specific error
2. **Reproduce locally**: Run the same commands locally:
   ```bash
   uvx ruff check src/
   uv run pytest
   ```
3. **Check for conflicts**: `grep -rn "<<<<<<" src/`
4. **Review recent changes**: `git log --oneline -10`

## Lessons Learned from Upstream Merge

This section documents hard-won lessons from merging upstream changes.

### Critical Rules

1. **NEVER use `git checkout --theirs` for pyproject.toml or __init__.py**
   - Using `--theirs` on pyproject.toml discards the fork version entirely
   - The stash with fork changes gets lost
   - Always manually edit to preserve fork values after merge

2. **Use upstream as clean base, then ADD fork customizations**
   - Merge upstream/main cleanly first
   - Then manually add fork-specific functions/values AFTER merge
   - This prevents accidental overwriting

3. **The import block is the SINGLE SOURCE OF TRUTH**
   - All fork customizations must be in the try/except import block
   - Both the imports AND the fallback functions must be complete
   - Missing fallbacks = runtime errors when the fork modules are not available

### pyproject.toml Wheel Paths

The fork uses `specify_cli/core_pack/...` paths (NOT root-level directories):

```toml
[tool.hatch.build.targets.wheel.force-include]
# Tikalk bundled extensions
"extensions/levelup" = "specify_cli/core_pack/extensions/levelup"
"extensions/evals" = "specify_cli/core_pack/extensions/evals"
"extensions/architect" = "specify_cli/core_pack/extensions/architect"
"extensions/product" = "specify_cli/core_pack/extensions/product"
"extensions/tdd" = "specify_cli/core_pack/extensions/tdd"  # Don't forget!
# Tikalk bundled presets
"presets/agentic-sdlc" = "specify_cli/bundled_presets/agentic-sdlc"
# Core pack assets
"templates/agent-file-template.md" = "specify_cli/core_pack/templates/agent-file-template.md"
# ... etc
```

**Common mistake**: Using root-level paths like `"extensions/levelup" = "extensions/levelup"` will cause build errors because those paths don't exist inside the wheel.

### __init__.py Required Customizations

After merging upstream, ensure these are present in __init__.py:

1. **Full import block** (see above) - with ALL imports and fallbacks
2. **TEAM_DIRECTIVES_DIRNAME** - for team-ai-directives feature
3. **_run_git_command()** - helper for git operations
4. **sync_team_ai_directives()** - clones/updates team repo
5. **compute_skill_output_name()** - delegates to `_core_fork`
6. **TAGLINE** - fork's tagline (different from upstream)

### __init__.py Theming

Apply theming to all UI elements using `accent_style()` and `accent()`:

- `show_banner()`: Use `BANNER_COLORS` and `accent_style()` for tagline
- StepTracker title: `f"[{accent_style()}]{self.title}"`
- "Selected AI assistant:" and "Selected script type:": Use `accent()`
- "Project ready.": Use `accent(bold=True)`
- All Panel borders: Use `border_style=accent_style()`
- Next Steps and Enhancement Commands panels

### Tracker Steps

The init flow must include these steps in order:

```python
for key, label in [
    ("chmod", "Ensure scripts executable"),
    ("project-skills", "Install Projects skills"),
    ("constitution", "Constitution setup"),
    ("git", "Install git extension"),
    ("workflow", "Install bundled workflow"),
    ("team-directives", "Team AI Directives setup"),
    ("extensions", "Install bundled extensions"),
    ("presets", "Install bundled presets"),
]:
    tracker.add(key, label)

# Final MUST be added LAST
tracker.add("final", "Finalize")
```

### Command Prefix

The fork uses `/spec.*` prefix instead of upstream's `/speckit.*`:

```python
def _display_cmd(name: str) -> str:
    # ... agent-specific cases ...
    # Fork default: use "spec." prefix instead of "speckit."
    return f"/spec.{name}"
```

### Backup Before Merge

Always create a backup branch BEFORE merging:

```bash
git branch backup-before-upstream-merge-$(date +%Y%m%d-%H%M%S)
```

This allows you to:
- Compare against backup to see exactly what changed
- Restore any accidentally lost customizations
- Debug issues by comparing working vs broken state

### Integration Test File Inventory Tests

The fork bundles extensions, presets, and skills that aren't present in upstream. This causes the `test_complete_file_inventory_*` tests to fail because they expect upstream's file count.

**Solution**: Skip these tests on the fork by checking `PKG_NAMES`:

```python
def test_complete_file_inventory_sh(self, tmp_path):
    """Every file produced by specify init --integration <key> --script sh."""
    from specify_cli import PKG_NAMES
    if any("agentic-sdlc" in pkg for pkg in PKG_NAMES):
        import pytest
        pytest.skip("Fork has bundled extensions/presets with different file counts")
    # ... rest of test
```

This check exists in:
- `tests/integrations/test_integration_base_markdown.py`
- `tests/integrations/test_integration_base_skills.py`

The tests pass upstream (no skip) and skip on the fork (with skip), ensuring CI passes in both environments.
