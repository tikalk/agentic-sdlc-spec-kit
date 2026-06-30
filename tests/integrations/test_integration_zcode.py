"""Tests for ZcodeIntegration — skills-based integration (Z.AI)."""

from .test_integration_base_skills import SkillsIntegrationTests
from tests.conftest import _cmd_prefix


class TestZcodeIntegration(SkillsIntegrationTests):
    KEY = "zcode"
    FOLDER = ".zcode/"
    COMMANDS_SUBDIR = "skills"
    REGISTRAR_DIR = ".zcode/skills"


class TestZcodeInvocation:
    """ZCode renders $speckit-* chat invocations (like Codex)."""

    def test_next_steps_show_dollar_skill_invocation(self, tmp_path):
        """ZCode next-steps guidance should display $speckit-* usage."""
        import os
        from typer.testing import CliRunner
        from specify_cli import app

        project = tmp_path / "zcode-next-steps"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", "zcode",
                "--ignore-agent-tools", "--script", "sh",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0
        assert f"${_cmd_prefix()}-constitution" in result.output
        assert f"/{_cmd_prefix()}.constitution" not in result.output
