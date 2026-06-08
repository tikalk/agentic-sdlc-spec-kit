"""
Tests for merge-task-branch subcommand in worktree-utils.sh/ps1.
"""

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

from tests.conftest import requires_bash
from tests.extensions.git.test_git_worktree import (
    PROJECT_ROOT,
    EXT_BASH,
    EXT_PS,
    CORE_COMMON_SH,
    CORE_COMMON_PS,
    HAS_PWSH,
    _init_git,
    _setup_project,
    _run_bash,
    _run_pwsh,
)


def _git_env():
    return {**os.environ, "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.com", "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.com"}


def _run_bash_in_worktree(script_name: str, worktree: Path, project: Path, *args: str) -> subprocess.CompletedProcess:
    """Run a bash script from inside a worktree."""
    script = project / ".specify" / "extensions" / "git" / "scripts" / "bash" / script_name
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=worktree,
        capture_output=True,
        text=True,
        env={**os.environ},
    )


@requires_bash
class TestMergeTaskBranchBash:
    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash("worktree-utils.sh", project, "create-task-branch", "--feature", "demo", "--task-id", "T001", "--task-slug", "auth")

        wt = project / ".worktrees" / "demo"
        # Add a commit on the task branch
        subprocess.run(["git", "checkout", "-q", "demo--task-1-auth"], cwd=wt, check=True, env=_git_env())
        (wt / "auth.txt").write_text("auth", encoding="utf-8")
        subprocess.run(["git", "add", "auth.txt"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "commit", "-q", "-m", "T001 auth"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "checkout", "-q", "demo"], cwd=wt, check=True, env=_git_env())

        result = _run_bash_in_worktree("worktree-utils.sh", wt, project, "merge-task-branch", "--feature", "demo", "--task-id", "T001")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["merged"] is True
        assert data["has_conflict"] is False
        assert data["feature_tip"] != ""

        # Task branch should be removed
        show = subprocess.run(["git", "show-ref", "--verify", "--quiet", "refs/heads/demo--task-1-auth"], cwd=wt, capture_output=True)
        assert show.returncode != 0

        # Manifest should no longer list T001
        manifest = json.loads((wt / "git.worktree-manifest.json").read_text())
        ids = [tb["id"] for tb in manifest["task_branches"]]
        assert "T001" not in ids

    def test_conflict_reported(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash("worktree-utils.sh", project, "create-task-branch", "--feature", "demo", "--task-id", "T001", "--task-slug", "auth")

        wt = project / ".worktrees" / "demo"
        # Add conflicting commit on feature branch
        (wt / "shared.txt").write_text("feature", encoding="utf-8")
        subprocess.run(["git", "add", "shared.txt"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "commit", "-q", "-m", "feature work"], cwd=wt, check=True, env=_git_env())

        # Add conflicting commit on task branch
        subprocess.run(["git", "checkout", "-q", "demo--task-1-auth"], cwd=wt, check=True, env=_git_env())
        (wt / "shared.txt").write_text("task", encoding="utf-8")
        subprocess.run(["git", "add", "shared.txt"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "commit", "-q", "-m", "task work"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "checkout", "-q", "demo"], cwd=wt, check=True, env=_git_env())

        result = _run_bash_in_worktree("worktree-utils.sh", wt, project, "merge-task-branch", "--feature", "demo", "--task-id", "T001")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["merged"] is False
        assert data["has_conflict"] is True
        assert "shared.txt" in data["conflict_files"]

        # Task branch should still exist because merge was aborted
        show = subprocess.run(["git", "show-ref", "--verify", "--quiet", "refs/heads/demo--task-1-auth"], cwd=wt, capture_output=True)
        assert show.returncode == 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestMergeTaskBranchPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        _run_pwsh("worktree-utils.ps1", project, "create-task-branch", "-Feature", "demo", "-TaskId", "T001", "-TaskSlug", "auth")

        wt = project / ".worktrees" / "demo"
        subprocess.run(["git", "checkout", "-q", "demo--task-1-auth"], cwd=wt, check=True, env=_git_env())
        (wt / "auth.txt").write_text("auth", encoding="utf-8")
        subprocess.run(["git", "add", "auth.txt"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "commit", "-q", "-m", "T001 auth"], cwd=wt, check=True, env=_git_env())
        subprocess.run(["git", "checkout", "-q", "demo"], cwd=wt, check=True, env=_git_env())

        result = _run_pwsh("worktree-utils.ps1", wt, "merge-task-branch", "-Feature", "demo", "-TaskId", "T001")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["merged"] is True
