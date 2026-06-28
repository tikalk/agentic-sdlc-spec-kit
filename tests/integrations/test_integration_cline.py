"""Tests for ClineIntegration."""

import os
import pytest

from specify_cli.integrations import get_integration
from specify_cli.integrations.cline import format_cline_command_name
from .test_integration_base_markdown import MarkdownIntegrationTests


class TestClineCommandNameFormatter:
    """Test the Cline command name formatter."""

    def _expected(self, name: str) -> str:
        """Return the expected prefixed name (fork uses 'spec-', upstream 'speckit-')."""
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        return f"{pfx}-{name}"

    def test_simple_name_without_prefix(self):
        """Test formatting a simple name without 'speckit.' prefix."""
        assert format_cline_command_name("plan") == self._expected("plan")
        assert format_cline_command_name("tasks") == self._expected("tasks")
        assert format_cline_command_name("specify") == self._expected("specify")

    def test_name_with_speckit_prefix(self):
        """Test formatting a name that already has 'speckit.' prefix."""
        assert format_cline_command_name("speckit.plan") == self._expected("plan")
        assert format_cline_command_name("speckit.tasks") == self._expected("tasks")

    def test_extension_command_name(self):
        """Test formatting extension command names with dots."""
        assert (
            format_cline_command_name("speckit.my-extension.example")
            == self._expected("my-extension-example")
        )
        assert (
            format_cline_command_name("my-extension.example")
            == self._expected("my-extension-example")
        )

    def test_idempotent_already_hyphenated(self):
        """Test that already-hyphenated names with current prefix are idempotent."""
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        assert format_cline_command_name(f"{pfx}-plan") == f"{pfx}-plan"
        assert (
            format_cline_command_name(f"{pfx}-my-extension-example")
            == f"{pfx}-my-extension-example"
        )


class TestClineIntegration(MarkdownIntegrationTests):
    KEY = "cline"
    FOLDER = ".clinerules/"
    COMMANDS_SUBDIR = "workflows"
    REGISTRAR_DIR = ".clinerules/workflows"
    CONTEXT_FILE = ".clinerules/specify-rules.md"

    @pytest.mark.parametrize(
        "cmd_name, base_name",
        [
            ("plan", "plan"),
            ("speckit.plan", "plan"),
            ("speckit.git.commit", "git-commit"),
            ("speckit.git.publish", "git-publish"),
            ("speckit", "speckit"),
            ("speckitfoo", "speckitfoo"),
        ],
    )
    def test_cline_command_filename(self, cmd_name, base_name):
        """Verify Cline uses hyphenated filenames."""
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        cline = get_integration("cline")
        assert cline.command_filename(cmd_name) == f"{pfx}-{base_name}.md"

    def test_cline_invoke_separator(self):
        """Verify Cline uses hyphen as invoke separator."""
        cline = get_integration("cline")
        assert cline.invoke_separator == "-"
        assert cline.registrar_config["invoke_separator"] == "-"

    def test_cline_name_injection_and_formatting(self):
        """Verify Cline has inject_name and format_name configured."""
        cline = get_integration("cline")
        assert cline.registrar_config["inject_name"] is True
        assert cline.registrar_config["format_name"] == format_cline_command_name

    def test_cline_handoff_rewrite(self):
        """Verify Cline rewrites agent: speckit.foo to agent: <prefix>-foo."""
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        cline = get_integration("cline")
        content = "---\nagent: speckit.plan\n---\n"
        rewritten = cline._rewrite_handoff_references(content)
        assert rewritten == f"---\nagent: {pfx}-plan\n---\n"

    def test_cline_hook_instruction_injection(self):
        """Verify Cline injects the dot-to-hyphen note for hooks."""
        cline = get_integration("cline")
        content = "- For each executable hook, output the following:\n"
        injected = cline._inject_hook_command_note(content)
        assert "replace dots (`.`) with hyphens (`-`)" in injected
        assert "- For each executable hook, output the following:" in injected

    # -- Overrides for MarkdownIntegrationTests ---------------------------

    def test_setup_creates_files(self, tmp_path):
        from specify_cli.integrations.manifest import IntegrationManifest

        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.setup(tmp_path, m)
        assert len(created) > 0
        cmd_files = [
            f
            for f in created
            if "scripts" not in f.parts
            and f.suffix == ".md"
            and f.name != i.context_file
        ]
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        for f in cmd_files:
            assert f.exists()
            assert f.name.startswith(f"{pfx}-")
            assert f.name.endswith(".md")

        specify_file = next(
            (f for f in cmd_files if f.name == f"{pfx}-specify.md"), None
        )
        assert specify_file is not None
        specify_contents = specify_file.read_text(encoding="utf-8")
        assert f"/{pfx}-plan" in specify_contents
        assert "/speckit.plan" not in specify_contents

    def test_integration_flag_creates_files(self, tmp_path):
        from typer.testing import CliRunner
        from specify_cli import app

        project = tmp_path / f"int-{self.KEY}"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(
                app,
                [
                    "init",
                    "--here",
                    "--integration",
                    self.KEY,
                    "--script",
                    "sh",
                    "--ignore-agent-tools",
                ],
                catch_exceptions=False,
            )
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        i = get_integration(self.KEY)
        cmd_dir = i.commands_dest(project)
        assert cmd_dir.is_dir()
        from tests.conftest import _cmd_prefix
        commands = sorted(cmd_dir.glob(f"{_cmd_prefix()}-*"))
        assert len(commands) > 0

    def _expected_files(self, script_variant: str, project=None) -> list[str]:
        """Override to expect hyphenated prefix."""
        from tests.conftest import _cmd_prefix, _is_fork
        i = get_integration(self.KEY)
        cmd_dir = i.registrar_config["dir"]
        files = []

        # Command files
        for stem in (
            self.COMMANDS_SUBDIR_STEMS
            if hasattr(self, "COMMANDS_SUBDIR_STEMS")
            else self.COMMAND_STEMS
        ):
            files.append(f"{cmd_dir}/{_cmd_prefix()}-{stem.replace('.', '-')}.md")

        # Framework files
        files.append(".specify/integration.json")
        files.append(".specify/init-options.json")
        files.append(f".specify/integrations/{self.KEY}.manifest.json")
        files.append(".specify/integrations/speckit.manifest.json")

        if script_variant == "sh":
            for name in [
                "check-prerequisites.sh",
                "common.sh",
                "create-new-feature.sh",
                "setup-plan.sh",
                "setup-tasks.sh",
            ]:
                files.append(f".specify/scripts/bash/{name}")
        else:
            for name in [
                "check-prerequisites.ps1",
                "common.ps1",
                "create-new-feature.ps1",
                "setup-plan.ps1",
                "setup-tasks.ps1",
            ]:
                files.append(f".specify/scripts/powershell/{name}")

        for name in [
            "checklist-template.md",
            "constitution-template.md",
            "plan-template.md",
            "spec-template.md",
            "tasks-template.md",
        ]:
            files.append(f".specify/templates/{name}")

        files.append(".specify/memory/constitution.md")
        # Bundled workflow
        files.append(".specify/workflows/speckit/workflow.yml")
        files.append(".specify/workflows/workflow-registry.json")

        # Bundled agent-context extension
        files.append(".specify/extensions.yml")
        files.append(".specify/extensions/.registry")
        files.append(".specify/extensions/agent-context/README.md")
        files.append(".specify/extensions/agent-context/agent-context-config.yml")
        files.append(".specify/extensions/agent-context/commands/speckit.agent-context.update.md")
        files.append(".specify/extensions/agent-context/extension.yml")
        files.append(".specify/extensions/agent-context/scripts/bash/update-agent-context.sh")
        files.append(".specify/extensions/agent-context/scripts/powershell/update-agent-context.ps1")

        # Agent context file (if set)
        if i.context_file:
            files.append(i.context_file)

        # On the fork, bundled extensions and presets create additional files.
        if _is_fork() and project is not None:
            from pathlib import Path as _Path
            proj = _Path(project)
            for child in proj.rglob("*"):
                if not child.is_file():
                    continue
                rel = child.relative_to(proj).as_posix()
                if rel not in files:
                    files.append(rel)

        return sorted(files)
