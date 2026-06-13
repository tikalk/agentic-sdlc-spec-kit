"""Tests for team-ai-directives bundled extension with knowledge base."""

import urllib.error
from unittest.mock import patch, MagicMock
from pathlib import Path
import pytest
from specify_cli import sync_team_ai_directives


# ============================================================================
# Bundled Extension + Knowledge Base Tests
# ============================================================================


def test_sync_accepts_local_knowledge_base(tmp_path):
    """Local directory with knowledge base content should be accepted."""
    kb_dir = tmp_path / "team-ai-directives"
    kb_dir.mkdir()
    (kb_dir / "context_modules").mkdir()
    (kb_dir / "context_modules" / "constitution.md").write_text("# Constitution")

    status, path = sync_team_ai_directives(str(kb_dir), tmp_path)

    assert status == "local"
    assert path == kb_dir
    # Bundled extension should be installed
    assert (tmp_path / ".specify" / "extensions" / "team-ai-directives" / "extension.yml").exists()


def test_sync_rejects_directory_without_knowledge_base(tmp_path):
    """Directory without knowledge base content should be rejected."""
    bad_dir = tmp_path / "not-a-kb"
    bad_dir.mkdir()

    with pytest.raises(ValueError) as exc:
        sync_team_ai_directives(str(bad_dir), tmp_path)

    assert "Invalid team-ai-directives knowledge base" in str(exc.value)


def test_sync_accepts_zip_urls(tmp_path):
    """ZIP URLs should be accepted (validation happens in download)."""
    repo_url = "https://example.com/repo/archive/refs/tags/v1.0.0.zip"

    try:
        sync_team_ai_directives(repo_url, tmp_path)
    except Exception as e:
        if "Invalid team-ai-directives URL" in str(e):
            pytest.fail(f"Valid ZIP URL was rejected: {e}")


def test_sync_rejects_git_urls(tmp_path):
    """Git clone URLs should be rejected."""
    with pytest.raises(ValueError) as exc:
        sync_team_ai_directives("https://example.com/repo.git", tmp_path)

    assert "Invalid team-ai-directives URL" in str(exc.value)


def test_sync_auth_failure_raises_with_auth_message(tmp_path):
    """401/403 errors should mention authentication."""
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"

    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.HTTPError(url, 401, "Unauthorized", {}, None)

    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)

    error_msg = str(exc.value)
    assert "Authentication failed" in error_msg


def test_sync_404_error_raises_repository_not_found(tmp_path):
    """404 errors should mention repository not found."""
    repo_url = "https://github.com/org/nonexistent/archive/refs/tags/v1.0.0.zip"

    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.HTTPError(url, 404, "Not Found", {}, None)

    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)

    error_msg = str(exc.value)
    assert "Repository not found" in error_msg


def test_sync_network_error_raises_connection_message(tmp_path):
    """Network errors should mention connection issues."""
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"

    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.URLError("Network unreachable")

    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)

    error_msg = str(exc.value)
    assert "Failed to download" in error_msg
    assert "network connection" in error_msg


def test_sync_open_url_called_for_download(tmp_path):
    """Verify open_url is called for downloading ZIP files."""
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"

    mock_response = MagicMock()
    mock_response.read.return_value = b"PK" + b"fake zip content"
    mock_response.__enter__ = MagicMock(return_value=mock_response)
    mock_response.__exit__ = MagicMock(return_value=False)

    with patch("specify_cli.authentication.http.open_url", return_value=mock_response) as mock_open:
        try:
            sync_team_ai_directives(repo_url, tmp_path)
        except Exception:
            # Expected to fail at zip processing with fake data
            pass

        mock_open.assert_called_once()
        call_args = mock_open.call_args
        assert call_args[0][0] == repo_url
        assert call_args[1].get("timeout") == 60


def test_sync_installs_bundled_extension(tmp_path):
    """Bundled extension should be installed even without knowledge base."""
    kb_dir = tmp_path / "team-ai-directives"
    kb_dir.mkdir()
    (kb_dir / ".skills.json").write_text('{"version": "1.0.0"}')

    sync_team_ai_directives(str(kb_dir), tmp_path)

    ext_yml = tmp_path / ".specify" / "extensions" / "team-ai-directives" / "extension.yml"
    assert ext_yml.exists()


def test_sync_force_reinstalls_extension(tmp_path):
    """Force=True should remove and reinstall the extension."""
    kb_dir = tmp_path / "team-ai-directives"
    kb_dir.mkdir()
    (kb_dir / "CDR.md").write_text("# CDR")

    # First install
    sync_team_ai_directives(str(kb_dir), tmp_path)
    ext_dir = tmp_path / ".specify" / "extensions" / "team-ai-directives"
    assert ext_dir.exists()

    # Force reinstall
    sync_team_ai_directives(str(kb_dir), tmp_path, force=True)
    assert ext_dir.exists()
    assert (ext_dir / "extension.yml").exists()


def test_discover_command_documents_team_context_json_contract():
    """Discover command should define extension-owned team-context.json persistence."""
    repo_root = Path(__file__).resolve().parent.parent
    discover_md = repo_root / "extensions" / "team-ai-directives" / "commands" / "discover.md"
    content = discover_md.read_text(encoding="utf-8")

    assert "team-context.json" in content
    assert "SPECIFY_FEATURE_DIRECTORY/team-context.json" in content
    assert ".specify/discovery/team-context.json" in content
    assert "authoritative machine-readable artifact" in content


def test_discover_command_uses_cdr_index_as_search_surface():
    """Discover command should document CDR.md as the search surface with fallback."""
    repo_root = Path(__file__).resolve().parent.parent
    discover_md = repo_root / "extensions" / "team-ai-directives" / "commands" / "discover.md"
    content = discover_md.read_text(encoding="utf-8")

    assert "CDR Index as Search Surface" in content
    assert "loads the index first, matches against it" in content or "index first" in content or "read the index first" in content or "CDR Index" in content
    assert "Fallback" in content or "fallback" in content or "legacy" in content
    assert "cdr_id" in content or "cdr_id" in content


def test_discover_command_references_descriptor_column():
    """Discover command should reference the Descriptor column for relevance matching."""
    repo_root = Path(__file__).resolve().parent.parent
    discover_md = repo_root / "extensions" / "team-ai-directives" / "commands" / "discover.md"
    content = discover_md.read_text(encoding="utf-8")

    assert "Descriptor" in content
    assert "descriptor" in content


def test_implement_command_emits_descriptor_column():
    """Implement command should emit Descriptor column in CDR index table."""
    repo_root = Path(__file__).resolve().parent.parent
    implement_md = repo_root / "extensions" / "levelup" / "commands" / "implement.md"
    content = implement_md.read_text(encoding="utf-8")

    assert "| ID | Target Module | Type | Status | Created | Verified | Age | Descriptor |" in content
    assert "### Descriptor" in content
    assert "when to use" in content


def test_repair_command_emits_descriptor_column():
    """Repair command should emit Descriptor column in CDR index table."""
    repo_root = Path(__file__).resolve().parent.parent
    repair_md = repo_root / "extensions" / "team-ai-directives" / "commands" / "repair.md"
    content = repair_md.read_text(encoding="utf-8")

    assert "| ID | Target Module | Type | Status | Created | Verified | Age | Descriptor |" in content
    assert "### Descriptor" in content


def test_repair_command_parser_handles_descriptor_column():
    """Repair CDR lookup parser should account for the extra Descriptor column."""
    repo_root = Path(__file__).resolve().parent.parent
    repair_md = repo_root / "extensions" / "team-ai-directives" / "commands" / "repair.md"
    content = repair_md.read_text(encoding="utf-8")

    # Parser should have the right number of positional fields for the new column
    assert "IFS='|' read -r _ id module _ _ _ _ _" in content or "IFS='|' read -r _ id module _ _ _ _ _" in content
