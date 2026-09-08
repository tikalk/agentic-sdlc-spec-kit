"""Regression tests for fork-specific initialization helpers."""

from __future__ import annotations

import zipfile

import pytest

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
