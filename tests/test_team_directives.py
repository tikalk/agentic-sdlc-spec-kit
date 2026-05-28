"""Tests for team-ai-directives synchronization with authentication module."""

import json
import urllib.error
from unittest.mock import patch, MagicMock
import pytest
from specify_cli import sync_team_ai_directives
from specify_cli.cli_customization import (
    resolve_extension_dir,
    get_reference_extension_paths,
    build_alias_map,
    check_reference_extension_update,
    apply_reference_extension_update,
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
        json.dumps(
            {
                "schema_version": "1.0",
                "extensions": {
                    ext_id: {"source": "reference", "path": str(ref_path)}
                },
            }
        )
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
        json.dumps(
            {
                "schema_version": "1.0",
                "extensions": {
                    "team-ai-directives": {
                        "source": "reference",
                        "path": str(ref_path),
                    },
                    "git": {"source": "local", "path": "/some/path"},
                },
            }
        )
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
        json.dumps(
            {
                "schema_version": "1.0",
                "extensions": {
                    "team-ai-directives": {
                        "source": "reference",
                        "path": str(ref_path),
                    }
                },
            }
        )
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


def test_preset_resolver_finds_reference_extension_commands(tmp_path):
    """PresetResolver.resolve() should find commands in reference extensions.

    Regression test for the bug where resolve(), resolve_extension_command_via_manifest(),
    _get_source_info(), and collect_all_layers() all hardcoded
    ``self.extensions_dir / ext_id`` and ignored reference extensions living
    outside ``.specify/extensions/``.
    """
    from specify_cli.presets import PresetResolver

    project_root = tmp_path
    ext_id = "team-ai-directives"
    ref_path = project_root / ext_id
    ref_path.mkdir()

    # Create extension manifest with a command
    (ref_path / "extension.yml").write_text(
        'schema_version: "1.0"\n'
        "extension:\n"
        '  id: "team-ai-directives"\n'
        '  name: "Team AI Directives"\n'
        '  version: "1.0.0"\n'
        '  description: "Team-specific AI directives"\n'
        "requires:\n"
        '  speckit_version: ">=0.1.0"\n'
        "provides:\n"
        "  commands:\n"
        '    - name: "adlc.team-ai-directives.constitution"\n'
        '      file: "commands/constitution.md"\n'
        '      description: "Load team constitution"\n'
    )
    commands_dir = ref_path / "commands"
    commands_dir.mkdir()
    (commands_dir / "constitution.md").write_text("# Team Constitution\n")

    # Register as reference extension
    registry_dir = project_root / ".specify" / "extensions"
    registry_dir.mkdir(parents=True)
    (registry_dir / ".registry").write_text(
        json.dumps(
            {
                "schema_version": "1.0",
                "extensions": {
                    ext_id: {"source": "reference", "path": str(ref_path)}
                },
            }
        )
    )

    resolver = PresetResolver(project_root)

    # Test resolve_extension_command_via_manifest() finds the command
    # in a reference extension living outside .specify/extensions/
    found_via_manifest = resolver.resolve_extension_command_via_manifest(
        "adlc.team-ai-directives.constitution"
    )
    assert found_via_manifest is not None
    assert found_via_manifest == commands_dir / "constitution.md"

    # Test collect_all_layers() includes the reference extension
    layers = resolver.collect_all_layers(
        "adlc.team-ai-directives.constitution", "command"
    )
    assert any("team-ai-directives" in layer.get("source", "") for layer in layers)


# ============================================================================
# Reference Extension Update Helpers
# ============================================================================


def test_check_reference_extension_update_success(tmp_path):
    """Should detect newer version in reference extension manifest."""
    ext_id = "test-ref"
    ref_path = tmp_path / ext_id
    ref_path.mkdir()

    manifest = {
        "schema_version": "1.0",
        "extension": {
            "id": ext_id,
            "name": "Test Ref",
            "version": "2.0.0",
            "description": "Test",
        },
        "requires": {"speckit_version": ">=0.1.0"},
        "provides": {"commands": []},
    }
    import yaml

    (ref_path / "extension.yml").write_text(yaml.dump(manifest, sort_keys=False))

    from packaging import version as pkg_version

    installed = pkg_version.Version("1.0.0")
    metadata = {"source": "reference", "path": str(ref_path)}

    new_version, info = check_reference_extension_update(ext_id, metadata, installed)

    assert new_version is not None
    assert str(new_version) == "2.0.0"
    assert info["manifest_version"] == "2.0.0"
    assert info["reference_path"] == ref_path


def test_check_reference_extension_update_no_change(tmp_path):
    """Should return None when local manifest matches installed version."""
    ext_id = "test-ref"
    ref_path = tmp_path / ext_id
    ref_path.mkdir()

    manifest = {
        "schema_version": "1.0",
        "extension": {
            "id": ext_id,
            "name": "Test Ref",
            "version": "1.0.0",
            "description": "Test",
        },
        "requires": {"speckit_version": ">=0.1.0"},
        "provides": {"commands": []},
    }
    import yaml

    (ref_path / "extension.yml").write_text(yaml.dump(manifest, sort_keys=False))

    from packaging import version as pkg_version

    installed = pkg_version.Version("1.0.0")
    metadata = {"source": "reference", "path": str(ref_path)}

    new_version, info = check_reference_extension_update(ext_id, metadata, installed)

    assert new_version is None
    assert info is None


def test_check_reference_extension_update_not_reference(tmp_path):
    """Should return None for non-reference extensions."""
    from packaging import version as pkg_version

    installed = pkg_version.Version("1.0.0")
    metadata = {"source": "remote", "version": "1.0.0"}

    new_version, info = check_reference_extension_update("test", metadata, installed)

    assert new_version is None
    assert info is None


def test_apply_reference_extension_update_success(tmp_path):
    """Should re-register reference extension with new version and preserve priority."""
    from specify_cli.extensions import ExtensionManager
    from specify_cli import get_speckit_version

    project_dir = tmp_path / "project"
    project_dir.mkdir()
    (project_dir / ".specify" / "extensions" / ".claude" / "commands").mkdir(parents=True)

    ext_id = "test-ref-update"
    ref_path = tmp_path / ext_id
    ref_path.mkdir()

    # v1.0.0 manifest
    manifest_v1 = {
        "schema_version": "1.0",
        "extension": {
            "id": ext_id,
            "name": "Test Ref",
            "version": "1.0.0",
            "description": "Test",
        },
        "requires": {"speckit_version": ">=0.1.0"},
        "provides": {"commands": [{"name": f"adlc.{ext_id}.hello", "file": "hello.md"}]},
    }
    (ref_path / "hello.md").write_text("---\ndescription: Test\n---\n\n$ARGUMENTS\n")
    import yaml

    (ref_path / "extension.yml").write_text(yaml.dump(manifest_v1, sort_keys=False))

    manager = ExtensionManager(project_dir)
    speckit_version = get_speckit_version()

    # Register v1.0.0 with priority 5
    manager.register_reference_extension(ref_path, speckit_version, priority=5)

    registry_v1 = manager.registry.get(ext_id)
    assert registry_v1["version"] == "1.0.0"
    assert registry_v1["priority"] == 5

    # Update manifest to v2.0.0
    manifest_v2 = dict(manifest_v1)
    manifest_v2["extension"]["version"] = "2.0.0"
    (ref_path / "extension.yml").write_text(yaml.dump(manifest_v2, sort_keys=False))

    # Apply update
    update_info = {"reference_path": ref_path, "manifest_version": "2.0.0"}
    apply_reference_extension_update(
        manager, ext_id, update_info, speckit_version, registry_v1
    )

    registry_v2 = manager.registry.get(ext_id)
    assert registry_v2["version"] == "2.0.0"
    assert registry_v2["priority"] == 5  # preserved
    assert registry_v2["source"] == "reference"


def test_copy_reference_extension_commands(tmp_path):
    """Should copy command files from reference path to local extension dir."""
    from specify_cli.cli_customization import copy_reference_extension_commands

    project_dir = tmp_path / "project"
    project_dir.mkdir()

    ref_path = tmp_path / "test-ext"
    ref_path.mkdir()
    commands_dir = ref_path / "commands"
    commands_dir.mkdir()
    (commands_dir / "hello.md").write_text("hello")
    (commands_dir / "world.md").write_text("world")

    copy_reference_extension_commands(project_dir, "test-ext", ref_path)

    dest_dir = project_dir / ".specify" / "extensions" / "test-ext" / "commands"
    assert (dest_dir / "hello.md").exists()
    assert (dest_dir / "world.md").exists()
    assert (dest_dir / "hello.md").read_text() == "hello"


def test_copy_reference_extension_commands_missing_source(tmp_path):
    """Should silently skip when source commands dir does not exist."""
    from specify_cli.cli_customization import copy_reference_extension_commands

    project_dir = tmp_path / "project"
    project_dir.mkdir()

    ref_path = tmp_path / "test-ext"
    ref_path.mkdir()  # no commands/ subdir

    # Should not raise
    copy_reference_extension_commands(project_dir, "test-ext", ref_path)

    dest_dir = project_dir / ".specify" / "extensions" / "test-ext" / "commands"
    assert not dest_dir.exists()


def test_copy_reference_extension_commands_overwrites_existing(tmp_path):
    """Should replace existing command files on re-copy."""
    from specify_cli.cli_customization import copy_reference_extension_commands

    project_dir = tmp_path / "project"
    project_dir.mkdir()

    ref_path = tmp_path / "test-ext"
    ref_path.mkdir()
    commands_dir = ref_path / "commands"
    commands_dir.mkdir()
    (commands_dir / "cmd.md").write_text("v2")

    # Pre-create old version
    dest_dir = project_dir / ".specify" / "extensions" / "test-ext" / "commands"
    dest_dir.mkdir(parents=True)
    (dest_dir / "cmd.md").write_text("v1")
    (dest_dir / "old.md").write_text("should be removed")

    copy_reference_extension_commands(project_dir, "test-ext", ref_path)

    assert (dest_dir / "cmd.md").read_text() == "v2"
    assert not (dest_dir / "old.md").exists()
