"""End-to-end coverage for the local post-initialization verifier."""

from __future__ import annotations

import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "verify-post-initialization-configuration.sh"


def test_verifier_checks_post_initialization_configuration() -> None:
    """The helper validates the documented local configuration workflow."""
    result = subprocess.run(
        ["bash", str(SCRIPT), "--specify", str(REPO_ROOT / ".venv" / "bin" / "specify")],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stderr
    assert "Post-initialization configuration verified." in result.stdout
