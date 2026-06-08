from pathlib import Path


def test_verify_command_template_exists():
    repo_root = Path(__file__).parent.parent
    template_file = (
        repo_root / "presets/agentic-sdlc/commands/adlc.spec.verify.md"
    )

    assert template_file.exists(), f"Verify command template not found: {template_file}"


def test_verify_command_mentions_evidence_artifact():
    repo_root = Path(__file__).parent.parent
    template_file = (
        repo_root / "presets/agentic-sdlc/commands/adlc.spec.verify.md"
    )
    content = template_file.read_text(encoding="utf-8")

    assert "evidence.md" in content, "Verify command must write evidence.md"
    assert "/spec.verify" in content, "Verify command should document /spec.verify"
    assert "Mission Brief Summary" in content, "Mission Brief section missing"
    assert "Success Criteria Validation" in content, "Success criteria table missing"
    assert "Constraint Validation" in content, "Constraint validation table missing"
    assert "What Was Checked" in content, "Checked evidence section missing"
    assert "What Was Not Checked" in content, "Unchecked evidence section missing"
    assert "Residual Risks" in content, "Residual risks section missing"
    assert "Provenance" in content, "Provenance section missing"


def test_verify_command_uses_feature_prerequisite_script():
    repo_root = Path(__file__).parent.parent
    template_file = (
        repo_root / "presets/agentic-sdlc/commands/adlc.spec.verify.md"
    )
    content = template_file.read_text(encoding="utf-8")

    assert "check-prerequisites.sh --json --include-tasks" in content
    assert "check-prerequisites.ps1 -Json -IncludeTasks" in content
