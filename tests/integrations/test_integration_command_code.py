"""Tests for CommandCodeIntegration — skills-based integration (Command Code)."""

from .test_integration_base_skills import SkillsIntegrationTests


class TestCommandCodeIntegration(SkillsIntegrationTests):
    KEY = "command-code"
    FOLDER = ".commandcode/"
    COMMANDS_SUBDIR = "skills"
    REGISTRAR_DIR = ".commandcode/skills"


class TestCommandCodeInvocation:
    """Command Code renders $speckit-* chat invocations (like Codex/ZCode)."""

    def test_next_steps_show_dollar_skill_invocation(self, tmp_path):
        import os

        from typer.testing import CliRunner

        from specify_cli import PKG_NAMES, app

        # Fork uses "spec" command prefix instead of upstream's "speckit".
        if any("agentic-sdlc" in pkg for pkg in PKG_NAMES):
            _cmd_prefix = "spec"
        else:
            _cmd_prefix = "speckit"

        project = tmp_path / "command-code-next-steps"
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
                    "command-code",
                    "--ignore-agent-tools",
                    "--script",
                    "sh",
                ],
                catch_exceptions=False,
            )
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0
        assert f"${_cmd_prefix}-constitution" in result.output
        assert f"/{_cmd_prefix}.constitution" not in result.output
