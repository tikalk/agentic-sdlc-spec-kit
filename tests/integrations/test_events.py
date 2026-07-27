"""Tests for events module: integration runtime events."""

from __future__ import annotations

import json
import os
import platform
from unittest.mock import MagicMock

import pytest

from specify_cli.events import (
    CANONICAL_EVENTS,
    EVENTS_DISPATCHER_REL,
    collect_extension_events,
    install_integration_events,
    remove_integration_events,
    resolve_events,
    validate_events,
    resolve_and_run_event_command,
)
from specify_cli.integrations.manifest import IntegrationManifest
from specify_cli.integrations.claude import ClaudeIntegration
from specify_cli.integrations.cursor_agent import CursorAgentIntegration
from specify_cli.integrations.opencode import OpencodeIntegration
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
        assert result == {"post_tool_use": [{"command": "speckit.tdd.validate"}]}

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
        assert result["session_start"] == [{"command": "speckit.my-ext.boot"}]

    def test_layer3_multiple_extensions_same_event_accumulate(self, tmp_path):
        """Two extensions declaring the same event both run (#2)."""
        for ext_id, cmd in (("my-ext", "speckit.my-ext.boot"), ("other-ext", "speckit.other.boot")):
            ext_dir = tmp_path / ".specify" / "extensions" / ext_id
            ext_dir.mkdir(parents=True)
            (ext_dir / "extension.yml").write_text(
                f"events:\n  session_start:\n    command: {cmd}\n",
                encoding="utf-8",
            )
        result = resolve_events("claude", None, tmp_path, None)
        assert result["session_start"] == [
            {"command": "speckit.my-ext.boot"},
            {"command": "speckit.other.boot"},
        ]

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
        assert result == {"stop": [{"command": "speckit.override.stop"}]}

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
        assert result == {"pre_tool_use": [{"command": "speckit.my-ext.check"}]}

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
            "pre_tool_use": [{"command": "speckit.tdd.validate", "matcher": "Edit|Write"}],
        }
        install_integration_events(integration, tmp_path, manifest, events)

        config_path = tmp_path / ".claude/settings.json"
        assert config_path.is_file()
        data = json.loads(config_path.read_text())
        assert "hooks" in data
        assert "PreToolUse" in data["hooks"]
        assert data["hooks"]["PreToolUse"][0]["matcher"] == "Edit|Write"
        # #6: native schema is a single `command` string, not command+args.
        inner = data["hooks"]["PreToolUse"][0]["hooks"][0]
        assert isinstance(inner["command"], str)
        assert "args" not in inner
        assert "speckit.tdd.validate" in inner["command"]
        assert "pre_tool_use" in inner["command"]
        # The dispatcher path must be prefixed with ${CLAUDE_PROJECT_DIR}/ for Claude.
        assert "${CLAUDE_PROJECT_DIR}/" in inner["command"]

    def test_claude_emits_all_handlers_for_same_event(self, tmp_path):
        """#2: two handlers on the same event both appear in the native config."""
        integration = ClaudeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        events = {
            "pre_tool_use": [
                {"command": "speckit.tdd.validate"},
                {"command": "speckit.other.check"},
            ],
        }
        install_integration_events(integration, tmp_path, manifest, events)

        data = json.loads((tmp_path / ".claude/settings.json").read_text())
        inner_hooks = data["hooks"]["PreToolUse"][0]["hooks"]
        commands = [h["command"] for h in inner_hooks]
        assert any("speckit.tdd.validate" in c for c in commands)
        assert any("speckit.other.check" in c for c in commands)

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
            "pre_tool_use": [{"command": "speckit.tdd.validate"}],
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
            "session_start": [{"command": "speckit.agent-context.update", "timeout": 60}],
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
        # #6: a complete shell command string (not command+args).
        assert "speckit.agent-context.update" in entry["bash"]
        assert "session_start" in entry["bash"]
        assert entry["bash"] == entry["powershell"]
        assert entry["timeoutSec"] == 60


# -- Gemini timeout unit (#7) ------------------------------------------------

class TestGeminiTimeoutUnit:
    """Gemini measures hook timeouts in milliseconds, not seconds."""

    def test_gemini_timeout_converted_to_ms(self, tmp_path):
        from specify_cli.integrations.gemini import GeminiIntegration
        from specify_cli.events import _native_timeout

        integration = GeminiIntegration()
        # 60 (seconds) -> 60000 (ms) for Gemini; unchanged for seconds-based agents.
        assert _native_timeout(integration, 60) == 60000
        assert _native_timeout(ClaudeIntegration(), 60) == 60


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
            "pre_tool_use": [{"command": "speckit.tdd.validate", "matcher": "Edit"}],
            "session_start": [{"command": "speckit.agent-context.update"}],
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
        # #13: failures must propagate via throw, not process.exit(2) which
        # would kill the OpenCode host process.
        assert "process.exit(2)" not in content
        assert "throw new Error" in content

    def test_opencode_ts_plugin_uses_resolved_interpreter(self, tmp_path):
        """#16: the dispatcher is launched with a resolved interpreter (venv
        when present), not a hard-coded ``python3``."""
        integration = OpencodeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        # Create a project venv so resolve_python_interpreter returns it.
        venv_bin = tmp_path / ".venv" / "bin" / "python"
        venv_bin.parent.mkdir(parents=True)
        venv_bin.write_text("#!/bin/sh\n")

        events = {"session_start": [{"command": "speckit.boot"}]}
        install_integration_events(integration, tmp_path, manifest, events)
        content = (tmp_path / ".opencode/plugin/speckit-events.ts").read_text()
        assert ".venv/bin/python" in content

    def test_opencode_ts_plugin_emits_all_handlers(self, tmp_path):
        """#2: multiple handlers on the same native event all invoke runEvent."""
        integration = OpencodeIntegration()
        manifest = MagicMock(spec=IntegrationManifest)
        manifest.files = {}
        manifest.record_file = MagicMock()
        manifest.record_existing = MagicMock()

        events = {
            "session_start": [
                {"command": "speckit.first.boot"},
                {"command": "speckit.second.boot"},
            ],
        }
        install_integration_events(integration, tmp_path, manifest, events)
        content = (tmp_path / ".opencode/plugin/speckit-events.ts").read_text()
        assert "speckit.first.boot" in content
        assert "speckit.second.boot" in content


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


# -- Merge/teardown idempotency & safety (Tier 3) ----------------------------

def _claude_manifest(tmp_path):
    manifest = MagicMock(spec=IntegrationManifest)
    manifest.files = {}
    manifest.record_file = MagicMock()
    manifest.record_existing = MagicMock()
    manifest.remove = MagicMock()
    return manifest


class TestMergeIdempotency:
    """#9/#11: marker recursion and full-clean-before-add."""

    def test_upgrade_does_not_duplicate_nested_hooks(self, tmp_path):
        """#9: re-running install replaces prior Specify inner hooks instead of
        appending a second matcher-group on every upgrade."""
        integration = ClaudeIntegration()
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)

        events = {"pre_tool_use": [{"command": "speckit.tdd.validate"}]}
        for _ in range(2):
            manifest = _claude_manifest(tmp_path)
            install_integration_events(integration, tmp_path, manifest, events)

        data = json.loads(config_path.read_text())
        groups = data["hooks"]["PreToolUse"]
        # Exactly one matcher-group for Specify (no duplication).
        assert len(groups) == 1
        inner = groups[0]["hooks"]
        assert len(inner) == 1
        assert "speckit.tdd.validate" in inner[0]["command"]

    def test_override_change_removes_stale_event(self, tmp_path):
        """#11: when the resolved set changes from pre_tool_use to stop, the
        old marked pre_tool_use entry is removed, not left active."""
        integration = ClaudeIntegration()
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)

        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
        )
        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"stop": [{"command": "speckit.end"}]},
        )

        data = json.loads(config_path.read_text())
        assert "PreToolUse" not in data["hooks"]
        assert "Stop" in data["hooks"]


class TestEmptyMapRemoval:
    """#3: --events false / empty resolved map strips prior hooks."""

    def test_empty_events_removes_prior_hooks(self, tmp_path):
        integration = ClaudeIntegration()
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)

        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
        )
        assert config_path.is_file()

        # Now resolve to empty (--events false): prior hooks must be removed.
        install_integration_events(integration, tmp_path, _claude_manifest(tmp_path), {})

        # The dispatcher is shared and left in place (#10); only native hooks
        # are stripped. The settings file had no user content → deleted (#14).
        assert not config_path.exists() or "hooks" not in json.loads(config_path.read_text())


class TestTeardownDataSafety:
    """#14/#22/#23: preserve user content, delete Spec-Kit-created empties."""

    def test_remove_deletes_spec_kit_created_config(self, tmp_path):
        """#14: a config Spec Kit created from scratch is deleted (not left as
        ``{}``) so manifest.uninstall() doesn't preserve an empty stub."""
        integration = ClaudeIntegration()
        manifest = _claude_manifest(tmp_path)
        install_integration_events(
            integration, tmp_path, manifest,
            {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
        )
        config_path = tmp_path / ".claude/settings.json"
        assert config_path.is_file()

        remove_integration_events(integration, tmp_path, manifest)
        assert not config_path.exists()

    def test_remove_preserves_user_content_in_config(self, tmp_path):
        """#14: a pre-existing config with user content is kept (user hooks
        survive teardown)."""
        integration = ClaudeIntegration()
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(json.dumps({
            "hooks": {
                "PreToolUse": [{
                    "matcher": "Bash",
                    "hooks": [{"type": "command", "command": "user-check"}],
                }]
            },
            "userSetting": True,
        }))

        manifest = _claude_manifest(tmp_path)
        install_integration_events(
            integration, tmp_path, manifest,
            {"stop": [{"command": "speckit.end"}]},
        )
        remove_integration_events(integration, tmp_path, manifest)

        data = json.loads(config_path.read_text())
        # User hook and setting preserved; Specify hook gone.
        assert data["userSetting"] is True
        assert "Stop" not in data.get("hooks", {})
        assert data["hooks"]["PreToolUse"][0]["matcher"] == "Bash"

    def test_jsonc_config_not_reset_on_merge(self, tmp_path):
        """#22: a JSONC/unparseable native config is left untouched on merge."""
        integration = ClaudeIntegration()
        config_path = tmp_path / ".claude/settings.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        jsonc = '{\n  // my comment\n  "hooks": {}\n}\n'
        config_path.write_text(jsonc)

        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
        )
        # User content preserved verbatim — not reset to {}.
        assert config_path.read_text() == jsonc

    def test_jsonc_opencode_config_not_reset(self, tmp_path):
        """#23: a malformed opencode.json is preserved, not reset to {}."""
        integration = OpencodeIntegration()
        config_path = tmp_path / "opencode.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        malformed = "{ not valid json"
        config_path.write_text(malformed)

        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"session_start": [{"command": "speckit.boot"}]},
        )
        assert config_path.read_text() == malformed


class TestCopilotMergeTeardown:
    """#8: Copilot dedicated hooks JSON merges owned entries / teardown
    removes only owned entries."""

    def test_copilot_merge_preserves_user_hooks(self, tmp_path):
        integration = CopilotIntegration()
        config_path = tmp_path / ".github/hooks/speckit.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(json.dumps({
            "version": 1,
            "hooks": {
                "sessionStart": [{"type": "command", "bash": "user-hook"}],
            },
        }))

        install_integration_events(
            integration, tmp_path, _claude_manifest(tmp_path),
            {"session_start": [{"command": "speckit.boot"}]},
        )
        data = json.loads(config_path.read_text())
        entries = data["hooks"]["sessionStart"]
        bash_cmds = [e.get("bash") for e in entries]
        assert "user-hook" in bash_cmds
        assert any("speckit.boot" in c for c in bash_cmds)

    def test_copilot_teardown_removes_only_owned_entries(self, tmp_path):
        integration = CopilotIntegration()
        config_path = tmp_path / ".github/hooks/speckit.json"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(json.dumps({
            "version": 1,
            "hooks": {
                "sessionStart": [{"type": "command", "bash": "user-hook"}],
            },
        }))

        manifest = _claude_manifest(tmp_path)
        install_integration_events(
            integration, tmp_path, manifest,
            {"session_start": [{"command": "speckit.boot"}]},
        )
        remove_integration_events(integration, tmp_path, manifest)

        data = json.loads(config_path.read_text())
        # User hook preserved; Spec-Kit entry gone.
        assert data["hooks"]["sessionStart"][0]["bash"] == "user-hook"

    def test_copilot_teardown_deletes_spec_kit_only_file(self, tmp_path):
        """#8/#14: when the file held only Spec-Kit entries, teardown deletes it."""
        integration = CopilotIntegration()
        manifest = _claude_manifest(tmp_path)
        install_integration_events(
            integration, tmp_path, manifest,
            {"session_start": [{"command": "speckit.boot"}]},
        )
        config_path = tmp_path / ".github/hooks/speckit.json"
        assert config_path.is_file()
        remove_integration_events(integration, tmp_path, manifest)
        assert not config_path.exists()


class TestSharedDispatcherRefcount:
    """#10: the shared .specify/events.py dispatcher is not deleted while
    another installed event-capable integration still references it."""

    def test_dispatcher_kept_when_other_integration_references_it(self, tmp_path):
        # Simulate two event-capable integrations installed: claude (the one
        # being uninstalled) and codex (still installed). The codex manifest
        # lists the dispatcher, so removing claude must not delete it.
        from specify_cli.integrations.codex import CodexIntegration

        claude = ClaudeIntegration()
        codex = CodexIntegration()

        # Install claude's events (writes dispatcher + claude config).
        claude_manifest = _claude_manifest(tmp_path)
        install_integration_events(
            claude, tmp_path, claude_manifest,
            {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
        )
        # Install codex's events (re-writes shared dispatcher + codex config).
        codex_manifest = MagicMock(spec=IntegrationManifest)
        codex_manifest.files = {}
        codex_manifest.record_file = MagicMock()
        codex_manifest.record_existing = MagicMock()
        codex_manifest.remove = MagicMock()
        install_integration_events(
            codex, tmp_path, codex_manifest,
            {"pre_tool_use": [{"command": "speckit.codex.check"}]},
        )

        # Persist a codex manifest on disk so the refcount check finds it.
        codex_disk = IntegrationManifest(codex.key, tmp_path, version="test")
        codex_disk._files = {EVENTS_DISPATCHER_REL: "x"}
        codex_disk.save()

        # Write the integration-state JSON so installed_integration_keys sees codex.
        import json as _json
        state_path = tmp_path / ".specify" / "integrations.json"
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state_path.write_text(_json.dumps({
            "default_integration": "claude",
            "installed_integrations": ["claude", "codex"],
        }))

        dispatcher_path = tmp_path / EVENTS_DISPATCHER_REL
        assert dispatcher_path.exists()

        # Removing claude should leave the dispatcher (codex still uses it).
        remove_integration_events(claude, tmp_path, claude_manifest)
        assert dispatcher_path.exists()


class TestSafeWriteDestination:
    """#12: write targets are validated before any bytes are written."""

    def test_symlinked_config_dir_rejected(self, tmp_path):
        integration = ClaudeIntegration()
        # Create a symlinked .claude directory pointing outside the project.
        outside = tmp_path / "outside"
        outside.mkdir()
        linked = tmp_path / ".claude"
        os.symlink(outside, linked)

        with pytest.raises(ValueError, match="(?i)symlink|escapes|outside"):
            install_integration_events(
                integration, tmp_path, _claude_manifest(tmp_path),
                {"pre_tool_use": [{"command": "speckit.tdd.validate"}]},
            )
        # No content written through the symlink.
        assert not (outside / "settings.json").exists()
