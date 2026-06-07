"""
Tests for the worktree-utils script (extensions/git/scripts/{bash,powershell}/).

Validates all 8 subcommands:
  create-feature-worktree, remove-feature-worktree,
  create-task-branch, remove-task-branch,
  is-in-worktree, list-worktrees, read-manifest, finish-feature

Bash tests cover happy-path + error-path + --help.
PowerShell tests are smoke tests (--help + 1 happy-path) per Phase 1 Step 6 plan.

These tests are fork-neutral: worktree-utils.sh uses hard-coded
WORKTREE_*_DEFAULT constants (no dependency on extensions_fork.py), so they
run in both upstream and the Tikal fork.
"""

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

from tests.conftest import requires_bash

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
EXT_DIR = PROJECT_ROOT / "extensions" / "git"
EXT_BASH = EXT_DIR / "scripts" / "bash"
EXT_PS = EXT_DIR / "scripts" / "powershell"
CORE_COMMON_SH = PROJECT_ROOT / "scripts" / "bash" / "common.sh"
CORE_COMMON_PS = PROJECT_ROOT / "scripts" / "powershell" / "common.ps1"

HAS_PWSH = shutil.which("pwsh") is not None


# ── Helpers ──────────────────────────────────────────────────────────────────


def _init_git(path: Path) -> None:
    """Initialize a git repo with a dummy commit on the default branch."""
    subprocess.run(["git", "init", "-q", "-b", "main"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.name", "Test User"], cwd=path, check=True)
    subprocess.run(
        ["git", "commit", "--allow-empty", "-m", "seed", "-q"],
        cwd=path,
        check=True,
    )


def _setup_project(tmp_path: Path, *, git: bool = True) -> Path:
    """Mirror the harness from test_git_extension.py: copy core + ext scripts
    and initialize git so the new worktree-utils scripts are reachable."""
    bash_dir = tmp_path / "scripts" / "bash"
    bash_dir.mkdir(parents=True)
    shutil.copy(CORE_COMMON_SH, bash_dir / "common.sh")

    ps_dir = tmp_path / "scripts" / "powershell"
    ps_dir.mkdir(parents=True)
    shutil.copy(CORE_COMMON_PS, ps_dir / "common.ps1")

    (tmp_path / ".specify" / "templates").mkdir(parents=True)

    ext_bash = tmp_path / ".specify" / "extensions" / "git" / "scripts" / "bash"
    ext_bash.mkdir(parents=True)
    for f in EXT_BASH.iterdir():
        dest = ext_bash / f.name
        shutil.copy(f, dest)
        dest.chmod(0o755)

    ext_ps = tmp_path / ".specify" / "extensions" / "git" / "scripts" / "powershell"
    ext_ps.mkdir(parents=True)
    for f in EXT_PS.iterdir():
        shutil.copy(f, ext_ps / f.name)

    shutil.copy(EXT_DIR / "extension.yml", tmp_path / ".specify" / "extensions" / "git" / "extension.yml")

    if git:
        _init_git(tmp_path)

    return tmp_path


_GIT_ENV = {
    "GIT_AUTHOR_NAME": "Test User",
    "GIT_AUTHOR_EMAIL": "test@example.com",
    "GIT_COMMITTER_NAME": "Test User",
    "GIT_COMMITTER_EMAIL": "test@example.com",
}


def _run_bash(script_name: str, cwd: Path, *args: str, env_extra: dict | None = None) -> subprocess.CompletedProcess:
    script = cwd / ".specify" / "extensions" / "git" / "scripts" / "bash" / script_name
    env = {**os.environ, **_GIT_ENV, **(env_extra or {})}
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


def _run_pwsh(script_name: str, cwd: Path, *args: str) -> subprocess.CompletedProcess:
    script = cwd / ".specify" / "extensions" / "git" / "scripts" / "powershell" / script_name
    env = {**os.environ, **_GIT_ENV}
    return subprocess.run(
        ["pwsh", "-NoProfile", "-File", str(script), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


# ── Scripts present ──────────────────────────────────────────────────────────


class TestWorktreeUtilsScriptsPresent:
    def test_bash_script_exists(self):
        assert (EXT_BASH / "worktree-utils.sh").is_file()

    def test_powershell_script_exists(self):
        assert (EXT_PS / "worktree-utils.ps1").is_file()


# ── create-feature-worktree ──────────────────────────────────────────────────


@requires_bash
class TestCreateFeatureWorktreeBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path(self, tmp_path: Path):
        """Creates a real git worktree, branch, and manifest; JSON has expected fields."""
        project = _setup_project(tmp_path)
        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["worktree_branch"] == "demo"
        assert data["worktree_path"] == ".worktrees/demo"
        assert data["base_dir"] == ".worktrees"
        assert data["manifest_written"] is True

        # Verify git worktree was actually created.
        wt = project / ".worktrees" / "demo"
        assert wt.is_dir()
        assert (wt / "git.worktree-manifest.json").is_file()

        # Verify the feature branch exists in the primary checkout.
        show = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", "refs/heads/demo"],
            cwd=project, capture_output=True,
        )
        assert show.returncode == 0

    def test_refuses_when_path_exists(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "demo",
        )
        assert result.returncode != 0
        assert "already exists" in result.stderr.lower()

    def test_refuses_when_feature_branch_exists(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        # Pre-create a branch named "demo" in the primary checkout.
        subprocess.run(["git", "branch", "demo"], cwd=project, check=True, env={**os.environ, **_GIT_ENV})

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "demo",
        )
        assert result.returncode != 0
        assert "already exists" in result.stderr.lower()

    def test_missing_feature_arg(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "create-feature-worktree")
        assert result.returncode != 0
        assert "--feature" in result.stderr

    def test_honors_base_branch_flag(self, tmp_path: Path):
        """--base lets caller pick the starting branch for the worktree."""
        project = _setup_project(tmp_path)
        # Create a base branch with a different commit.
        subprocess.run(["git", "checkout", "-q", "-b", "other"], cwd=project, check=True, env={**os.environ, **_GIT_ENV})
        subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "on other", "-q"],
            cwd=project, check=True, env={**os.environ, **_GIT_ENV},
        )
        subprocess.run(["git", "checkout", "-q", "main"], cwd=project, check=True, env={**os.environ, **_GIT_ENV})

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "featb", "--base", "other",
        )
        assert result.returncode == 0, result.stderr
        # The feature branch should descend from `other` (HEAD of `other` is on the feature branch).
        log = subprocess.run(
            ["git", "log", "featb", "--oneline"],
            cwd=project, capture_output=True, text=True,
        )
        assert "on other" in log.stdout


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestCreateFeatureWorktreePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr
        assert "create-feature-worktree" in result.stdout.lower()

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "create-feature-worktree", "-Feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["worktree_branch"] == "demo"
        assert (project / ".worktrees" / "demo" / "git.worktree-manifest.json").is_file()


# ── remove-feature-worktree ──────────────────────────────────────────────────


@requires_bash
class TestRemoveFeatureWorktreeBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "remove-feature-worktree", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path(self, tmp_path: Path):
        """Removes worktree + feature branch when manifest exists and no task branches remain."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-feature-worktree", "--feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["removed"] is True
        assert data["branch_deleted"] is True
        assert not (project / ".worktrees" / "demo").exists()

        show = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", "refs/heads/demo"],
            cwd=project, capture_output=True,
        )
        assert show.returncode != 0

    def test_refuses_when_worktree_missing(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-feature-worktree", "--feature", "ghost",
        )
        assert result.returncode != 0
        assert "does not exist" in result.stderr.lower()

    def test_refuses_when_task_branches_remain(self, tmp_path: Path):
        """Provenance guard: with task branches in manifest, must use finish-feature or --force."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "task",
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-feature-worktree", "--feature", "demo",
        )
        assert result.returncode != 0
        assert "task branch" in result.stderr.lower() or "finish-feature" in result.stderr.lower()

    def test_force_overrides_task_branch_guard(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "task",
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-feature-worktree", "--feature", "demo", "--force",
        )
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout)["ok"] is True

    def test_refuses_when_manifest_missing_without_force(self, tmp_path: Path):
        """A worktree directory exists but has no manifest — refuses unless --force."""
        project = _setup_project(tmp_path)
        wt = project / ".worktrees" / "orphan"
        # `git worktree add` will create the directory itself; we don't pre-mkdir.
        subprocess.run(
            ["git", "worktree", "add", "--detach", str(wt), "main"],
            cwd=project, check=True, env={**os.environ, **_GIT_ENV},
        )
        # No manifest written — provenance missing.

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-feature-worktree", "--feature", "orphan",
        )
        assert result.returncode != 0
        assert "manifest" in result.stderr.lower() or "refusing" in result.stderr.lower()


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestRemoveFeatureWorktreePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "remove-feature-worktree", "-Feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout)["ok"] is True


# ── create-task-branch ───────────────────────────────────────────────────────


@requires_bash
class TestCreateTaskBranchBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "create-task-branch", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path(self, tmp_path: Path):
        """Creates task branch inside the feature worktree + manifest entry."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "auth-middleware",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["manifest_updated"] is True
        # {id} substitution strips the leading "T" (T001 -> 1) per AGENTS.md.
        assert data["task_branch"] == "demo--task-1-auth-middleware"

        # Verify the task branch exists inside the worktree.
        show = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", "refs/heads/demo--task-1-auth-middleware"],
            cwd=project / ".worktrees" / "demo", capture_output=True,
        )
        assert show.returncode == 0

        # Verify manifest was updated.
        manifest = json.loads(
            (project / ".worktrees" / "demo" / "git.worktree-manifest.json").read_text()
        )
        ids = [tb["id"] for tb in manifest["task_branches"]]
        assert "T001" in ids

    def test_refuses_invalid_task_id(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "001abc", "--task-slug", "x",
        )
        assert result.returncode != 0
        assert "invalid" in result.stderr.lower() or "task_id" in result.stderr.lower()

    def test_refuses_missing_worktree(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "ghost",
            "--task-id", "T001", "--task-slug", "x",
        )
        assert result.returncode != 0
        assert "worktree" in result.stderr.lower() or "does not exist" in result.stderr.lower()

    def test_refuses_duplicate_task_branch(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "auth",
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "auth",
        )
        assert result.returncode != 0
        assert "already exists" in result.stderr.lower()

    def test_missing_required_args(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "create-task-branch")
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestCreateTaskBranchPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "create-task-branch", "-Feature", "demo",
            "-TaskId", "T001", "-TaskSlug", "auth-middleware",
        )
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout)["ok"] is True


# ── remove-task-branch ───────────────────────────────────────────────────────


@requires_bash
class TestRemoveTaskBranchBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "remove-task-branch", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "x",
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-task-branch", "--feature", "demo", "--task-id", "T001",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["removed"] is True
        assert data["manifest_updated"] is True

        # Manifest entry should be gone.
        manifest = json.loads(
            (project / ".worktrees" / "demo" / "git.worktree-manifest.json").read_text()
        )
        assert all(tb["id"] != "T001" for tb in manifest["task_branches"])

    def test_refuses_not_fully_merged_without_force(self, tmp_path: Path):
        """A task branch with unmerged commits cannot be `-d` deleted without --force."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "x",
        )
        # Add a divergent commit on the task branch.
        wt = project / ".worktrees" / "demo"
        subprocess.run(
            ["git", "checkout", "-q", "demo--task-1-x"],
            cwd=wt, check=True, env={**os.environ, **_GIT_ENV},
        )
        subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "diverge", "-q"],
            cwd=wt, check=True, env={**os.environ, **_GIT_ENV},
        )
        subprocess.run(
            ["git", "checkout", "-q", "demo"],
            cwd=wt, check=True, env={**os.environ, **_GIT_ENV},
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-task-branch", "--feature", "demo", "--task-id", "T001",
        )
        assert result.returncode != 0
        assert "not fully merged" in result.stderr.lower() or "--force" in result.stderr.lower()

    def test_refuses_missing_worktree(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "worktree-utils.sh", project,
            "remove-task-branch", "--feature", "ghost", "--task-id", "T001",
        )
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestRemoveTaskBranchPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        _run_pwsh(
            "worktree-utils.ps1", project,
            "create-task-branch", "-Feature", "demo",
            "-TaskId", "T001", "-TaskSlug", "x",
        )
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "remove-task-branch", "-Feature", "demo", "-TaskId", "T001",
        )
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout)["ok"] is True


# ── is-in-worktree ───────────────────────────────────────────────────────────


@requires_bash
class TestIsInWorktreeBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "is-in-worktree", "--help")
        assert result.returncode == 0, result.stderr
        assert "Exit codes" in result.stdout or "exit" in result.stdout.lower()

    def test_returns_false_in_primary(self, tmp_path: Path):
        """When invoked from a primary checkout, exit 0 and is_in_worktree=false."""
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "is-in-worktree")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["is_in_worktree"] is False
        assert data["feature"] == ""


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestIsInWorktreePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_returns_false_in_primary(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "is-in-worktree")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["is_in_worktree"] is False


# ── list-worktrees ───────────────────────────────────────────────────────────


@requires_bash
class TestListWorktreesBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "list-worktrees", "--help")
        assert result.returncode == 0, result.stderr

    def test_empty_list(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "list-worktrees")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["worktrees"] == []

    def test_populated_list(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "alpha")
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "beta")

        result = _run_bash("worktree-utils.sh", project, "list-worktrees")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        features = {w["feature"] for w in data["worktrees"]}
        assert features == {"alpha", "beta"}
        for w in data["worktrees"]:
            assert w["has_manifest"] is True


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestListWorktreesPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_populated_list(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "alpha")
        result = _run_pwsh("worktree-utils.ps1", project, "list-worktrees")
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert {w["feature"] for w in data["worktrees"]} == {"alpha"}


# ── read-manifest ────────────────────────────────────────────────────────────


@requires_bash
class TestReadManifestBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "read-manifest", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "read-manifest", "--worktree-path", ".worktrees/demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["feature"] == "demo"
        assert data["feature_branch"] == "demo"
        assert data["worktree_path"].endswith(".worktrees/demo")
        assert data["task_branches"] == []
        assert data["schema_version"] == "1.0"

    def test_refuses_missing_path_arg(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "read-manifest")
        assert result.returncode != 0
        assert "--worktree-path" in result.stderr

    def test_refuses_missing_manifest_file(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        (project / "empty-wt").mkdir()
        result = _run_bash(
            "worktree-utils.sh", project,
            "read-manifest", "--worktree-path", "empty-wt",
        )
        assert result.returncode != 0
        assert "manifest" in result.stderr.lower()


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestReadManifestPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "read-manifest", "-WorktreePath", ".worktrees/demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["feature"] == "demo"


# ── finish-feature ───────────────────────────────────────────────────────────


@requires_bash
class TestFinishFeatureBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "finish-feature", "--help")
        assert result.returncode == 0, result.stderr
        assert "Usage" in result.stdout

    def test_happy_path_removes_everything(self, tmp_path: Path):
        """Provenance-based cleanup: deletes task branches, worktree, and feature branch."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T001", "--task-slug", "x",
        )
        _run_bash(
            "worktree-utils.sh", project,
            "create-task-branch", "--feature", "demo",
            "--task-id", "T002", "--task-slug", "y",
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "finish-feature", "--feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["task_branches_removed"] == 2
        assert data["worktree_removed"] is True
        assert data["branch_deleted"] is True

        assert not (project / ".worktrees" / "demo").exists()
        show = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", "refs/heads/demo"],
            cwd=project, capture_output=True,
        )
        assert show.returncode != 0

    def test_keep_branch_preserves_feature_branch(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "finish-feature", "--feature", "demo", "--keep-branch",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["keep_branch"] is True
        assert data["branch_deleted"] is False
        show = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", "refs/heads/demo"],
            cwd=project, capture_output=True,
        )
        assert show.returncode == 0

    def test_refuses_without_manifest(self, tmp_path: Path):
        """No manifest in worktree dir — provenance missing, refuses without --force."""
        project = _setup_project(tmp_path)
        wt = project / ".worktrees" / "orphan"
        subprocess.run(
            ["git", "worktree", "add", "--detach", str(wt), "main"],
            cwd=project, check=True, env={**os.environ, **_GIT_ENV},
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "finish-feature", "--feature", "orphan",
        )
        assert result.returncode != 0
        assert "manifest" in result.stderr.lower() or "refusing" in result.stderr.lower()

    def test_force_skips_task_branch_cleanup(self, tmp_path: Path):
        """With --force and no manifest, task branches are not enumerated (manifest is the source of truth)."""
        project = _setup_project(tmp_path)
        wt = project / ".worktrees" / "orphan"
        subprocess.run(
            ["git", "worktree", "add", "--detach", str(wt), "main"],
            cwd=project, check=True, env={**os.environ, **_GIT_ENV},
        )

        result = _run_bash(
            "worktree-utils.sh", project,
            "finish-feature", "--feature", "orphan", "--force",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["task_branches_removed"] == 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestFinishFeaturePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("worktree-utils.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        _run_pwsh("worktree-utils.ps1", project, "create-feature-worktree", "-Feature", "demo")
        result = _run_pwsh(
            "worktree-utils.ps1", project,
            "finish-feature", "-Feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert not (project / ".worktrees" / "demo").exists()
