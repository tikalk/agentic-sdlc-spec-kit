import json
import shutil
import subprocess
from pathlib import Path


def test_prepare_levelup_outputs_context(tmp_path, monkeypatch):
    repo_root = tmp_path / "repo"
    (repo_root / "scripts" / "bash").mkdir(parents=True)
    (repo_root / ".specify" / "templates").mkdir(parents=True)
    (repo_root / ".specify" / "memory").mkdir(parents=True)

    project_root = Path(__file__).resolve().parent.parent
    top_level_root = project_root.parent

    # Copy scripts
    shutil.copy(project_root / "scripts" / "bash" / "prepare-levelup.sh", repo_root / "scripts" / "bash" / "prepare-levelup.sh")
    shutil.copy(project_root / "scripts" / "bash" / "common.sh", repo_root / "scripts" / "bash" / "common.sh")

    # Constitution and directives
    memory_root = repo_root / ".specify" / "memory"
    (memory_root / "team-ai-directives").mkdir(parents=True)
    (memory_root / "team-ai-directives" / "context_modules").mkdir(parents=True)
    (memory_root / "team-ai-directives" / "drafts").mkdir(parents=True)
    (memory_root / "constitution.md").write_text("Principles")

    # Feature structure
    feature_dir = repo_root / "specs" / "001-levelup-test"
    feature_dir.mkdir(parents=True)
    (feature_dir / "spec.md").write_text("# Spec")
    (feature_dir / "plan.md").write_text("# Plan")
    (feature_dir / "tasks.md").write_text("# Tasks")
    (feature_dir / "research.md").write_text("# Research")
    (feature_dir / "quickstart.md").write_text("# Quickstart")
    (feature_dir / "context.md").write_text("# Feature Context\n- filled")

    monkeypatch.setenv("SPECIFY_FEATURE", "001-levelup-test")

    subprocess.run(["git", "init"], cwd=repo_root, check=True, capture_output=True, text=True)

    result = subprocess.run(
        ["bash", str(repo_root / "scripts" / "bash" / "prepare-levelup.sh"), "--json"],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )

    json_line = next((line for line in result.stdout.splitlines()[::-1] if line.strip().startswith("{")), "")
    assert json_line, "Expected JSON output"
    data = json.loads(json_line)

    assert data["SPEC_FILE"].endswith("specs/001-levelup-test/spec.md")
    assert data["PLAN_FILE"].endswith("specs/001-levelup-test/plan.md")
    assert data["TASKS_FILE"].endswith("specs/001-levelup-test/tasks.md")
    assert data["KNOWLEDGE_ROOT"].endswith(".specify/memory/team-ai-directives")
    assert data["KNOWLEDGE_DRAFTS"].endswith(".specify/memory/team-ai-directives/drafts")
