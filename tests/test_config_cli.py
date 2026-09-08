"""Behavior tests for the post-initialization configuration CLI."""

from __future__ import annotations

from pathlib import Path

import pytest
from typer.testing import CliRunner

from specify_cli import app, load_init_options, save_init_options
from specify_cli.commands import config


runner = CliRunner()


def _project(tmp_path):
    project = tmp_path / "project"
    (project / ".specify").mkdir(parents=True)
    save_init_options(
        project,
        {
            "ai": "codex",
            "feature_numbering": "sequential",
            "script": "sh",
            "speckit_version": "0.0.0-test",
        },
    )
    return project


def test_config_list_shows_initialization_settings(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "list"])

    assert result.exit_code == 0, result.output
    assert "script" in result.output
    assert "sh" in result.output
    assert "feature-numbering" in result.output
    assert "sequential" in result.output


def test_config_list_shows_recorded_skills_layout(tmp_path, monkeypatch):
    project = _project(tmp_path)
    save_init_options(project, {**load_init_options(project), "ai_skills": True})
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "list"])

    assert result.exit_code == 0, result.output
    assert "ai-skills" in result.output
    assert "True" in result.output


@pytest.mark.parametrize(
    "command", [["config", "get", "team-ai-directives"], ["config", "list"]]
)
def test_config_displays_literal_brackets_in_saved_values(tmp_path, monkeypatch, command):
    project = _project(tmp_path)
    saved_path = "/tmp/team-[directives]"
    save_init_options(
        project,
        {**load_init_options(project), "team_ai_directives": saved_path},
    )
    monkeypatch.chdir(project)

    result = runner.invoke(app, command)

    assert result.exit_code == 0, result.output
    assert saved_path in result.output


def test_config_set_script_rejects_metadata_only_change(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "set", "script", "py"])

    assert result.exit_code != 0
    assert "specify integration upgrade" in result.output
    assert "--script" in result.output
    assert load_init_options(project)["script"] == "sh"


@pytest.mark.parametrize("key", ["ai-skills", "AI_SKILLS"])
def test_config_set_skills_guides_to_integration_options(tmp_path, monkeypatch, key):
    project = _project(tmp_path)
    monkeypatch.chdir(project)
    before = load_init_options(project)

    result = runner.invoke(app, ["config", "set", key, "true"])

    assert result.exit_code != 0
    assert "specify integration upgrade" in result.output
    assert "--integration-options" in result.output
    assert "--help" in result.output
    assert "use true" not in result.output
    assert load_init_options(project) == before


@pytest.mark.parametrize("key", ["here", "HERE", "speckit-version", "SPECKIT_VERSION"])
def test_config_set_identifies_read_only_keys(tmp_path, monkeypatch, key):
    project = _project(tmp_path)
    monkeypatch.chdir(project)
    before = load_init_options(project)

    result = runner.invoke(app, ["config", "set", key, "anything"])

    assert result.exit_code != 0
    assert "read-only" in result.output
    assert "Unknown" not in result.output
    assert load_init_options(project) == before


def test_config_set_unknown_key_preserves_state(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)
    before = load_init_options(project)
    result = runner.invoke(app, ["config", "set", "not-a-setting", "anything"])
    assert result.exit_code != 0
    assert "Unknown configuration key" in result.output
    assert load_init_options(project) == before


def test_config_set_feature_numbering_persists_valid_value(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(
        app, ["config", "set", "feature-numbering", "timestamp"]
    )

    assert result.exit_code == 0, result.output
    assert load_init_options(project)["feature_numbering"] == "timestamp"


@pytest.mark.parametrize("key", ["ai", "integration", "INTEGRATION"])
def test_config_rejects_integration_mutation_with_owner_guidance(tmp_path, monkeypatch, key):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "set", key, "claude"])

    assert result.exit_code != 0
    assert "specify integration use claude" in result.output
    assert load_init_options(project)["ai"] == "codex"


def test_config_extension_list_reuses_extension_commands(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "extension", "list"])

    assert result.exit_code == 0, result.output
    assert "No extensions installed" in result.output


def test_config_help_lists_configuration_commands():
    result = runner.invoke(app, ["config", "--help"])

    assert result.exit_code == 0, result.output
    assert "set" in result.output
    assert "unset" in result.output
    assert "extension" in result.output


def test_config_set_team_directives_saves_resolved_source_and_skills(
    tmp_path, monkeypatch
):
    project = _project(tmp_path)
    monkeypatch.chdir(project)
    calls = []

    def sync(source, project_root, *, force):
        calls.append(("sync", source, project_root, force))
        return "local", Path("/resolved/team-directives")

    def install_skills(**kwargs):
        calls.append(("skills", kwargs))
        return ["team-boot"]

    monkeypatch.setattr(config, "sync_team_ai_directives", sync, raising=False)
    monkeypatch.setattr(config, "_install_skills_from_path", install_skills, raising=False)

    result = runner.invoke(
        app,
        ["config", "set", "team-ai-directives", "/input/team-directives"],
    )

    assert result.exit_code == 0, result.output
    assert load_init_options(project)["team_ai_directives"] == "/resolved/team-directives"
    assert calls == [
        ("sync", "/input/team-directives", project, False),
        (
            "skills",
            {
                "team_directives_path": Path("/resolved/team-directives"),
                "project_path": project,
                "selected_ai": "codex",
                "force": False,
            },
        ),
    ]


def test_config_set_team_directives_installs_mcp_configuration(tmp_path, monkeypatch):
    """A post-init directives source must apply its MCP configuration."""
    project = _project(tmp_path)
    source = tmp_path / "knowledge-base"
    source.mkdir()
    (source / ".mcp.json").write_text('{"mcpServers": {"team": {}}}')
    monkeypatch.chdir(project)

    def sync(value, project_root, *, force):
        return "local", source

    def install_skills(**kwargs):
        return []

    def install_mcp(team_path, project_root):
        assert team_path == source
        (project_root / ".mcp.json").write_text('{"mcpServers": {"team": {}}}')
        return True, [], [], []

    monkeypatch.setattr(config, "sync_team_ai_directives", sync)
    monkeypatch.setattr(config, "_install_skills_from_path", install_skills)
    monkeypatch.setattr(config, "install_mcp_config", install_mcp, raising=False)

    result = runner.invoke(
        app,
        ["config", "set", "team-ai-directives", str(source)],
    )

    assert result.exit_code == 0, result.output
    assert (project / ".mcp.json").read_text() == '{"mcpServers": {"team": {}}}'


def test_config_set_team_directives_preserves_source_when_mcp_install_fails(
    tmp_path, monkeypatch
):
    """A malformed MCP config must not be recorded as a successful setup."""
    project = _project(tmp_path)
    save_init_options(
        project,
        {**load_init_options(project), "team_ai_directives": "/previous/source"},
    )
    source = tmp_path / "knowledge-base"
    source.mkdir()
    (source / ".mcp.json").write_text("{")
    monkeypatch.chdir(project)

    def sync(value, project_root, *, force):
        return "local", source

    monkeypatch.setattr(config, "sync_team_ai_directives", sync)

    result = runner.invoke(
        app,
        ["config", "set", "team-ai-directives", str(source)],
    )

    assert result.exit_code == 1, result.output
    assert "Invalid MCP config" in result.output
    assert load_init_options(project)["team_ai_directives"] == "/previous/source"


def test_config_set_team_directives_persists_an_absolute_source_path(
    tmp_path, monkeypatch
):
    """A relative source must remain usable when later commands change CWD."""
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    def sync(value, project_root, *, force):
        return "local", Path("knowledge-base")

    def install_skills(**kwargs):
        return []

    monkeypatch.setattr(config, "sync_team_ai_directives", sync)
    monkeypatch.setattr(config, "_install_skills_from_path", install_skills)

    result = runner.invoke(
        app,
        ["config", "set", "team-ai-directives", "knowledge-base"],
    )

    assert result.exit_code == 0, result.output
    assert load_init_options(project)["team_ai_directives"] == str(
        (project / "knowledge-base").resolve()
    )


def test_config_unset_team_directives_removes_extension_and_saved_source(
    tmp_path, monkeypatch
):
    project = _project(tmp_path)
    save_init_options(
        project,
        {
            **load_init_options(project),
            "team_ai_directives": "/resolved/team-directives",
        },
    )
    monkeypatch.chdir(project)
    removed = []

    class FakeManager:
        def __init__(self, project_root):
            assert project_root == project

        def remove(self, extension_id):
            removed.append(extension_id)
            return True

    monkeypatch.setattr(config, "ExtensionManager", FakeManager)

    result = runner.invoke(app, ["config", "unset", "team-ai-directives"])

    assert result.exit_code == 0, result.output
    assert removed == ["team-ai-directives"]
    assert "team_ai_directives" not in load_init_options(project)
    assert "copied team skills" in result.output.lower()


@pytest.mark.parametrize("saved_source", [False, True])
def test_config_unset_absent_extension_reports_actual_outcome(
    tmp_path, monkeypatch, saved_source
):
    project = _project(tmp_path)
    if saved_source:
        save_init_options(project, {**load_init_options(project), "team_ai_directives": "/old"})
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "unset", "team-ai-directives"])

    assert result.exit_code == 0, result.output
    assert "team_ai_directives" not in load_init_options(project)
    assert "Removed" not in result.output
    if saved_source:
        assert "Cleared" in result.output
        assert "not installed" in result.output
        assert "copied team skills" in result.output.lower()
    else:
        assert "Nothing to unset" in result.output


@pytest.mark.parametrize("phase", ["synchronization", "skill installation"])
@pytest.mark.parametrize("existing_source", [False, True])
def test_config_team_directives_failure_preserves_source_and_allows_retry(
    tmp_path, monkeypatch, phase, existing_source
):
    from specify_cli import _init_fork

    project = _project(tmp_path)
    if existing_source:
        save_init_options(project, {**load_init_options(project), "team_ai_directives": "/old"})
    before = load_init_options(project)
    source = tmp_path / "knowledge-base"
    source.mkdir()
    (source / ".skills.json").write_text('{"default": ["first", "second"]}')
    for name in ("first", "second"):
        skill = source / "skills" / name / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text(f"{name} skill")
    partial_extension = project / ".specify" / "extensions" / "team-ai-directives"
    failing = True

    def sync(value, project_root, *, force):
        partial_extension.mkdir(parents=True, exist_ok=True)
        if failing and phase == "synchronization":
            raise ValueError("source unavailable")
        return "local", source

    original_copy = _init_fork.shutil.copy2

    def copy_skill(src, dst, *args, **kwargs):
        if failing and phase == "skill installation" and Path(src).parent.name == "second":
            Path(dst).write_text("incomplete skill")
            raise OSError("copy denied")
        return original_copy(src, dst, *args, **kwargs)

    monkeypatch.setattr(config, "sync_team_ai_directives", sync)
    monkeypatch.setattr(_init_fork.shutil, "copy2", copy_skill)
    monkeypatch.chdir(project)
    command = ["config", "set", "team-ai-directives", str(source)]

    result = runner.invoke(app, command)

    assert result.exit_code == 1, result.output
    output = " ".join(result.output.split())
    assert phase in output
    expected_cause = "source unavailable" if phase == "synchronization" else "copy denied"
    assert expected_cause in output
    assert "retry the same" in output.lower()
    assert "may remain" in output
    assert "Inspect and repair incomplete skill files" in output
    assert "existing skills are skipped on retry" in output
    assert "Updated" not in output
    assert "Traceback" not in output
    assert load_init_options(project) == before
    assert partial_extension.is_dir()
    first_skill = project / ".agents" / "skills" / "first" / "SKILL.md"
    if phase == "skill installation":
        assert first_skill.read_text() == "first skill"
        first_skill.write_text("preserved partial skill")
        incomplete_skill = project / ".agents" / "skills" / "second" / "SKILL.md"
        assert incomplete_skill.read_text() == "incomplete skill"
        # Follow the recovery guidance before retrying the failed operation.
        incomplete_skill.write_text("second skill")

    failing = False
    retry = runner.invoke(app, command)

    assert retry.exit_code == 0, retry.output
    assert load_init_options(project)["team_ai_directives"] == str(source)
    assert (project / ".agents" / "skills" / "second" / "SKILL.md").read_text() == "second skill"
    if phase == "skill installation":
        assert first_skill.read_text() == "preserved partial skill"
