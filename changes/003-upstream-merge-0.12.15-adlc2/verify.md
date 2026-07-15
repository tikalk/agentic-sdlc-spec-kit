# Verify: Upstream merge — 2 post-0.12.15 commits

**Change**: Upstream merge — 2 commits (post-0.12.15, on 0.12.16.dev0 line)
**Fork version**: `0.12.15+adlc1` → `0.12.15+adlc2`
**Date**: 2026-07-15
**Assisted-by**: opencode (model: glm-5.2, autonomous)

## Test Gate

- **ruff**: All checks passed
- **pytest** (`tests/test_workflows.py`): 613 passed, 1 skipped
- **Smoke test**: `specify init /tmp/merge-test2 --integration claude --script sh --ignore-agent-tools` → exit 0, version reports `0.12.15+adlc2`

## 4-Pillar Assessment

### 1. Spec Compliance — Did the merge cover all upstream changes?

**Score: 100/100**

- Both upstream commits merged: #3519 (while/do-while guard), #3516 (PyPI docs).
- 1 conflict resolved (README.md).
- All other files (5) auto-merged cleanly.
- New file `docs/install/pypi.md` adopted.

### 2. Code Quality — Conflict resolution quality

**Score: 95/100**

- **README.md**: kept fork's install instructions (tikalk repo, `uvx` one-time option); dropped upstream's PyPI install block because the fork doesn't publish to PyPI under the upstream package name — adding it would mislead fork users.
- No `--theirs` or `--ours` blanket strategies used.
- `ruff check src/` — clean.

### 3. Test Adequacy — Are new features tested?

**Score: 100/100**

- Upstream's 6 new parametrized tests for #3519 (while/do-while non-list steps) adopted and passing.
- Tests cover: dict, str, int as bad `steps` values; condition true/false paths.

### 4. Risk & Evidence — What could break in existing projects?

**Score: 95/100**

**What Was Checked**:
- `tests/test_workflows.py` — 613 passed, 1 skipped
- Lint (ruff) — clean
- Smoke test — creates project successfully
- Version string — `0.12.15+adlc2`

**Residual Risks**:
1. **While/do-while guard (#3519)**: workflows with a non-list `steps` in a while/do-while that previously crashed with `AttributeError` will now get a clean FAILED result. This is an improvement — the workflow was already broken, just crashily.
2. **No CRITICAL residual risks identified.**

## Verdict

All pillars ≥ 95. No CRITICAL residual risks. **Upgrade verified.** Proceed to commit, tag, and push.
