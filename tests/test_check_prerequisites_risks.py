import json
import shutil
import subprocess
from pathlib import Path


def test_check_prerequisites_exposes_risk_register(tmp_path, monkeypatch):
    repo_root = tmp_path / "repo"
    script_dir = repo_root / "scripts" / "bash"
    script_dir.mkdir(parents=True)

    project_root = Path(__file__).resolve().parent.parent

    shutil.copy(project_root / "scripts" / "bash" / "check-prerequisites.sh", script_dir / "check-prerequisites.sh")
    shutil.copy(project_root / "scripts" / "bash" / "common.sh", script_dir / "common.sh")

    feature_dir = repo_root / "specs" / "001-risk-feature"
    feature_dir.mkdir(parents=True)

    (feature_dir / "context.md").write_text("# Context\n- ready")

    (feature_dir / "spec.md").write_text(
        """# Spec\n\n## Risk Register\n- RISK: R1 | Statement: Data loss during retries | Impact: High | Likelihood: Medium | Test: Simulate retry storm\n- RISK: R2 | Statement: Unauthorized admin escalation | Impact: High | Likelihood: Low | Test: RBAC denies non-admin roles\n"""
    )

    (feature_dir / "plan.md").write_text(
        """# Plan\n\n## Risk Mitigation & Test Strategy\n- RISK: R1 | Statement: Data loss during retries | Mitigation Owner: Platform | Test Strategy: Stress retries integration test | Evidence Artefact: risk-tests/R1.log\n- RISK: R2 | Statement: Unauthorized admin escalation | Mitigation Owner: Security | Test Strategy: RBAC integration test | Evidence Artefact: risk-tests/R2.log\n"""
    )

    monkeypatch.setenv("SPECIFY_FEATURE", "001-risk-feature")

    subprocess.run(["git", "init"], cwd=repo_root, check=True, capture_output=True, text=True)

    result = subprocess.run(
        ["bash", str(script_dir / "check-prerequisites.sh"), "--json"],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )

    json_line = next((line for line in result.stdout.splitlines()[::-1] if line.strip().startswith("{")), "")
    assert json_line, "Expected JSON output"
    payload = json.loads(json_line)

    assert len(payload["SPEC_RISKS"]) == 2
    assert {risk["id"] for risk in payload["SPEC_RISKS"]} == {"R1", "R2"}
    r1_plan = {risk["id"]: risk for risk in payload["PLAN_RISKS"]}["R1"]
    assert r1_plan["test_strategy"].startswith("Stress retries")
    assert r1_plan["evidence_artefact"] == "risk-tests/R1.log"
