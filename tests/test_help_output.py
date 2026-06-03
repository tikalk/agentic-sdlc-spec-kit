"""Regression tests for themed top-level help output."""

from typer.testing import CliRunner

from specify_cli import app
from tests.conftest import strip_ansi


runner = CliRunner()


def test_root_help_shows_themed_help_panel():
    result = runner.invoke(app, ["--help"])

    assert result.exit_code == 0
    output = strip_ansi(result.output)
    assert "Use specify <command> --help for command-specific guidance." in output
    assert "Help" in output
    assert "Setup tool for Specify spec-driven development projects" in output
