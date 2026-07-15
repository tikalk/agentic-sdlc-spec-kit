"""
Test that bundled extensions properly register hooks during installation.

This test verifies the fix for the issue where .specify/extensions.yml
was not being created when bundled extensions with hooks were installed
via _install_bundled_extensions().
"""

import shutil
import tempfile
import yaml
from pathlib import Path

import pytest

from specify_cli.extensions import ExtensionManager


@pytest.fixture
def temp_project():
    """Create a temporary project directory."""
    tmpdir = tempfile.mkdtemp()
    project_path = Path(tmpdir)
    (project_path / ".specify").mkdir()
    (project_path / ".claude" / "commands").mkdir(parents=True)
    yield project_path
    shutil.rmtree(tmpdir)


@pytest.fixture
def extension_with_hooks(temp_project):
    """Create a test extension directory with hooks."""
    ext_source = temp_project / "ext_source"
    ext_source.mkdir()

    ext_manifest = {
        "schema_version": "1.0",
        "extension": {
            "id": "test-hooks",
            "name": "Test Extension With Hooks",
            "version": "1.0.0",
            "description": "Test extension for hook registration",
            "author": "test",
            "license": "MIT",
        },
        "requires": {
            "speckit_version": ">=0.1.0",
        },
        "provides": {
            "commands": [
                {
                    "name": "speckit.test-hooks.before",
                    "file": "commands/test.md",
                    "description": "Test command",
                }
            ],
        },
        "hooks": {
            "before_specify": {
                "command": "speckit.test-hooks.before",
                "description": "Test hook before specify",
                "optional": False,
            },
            "after_tasks": {
                "command": "speckit.test-hooks.before",
                "description": "Test hook after tasks",
                "optional": True,
                "prompt": "Run test after tasks?",
            },
        },
    }

    (ext_source / "extension.yml").write_text(yaml.dump(ext_manifest))

    # Create commands directory and file
    commands_dir = ext_source / "commands"
    commands_dir.mkdir()
    (commands_dir / "test.md").write_text("# Test Command\n\nTest content")

    return ext_source


def test_hook_registration_during_install(temp_project, extension_with_hooks):
    """Test that hooks are registered when installing an extension with hooks."""
    # Verify extensions.yml doesn't exist initially
    extensions_yml = temp_project / ".specify" / "extensions.yml"
    assert not extensions_yml.exists()

    # Install extension using the manager (which should register hooks)
    manager = ExtensionManager(temp_project)
    manager.install_from_directory(
        extension_with_hooks, "0.3.0", register_commands=False
    )

    # Verify extensions.yml was created
    assert extensions_yml.exists(), (
        "extensions.yml should be created after installing extension with hooks"
    )

    # Verify hooks were registered
    config = yaml.safe_load(extensions_yml.read_text())
    assert "hooks" in config, "extensions.yml should contain hooks key"

    # Verify before_specify hook
    assert "before_specify" in config["hooks"], (
        "before_specify hook should be registered"
    )
    before_hooks = config["hooks"]["before_specify"]
    assert len(before_hooks) == 1
    assert before_hooks[0]["extension"] == "test-hooks"
    assert before_hooks[0]["command"] == "speckit.test-hooks.before"
    assert before_hooks[0]["enabled"] is True
    assert before_hooks[0]["optional"] is False

    # Verify after_tasks hook
    assert "after_tasks" in config["hooks"], "after_tasks hook should be registered"
    after_hooks = config["hooks"]["after_tasks"]
    assert len(after_hooks) == 1
    assert after_hooks[0]["extension"] == "test-hooks"
    assert after_hooks[0]["command"] == "speckit.test-hooks.before"
    assert after_hooks[0]["enabled"] is True
    assert after_hooks[0]["optional"] is True
    assert after_hooks[0]["prompt"] == "Run test after tasks?"


def test_hook_registration_preserves_existing_hooks(temp_project, extension_with_hooks):
    """Test that registering hooks for a new extension preserves existing hooks."""
    # Create initial hooks config
    extensions_yml = temp_project / ".specify" / "extensions.yml"
    initial_config = {
        "installed": [],
        "settings": {"auto_execute_hooks": True},
        "hooks": {
            "before_plan": [
                {
                    "extension": "existing-ext",
                    "command": "existing.command",
                    "enabled": True,
                    "optional": True,
                }
            ]
        },
    }
    extensions_yml.write_text(yaml.dump(initial_config))

    # Install new extension with hooks
    manager = ExtensionManager(temp_project)
    manager.install_from_directory(
        extension_with_hooks, "0.3.0", register_commands=False
    )

    # Verify both old and new hooks exist
    config = yaml.safe_load(extensions_yml.read_text())

    # Old hook should still be there
    assert "before_plan" in config["hooks"]
    assert len(config["hooks"]["before_plan"]) == 1
    assert config["hooks"]["before_plan"][0]["extension"] == "existing-ext"

    # New hooks should be added
    assert "before_specify" in config["hooks"]
    assert config["hooks"]["before_specify"][0]["extension"] == "test-hooks"

    assert "after_tasks" in config["hooks"]
    assert config["hooks"]["after_tasks"][0]["extension"] == "test-hooks"


def test_extension_without_hooks_doesnt_create_yml(temp_project):
    """Test that extension without hooks doesn't create extensions.yml."""
    # Create extension without hooks
    ext_source = temp_project / "ext_no_hooks"
    ext_source.mkdir()

    ext_manifest = {
        "schema_version": "1.0",
        "extension": {
            "id": "test-no-hooks",
            "name": "Test Extension Without Hooks",
            "version": "1.0.0",
            "description": "Test extension without hooks",
            "author": "test",
            "license": "MIT",
        },
        "requires": {
            "speckit_version": ">=0.1.0",
        },
        "provides": {
            "commands": [
                {
                    "name": "speckit.test-no-hooks.dummy",
                    "file": "commands/dummy.md",
                    "description": "Dummy command",
                }
            ],
        },
    }

    (ext_source / "extension.yml").write_text(yaml.dump(ext_manifest))

    # Create commands directory and file
    commands_dir = ext_source / "commands"
    commands_dir.mkdir()
    (commands_dir / "dummy.md").write_text("# Dummy Command\n\nDummy content")

    extensions_yml = temp_project / ".specify" / "extensions.yml"
    assert not extensions_yml.exists()

    # Install extension
    manager = ExtensionManager(temp_project)
    manager.install_from_directory(ext_source, "0.3.0", register_commands=False)

    # extensions.yml IS created even if extension has no hooks
    # (to track installed extensions in the installed list)
    assert extensions_yml.exists(), (
        "extensions.yml should be created to track installed extensions"
    )
    
    # But hooks section should be empty/missing
    config = yaml.safe_load(extensions_yml.read_text())
    assert not config.get("hooks"), "hooks section should be empty for extensions without hooks"


def test_hook_update_replaces_existing_hook(temp_project, extension_with_hooks):
    """Test that updating an extension updates its hooks in extensions.yml."""
    # Install first version
    manager = ExtensionManager(temp_project)
    manager.install_from_directory(
        extension_with_hooks, "0.3.0", register_commands=False
    )

    extensions_yml = temp_project / ".specify" / "extensions.yml"
    yaml.safe_load(extensions_yml.read_text())

    # Uninstall
    manager.remove("test-hooks")

    # Modify hooks in extension
    manifest_path = extension_with_hooks / "extension.yml"
    manifest_data = yaml.safe_load(manifest_path.read_text())
    manifest_data["extension"]["version"] = "2.0.0"
    manifest_data["hooks"]["before_specify"]["description"] = "Updated description"
    manifest_data["hooks"]["before_specify"]["optional"] = True  # Changed from False
    manifest_path.write_text(yaml.dump(manifest_data))

    # Reinstall
    manager.install_from_directory(
        extension_with_hooks, "0.3.0", register_commands=False
    )

    # Verify hooks were updated
    config_v2 = yaml.safe_load(extensions_yml.read_text())
    before_hook = config_v2["hooks"]["before_specify"][0]

    assert before_hook["description"] == "Updated description"
    assert before_hook["optional"] is True  # Should be updated


def test_team_ai_directives_declares_hooks():
    """Test that the bundled team-ai-directives extension declares hooks.

    The extension must register before_specify and before_plan hooks so that
    team-discover is auto-invoked by the spec workflow's pre-execution hook
    checks. Without these declarations, register_hooks() writes nothing and
    the agent never triggers team-discover during /spec.specify or /spec.plan.
    """
    ext_yml = (
        Path(__file__).resolve().parent.parent
        / "extensions"
        / "team-ai-directives"
        / "extension.yml"
    )
    assert ext_yml.exists(), "team-ai-directives/extension.yml must exist"

    manifest = yaml.safe_load(ext_yml.read_text())
    assert "hooks" in manifest, (
        "team-ai-directives extension.yml must declare a 'hooks' block "
        "so that register_hooks() populates extensions.yml during install"
    )

    hooks = manifest["hooks"]
    assert "before_specify" in hooks, (
        "team-ai-directives must register a before_specify hook to auto-invoke "
        "team-discover before /spec.specify"
    )
    assert hooks["before_specify"]["command"] == "adlc.team-ai-directives.discover"
    assert hooks["before_specify"]["optional"] is False, (
        "before_specify hook should be mandatory (optional: false)"
    )

    assert "before_plan" in hooks, (
        "team-ai-directives must register a before_plan hook to auto-invoke "
        "team-discover before /spec.plan"
    )
    assert hooks["before_plan"]["command"] == "adlc.team-ai-directives.discover"
    assert hooks["before_plan"]["optional"] is False, (
        "before_plan hook should be mandatory (optional: false)"
    )


def test_team_ai_directives_registers_boot_command():
    """Test that the bundled team-ai-directives extension registers team.boot.

    The boot command must have model-invocation: true so the CLI auto-generates
    a team-boot skill. This skill appears in the agent's available skills list
    and can be self-triggered by the model on any interaction — not just spec
    workflow commands. Without it, the AGENTS.md "Strict Compliance" directive
    has no actionable skill for the model to invoke on plain user messages.
    """
    ext_yml = (
        Path(__file__).resolve().parent.parent
        / "extensions"
        / "team-ai-directives"
        / "extension.yml"
    )
    assert ext_yml.exists(), "team-ai-directives/extension.yml must exist"

    manifest = yaml.safe_load(ext_yml.read_text())
    commands = manifest.get("provides", {}).get("commands", [])

    boot_cmd = None
    for cmd in commands:
        if cmd.get("name") == "adlc.team-ai-directives.boot":
            boot_cmd = cmd
            break

    assert boot_cmd is not None, (
        "team-ai-directives must register an adlc.team-ai-directives.boot command"
    )
    assert "team.boot" in boot_cmd.get("aliases", []), (
        "team.boot alias must be registered for the boot command"
    )

    boot_file = (
        Path(__file__).resolve().parent.parent
        / "extensions"
        / "team-ai-directives"
        / boot_cmd["file"]
    )
    assert boot_file.exists(), f"boot command file {boot_cmd['file']} must exist"

    boot_content = boot_file.read_text()
    assert "model-invocation: true" in boot_content, (
        "boot command must have model-invocation: true so the CLI "
        "auto-generates a team-boot skill"
    )
    assert "EXTREMELY_IMPORTANT" in boot_content, (
        "boot command must use EXTREMELY_IMPORTANT framing to enforce "
        "the skill check directive"
    )
    assert "Anti-Pattern" in boot_content, (
        "boot command must include an anti-pattern table that counters "
        "rationalizations for skipping the skill check"
    )
