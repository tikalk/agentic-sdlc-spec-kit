"""Validate that after_implement hooks are properly registered after extension install."""

import os
from pathlib import Path

import yaml
from typer.testing import CliRunner

from specify_cli import app


def test_after_implement_includes_optional_hook(tmp_path: Path):
    project_dir = tmp_path / "proj"
    runner = CliRunner()
    result = runner.invoke(
        app,
        [
            "init",
            str(project_dir),
            "--integration", "claude",
            "--ignore-agent-tools",
            "--script", "sh",
        ],
    )
    assert result.exit_code == 0, result.stdout

    cwd = os.getcwd()
    os.chdir(str(project_dir))
    try:
        result = runner.invoke(app, ["extension", "add", "tdd"])
    finally:
        os.chdir(cwd)
    assert result.exit_code == 0, result.stdout

    config_path = project_dir / ".specify" / "extensions.yml"
    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))

    hooks = config["hooks"]["after_implement"]
    assert len(hooks) >= 1, "Expected at least one after_implement hook"

    tdd_hooks = [h for h in hooks if h.get("extension") == "tdd"]
    assert len(tdd_hooks) >= 1, "Expected at least one tdd after_implement hook"

    hook = tdd_hooks[0]
    assert hook["enabled"] is True
    assert hook.get("optional", False) is True
    assert hook.get("condition") is None
