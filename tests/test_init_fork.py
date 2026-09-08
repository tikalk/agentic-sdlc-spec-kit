"""Regression tests for fork-specific initialization helpers."""

from __future__ import annotations

import json
import zipfile

import pytest

from specify_cli._init_options import load_init_options
from specify_cli import _init_fork


def test_replace_cached_team_directives_archive_preserves_previous_cache_on_failure(
    tmp_path,
):
    """A malformed replacement archive must not discard the saved knowledge base."""
    downloads = tmp_path / "downloads"
    downloads.mkdir()
    previous = downloads / "team-ai-directives-kb-extracted"
    previous.mkdir()
    (previous / "CDR.md").write_text("previous directives")
    archive = downloads / "team-ai-directives-kb.zip"
    archive.write_bytes(b"PKnot-a-valid-zip")

    with pytest.raises(zipfile.BadZipFile):
        _init_fork._replace_cached_team_directives_archive(archive, downloads)

    assert (previous / "CDR.md").read_text() == "previous directives"


def test_restore_cached_team_directives_archive_restores_previous_cache(tmp_path):
    """Post-extraction setup failures must be able to restore the prior cache."""
    downloads = tmp_path / "downloads"
    downloads.mkdir()
    current = downloads / "team-ai-directives-kb-extracted"
    backup = downloads / "team-ai-directives-kb-previous"
    current.mkdir()
    backup.mkdir()
    (current / "CDR.md").write_text("replacement directives")
    (backup / "CDR.md").write_text("previous directives")

    _init_fork._restore_cached_team_directives_archive(downloads)

    assert (current / "CDR.md").read_text() == "previous directives"
    assert not backup.exists()


def test_pre_init_records_mcp_entries_for_later_cleanup(tmp_path, monkeypatch):
    """MCP entries installed during init need the same ownership metadata as config set."""
    project = tmp_path / "project"
    (project / ".specify").mkdir(parents=True)
    source = tmp_path / "knowledge-base"
    source.mkdir()
    (source / ".mcp.json").write_text('{"mcpServers": {"team": {}}}')

    class Tracker:
        def add(self, *args):
            pass

        def start(self, *args):
            pass

        def complete(self, *args):
            pass

        def skip(self, *args):
            pass

        def error(self, *args):
            pass

    monkeypatch.setattr(
        _init_fork,
        "sync_team_ai_directives",
        lambda value, project_root, *, force: ("local", source),
    )
    monkeypatch.setattr(_init_fork, "_install_skills_from_path", lambda **kwargs: [])

    def install_mcp(team_path, project_root):
        (project_root / ".mcp.json").write_text('{"mcpServers": {"team": {}}}')
        return True, [], [], []

    monkeypatch.setattr(_init_fork, "install_mcp_config", install_mcp)

    _init_fork.pre_init(project, "codex", str(source), tracker=Tracker())

    assert load_init_options(project)["team_ai_directives_mcp"] == {
        "mcpServers": {"team": {}}
    }
