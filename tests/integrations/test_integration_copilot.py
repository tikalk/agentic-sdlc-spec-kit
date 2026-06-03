"""Tests for CopilotIntegration."""

import json
import os

import yaml

from specify_cli.integrations import get_integration
from specify_cli.integrations.manifest import IntegrationManifest
from tests.conftest import _cmd_prefix, _is_fork, _skill_prefix, install_preset_to


class TestCopilotIntegration:
    def test_copilot_key_and_config(self):
        copilot = get_integration("copilot")
        assert copilot is not None
        assert copilot.key == "copilot"
        assert copilot.config["folder"] == ".github/"
        assert copilot.config["commands_subdir"] == "agents"
        assert copilot.registrar_config["extension"] == ".agent.md"
        assert copilot.context_file == ".github/copilot-instructions.md"

    def test_command_filename_agent_md(self):
        copilot = get_integration("copilot")
        from specify_cli import PKG_NAMES
        pfx = "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"
        assert copilot.command_filename("plan") == f"{pfx}.plan.agent.md"

    def test_setup_creates_agent_md_files(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        assert len(created) > 0
        agent_files = [f for f in created if ".agent." in f.name]
        assert len(agent_files) > 0
        for f in agent_files:
            assert f.parent == tmp_path / ".github" / "agents"
            assert f.name.endswith(".agent.md")

    def test_setup_creates_companion_prompts(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        prompt_files = [f for f in created if f.parent.name == "prompts"]
        assert len(prompt_files) > 0
        for f in prompt_files:
            assert f.name.endswith(".prompt.md")
            content = f.read_text(encoding="utf-8")
            assert content.startswith(f"---\nagent: {_cmd_prefix()}.")

    def test_agent_and_prompt_counts_match(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        agents = [f for f in created if ".agent.md" in f.name]
        prompts = [f for f in created if ".prompt.md" in f.name]
        assert len(agents) == len(prompts)

    def test_setup_creates_vscode_settings_new(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        assert copilot._vscode_settings_path() is not None
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        settings = tmp_path / ".vscode" / "settings.json"
        assert settings.exists()
        assert settings in created
        assert any("settings.json" in k for k in m.files)

    def test_setup_merges_existing_vscode_settings(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        vscode_dir = tmp_path / ".vscode"
        vscode_dir.mkdir(parents=True)
        existing = {"editor.fontSize": 14, "custom.setting": True}
        (vscode_dir / "settings.json").write_text(json.dumps(existing, indent=4), encoding="utf-8")
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        settings = tmp_path / ".vscode" / "settings.json"
        data = json.loads(settings.read_text(encoding="utf-8"))
        assert data["editor.fontSize"] == 14
        assert data["custom.setting"] is True
        assert settings not in created
        assert not any("settings.json" in k for k in m.files)

    def test_all_created_files_tracked_in_manifest(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m)
        for f in created:
            rel = f.resolve().relative_to(tmp_path.resolve()).as_posix()
            assert rel in m.files, f"Created file {rel} not tracked in manifest"

    def test_install_uninstall_roundtrip(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.install(tmp_path, m)
        assert len(created) > 0
        m.save()
        for f in created:
            assert f.exists()
        removed, skipped = copilot.uninstall(tmp_path, m)
        assert len(removed) == len(created)
        assert skipped == []

    def test_modified_file_survives_uninstall(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.install(tmp_path, m)
        m.save()
        modified_file = created[0]
        modified_file.write_text("user modified this", encoding="utf-8")
        removed, skipped = copilot.uninstall(tmp_path, m)
        assert modified_file.exists()
        assert modified_file in skipped

    def test_directory_structure(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        copilot.setup(tmp_path, m)
        agents_dir = tmp_path / ".github" / "agents"
        assert agents_dir.is_dir()
        agent_files = sorted(agents_dir.glob(f"{_cmd_prefix()}.*.agent.md"))
        assert len(agent_files) == 9
        expected_commands = {
            "analyze", "checklist", "clarify", "constitution",
            "implement", "plan", "specify", "tasks", "taskstoissues",
        }
        actual_commands = {f.name.removeprefix(f"{_cmd_prefix()}.").removesuffix(".agent.md") for f in agent_files}
        assert actual_commands == expected_commands

    def test_templates_are_processed(self, tmp_path):
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        copilot.setup(tmp_path, m)
        agents_dir = tmp_path / ".github" / "agents"
        for agent_file in agents_dir.glob(f"{_cmd_prefix()}.*.agent.md"):
            content = agent_file.read_text(encoding="utf-8")
            assert "{SCRIPT}" not in content, f"{agent_file.name} has unprocessed {{SCRIPT}}"
            assert "__AGENT__" not in content, f"{agent_file.name} has unprocessed __AGENT__"
            assert "{ARGS}" not in content, f"{agent_file.name} has unprocessed {{ARGS}}"
            assert "__SPECKIT_COMMAND_" not in content, f"{agent_file.name} has unprocessed __SPECKIT_COMMAND_*__"
            assert "\nscripts:\n" not in content

    def test_specify_agent_resolves_active_spec_template(self, tmp_path):
        """Generated specify agent must not hardcode the core spec template."""
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        copilot.setup(tmp_path, m)

        specify_file = tmp_path / ".github" / "agents" / f"{_cmd_prefix()}.specify.agent.md"
        content = specify_file.read_text(encoding="utf-8")

        assert "specify preset resolve spec-template" in content
        assert "resolved active `spec-template`" in content
        assert "Copy `.specify/templates/spec-template.md`" not in content
        assert "Load `.specify/templates/spec-template.md`" not in content

    def test_plan_references_correct_context_file(self, tmp_path):
        """The generated plan command must reference copilot's context file."""
        from specify_cli.integrations.copilot import CopilotIntegration
        copilot = CopilotIntegration()
        m = IntegrationManifest("copilot", tmp_path)
        copilot.setup(tmp_path, m)
        plan_file = tmp_path / ".github" / "agents" / f"{_cmd_prefix()}.plan.agent.md"
        assert plan_file.exists()
        content = plan_file.read_text(encoding="utf-8")
        assert copilot.context_file in content, (
            f"Plan command should reference {copilot.context_file!r}"
        )
        assert "__CONTEXT_FILE__" not in content

    def test_complete_file_inventory_sh(self, tmp_path):
        """Every file produced by specify init --integration copilot --script sh."""
        from typer.testing import CliRunner
        from specify_cli import app
        project = tmp_path / "inventory-sh"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", "copilot", "--script", "sh", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        actual = sorted(p.relative_to(project).as_posix() for p in project.rglob("*") if p.is_file())
        files = [
            ".github/agents/speckit.agent-context.update.agent.md",
            f".github/agents/{_cmd_prefix()}.analyze.agent.md",
            f".github/agents/{_cmd_prefix()}.checklist.agent.md",
            f".github/agents/{_cmd_prefix()}.clarify.agent.md",
            f".github/agents/{_cmd_prefix()}.constitution.agent.md",
            f".github/agents/{_cmd_prefix()}.implement.agent.md",
            f".github/agents/{_cmd_prefix()}.plan.agent.md",
            f".github/agents/{_cmd_prefix()}.specify.agent.md",
            f".github/agents/{_cmd_prefix()}.tasks.agent.md",
            f".github/agents/{_cmd_prefix()}.taskstoissues.agent.md",
            ".github/prompts/speckit.agent-context.update.prompt.md",
            f".github/prompts/{_cmd_prefix()}.analyze.prompt.md",
            f".github/prompts/{_cmd_prefix()}.checklist.prompt.md",
            f".github/prompts/{_cmd_prefix()}.clarify.prompt.md",
            f".github/prompts/{_cmd_prefix()}.constitution.prompt.md",
            f".github/prompts/{_cmd_prefix()}.implement.prompt.md",
            f".github/prompts/{_cmd_prefix()}.plan.prompt.md",
            f".github/prompts/{_cmd_prefix()}.specify.prompt.md",
            f".github/prompts/{_cmd_prefix()}.tasks.prompt.md",
            f".github/prompts/{_cmd_prefix()}.taskstoissues.prompt.md",
            ".vscode/settings.json",
            ".github/copilot-instructions.md",
            ".specify/extensions.yml",
            ".specify/extensions/.registry",
            ".specify/extensions/agent-context/README.md",
            ".specify/extensions/agent-context/agent-context-config.yml",
            ".specify/extensions/agent-context/commands/speckit.agent-context.update.md",
            ".specify/extensions/agent-context/extension.yml",
            ".specify/extensions/agent-context/scripts/bash/update-agent-context.sh",
            ".specify/extensions/agent-context/scripts/powershell/update-agent-context.ps1",
            ".specify/integration.json",
            ".specify/init-options.json",
            ".specify/integrations/copilot.manifest.json",
            ".specify/integrations/speckit.manifest.json",
            ".specify/scripts/bash/check-prerequisites.sh",
            ".specify/scripts/bash/common.sh",
            ".specify/scripts/bash/create-new-feature.sh",
            ".specify/scripts/bash/setup-plan.sh",
            ".specify/scripts/bash/setup-tasks.sh",
            ".specify/templates/checklist-template.md",
            ".specify/templates/constitution-template.md",
            ".specify/templates/plan-template.md",
            ".specify/templates/spec-template.md",
            ".specify/templates/tasks-template.md",
            ".specify/memory/constitution.md",
            ".specify/workflows/speckit/workflow.yml",
            ".specify/workflows/workflow-registry.json",
        ]
        # On the fork, bundled extensions and presets create additional files.
        if _is_fork():
            from pathlib import Path as _Path
            proj = _Path(project)
            for child in proj.rglob("*"):
                if not child.is_file():
                    continue
                rel = child.relative_to(proj).as_posix()
                if rel not in files:
                    files.append(rel)
        expected = sorted(files)
        assert actual == expected, (
            f"Missing: {sorted(set(expected) - set(actual))}\n"
            f"Extra: {sorted(set(actual) - set(expected))}"
        )

    def test_complete_file_inventory_ps(self, tmp_path):
        """Every file produced by specify init --integration copilot --script ps."""
        from typer.testing import CliRunner
        from specify_cli import app
        project = tmp_path / "inventory-ps"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", "copilot", "--script", "ps", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        actual = sorted(p.relative_to(project).as_posix() for p in project.rglob("*") if p.is_file())
        files = [
            ".github/agents/speckit.agent-context.update.agent.md",
            f".github/agents/{_cmd_prefix()}.analyze.agent.md",
            f".github/agents/{_cmd_prefix()}.checklist.agent.md",
            f".github/agents/{_cmd_prefix()}.clarify.agent.md",
            f".github/agents/{_cmd_prefix()}.constitution.agent.md",
            f".github/agents/{_cmd_prefix()}.implement.agent.md",
            f".github/agents/{_cmd_prefix()}.plan.agent.md",
            f".github/agents/{_cmd_prefix()}.specify.agent.md",
            f".github/agents/{_cmd_prefix()}.tasks.agent.md",
            f".github/agents/{_cmd_prefix()}.taskstoissues.agent.md",
            ".github/prompts/speckit.agent-context.update.prompt.md",
            f".github/prompts/{_cmd_prefix()}.analyze.prompt.md",
            f".github/prompts/{_cmd_prefix()}.checklist.prompt.md",
            f".github/prompts/{_cmd_prefix()}.clarify.prompt.md",
            f".github/prompts/{_cmd_prefix()}.constitution.prompt.md",
            f".github/prompts/{_cmd_prefix()}.implement.prompt.md",
            f".github/prompts/{_cmd_prefix()}.plan.prompt.md",
            f".github/prompts/{_cmd_prefix()}.specify.prompt.md",
            f".github/prompts/{_cmd_prefix()}.tasks.prompt.md",
            f".github/prompts/{_cmd_prefix()}.taskstoissues.prompt.md",
            ".vscode/settings.json",
            ".github/copilot-instructions.md",
            ".specify/extensions.yml",
            ".specify/extensions/.registry",
            ".specify/extensions/agent-context/README.md",
            ".specify/extensions/agent-context/agent-context-config.yml",
            ".specify/extensions/agent-context/commands/speckit.agent-context.update.md",
            ".specify/extensions/agent-context/extension.yml",
            ".specify/extensions/agent-context/scripts/bash/update-agent-context.sh",
            ".specify/extensions/agent-context/scripts/powershell/update-agent-context.ps1",
            ".specify/integration.json",
            ".specify/init-options.json",
            ".specify/integrations/copilot.manifest.json",
            ".specify/integrations/speckit.manifest.json",
            ".specify/scripts/powershell/check-prerequisites.ps1",
            ".specify/scripts/powershell/common.ps1",
            ".specify/scripts/powershell/create-new-feature.ps1",
            ".specify/scripts/powershell/setup-plan.ps1",
            ".specify/scripts/powershell/setup-tasks.ps1",
            ".specify/templates/checklist-template.md",
            ".specify/templates/constitution-template.md",
            ".specify/templates/plan-template.md",
            ".specify/templates/spec-template.md",
            ".specify/templates/tasks-template.md",
            ".specify/memory/constitution.md",
            ".specify/workflows/speckit/workflow.yml",
            ".specify/workflows/workflow-registry.json",
        ]
        # On the fork, bundled extensions and presets create additional files.
        if _is_fork():
            from pathlib import Path as _Path
            proj = _Path(project)
            for child in proj.rglob("*"):
                if not child.is_file():
                    continue
                rel = child.relative_to(proj).as_posix()
                if rel not in files:
                    files.append(rel)
        expected = sorted(files)
        assert actual == expected, (
            f"Missing: {sorted(set(expected) - set(actual))}\n"
            f"Extra: {sorted(set(actual) - set(expected))}"
        )


class TestCopilotSkillsMode:
    """Tests for Copilot integration in --skills mode."""

    _SKILL_COMMANDS = [
        "analyze", "checklist", "clarify", "constitution",
        "implement", "plan", "specify", "tasks", "taskstoissues",
    ]

    def _make_copilot(self):
        from specify_cli.integrations.copilot import CopilotIntegration
        return CopilotIntegration()

    def _setup_skills(self, copilot, tmp_path):
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.setup(tmp_path, m, parsed_options={"skills": True})
        return created, m

    # -- Options ----------------------------------------------------------

    def test_options_include_skills_flag(self):
        copilot = get_integration("copilot")
        opts = copilot.options()
        skills_opts = [o for o in opts if o.name == "--skills"]
        assert len(skills_opts) == 1
        assert skills_opts[0].is_flag is True
        assert skills_opts[0].default is False

    # -- Skills directory structure ---------------------------------------

    def test_skills_creates_skill_files(self, tmp_path):
        install_preset_to(tmp_path)
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        assert len(created) > 0
        skill_files = [f for f in created if f.name == "SKILL.md"]
        assert len(skill_files) > 0
        for f in skill_files:
            assert f.exists()
            skill_dir = f.parent.name
            # Extract command by stripping known prefixes
            cmd = skill_dir
            for pfx in ("spec-", "speckit-"):
                if cmd.startswith(pfx):
                    cmd = cmd[len(pfx):]
                    break
            from tests.conftest import _skill_prefix
            assert skill_dir.startswith(f"{_skill_prefix(cmd, project_root=tmp_path)}-"), (
                f"Expected {_skill_prefix(cmd, project_root=tmp_path)}-{cmd}, got {skill_dir}"
            )

    def test_skills_directory_under_github_skills(self, tmp_path):
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skills_dir = tmp_path / ".github" / "skills"
        assert skills_dir.is_dir()
        skill_files = [f for f in created if f.name == "SKILL.md"]
        for f in skill_files:
            assert f.resolve().parent.parent == skills_dir.resolve(), (
                f"{f} is not under {skills_dir}"
            )

    def test_skills_directory_structure(self, tmp_path):
        """Each command produces speckit-<name>/SKILL.md."""
        install_preset_to(tmp_path)
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        expected_commands = set(self._SKILL_COMMANDS)
        actual_commands = set()
        for f in skill_files:
            skill_dir_name = f.parent.name
            # Extract command by stripping known prefixes
            cmd = skill_dir_name
            for pfx in ("spec-", "speckit-"):
                if cmd.startswith(pfx):
                    cmd = cmd[len(pfx):]
                    break
            from tests.conftest import _skill_prefix
            assert skill_dir_name.startswith(f"{_skill_prefix(cmd, project_root=tmp_path)}-"), (
                f"Expected {_skill_prefix(cmd, project_root=tmp_path)}-{cmd}, got {skill_dir_name}"
            )
            actual_commands.add(cmd)
        assert actual_commands == expected_commands

    # -- No companion files in skills mode --------------------------------

    def test_skills_no_prompt_md_companions(self, tmp_path):
        """Skills mode must not generate .prompt.md companion files."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        prompt_files = [f for f in created if f.name.endswith(".prompt.md")]
        assert prompt_files == []
        prompts_dir = tmp_path / ".github" / "prompts"
        if prompts_dir.exists():
            assert list(prompts_dir.iterdir()) == []

    def test_skills_no_vscode_settings(self, tmp_path):
        """Skills mode must not create or merge .vscode/settings.json."""
        copilot = self._make_copilot()
        self._setup_skills(copilot, tmp_path)
        settings = tmp_path / ".vscode" / "settings.json"
        assert not settings.exists()

    def test_skills_no_agent_md_files(self, tmp_path):
        """Skills mode must not produce .agent.md files."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        agent_files = [f for f in created if f.name.endswith(".agent.md")]
        assert agent_files == []

    # -- Frontmatter structure --------------------------------------------

    def test_skill_frontmatter_structure(self, tmp_path):
        """SKILL.md must have name, description, compatibility, metadata."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        for f in skill_files:
            content = f.read_text(encoding="utf-8")
            assert content.startswith("---\n"), f"{f} missing frontmatter"
            parts = content.split("---", 2)
            fm = yaml.safe_load(parts[1])
            assert "name" in fm, f"{f} frontmatter missing 'name'"
            assert "description" in fm, f"{f} frontmatter missing 'description'"
            assert "compatibility" in fm, f"{f} frontmatter missing 'compatibility'"
            assert "metadata" in fm, f"{f} frontmatter missing 'metadata'"
            assert fm["metadata"]["author"] == "github-spec-kit"

    # -- Copilot-specific post-processing ---------------------------------

    def test_post_process_skill_content_does_not_inject_mode(self):
        """post_process_skill_content() must NOT inject mode: — VS Code Copilot does not support it."""
        copilot = self._make_copilot()
        content = (
            "---\n"
            'name: "speckit-plan"\n'
            'description: "Plan workflow"\n'
            "---\n"
            "\nBody content\n"
        )
        updated = copilot.post_process_skill_content(content)
        assert "mode:" not in updated

    def test_post_process_skill_content_injects_hook_note(self):
        """post_process_skill_content() should inject shared hook guidance but not mode:."""
        copilot = self._make_copilot()
        content = (
            "---\n"
            'name: "speckit-specify"\n'
            'description: "Specify workflow"\n'
            "---\n"
            "\n- For each executable hook, output the following\n"
        )
        updated = copilot.post_process_skill_content(content)
        assert "replace dots" in updated
        assert "mode:" not in updated

    def test_post_process_idempotent(self):
        """post_process_skill_content() must be idempotent."""
        copilot = self._make_copilot()
        content = (
            "---\n"
            'name: "speckit-plan"\n'
            'description: "Plan workflow"\n'
            "---\n"
            "\nBody content\n"
        )
        first = copilot.post_process_skill_content(content)
        second = copilot.post_process_skill_content(first)
        assert first == second

    def test_skills_do_not_have_mode_in_frontmatter(self, tmp_path):
        """Generated SKILL.md files must NOT contain mode: — VS Code Copilot does not support it."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        assert len(skill_files) > 0
        for f in skill_files:
            content = f.read_text(encoding="utf-8")
            parts = content.split("---", 2)
            fm = yaml.safe_load(parts[1])
            assert "mode" not in fm, f"{f} frontmatter must not contain unsupported 'mode' field"

    def test_skills_hook_sections_explain_dotted_command_conversion(self, tmp_path):
        """Generated skills with hook sections should include shared hook guidance."""
        copilot = self._make_copilot()
        self._setup_skills(copilot, tmp_path)
        specify_skill = tmp_path / ".github" / "skills" / "speckit-specify" / "SKILL.md"
        content = specify_skill.read_text(encoding="utf-8")
        assert "replace dots" in content

    # -- Template processing ----------------------------------------------

    def test_skills_templates_are_processed(self, tmp_path):
        """Skill body must have placeholders replaced."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        assert len(skill_files) > 0
        for f in skill_files:
            content = f.read_text(encoding="utf-8")
            assert "{SCRIPT}" not in content, f"{f.name} has unprocessed {{SCRIPT}}"
            assert "__AGENT__" not in content, f"{f.name} has unprocessed __AGENT__"
            assert "{ARGS}" not in content, f"{f.name} has unprocessed {{ARGS}}"
            assert "__SPECKIT_COMMAND_" not in content, f"{f.name} has unprocessed __SPECKIT_COMMAND_*__"

    def test_skills_command_refs_use_hyphen(self, tmp_path):
        """Copilot skills mode must use /speckit-<name> not /speckit.<name>."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        assert len(skill_files) > 0
        for f in skill_files:
            content = f.read_text(encoding="utf-8")
            assert "/speckit." not in content, (
                f"{f.name} contains dot-notation /speckit. reference; "
                f"skills mode must use /speckit-<name>"
            )

    def test_skills_mode_invoke_separator(self):
        """Copilot effective_invoke_separator should reflect skills mode."""
        copilot = self._make_copilot()
        assert copilot.effective_invoke_separator() == "."
        assert copilot.effective_invoke_separator({"skills": True}) == "-"
        assert copilot.effective_invoke_separator({"skills": False}) == "."

    def test_skill_body_has_content(self, tmp_path):
        """Each SKILL.md body should contain template content."""
        copilot = self._make_copilot()
        created, _ = self._setup_skills(copilot, tmp_path)
        skill_files = [f for f in created if f.name == "SKILL.md"]
        for f in skill_files:
            content = f.read_text(encoding="utf-8")
            parts = content.split("---", 2)
            body = parts[2].strip() if len(parts) >= 3 else ""
            assert len(body) > 0, f"{f} has empty body"

    def test_plan_references_correct_context_file(self, tmp_path):
        """The generated plan skill must reference copilot's context file."""
        copilot = self._make_copilot()
        self._setup_skills(copilot, tmp_path)
        plan_file = tmp_path / ".github" / "skills" / "speckit-plan" / "SKILL.md"
        assert plan_file.exists()
        content = plan_file.read_text(encoding="utf-8")
        assert copilot.context_file in content
        assert "__CONTEXT_FILE__" not in content

    # -- Manifest tracking ------------------------------------------------

    def test_all_files_tracked_in_manifest(self, tmp_path):
        copilot = self._make_copilot()
        created, m = self._setup_skills(copilot, tmp_path)
        for f in created:
            rel = f.resolve().relative_to(tmp_path.resolve()).as_posix()
            assert rel in m.files, f"{rel} not tracked in manifest"

    # -- Install/uninstall roundtrip --------------------------------------

    def test_install_uninstall_roundtrip(self, tmp_path):
        copilot = self._make_copilot()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.install(tmp_path, m, parsed_options={"skills": True})
        assert len(created) > 0
        m.save()
        for f in created:
            assert f.exists()
        removed, skipped = copilot.uninstall(tmp_path, m)
        assert len(removed) == len(created)
        assert skipped == []

    def test_modified_file_survives_uninstall(self, tmp_path):
        copilot = self._make_copilot()
        m = IntegrationManifest("copilot", tmp_path)
        created = copilot.install(tmp_path, m, parsed_options={"skills": True})
        m.save()
        modified_file = created[0]
        modified_file.write_text("user modified this", encoding="utf-8")
        removed, skipped = copilot.uninstall(tmp_path, m)
        assert modified_file.exists()
        assert modified_file in skipped

    # -- build_command_invocation -----------------------------------------

    def test_build_command_invocation_skills_mode(self):
        copilot = self._make_copilot()
        copilot._skills_mode = True
        # With dotted name: resolve_command_alias uses cwd for alias lookup;
        # result depends on whether the agentic-sdlc preset is installed at cwd.
        pfx = _skill_prefix("plan")
        assert copilot.build_command_invocation("speckit.plan") == f"/{pfx}-plan"
        # Plain name: returned as-is (no prefix added by resolve_command_alias)
        assert copilot.build_command_invocation("plan") == "/plan"
        assert copilot.build_command_invocation("plan", "my args") == "/plan my args"

    def test_build_command_invocation_skills_extension_command(self):
        copilot = self._make_copilot()
        copilot._skills_mode = True
        # Extension alias resolution depends on whether the git extension is
        # installed at cwd; accept both possible results.
        result = copilot.build_command_invocation("speckit.git.commit")
        assert result in ("/speckit-git-commit", "/git-commit")
        # "git.commit" is not in the alias map as a key, so it's always unchanged
        assert copilot.build_command_invocation("git.commit") == "/git-commit"

    def test_build_command_invocation_default_mode(self):
        copilot = self._make_copilot()
        assert copilot.build_command_invocation("plan", "my args") == "my args"
        assert copilot.build_command_invocation("plan") == ""

    # -- Context section ---------------------------------------------------

    def test_skills_setup_upserts_context_section(self, tmp_path):
        copilot = self._make_copilot()
        self._setup_skills(copilot, tmp_path)
        ctx_path = tmp_path / copilot.context_file
        assert ctx_path.exists()
        content = ctx_path.read_text(encoding="utf-8")
        assert "<!-- SPECKIT START -->" in content
        assert "<!-- SPECKIT END -->" in content

    # -- CLI integration test ---------------------------------------------

    def test_init_with_integration_options_skills(self, tmp_path):
        """specify init --integration copilot --integration-options='--skills' scaffolds skills."""
        from typer.testing import CliRunner
        from specify_cli import app
        project = tmp_path / "copilot-skills"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", "copilot",
                "--integration-options", "--skills",
                "--script", "sh", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init failed: {result.output}"
        skills_dir = project / ".github" / "skills"
        assert skills_dir.is_dir(), "Skills directory was not created"
        plan_skill = skills_dir / "speckit-plan" / "SKILL.md"
        assert plan_skill.exists(), "speckit-plan/SKILL.md not found"
        # Verify no default-mode artifacts
        assert not (project / ".github" / "agents").exists()
        assert not (project / ".github" / "prompts").exists()
        assert not (project / ".vscode" / "settings.json").exists()

    def test_complete_file_inventory_skills_sh(self, tmp_path):
        """Every file produced by specify init --integration copilot --integration-options='--skills' --script sh."""
        from typer.testing import CliRunner
        from specify_cli import app
        project = tmp_path / "inventory-skills-sh"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", "copilot",
                "--integration-options", "--skills",
                "--script", "sh", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init failed: {result.output}"
        actual = sorted(p.relative_to(project).as_posix() for p in project.rglob("*") if p.is_file())
        files = [
            # Skill files (core + extension-installed agent-context command)
            *[f".github/skills/speckit-{cmd}/SKILL.md" for cmd in self._SKILL_COMMANDS],
            ".github/skills/speckit-agent-context-update/SKILL.md",
            # Context file
            ".github/copilot-instructions.md",
            # Bundled agent-context extension
            ".specify/extensions.yml",
            ".specify/extensions/.registry",
            ".specify/extensions/agent-context/README.md",
            ".specify/extensions/agent-context/agent-context-config.yml",
            ".specify/extensions/agent-context/commands/speckit.agent-context.update.md",
            ".specify/extensions/agent-context/extension.yml",
            ".specify/extensions/agent-context/scripts/bash/update-agent-context.sh",
            ".specify/extensions/agent-context/scripts/powershell/update-agent-context.ps1",
            # Integration metadata
            ".specify/init-options.json",
            ".specify/integration.json",
            ".specify/integrations/copilot.manifest.json",
            ".specify/integrations/speckit.manifest.json",
            # Scripts (sh)
            ".specify/scripts/bash/check-prerequisites.sh",
            ".specify/scripts/bash/common.sh",
            ".specify/scripts/bash/create-new-feature.sh",
            ".specify/scripts/bash/setup-plan.sh",
            ".specify/scripts/bash/setup-tasks.sh",
            # Templates
            ".specify/templates/checklist-template.md",
            ".specify/templates/constitution-template.md",
            ".specify/templates/plan-template.md",
            ".specify/templates/spec-template.md",
            ".specify/templates/tasks-template.md",
            ".specify/memory/constitution.md",
            # Bundled workflow
            ".specify/workflows/speckit/workflow.yml",
            ".specify/workflows/workflow-registry.json",
        ]
        # On the fork, bundled extensions and presets create additional files.
        if _is_fork():
            from pathlib import Path as _Path
            proj = _Path(project)
            for child in proj.rglob("*"):
                if not child.is_file():
                    continue
                rel = child.relative_to(proj).as_posix()
                if rel not in files:
                    files.append(rel)
        expected = sorted(files)
        assert actual == expected, (
            f"Missing: {sorted(set(expected) - set(actual))}\n"
            f"Extra: {sorted(set(actual) - set(expected))}"
        )

    # -- Singleton leak: _skills_mode must reset --------------------------

    def test_skills_mode_resets_on_default_setup(self, tmp_path):
        """setup() with skills=True then without must reset _skills_mode."""
        copilot = self._make_copilot()

        # First call: skills mode
        (tmp_path / "proj1").mkdir()
        m1 = IntegrationManifest("copilot", tmp_path / "proj1")
        copilot.setup(tmp_path / "proj1", m1, parsed_options={"skills": True})
        assert copilot._skills_mode is True

        # Second call: default mode (no skills option)
        (tmp_path / "proj2").mkdir()
        m2 = IntegrationManifest("copilot", tmp_path / "proj2")
        copilot.setup(tmp_path / "proj2", m2)
        assert copilot._skills_mode is False

        # build_command_invocation must use default (dotted) mode
        assert copilot.build_command_invocation("plan", "args") == "args"

    # -- Auto-detection must ignore unrelated .github/skills/ -------------

    def test_dispatch_ignores_unrelated_skills_directory(self, tmp_path):
        """dispatch_command() must not treat unrelated .github/skills/ as skills mode."""
        copilot = self._make_copilot()
        # Create a .github/skills/ with non-speckit content (e.g. GitHub Skills training)
        unrelated = tmp_path / ".github" / "skills" / "introduction-to-github"
        unrelated.mkdir(parents=True)
        (unrelated / "README.md").write_text("# GitHub Skills training\n")

        # Should NOT detect skills mode — cli_args should contain --agent
        import unittest.mock as mock
        with mock.patch("subprocess.run") as mock_run:
            mock_run.return_value = mock.Mock(returncode=0, stdout="", stderr="")
            copilot.dispatch_command("plan", "my args", project_root=tmp_path, stream=False)
            call_args = mock_run.call_args[0][0]
            assert "--agent" in call_args, (
                f"Expected --agent in cli_args but got: {call_args}"
            )
            # resolve_command_alias strips speckit. prefix when no alias exists
            assert "plan" in call_args

    def test_dispatch_detects_speckit_skills_layout(self, tmp_path):
        """dispatch_command() detects speckit-*/SKILL.md as skills mode."""
        copilot = self._make_copilot()
        skill_dir = tmp_path / ".github" / "skills" / "speckit-plan"
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text("---\nname: speckit-plan\n---\n")

        import unittest.mock as mock
        with mock.patch("subprocess.run") as mock_run:
            mock_run.return_value = mock.Mock(returncode=0, stdout="", stderr="")
            copilot.dispatch_command("plan", "my args", project_root=tmp_path, stream=False)
            call_args = mock_run.call_args[0][0]
            assert "--agent" not in call_args, (
                f"Skills mode should not use --agent, got: {call_args}"
            )
            prompt = call_args[call_args.index("-p") + 1]
            # resolve_command_alias returns plain name without prefix in clean env
            assert "/plan" in prompt, (
                f"Skills mode prompt should invoke /plan, got: {prompt}"
            )
            assert "my args" in prompt, (
                f"Skills mode prompt should preserve user args, got: {prompt}"
            )

    # -- Next-steps display for Copilot skills mode -----------------------

    def test_init_skills_next_steps_show_skill_syntax(self, tmp_path):
        """specify init --integration copilot --integration-options='--skills' shows /speckit-plan not /speckit.plan."""
        from typer.testing import CliRunner
        from specify_cli import app
        project = tmp_path / "copilot-nextsteps"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", "copilot",
                "--integration-options", "--skills",
                "--script", "sh", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init failed: {result.output}"
        # Full init installs bundled presets (with aliases) → use global fork prefix
        pfx = _cmd_prefix()
        assert f"/{pfx}-plan" in result.output, (
            f"Expected /{pfx}-plan in next steps but got:\n{result.output}"
        )
        # Must NOT show the dotted /speckit.plan form
        assert "/speckit.plan" not in result.output, (
            f"Should not show /speckit.plan in skills mode:\n{result.output}"
        )
