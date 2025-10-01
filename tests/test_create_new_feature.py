import json
import shutil
import subprocess
from pathlib import Path


def test_create_new_feature_outputs_context_paths(tmp_path):
    repo_root = tmp_path / "repo"
    script_dir = repo_root / "scripts" / "bash"
    template_dir = repo_root / ".specify" / "templates"
    memory_dir = repo_root / ".specify" / "memory"

    script_dir.mkdir(parents=True)
    template_dir.mkdir(parents=True)
    memory_dir.mkdir(parents=True)

    project_root = Path(__file__).resolve().parent.parent
    top_level_root = project_root.parent

    shutil.copy(project_root / "scripts" / "bash" / "create-new-feature.sh", script_dir / "create-new-feature.sh")
    shutil.copy(top_level_root / ".specify" / "templates" / "spec-template.md", template_dir / "spec-template.md")

    constitution_path = memory_dir / "constitution.md"
    constitution_path.write_text("Principles")

    team_root = memory_dir / "team-ai-directives"
    (team_root / "context_modules").mkdir(parents=True)
    (team_root / "context_modules" / "principles.md").write_text("Rule")

    script_path = script_dir / "create-new-feature.sh"

    result = subprocess.run(
        ["bash", str(script_path), "--json", "Add stage one feature"],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )

    data = json.loads(result.stdout.strip())

    spec_file = Path(data["SPEC_FILE"])
    assert spec_file.exists()
    context_file = spec_file.parent / "context.md"
    assert context_file.exists()
    context_text = context_file.read_text()
    assert "[NEEDS INPUT]" in context_text
    assert "Feature Context" in context_text
    assert data["CONSTITUTION"] == str(constitution_path)
    assert data["TEAM_DIRECTIVES"] == str(team_root)
    assert data["HAS_GIT"] == "false"
