"""Behavior tests for the post-initialization configuration CLI."""

from __future__ import annotations

from pathlib import Path

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


def test_config_set_script_persists_valid_value(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "set", "script", "py"])

    assert result.exit_code == 0, result.output
    assert load_init_options(project)["script"] == "py"


def test_config_set_feature_numbering_persists_valid_value(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(
        app, ["config", "set", "feature-numbering", "timestamp"]
    )

    assert result.exit_code == 0, result.output
    assert load_init_options(project)["feature_numbering"] == "timestamp"


def test_config_rejects_integration_mutation_with_owner_guidance(tmp_path, monkeypatch):
    project = _project(tmp_path)
    monkeypatch.chdir(project)

    result = runner.invoke(app, ["config", "set", "integration", "claude"])

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
