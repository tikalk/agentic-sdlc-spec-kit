import json
import shutil
import subprocess
from pathlib import Path


def test_setup_plan_outputs_context_paths(tmp_path, monkeypatch):
    repo_root = tmp_path / "repo"
    script_dir = repo_root / "scripts" / "bash"
    script_dir.mkdir(parents=True)

    specify_dir = repo_root / ".specify"
    templates_dir = specify_dir / "templates"
    memory_dir = specify_dir / "memory"
    templates_dir.mkdir(parents=True)
    memory_dir.mkdir(parents=True)

    # Copy required scripts and template
    project_root = Path(__file__).resolve().parent.parent
    shutil.copy(project_root / "scripts" / "bash" / "setup-plan.sh", script_dir / "setup-plan.sh")
    shutil.copy(project_root / "scripts" / "bash" / "common.sh", script_dir / "common.sh")
    shutil.copy(project_root / "templates" / "plan-template.md", templates_dir / "plan-template.md")

    # Seed constitution and team directives
    constitution = memory_dir / "constitution.md"
    constitution.write_text("Principles")
    team_directives = memory_dir / "team-ai-directives"
    (team_directives / "context_modules").mkdir(parents=True)

    # Seed feature spec directory
    feature_dir = repo_root / "specs" / "001-test-feature"
    feature_dir.mkdir(parents=True)
    (feature_dir / "spec.md").write_text("# Spec")
    (feature_dir / "context.md").write_text("""# Feature Context\n- filled""")

    # Prefer SPECIFY_FEATURE to avoid git dependency
    monkeypatch.setenv("SPECIFY_FEATURE", "001-test-feature")

    subprocess.run(
        ["git", "init"],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )

    result = subprocess.run(
        ["bash", str(script_dir / "setup-plan.sh"), "--json"],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )

    json_line = next((line for line in result.stdout.splitlines()[::-1] if line.strip().startswith("{")), "")
    assert json_line, "Expected JSON output from setup-plan script"
    data = json.loads(json_line)
    assert data["FEATURE_SPEC"].endswith("specs/001-test-feature/spec.md")
    assert data["CONSTITUTION"] == str(constitution)
    assert data["TEAM_DIRECTIVES"] == str(team_directives)
    assert data["CONTEXT_FILE"] == str(feature_dir / "context.md")
