"""Tests for team-ai-directives synchronization with authentication module."""

import urllib.error
from unittest.mock import patch, MagicMock
import pytest
from specify_cli import sync_team_ai_directives
from specify_cli.cli_customization import (
    resolve_extension_dir,
    get_reference_extension_paths,
    build_alias_map,
)


# ============================================================================
# Reference Extension Path Resolution Tests
# ============================================================================


def test_resolve_extension_dir_for_reference(tmp_path):
    """Should return stored path for reference extensions."""
    ext_id = "my-ref-ext"
    ref_path = tmp_path / "my-ref-ext"
    ref_path.mkdir()

    # Create registry with reference extension
    registry_dir = tmp_path / ".specify" / "extensions"
    registry_dir.mkdir(parents=True)
    registry_file = registry_dir / ".registry"
    registry_file.write_text(
        f'{{"schema_version": "1.0", "extensions": '
        f'{{"{ext_id}": {{"source": "reference", "path": "{ref_path}"}}}}}}'
    )

    result = resolve_extension_dir(tmp_path, ext_id)
    assert result == ref_path


def test_resolve_extension_dir_for_installed(tmp_path):
    """Should fall back to .specify/extensions/{id} for copied extensions."""
    ext_id = "git"
    installed_path = tmp_path / ".specify" / "extensions" / ext_id
    installed_path.mkdir(parents=True)

    result = resolve_extension_dir(tmp_path, ext_id)
    assert result == installed_path


def test_get_reference_extension_paths(tmp_path):
    """Should return only reference extensions with valid paths."""
    ref_path = tmp_path / "team-ai-directives"
    ref_path.mkdir()

    registry_dir = tmp_path / ".specify" / "extensions"
    registry_dir.mkdir(parents=True)
    registry_file = registry_dir / ".registry"
    registry_file.write_text(
        f'{{"schema_version": "1.0", "extensions": '
        f'{{"team-ai-directives": '
        f'{{"source": "reference", "path": "{ref_path}"}},'
        f'"git": {{"source": "local", "path": "/some/path"}}}}}}'
    )

    paths = get_reference_extension_paths(tmp_path)
    assert len(paths) == 1
    assert paths[0] == ref_path


def test_build_alias_map_includes_reference_extensions(tmp_path):
    """Should discover aliases from reference (top-level) extensions."""
    ref_path = tmp_path / "team-ai-directives"
    ref_path.mkdir()
    commands_dir = ref_path / "commands"
    commands_dir.mkdir()

    # Write extension.yml with aliases
    (ref_path / "extension.yml").write_text(
        'schema_version: "1.0"\n'
        'extension:\n'
        '  id: team-ai-directives\n'
        '  name: Team AI Directives\n'
        '  version: "1.0.0"\n'
        '  description: Test\n'
        'requires:\n'
        '  speckit_version: ">=0.3.0"\n'
        'provides:\n'
        '  commands:\n'
        '    - name: adlc.team-ai-directives.verify\n'
        '      file: commands/verify.md\n'
        '      aliases:\n'
        '        - team.verify\n'
    )

    # Register as reference extension
    registry_dir = tmp_path / ".specify" / "extensions"
    registry_dir.mkdir(parents=True)
    (registry_dir / ".registry").write_text(
        f'{{"schema_version": "1.0", "extensions": '
        f'{{"team-ai-directives": '
        f'{{"source": "reference", "path": "{ref_path}"}}}}}}'
    )

    alias_map = build_alias_map(tmp_path)
    assert alias_map.get("adlc.team-ai-directives.verify") == "team.verify"


def test_sync_accepts_zip_urls(tmp_path):
    """ZIP URLs should be accepted (validation happens in download, not here)."""
    repo_url = "https://example.com/repo/archive/refs/tags/v1.0.0.zip"
    
    # Just verify the URL is accepted (will fail at download time, but that's OK)
    # The function should not raise ValueError for valid ZIP URLs
    try:
        status, path = sync_team_ai_directives(repo_url, tmp_path)
    except Exception as e:
        # Expected to fail at download, but URL validation should pass
        if "Invalid team-ai-directives URL" in str(e):
            pytest.fail(f"Valid ZIP URL was rejected: {e}")


def test_sync_accepts_github_archive_urls(tmp_path):
    """GitHub archive URLs should be accepted."""
    repo_url = "https://github.com/myorg/team-ai-directives/archive/refs/tags/v1.0.0.zip"
    
    # URL validation should pass
    try:
        status, path = sync_team_ai_directives(repo_url, tmp_path)
    except Exception as e:
        if "Invalid team-ai-directives URL" in str(e):
            pytest.fail(f"Valid GitHub archive URL was rejected: {e}")


def test_sync_accepts_gitlab_archive_urls(tmp_path):
    """GitLab archive URLs should be accepted."""
    repo_url = "https://gitlab.com/myorg/team-ai-directives/-/archive/v1.0.0/team-ai-directives-v1.0.0.zip"
    
    # URL validation should pass
    try:
        status, path = sync_team_ai_directives(repo_url, tmp_path)
    except Exception as e:
        if "Invalid team-ai-directives URL" in str(e):
            pytest.fail(f"Valid GitLab archive URL was rejected: {e}")


def test_sync_rejects_git_urls(tmp_path):
    """Git clone URLs should be rejected."""
    with pytest.raises(ValueError) as exc:
        sync_team_ai_directives("https://example.com/repo.git", tmp_path)
    
    assert "Invalid team-ai-directives URL" in str(exc.value)


def test_sync_returns_local_path_when_given_directory(tmp_path):
    """Local directory paths should be accepted and installed to extensions."""
    local_repo = tmp_path / "team-ai-directives"
    local_repo.mkdir(parents=True)
    commands_dir = local_repo / "commands"
    commands_dir.mkdir(parents=True)
    # extension.yml with required structure
    (local_repo / "extension.yml").write_text('''schema_version: "1.0"

extension:
  id: "team-ai-directives"
  name: "Team AI Directives"
  version: "1.0.0"
  description: "Team-specific AI agent context"
  author: "Team"
  repository: "https://github.com/test/team-ai-directives"
  license: "MIT"

requires:
  speckit_version: ">=0.3.0"

provides:
  commands:
    - name: "adlc.team-ai-directives.verify"
      file: "commands/verify.md"
      description: "Test command"
''')
    (commands_dir / "verify.md").write_text("# Test verify")

    status, path = sync_team_ai_directives(str(local_repo), tmp_path)

    assert status == "local"
    # The function returns the installed path in extensions/
    assert path == tmp_path / ".specify" / "extensions" / "team-ai-directives"


def test_sync_auth_failure_raises_with_auth_json_message(tmp_path, monkeypatch):
    """401/403 errors should mention auth.json configuration."""
    from tests.auth_helpers import inject_github_config
    
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"
    
    # Inject GitHub config
    monkeypatch.setenv("GH_TOKEN", "invalid-token")
    inject_github_config(monkeypatch, token_env="GH_TOKEN")
    
    # Mock open_url to raise 401 error
    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.HTTPError(
            url, 401, "Unauthorized", {}, None
        )
    
    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)
    
    error_msg = str(exc.value)
    assert "Authentication failed" in error_msg
    assert "auth.json" in error_msg
    assert "github.com/tikalk/agentic-sdlc-spec-kit/blob/main/docs/reference/authentication.md" in error_msg


def test_sync_404_error_raises_repository_not_found(tmp_path):
    """404 errors should mention repository not found."""
    repo_url = "https://github.com/org/nonexistent/archive/refs/tags/v1.0.0.zip"
    
    # Mock open_url to raise 404 error
    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.HTTPError(
            url, 404, "Not Found", {}, None
        )
    
    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)
    
    error_msg = str(exc.value)
    assert "Repository not found" in error_msg
    assert "verify the URL" in error_msg


def test_sync_network_error_raises_connection_message(tmp_path):
    """Network errors should mention connection issues."""
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"
    
    # Mock open_url to raise URLError
    def mock_open_url(url, timeout=10, extra_headers=None):
        raise urllib.error.URLError("Network unreachable")
    
    with patch("specify_cli.authentication.http.open_url", mock_open_url):
        with pytest.raises(ValueError) as exc:
            sync_team_ai_directives(repo_url, tmp_path)
    
    error_msg = str(exc.value)
    assert "Failed to download" in error_msg
    assert "network connection" in error_msg


def test_sync_open_url_called_for_download(tmp_path, monkeypatch):
    """Verify open_url is called for downloading ZIP files."""
    repo_url = "https://github.com/org/repo/archive/refs/tags/v1.0.0.zip"
    
    # Create a mock response
    mock_response = MagicMock()
    mock_response.read.return_value = b"fake zip content"
    mock_response.__enter__ = MagicMock(return_value=mock_response)
    mock_response.__exit__ = MagicMock(return_value=False)
    
    with patch("specify_cli.authentication.http.open_url", return_value=mock_response) as mock_open:
        # Should call open_url for download
        try:
            sync_team_ai_directives(repo_url, tmp_path)
        except Exception:
            # We expect it to fail at zip processing with fake data
            pass
        
        # Verify open_url was called with correct URL
        mock_open.assert_called_once()
        call_args = mock_open.call_args
        assert call_args[0][0] == repo_url
        assert call_args[1].get("timeout") == 60
