"""Smoke tests for the bundled evals extension scripts.

These tests exercise the public evals lifecycle entrypoints directly from a
temporary project root. PowerShell tests are skipped locally when ``pwsh`` is
not installed, but will run in CI environments that provide it.
"""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
from pathlib import Path

import pytest

from tests.conftest import requires_bash


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
EVALS_EXT_DIR = PROJECT_ROOT / "extensions" / "evals"
HAS_PWSH = shutil.which("pwsh") is not None


def _setup_project(tmp_path: Path) -> Path:
    """Create a disposable project root with the evals extension tree copied in."""
    dest = tmp_path / "extensions" / "evals"
    shutil.copytree(EVALS_EXT_DIR, dest)

    for script in (dest / "scripts" / "bash").glob("*.sh"):
        script.chmod(script.stat().st_mode | stat.S_IXUSR)

    return tmp_path


def _create_accepted_draft(project: Path) -> Path:
    drafts = project / ".specify" / "drafts"
    drafts.mkdir(parents=True, exist_ok=True)
    draft = drafts / "eval-001.md"
    draft.write_text(
        """---
id: eval-001
name: Authentication Safety
status: accepted
failure_type: specification_failure
tier: 1
evaluator_type: code-based
---

# Evaluation Criterion: Authentication Safety

## Error Analysis Notes

Spec responses must not disclose secrets or bypass auth requirements.

## Examples

### Pass Examples
- Response explains login flow without exposing credentials.

### Fail Examples
- Response suggests hardcoding passwords in source control.

## Implementation Notes

Binary pass/fail only.
""",
        encoding="utf-8",
    )
    return draft


def _parse_json_output(result: subprocess.CompletedProcess[str]) -> dict:
    stdout = result.stdout.strip()
    assert stdout, f"Expected JSON output, got empty stdout/stderr={result.stderr!r}"

    decoder = json.JSONDecoder()
    idx = 0
    payload = None
    while idx < len(stdout):
        if stdout[idx] not in "[{":
            idx += 1
            continue
        try:
            payload, end = decoder.raw_decode(stdout[idx:])
            idx += end
        except json.JSONDecodeError:
            idx += 1

    assert payload is not None, f"Could not decode JSON from stdout={result.stdout!r} stderr={result.stderr!r}"
    return payload


def _run_bash(project: Path, *args: str) -> subprocess.CompletedProcess[str]:
    script = project / "extensions" / "evals" / "scripts" / "bash" / "setup-evals.sh"
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=project,
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )


def _run_pwsh(project: Path, *args: str) -> subprocess.CompletedProcess[str]:
    script = project / "extensions" / "evals" / "scripts" / "powershell" / "setup-evals.ps1"
    return subprocess.run(
        ["pwsh", "-NoProfile", "-File", str(script), *args],
        cwd=project,
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )


def _assert_last_json_success(result: subprocess.CompletedProcess[str], expected_action: str) -> dict:
    payload = _parse_json_output(result)
    assert payload["action"] == expected_action
    assert payload["status"] == "success", result.stdout
    return payload


@requires_bash
class TestEvalsExtensionBash:
    def test_public_lifecycle_smoke(self, tmp_path: Path):
        project = _setup_project(tmp_path)

        init_result = _run_bash(project, "init", "--json")
        assert init_result.returncode == 0, init_result.stderr
        init_payload = _assert_last_json_success(init_result, "init")
        assert (project / "evals" / "promptfoo" / "goldset.md").exists()

        specify_result = _run_bash(project, "specify", "--json")
        assert specify_result.returncode == 0, specify_result.stderr
        specify_payload = _assert_last_json_success(specify_result, "specify")
        assert (project / ".specify" / "drafts" / "eval-template.md").exists()

        _create_accepted_draft(project)

        clarify_result = _run_bash(project, "clarify", "--json")
        assert clarify_result.returncode == 0, clarify_result.stderr
        clarify_payload = _assert_last_json_success(clarify_result, "clarify")
        assert (project / "evals" / "promptfoo" / "goldset.json").exists()

        implement_result = _run_bash(project, "implement", "--json")
        assert implement_result.returncode == 0, implement_result.stderr
        implement_payload = _assert_last_json_success(implement_result, "implement")
        assert (project / "evals" / "promptfoo" / "graders" / "check_regulatory_compliance.py").exists()
        assert (project / "evals" / "promptfoo" / "config-tier1.js").exists()

        validate_result = _run_bash(project, "validate", "--json")
        assert validate_result.returncode == 0, validate_result.stderr
        validate_payload = _assert_last_json_success(validate_result, "validate")
        assert "implementation_inventory" in validate_payload["details"]

        analyze_result = _run_bash(project, "analyze", "--json")
        assert analyze_result.returncode == 0, analyze_result.stderr
        analyze_payload = _assert_last_json_success(analyze_result, "analyze")
        assert analyze_payload["details"]["insights_generated"] is True


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestEvalsExtensionPowerShell:
    def test_public_lifecycle_smoke(self, tmp_path: Path):
        project = _setup_project(tmp_path)

        init_result = _run_pwsh(project, "init", "-Json")
        assert init_result.returncode == 0, init_result.stderr
        init_payload = _assert_last_json_success(init_result, "init")
        assert (project / "evals" / "promptfoo" / "goldset.md").exists()

        specify_result = _run_pwsh(project, "specify", "-Json")
        assert specify_result.returncode == 0, specify_result.stderr
        specify_payload = _assert_last_json_success(specify_result, "specify")
        assert (project / ".specify" / "drafts" / "eval-template.md").exists()

        _create_accepted_draft(project)

        clarify_result = _run_pwsh(project, "clarify", "-Json")
        assert clarify_result.returncode == 0, clarify_result.stderr
        clarify_payload = _assert_last_json_success(clarify_result, "clarify")
        assert (project / "evals" / "promptfoo" / "goldset.json").exists()

        implement_result = _run_pwsh(project, "implement", "-Json")
        assert implement_result.returncode == 0, implement_result.stderr
        implement_payload = _assert_last_json_success(implement_result, "implement")
        assert (project / "evals" / "promptfoo" / "graders" / "check_context_adherence.py").exists()
        assert (project / "evals" / "promptfoo" / "config-tier2.js").exists()

        validate_result = _run_pwsh(project, "validate", "-Json")
        assert validate_result.returncode == 0, validate_result.stderr
        validate_payload = _assert_last_json_success(validate_result, "validate")
        assert "edd_compliance" in validate_payload["details"]

        analyze_result = _run_pwsh(project, "analyze", "-Json")
        assert analyze_result.returncode == 0, analyze_result.stderr
        analyze_payload = _assert_last_json_success(analyze_result, "analyze")
        assert analyze_payload["details"]["insights_generated"] is True
