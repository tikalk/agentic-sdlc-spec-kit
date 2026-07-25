"""Tests for events module: integration runtime events."""

from __future__ import annotations

import json
import platform
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
import yaml

from specify_cli.events import (
    CANONICAL_EVENTS,
    collect_extension_events,
    events_stale_exclusions,
    install_integration_events,
    remove_integration_events,
    resolve_events,
    validate_events,
    resolve_and_run_event_command,
)
from specify_cli.integrations.base import IntegrationBase
from specify_cli.integrations.manifest import IntegrationManifest
from specify_cli.integrations.claude import ClaudeIntegration
from specify_cli.integrations.cursor_agent import CursorAgentIntegration
from specify_cli.integrations.codex import CodexIntegration
from specify_cli.integrations.opencode import OpencodeIntegration
from specify_cli.integrations.qwen import QwenIntegration
from specify_cli.integrations.gemini import GeminiIntegration
from specify_cli.integrations.devin import DevinIntegration
from specify_cli.integrations.tabnine import TabnineIntegration
from specify_cli.integrations.copilot import CopilotIntegration


# -- resolve_events --------------------------------------------------------

class TestResolveEvents:
    """Test the 4-layer event resolution chain."""

    def test_layer1_disabled_returns_empty(self, tmp_path):
        """--events false returns empty dict."""
        result = resolve_events(
            "claude",
            {"events": {"post_tool_use": {"command": "speckit.tdd.validate"}}},
            tmp_path,
            {"events": "false"},
        )
        assert result == {}

    def test_layer4_built_in_defaults(self, tmp_path):
        """Returns baseline defaults when no overrides exist."""
        result = resolve_events(
            "claude",
            {"events": {"post_tool_use": {"command": "speckit.tdd.validate"}}},
            tmp_path,
            None,
        )
        assert result == {"post_tool_use": {"command": "speckit.tdd.validate"}}

    def test_layer3_extension_events_appended(self, tmp_path):
        """Extension-declared events are resolved and appended."""
        ext_dir = tmp_path / ".specify" / "extensions" / "my-ext"
        ext_dir.mkdir(parents=True)
        ext_yml = ext_dir / "extension.yml"
        ext_yml.write_text(
            "events:\n  session_start:\n    command: speckit.my-ext.boot\n",
            encoding="utf-8",
        )

        result = resolve_events(
            "claude",
            {"events": {"post_tool_use": {"command": "speckit.tdd.validate"}}},
            tmp_path,
            None,
        )
        assert "post_tool_use" in result
        assert "session_start" in result
        assert result["session_start"] == {"command": "speckit.my-ext.boot"}

    def test_layer2_yaml_override_replaces(self, tmp_path):
        """integration-events.yml override replaces baseline entirely."""
        override_file = tmp_path / ".specify" / "integration-events.yml"
        override_file.parent.mkdir(parents=True, exist_ok=True)
        override_file.write_text(
            "integrations:\n"
            "  claude:\n"
            "    events:\n"
            "      stop:\n"
            "        command: speckit.override.stop\n",
            encoding="utf-8",
        )

        result = resolve_events(
            "claude",
            {"events": {"post_tool_use": {"command": "speckit.tdd.validate"}}},
            tmp_path,
            None,
        )
        assert result == {"stop": {"command": "speckit.override.stop"}}

    def test_layer2_empty_events_disables(self, tmp_path):
        """Empty events override disables events."""
        override_file = tmp_path / ".specify" / "integration-events.yml"
        override_file.parent.mkdir(parents=True, exist_ok=True)
        override_file.write_text(
            "integrations:\n"
            "  claude:\n"
            "    events: {}\n",
            encoding="utf-8",
        )

        result = resolve_events(
            "claude",
            {"events": {"post_tool_use": {"command": "speckit.tdd.validate"}}},
            tmp_path,
            None,
        )
        assert result == {}

    def test_no_config_no_events(self, tmp_path):
        """Safe fallback with empty config/options."""
        result = resolve_events("claude", None, tmp_path, None)
        assert result == {}


# -- collect_extension_events -----------------------------------------------

class TestCollectExtensionEvents:
    """Test scanning extension.yml files for events: declarations."""

    def test_no_extensions_dir(self, tmp_path):
        assert collect_extension_events(tmp_path) == {}

    def test_no_events_in_extension(self, tmp_path):
        ext_dir = tmp_path / ".specify" / "extensions" / "my-ext"
        ext_dir.mkdir(parents=True)
        (ext_dir / "extension.yml").write_text("extension:\n  id: my-ext\n", encoding="utf-8")
        assert collect_extension_events(tmp_path) == {}

    def test_events_collected(self, tmp_path):
        ext_dir = tmp_path / ".specify" / "extensions" / "my-ext"
        ext_dir.mkdir(parents=True)
        (ext_dir / "extension.yml").write_text(
            "events:\n  pre_tool_use:\n    command: speckit.my-ext.check\n",
            encoding="utf-8",
        )
        result = collect_extension_events(tmp_path)
        assert result == {"pre_tool_use": {"command": "speckit.my-ext.check"}}

    def test_invalid_yaml_skipped(self, tmp_path):
        ext_dir = tmp_path / ".specify" / "extensions" / "my-ext"
        ext_dir.mkdir(parents=True)
        (ext_dir / "extension.yml").write_text("invalid: - - -", encoding="utf-8")
        assert collect_extension_events(tmp_path) == {}


# -- Class-driven mappings --------------------------------------------------

class TestCanonicalEventMapping:
    """Verify registry-driven mapping is correct on integration classes."""

    def test_claude_identity(self):
        integration = ClaudeIntegration()
        assert integration.supports_events() is True
        assert integration.CANONICAL_TO_NATIVE["pre_tool_use"] == "PreToolUse"
        assert integration.CANONICAL_TO_NATIVE["session_start"] == "SessionStart"

    def test_cursor_camelcase(self):
        integration = CursorAgentIntegration()
        assert integration.supports_events() is True
        assert integration.CANONICAL_TO_NATIVE["pre_tool_use"] == "preToolUse"
        assert integration.CANONICAL_TO_NATIVE["user_prompt_submit"] == "beforeSubmitPrompt"

    def test_opencode_limited(self):
        integration = OpencodeIntegration()
        assert integration.supports_events() is True
        assert integration.CANONICAL_TO_NATIVE["pre_tool_use"] == "tool.execute.before"
        assert "stop" not in integration.CANONICAL_TO_NATIVE

    def test_copilot_mapping(self):
        integration = CopilotIntegration()
        assert integration.supports_events() is True
        assert integration.CANONICAL_TO_NATIVE["session_start"] == "sessionStart"
        assert integration.CANONICAL_TO_NATIVE["user_prompt_submit"] == "userPromptSubmitted"


# -- validate_events --------------------------------------------------------

class TestValidateEvents:
    """Test manifest validation."""

    def test_unknown_event_rejected(self):
        from specify_cli.extensions import ValidationError
        data = {"events": {"unknown_event": {"command": "speckit.tdd.validate"}}}
        with pytest.raises(ValidationError) as exc:
            validate_events(data)
        assert "Unknown event" in str(exc.value)

    def test_known_event_accepted(self):
        data = {"events": {"pre_tool_use": {"command": "speckit.tdd.validate"}}}
        validate_events(data)  # no raise

    def test_all_canonical_events_accepted(self):
        data = {
            "events": {
                name: {"command": "speckit.test"}
                for name in CANONICAL_EVENTS
            }
        }
        validate_events(data)  # no raise


# -- Claude settings JSON merging -------------------------------------------

class TestClaudeJsonMerging:
    """Test Claude settings JSON merging and cleanup."""

    def test_merge_into_empty_file(self, tmp_path):
        integration = ClaudeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        events = {
            "pre_tool_use": {"command": "speckit.tdd.validate", "matcher": "Edit|Write"},
        }
        install_integration_events(integration, tmp_path, manifest, events)

        config_path = tmp_path / ".claude/settings.json"
        assert config_path.is_file()
        data = json.loads(config_path.read_text())
        assert "hooks" in data
        assert "PreToolUse" in data["hooks"]
        assert data["hooks"]["PreToolUse"][0]["matcher"] == "Edit|Write"

    def test_remove_preserves_user_hooks(self, tmp_path):
        integration = ClaudeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        # Pre-seed user setting
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(
            json.dumps(
                {
                    "hooks": {
                        "PreToolUse": [
                            {
                                "matcher": "Bash",
                                "hooks": [
                                    {
                                        "type": "command",
                                        "command": "user-check",
                                    }
                                ],
                            }
                        ]
                    }
                }
            )
        )

        events = {
            "pre_tool_use": {"command": "speckit.tdd.validate"},
        }
        install_integration_events(integration, tmp_path, manifest, events)
        remove_integration_events(integration, tmp_path, manifest)

        data = json.loads(config_path.read_text())
        assert "hooks" in data
        assert "PreToolUse" in data["hooks"]
        assert len(data["hooks"]["PreToolUse"]) == 1
        assert data["hooks"]["PreToolUse"][0]["matcher"] == "Bash"


# -- Copilot events JSON writing --------------------------------------------

class TestCopilotJsonWriting:
    """Test Copilot dedicated .github/hooks/speckit.json generation."""

    def test_copilot_json_generation(self, tmp_path):
        integration = CopilotIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        events = {
            "session_start": {"command": "speckit.agent-context.update", "timeout": 60},
        }
        install_integration_events(integration, tmp_path, manifest, events)

        config_path = tmp_path / ".github/hooks/speckit.json"
        assert config_path.is_file()
        data = json.loads(config_path.read_text())
        assert data["version"] == 1
        assert "hooks" in data
        assert "sessionStart" in data["hooks"]
        entry = data["hooks"]["sessionStart"][0]
        assert entry["type"] == "command"
        assert "speckit.agent-context.update" in entry["bash"]
        assert "session_start" in entry["bash"]
        assert entry["timeoutSec"] == 60


# -- Opencode TS Plugin merging ---------------------------------------------

class TestOpencodePluginMerging:
    """Test Opencode typescript plugin generation."""

    def test_opencode_ts_plugin_generation(self, tmp_path):
        integration = OpencodeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        events = {
            "pre_tool_use": {"command": "speckit.tdd.validate", "matcher": "Edit"},
            "session_start": {"command": "speckit.agent-context.update"},
        }
        install_integration_events(integration, tmp_path, manifest, events)

        plugin_path = tmp_path / ".opencode/plugin/speckit-events.ts"
        assert plugin_path.is_file()
        content = plugin_path.read_text()
        assert "runEvent" in content
        assert "tool.execute.before" in content
        assert "session.created" in content
        assert "speckit.tdd.validate" in content
        assert "speckit.agent-context.update" in content


# -- Command runner test (core execution) -----------------------------------

class TestCommandRunner:
    """Test the core command/script resolution and runner."""

    def test_run_command_not_found(self, tmp_path):
        code = resolve_and_run_event_command("nonexistent.command", "session_start", "{}", tmp_path)
        assert code == 0  # no-ops gracefully

    def test_run_command_resolves_and_executes(self, tmp_path):
        # Create a mock core command md file
        cmd_dir = tmp_path / ".specify" / "templates" / "commands"
        cmd_dir.mkdir(parents=True)
        cmd_file = cmd_dir / "test.md"
        cmd_file.write_text(
            "---\n"
            "description: \"Test\"\n"
            "scripts:\n"
            "  sh: scripts/test.sh\n"
            "---\n"
            "Body\n",
            encoding="utf-8",
        )

        script_dir = tmp_path / ".specify" / "scripts"
        script_dir.mkdir(parents=True)
        script_file = script_dir / "test.sh"
        script_file.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        script_file.chmod(0o755)

        # Skip on Windows because sh is POSIX
        if platform.system().lower().startswith("win"):
            return

        code = resolve_and_run_event_command("speckit.test", "session_start", "{}", tmp_path)
        assert code == 0
