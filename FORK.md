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
| `_extension_fork.py` | Leaf — pure constants (`EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`) | (none) |
| `_core_fork.py` | Alias resolution, MCP config, skill naming, preinstalled extension queries | `_extension_fork` |
| `_init_fork.py` | Theming, package identity, init hooks (`pre_init`/`post_init`), scaffolding, skill installation | `_core_fork`, `_extension_fork`, `_assets_fork` |
| `base_fork.py` | Fork-level helpers on `IntegrationBase` (e.g. `detect_native_worktree()`) | (none) |
| `extensions_fork.py` | Constants and schemas for fork-specific extension features (e.g. worktree config) | (none) |

**Dependency direction (locked):**

```
_assets_fork.py     (leaf)
_extension_fork.py  (leaf)
        ^
        |
_core_fork.py
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
- Version: `0.10.0+adlc6`
- Tag: `agentic-sdlc-v0.10.0+adlc6`

When a fork release changes only bundled extension behavior, keep the CLI version on the upstream base (for example `0.10.0+adlc3`) and bump the affected extension manifest version independently (for example `extensions/git/extension.yml` to `1.5.0`).

### Version History

| Version | Date | Base Upstream | Changes |
|---------|------|---------------|---------|
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

- `_extension_fork.py` — `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`
- `_core_fork.py` — `COMMAND_PREFIX`, `build_alias_map`, `resolve_command_alias`, `compute_skill_output_name`, MCP config helpers, `get_preinstalled_extensions`
- `_init_fork.py` — `ACCENT_COLOR`, `BANNER_COLORS`, `TAGLINE`, `PKG_NAMES`, `TEAM_DIRECTIVES_DIRNAME`, `accent`, `accent_style`, `apply_theming_patches`, `pre_init`, `post_init`, `get_team_directives_path`, `sync_team_ai_directives`, `get_speckit_version`, `GITHUB_API_LATEST`
- `base_fork.py` — `detect_native_worktree()`
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
| EXTENSION_NAMESPACES | ["speckit"] | ["speckit", "adlc"] | `_extension_fork` |
| EXTENSION_ALIAS_PATTERN_ENABLED | False | True | `_extension_fork` |
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
    from ._extension_fork import EXTENSION_NAMESPACES, EXTENSION_ALIAS_PATTERN_ENABLED
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
- Fork customizations stay in `_init_fork.py` / `_core_fork.py` / `_extension_fork.py` and the `__init__.py` import block
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

### Conflict Resolution Strategy

When conflicts occur during merge:

1. **Keep origin changes as base** - Our customizations in `_init_fork.py`, `_core_fork.py`, `_extension_fork.py`, `base_fork.py`, `extensions_fork.py` and the `__init__.py` import block must be preserved
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

- `_init_fork.py`, `_core_fork.py`, `_extension_fork.py` - Fork customization modules
- `base_fork.py`, `extensions_fork.py` - Fork-level helpers and feature constants
- `extensions.py` - Extension namespace configuration
- Bundled extensions in `pyproject.toml` - levelup, architect, quick, product, tdd
- Bundled presets in `pyproject.toml` - agentic-sdlc

## What Lives in the Fork Modules

The following customization categories live in the fork modules listed in [Fork module layout](#fork-module-layout). The mapping is:

1. **Theming** (`_init_fork.py`): `ACCENT_COLOR`, `BANNER_COLORS`, `accent()`, `accent_style()`
2. **Package Identity** (`_init_fork.py`): `PKG_NAMES`, `TAGLINE`, `get_speckit_version()`, `GITHUB_API_LATEST`
3. **Team Directives** (`_init_fork.py`): `TEAM_DIRECTIVES_DIRNAME`, `sync_team_ai_directives()`, `get_team_directives_path()`
4. **Init hooks** (`_init_fork.py`): `pre_init()`, `post_init()`
5. **Scaffolding** (`_init_fork.py`): `_scaffold_extensions_to_project()`, `_scaffold_presets_to_project()`, bundled extension/preset installation
6. **Extension Namespaces** (`_extension_fork.py`): `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED`, `FORK_INSTALL_COMMAND`
7. **Command aliasing** (`_core_fork.py`): `COMMAND_PREFIX`, `build_alias_map()`, `resolve_command_alias()`, `compute_skill_output_name()`, `FORK_COMMAND_NAMESPACES`
8. **MCP config** (`_core_fork.py`): `validate_mcp_config()`, `merge_mcp_configs_report_conflicts()`, `install_mcp_config()`
9. **Native tool detection** (`base_fork.py`): `detect_native_worktree()` on `IntegrationBase`
10. **Worktree constants** (`extensions_fork.py`): `WORKTREE_DEFAULT_ISOLATION_MODE`, `WORKTREE_VALID_ISOLATION_MODES`, `WORKTREE_MANIFEST_FILENAME`, `WORKTREE_BASE_DIR`, `WORKTREE_TASK_BRANCH_PATTERN`, `WORKTREE_CONFIG_KEY`, `WORKTREE_CONFIG_SCHEMA`
11. **Bundled-asset helpers** (`_assets_fork.py`): `get_bundled_extension_version()`, `get_bundled_extension_path()`, `get_bundled_preset_version()`, `get_bundled_preset_path()`, fork `_locate_bundled_preset()`

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
- Init hooks: `pre_init()`, `post_init()`
- Scaffolding: `_scaffold_extensions_to_project()`, `_scaffold_presets_to_project()`, `_install_bundled_extensions()`, `_install_bundled_presets()`
- Extension Namespaces: `EXTENSION_NAMESPACES`, `EXTENSION_ALIAS_PATTERN_ENABLED` *(also re-exported from `_extension_fork.py`)*

**Total**: ~1700 lines of fork-only code, split across five modules:

| Module | Approx. size | Role |
|---|---|---|
| `_init_fork.py` | ~1000 | Theming, init hooks, scaffolding |
| `_core_fork.py` | ~400 | Alias/MCP/skill helpers |
| `_assets_fork.py` | ~150 | Bundled-asset version/path helpers |
| `_extension_fork.py` | ~30 | Leaf constants |
| `base_fork.py` | ~15 | `detect_native_worktree()` |
| `extensions_fork.py` | ~25 | Worktree constants |

### `src/specify_cli/_assets_fork.py` — Bundled-Asset Fork Helpers

**File**: `src/specify_cli/_assets_fork.py`

Leaf fork module that wraps `_assets.py` (clean upstream) with fork-specific bundled-asset discovery. Moved here in `0.10.0+adlc12` to restore `_assets.py` to clean-upstream.

**Key exports**:
- `_locate_bundled_preset()`: upstream locator + `bundled_presets/` fallback for wheel/uv-tool installs
- `get_bundled_extension_version()`, `get_bundled_extension_path()` (relocated from adlc4)
- `get_bundled_preset_version()`, `get_bundled_preset_path()`

### Test Files

The following test files are fork-only:
- `tests/test_fork_inventory.py` — Fork inventory tests
- `tests/integrations/test_fork_inventory.py` — Integration inventory tests
- `tests/test_bundled_extension_hooks.py` — Bundled extension hook tests
- `tests/test_check_prerequisites_risks.py` — Prerequisite risk tests
- `tests/test_create_new_feature.py` — Feature creation tests
- `tests/auth_helpers.py` — Authentication test helpers
- `tests/test_team_directives.py` — Team AI directives tests

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
"extensions/quick" = "specify_cli/core_pack/extensions/quick"
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
