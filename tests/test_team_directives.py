from pathlib import Path
import pytest
from specify_cli import sync_team_ai_directives, TEAM_DIRECTIVES_DIRNAME


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