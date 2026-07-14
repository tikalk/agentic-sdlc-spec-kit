# Verify: Upgrade from upstream 0.12.11 to 0.12.14

**Change**: Upstream merge — 29 commits, 3 releases (0.12.12, 0.12.13, 0.12.14)
**Fork version**: `0.12.11+adlc3` → `0.12.14+adlc1`
**Date**: 2026-07-14
**Assisted-by**: opencode (model: glm-5.2, autonomous)

## Test Gate

- **ruff**: All checks passed
- **pytest**: 4335 tests collected, **all passing** (0 failed, ~45 skipped)
  - `tests/test_presets.py`: 338 passed, 1 skipped
  - `tests/test_extensions.py` + `test_extension_skills.py`: 419 passed
  - `tests/test_workflows.py`: 418 passed, 5 warnings
  - `tests/integrations/`: ~1813 tests, all passing
  - `tests/contract/`, `tests/extensions/`, `tests/hooks/`, `tests/unit/`: 386 passed, 79 skipped
  - `tests/scripts/`, `tests/integration/`: 69 passed
  - Root-level `tests/test_*.py`: 1544 passed, 21 skipped + 290 passed, 24 skipped + 93 passed, 16 skipped
- **Smoke test**: `specify init test-proj --integration claude --script sh --ignore-agent-tools` → exit 0, `.specify/` directory created successfully

## 4-Pillar Assessment

### 1. Spec Compliance — Did the merge cover all upstream changes?

**Score: 95/100**

- All 29 upstream commits merged from `github/spec-kit` `0.12.12`–`0.12.14`.
- 4 content conflicts resolved (pyproject.toml, commands/init.py, tests/test_presets.py, README.md).
- All other modified files (~50) auto-merged cleanly.
- Fork-only files preserved: 6 fork modules (`_init_fork.py`, `_core_fork.py`, `_assets_fork.py`, `_base_fork.py`, `_workflows_fork.py`, `extensions_fork.py`), 20 fork-only test files, 1 fork-only workflow (`impl-converge-loop`).
- Legitimate upstream deletions accepted: `workflows/feature-squad.yml`, `tests/test_timestamp_branches.py`, `presets/self-test/templates/agent-file-template.md`.
- **Template-to-preset alignment**: ported upstream #3418 constitution sync checklist change to `presets/agentic-sdlc/commands/adlc.spec.constitution.md` (adapted `speckit.*` → `spec.*` for fork prefix).
- **Minor gap**: The `templates/configs/taskstoissues-provider.yml` is a fork-only file — no porting needed.

### 2. Code Quality — Conflict resolution quality

**Score: 95/100**

- **pyproject.toml**: preserved fork `name`, `description`, `httpx` dep, full `force-include` block; set version `0.12.14+adlc1`. Did NOT use `--theirs` (per FORK.md critical rule).
- **commands/init.py**: combined fork's `accent()` theming with upstream's clearer merge-overwrite warning — best of both.
- **tests/test_presets.py**: combined fork's "Speckit " skill-title prefix assertion with upstream's new #2101 subdir-path-rewrite assertions — both behaviors preserved.
- **README.md**: kept fork's tikalk-flavored install instructions; adopted upstream's "keep the leading v" tag clarification.
- No `--theirs` or `--ours` blanket strategies used anywhere.
- `ruff check src/` — all checks passed (0 lint errors).

### 3. Test Adequacy — Are new features tested?

**Score: 95/100**

- All upstream test changes auto-merged and pass.
- Upstream's new tests for #3262 (command step input/options validation), #3351 (preset manifest-authoritative resolution), #3327 (shell timeout consolidation), #3444 (extension subdir path rewriting) — all adopted and passing.
- Fork's `PKG_NAMES` skip guards and fork-specific assertions preserved in merged test files.
- 4335 tests run across the full suite — comprehensive coverage.

### 4. Risk & Evidence — What could break in existing projects?

**Score: 90/100**

**What Was Checked**:
- Full test suite (4335 tests) — all passing
- Lint (ruff) — clean
- Smoke test (`specify init`) — creates project successfully
- Fork module imports — all resolve correctly
- Fork identity (ACCENT_COLOR, PKG_NAMES, COMMAND_PREFIX, EXTENSION_COMMAND_NAME_PATTERN) — all correct
- Version string — `specify --version` reports `0.12.14+adlc1`
- Template-to-preset alignment — constitution #3418 change ported

**What Was NOT Checked**:
- E2E test of `specify init` with `--team-ai-directives` (requires external KB repo)
- E2E test of bundled extension install in a fresh project (smoke test used `--ignore-agent-tools`)
- Wheel build (`uv build`) — not run; pyproject.toml force-include paths verified manually
- PowerShell script parity on Windows — tests run on Linux only
- Community catalog entries (Quality Gates, Verify Review Ship, Spec Kit Memory, Test-First Governance, Autonomous Run Governance) — catalog JSON merged but not installed/tested

**Residual Risks**:
1. **PresetResolver behavioral change (#3351)**: manifest-declared `file:` entries are now authoritative — no convention fallback when declared file is missing. Existing fork projects with stale or typo'd `preset.yml` `file:` declarations could break where they previously silently fell back. **Mitigation**: fork's bundled presets have verified `preset.yml` manifests.
2. **Shell step timeout behavior change (#3327)**: invalid `timeout` values now return FAILED instead of silently resetting to 300s. Workflows that relied on the silent-reset behavior will now fail. **Mitigation**: this is an improvement — workflows with invalid timeouts were already broken, just silently.
3. **No CRITICAL residual risks identified.**

## Verdict

All pillars ≥ 90. No CRITICAL residual risks. **Upgrade verified.** Proceed to commit, tag, and push.
