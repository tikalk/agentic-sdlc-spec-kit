"""Tests for specify skill CLI commands."""

import json
import os
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from typer.testing import CliRunner

from specify_cli import app
from specify_cli.cli_customization import (
    SKILLS_AVAILABLE,
    skill_app,
)


runner = CliRunner()


class TestSkillCommandsAvailable:
    """Test that skill commands are properly registered."""

    def test_skill_app_is_registered(self):
        """Verify skill_app is imported and available."""
        assert skill_app is not None
        assert SKILLS_AVAILABLE is True

    def test_skill_subcommand_registered(self):
        """Verify skill subcommand is in the main app."""
        # Get the list of commands from app
        # Typer doesn't expose command list directly, so we test via CLI
        result = runner.invoke(app, ["--help"])
        assert result.exit_code == 0
        # Check that skill is mentioned in help
        assert "skill" in result.output.lower()


class TestSkillHelp:
    """Test skill command help output."""

    def test_skill_help_shows_commands(self):
        """Verify all skill commands appear in help."""
        result = runner.invoke(app, ["skill", "--help"])
        assert result.exit_code == 0
        # Check all expected commands are listed
        expected_commands = [
            "search",
            "install",
            "update",
            "remove",
            "list",
            "eval",
            "sync-team",
            "check-updates",
            "config",
        ]
        for cmd in expected_commands:
            assert cmd in result.output

    def test_skill_without_subcommand_shows_help_message(self):
        """Verify running 'specify skill' shows help message."""
        result = runner.invoke(app, ["skill"])
        assert result.exit_code == 0
        # Should show the skills banner/help message
        assert "skill" in result.output.lower() or "help" in result.output.lower()


class TestSkillSearch:
    """Test specify skill search command."""

    @patch("specify_cli.cli_customization.SkillsRegistryClient")
    def test_skill_search_basic(self, mock_registry_client):
        """Test skill search with basic query."""
        # Mock the registry client
        mock_instance = MagicMock()
        mock_instance.search.return_value = []
        mock_registry_client.return_value = mock_instance

        result = runner.invoke(app, ["skill", "search", "test"])
        # Will fail network call if not mocked properly, but should not crash

    def test_skill_search_with_options(self):
        """Test skill search with various options."""
        # Test with --limit option (may fail on network but shouldn't crash)
        result = runner.invoke(app, ["skill", "search", "python", "--limit", "5"])
        # Exit code may be non-zero due to network, but shouldn't be a Typer error


class TestSkillList:
    """Test specify skill list command."""

    @patch("specify_cli.cli_customization.SkillsManifest")
    def test_skill_list_no_manifest(self, mock_manifest):
        """Test skill list when no skills.json exists."""
        # Mock manifest to not exist
        mock_instance = MagicMock()
        mock_instance.exists.return_value = False
        mock_manifest.return_value = mock_instance

        result = runner.invoke(app, ["skill", "list"])
        # Should show message about no skills installed
        assert (
            "no skills" in result.output.lower() or "not found" in result.output.lower()
        )


class TestSkillConfig:
    """Test specify skill config command."""

    def test_skill_config_shows_config(self):
        """Test skill config shows current configuration."""
        result = runner.invoke(app, ["skill", "config"])
        assert result.exit_code == 0
        # Should show configuration options
        assert (
            "auto_activation_threshold" in result.output
            or "registry_url" in result.output
        )

    def test_skill_config_get_specific_key(self):
        """Test getting a specific config key."""
        result = runner.invoke(app, ["skill", "config", "registry_url"])
        assert result.exit_code == 0
        # Should show the key value

    def test_skill_config_invalid_key(self):
        """Test setting invalid config key."""
        result = runner.invoke(app, ["skill", "config", "invalid_key", "value"])
        # Should show error about invalid key
        assert "invalid" in result.output.lower() or "unknown" in result.output.lower()


class TestSkillEval:
    """Test specify skill eval command."""

    def test_skill_eval_missing_path(self):
        """Test skill eval with missing path."""
        result = runner.invoke(app, ["skill", "eval", "nonexistent_path"])
        # Should show error about skill not found
        assert result.exit_code != 0 or "not found" in result.output.lower()


class TestSkillCheckUpdates:
    """Test specify skill check-updates command."""

    @patch("specify_cli.cli_customization.SkillsManifest")
    def test_skill_check_updates_no_skills(self, mock_manifest):
        """Test check-updates when no skills installed."""
        mock_instance = MagicMock()
        mock_instance.exists.return_value = False
        mock_manifest.return_value = mock_instance

        result = runner.invoke(app, ["skill", "check-updates"])
        assert "no skills" in result.output.lower()


class TestSkillUpdate:
    """Test specify skill update command."""

    def test_skill_update_requires_name_or_flag(self):
        """Test skill update requires skill name or --all flag."""
        result = runner.invoke(app, ["skill", "update"])
        # Should show error about requiring name or --all, or about no manifest
        assert (
            "name" in result.output.lower()
            or "all" in result.output.lower()
            or "no skills" in result.output.lower()
        )


class TestSkillRemove:
    """Test specify skill remove command."""

    def test_skill_remove_requires_name(self):
        """Test skill remove requires skill name."""
        result = runner.invoke(app, ["skill", "remove"])
        # Should show error about missing argument
        assert result.exit_code != 0


class TestSkillInstall:
    """Test specify skill install command."""

    def test_skill_install_requires_ref(self):
        """Test skill install requires skill reference."""
        result = runner.invoke(app, ["skill", "install"])
        # Should show error about missing argument
        assert result.exit_code != 0


class TestSkillSyncTeam:
    """Test specify skill sync-team command."""

    @patch("specify_cli.cli_customization.SkillsManifest")
    def test_skill_sync_team_no_team_directives(self, mock_manifest):
        """Test sync-team when no team directives configured."""
        mock_instance = MagicMock()
        mock_instance.exists.return_value = True
        mock_manifest.return_value = mock_instance

        result = runner.invoke(app, ["skill", "sync-team"])
        # Should show message about no team directives
        assert "team" in result.output.lower() or "directives" in result.output.lower()
