# Post-Initialization Configuration Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `specify config` command that safely displays and changes selected initialization settings and exposes existing extension management below `config extension`.

**Architecture:** Add a small `commands/config.py` Typer group registered by the root CLI. It reads and writes the existing `.specify/init-options.json` helpers, delegates `config extension` to the existing extension Typer group, and calls the existing team-directives synchronization facilities for source changes. It must not replace integration lifecycle commands.

**Tech Stack:** Python 3.11+, Typer, Rich, pytest `CliRunner`.

**Spec:** User-approved chat design: list/get and safe mutation of `script`, `feature-numbering`, and `team-ai-directives`; extension management exposed at `config extension`; integration ownership remains with `specify integration`.

## Global Constraints

- `specify integration use` remains the only way to change the active integration or skills layout.
- Persist configuration through `save_init_options()` so formatting remains consistent.
- Validate every public input before writing state.
- Reuse the existing extension group instead of duplicating extension lifecycle behavior.
- Changing or unsetting team directives must preserve user-created skills and warn about copied domain skills.

---

### Task 1: Add the configuration command with safe read/write behavior

**Files:**

- Create: `src/specify_cli/commands/config.py`
- Modify: `src/specify_cli/__init__.py`
- Test: `tests/test_config_cli.py`

**Interfaces:**

- Consumes: `load_init_options(project_root)`, `save_init_options(project_root, options)`, `_require_specify_project()`.
- Produces: `specify config list`, `get`, `set`, and `unset` commands; `specify config extension ...` forwards to the existing extension group.

- [x] **Step 1: Write failing CLI tests**

```python
def test_config_set_script_persists_valid_value(project, monkeypatch):
    monkeypatch.chdir(project)
    result = runner.invoke(app, ["config", "set", "script", "py"])
    assert result.exit_code == 0
    assert load_init_options(project)["script"] == "py"


def test_config_extension_list_reuses_extension_commands(project, monkeypatch):
    monkeypatch.chdir(project)
    result = runner.invoke(app, ["config", "extension", "list"])
    assert result.exit_code == 0
```

- [x] **Step 2: Run the focused test module and verify RED**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Expected: collection/import failure because `config` is not yet registered.

- [x] **Step 3: Implement the minimal command group**

```python
config_app = make_typer(name="config", help="View and manage project configuration")
config_app.add_typer(extension_app, name="extension")


@config_app.command("set")
def config_set(key: str, value: str) -> None:
    # Validate the allowed key/value pair, then save init options.
    ...
```

Implement `list` and `get` as read-only operations. Limit direct mutation to `script`, `feature-numbering`, and `team-ai-directives`. Reject all other keys with guidance to the owner command.

- [x] **Step 4: Run the focused tests and verify GREEN**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Expected: PASS.

### Task 2: Handle team-directives source lifecycle safely

**Files:**

- Modify: `src/specify_cli/commands/config.py`
- Modify: `tests/test_config_cli.py`

**Interfaces:**

- Consumes: `sync_team_ai_directives(source, project_root, force=False)`, `_install_skills_from_path(...)`, `ExtensionManager.remove("team-ai-directives")`.
- Produces: `config set team-ai-directives SOURCE` and `config unset team-ai-directives`.

- [x] **Step 1: Write failing lifecycle tests**

```python
def test_config_set_team_directives_saves_resolved_source(project, monkeypatch):
    monkeypatch.chdir(project)
    monkeypatch.setattr(config, "sync_team_ai_directives", lambda *_args, **_kwargs: ("local", Path("/resolved/team")))
    result = runner.invoke(app, ["config", "set", "team-ai-directives", "/input/team"])
    assert result.exit_code == 0
    assert load_init_options(project)["team_ai_directives"] == "/resolved/team"
```

- [x] **Step 2: Run the focused test module and verify RED**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Expected: FAIL because the lifecycle command is not implemented.

- [x] **Step 3: Implement source set/unset behavior**

Use the existing synchronization helper to validate and install the governance extension. Install default skills for the active integration when present. On unset, remove the governance extension, remove the saved source key, and print a warning that copied domain skills remain under the active agent’s skills directory for manual review.

- [x] **Step 4: Run focused tests and verify GREEN**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Expected: PASS.

### Task 3: Document the supported lifecycle

**Files:**

- Create: `docs/reference/configuration.md`
- Modify: `docs/toc.yml`
- Modify: `README.md`
- Test: `tests/test_config_cli.py`

**Interfaces:**

- Consumes: the public command surface from Tasks 1 and 2.
- Produces: discoverable reference documentation explaining init settings, team-directives source changes, and extension management delegation.

- [x] **Step 1: Add a command-surface test for help output**

```python
def test_config_help_lists_configuration_commands():
    result = runner.invoke(app, ["config", "--help"])
    assert result.exit_code == 0
    assert "team-ai-directives" in result.output
```

- [x] **Step 2: Write concise documentation**

Document exact commands, supported mutable keys, and the explicit boundary that active integration changes use `specify integration use`.

- [x] **Step 3: Run focused tests and Markdown lint**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Run: `npx --yes markdownlint-cli2 README.md docs/reference/configuration.md`

Expected: both commands pass.

### Task 4: Verify the integrated command

**Files:**

- Test: `tests/test_config_cli.py`

- [x] **Step 1: Check required tooling before test execution**

Run: `command -v uv && test -x .venv/bin/python`

- [x] **Step 2: Run the focused test suite**

Run: `.venv/bin/python -m pytest tests/test_config_cli.py -q`

Expected: PASS.

- [x] **Step 3: Run the relevant existing extension and initialization tests**

Run: `.venv/bin/python -m pytest tests/integrations/test_cli.py::TestInitTeamAiDirectives tests/test_extensions.py -q`

Expected: PASS.

- [x] **Step 4: Inspect the CLI manually**

Run: `specify config --help`

Expected: Help lists `list`, `get`, `set`, `unset`, and `extension`.
