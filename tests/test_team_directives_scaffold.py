"""Tests for neutral team-ai-directives scaffolding."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

import pytest
import yaml
from typer.testing import CliRunner

from specify_cli import _feature_capabilities, app
from specify_cli.team_directives_scaffold import scaffold_team_directives


runner = CliRunner()
EXPECTED_FILES = {
    ".mcp.json.example",
    ".skills.json",
    "AGENTS.md",
    "CDR.md",
    "README.md",
    "context_modules/constitution.md",
    "context_modules/examples/.gitkeep",
    "context_modules/personas/.gitkeep",
    "context_modules/rules/.gitkeep",
    "manifest.yml",
    "skills/.gitkeep",
}


def _generated_files(root: Path) -> set[str]:
    return {
        path.relative_to(root).as_posix() for path in root.rglob("*") if path.is_file()
    }


def test_scaffold_creates_neutral_valid_knowledge_base(tmp_path: Path):
    root = tmp_path / "platform-team"

    result = scaffold_team_directives(
        root,
        created_at=date(2026, 7, 19),
    )

    assert result.name == "platform-team"
    assert result.root == root
    assert _generated_files(root) == EXPECTED_FILES
    assert len(result.files) == len(EXPECTED_FILES)
    assert not (root / ".git").exists()

    manifest = yaml.safe_load((root / "manifest.yml").read_text(encoding="utf-8"))
    assert manifest == {
        "schema_version": "1.0",
        "team_ai_directives": {
            "name": "platform-team",
            "version": "0.1.0",
            "owner": "",
            "compatibility": {"speckit": ">=0.12.0"},
            "created_at": "2026-07-19",
        },
    }

    skills = json.loads((root / ".skills.json").read_text(encoding="utf-8"))
    assert skills["default"] == []
    assert skills["external"] == {}
    assert skills["skills"] == {}
    assert json.loads((root / ".mcp.json.example").read_text(encoding="utf-8")) == {
        "mcpServers": {}
    }

    constitution = (root / "context_modules/constitution.md").read_text(
        encoding="utf-8"
    )
    assert "type: Constitution" in constitution
    assert "No team-wide principles have been defined yet." in constitution


def test_scaffold_accepts_existing_empty_directory_and_name_override(tmp_path: Path):
    root = tmp_path / "directives"
    root.mkdir()

    result = scaffold_team_directives(root, "Platform Team")

    assert result.name == "Platform Team"
    manifest = yaml.safe_load((root / "manifest.yml").read_text(encoding="utf-8"))
    assert manifest["team_ai_directives"]["name"] == "Platform Team"
    readme = (root / "README.md").read_text(encoding="utf-8")
    assert '"/path/to/directives"' in readme
    assert "/path/to/Platform Team" not in readme


@pytest.mark.parametrize("target_kind", ["file", "non-empty-directory"])
def test_scaffold_rejects_occupied_destination(tmp_path: Path, target_kind: str):
    root = tmp_path / "team-ai-directives"
    if target_kind == "file":
        root.write_text("occupied", encoding="utf-8")
    else:
        root.mkdir()
        (root / "existing.md").write_text("occupied", encoding="utf-8")

    with pytest.raises(FileExistsError):
        scaffold_team_directives(root)


def test_scaffold_rejects_symlink_destination(tmp_path: Path):
    actual = tmp_path / "actual"
    actual.mkdir()
    link = tmp_path / "team-ai-directives"
    link.symlink_to(actual, target_is_directory=True)

    with pytest.raises(ValueError, match="symlink"):
        scaffold_team_directives(link)

    assert list(actual.iterdir()) == []


def test_scaffold_rolls_back_partial_write(tmp_path: Path, monkeypatch):
    root = tmp_path / "generated" / "nested" / "team-ai-directives"
    original_write_text = Path.write_text
    writes = 0

    def fail_second_write(path: Path, *args, **kwargs):
        nonlocal writes
        writes += 1
        if writes == 2:
            raise RuntimeError("simulated write failure")
        return original_write_text(path, *args, **kwargs)

    monkeypatch.setattr(Path, "write_text", fail_second_write)

    with pytest.raises(RuntimeError, match="simulated write failure"):
        scaffold_team_directives(root)

    assert not root.exists()
    assert not (tmp_path / "generated").exists()


def test_cli_uses_default_path_and_reports_next_step(tmp_path: Path, monkeypatch):
    monkeypatch.chdir(tmp_path)

    result = runner.invoke(app, ["team-directives", "init"])

    assert result.exit_code == 0, result.output
    root = tmp_path / "team-ai-directives"
    assert _generated_files(root) == EXPECTED_FILES
    assert "Created team-ai-directives scaffold" in result.output
    assert "no Git repository initialized" in result.output
    assert "specify init <project> --team-ai-directives" in result.output


def test_cli_help_and_name_option(tmp_path: Path):
    help_result = runner.invoke(app, ["team-directives", "init", "--help"])
    assert help_result.exit_code == 0
    assert "--name" in help_result.output

    root = tmp_path / "custom"
    result = runner.invoke(
        app,
        ["team-directives", "init", str(root), "--name", "Platform Team"],
    )
    assert result.exit_code == 0, result.output
    assert 'name: "Platform Team"' in (root / "manifest.yml").read_text(
        encoding="utf-8"
    )


def test_cli_rejects_non_empty_destination(tmp_path: Path):
    root = tmp_path / "team-ai-directives"
    root.mkdir()
    (root / "existing.md").write_text("keep", encoding="utf-8")

    result = runner.invoke(app, ["team-directives", "init", str(root)])

    assert result.exit_code == 1
    assert "Destination directory is not empty" in result.output
    assert (root / "existing.md").read_text(encoding="utf-8") == "keep"


def test_generated_scaffold_is_accepted_by_existing_sync_flow(
    tmp_path: Path,
    monkeypatch,
):
    from specify_cli import _init_fork

    root = tmp_path / "team-ai-directives"
    project = tmp_path / "project"
    project.mkdir()
    scaffold_team_directives(root)

    class FakeRegistry:
        @staticmethod
        def is_installed(_name: str) -> bool:
            return True

    class FakeExtensionManager:
        registry = FakeRegistry()

    monkeypatch.setattr(
        _init_fork,
        "ExtensionManager",
        lambda _project_root: FakeExtensionManager(),
    )
    monkeypatch.setattr(_init_fork, "_update_agent_context", lambda _path: None)

    status, resolved = _init_fork.sync_team_ai_directives(str(root), project)

    assert status == "local"
    assert resolved == root


def test_feature_capabilities_advertise_team_directives_init():
    assert _feature_capabilities()["team_directives_init"] is True
