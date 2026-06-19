"""
Tests for the worktree-utils script (extensions/git/scripts/{bash,powershell}/).

Validates subcommands:
  create-feature-worktree, remove-feature-worktree,
  is-in-worktree, list-worktrees, read-manifest

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

    def test_idempotent_when_path_exists(self, tmp_path: Path):
        """Idempotent: returns existing path with already_exists=true."""
        project = _setup_project(tmp_path)
        _run_bash("worktree-utils.sh", project, "create-feature-worktree", "--feature", "demo")

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["already_exists"] is True
        assert data["ok"] is True
        assert data["worktree_path"] == ".worktrees/demo"

    def test_idempotent_when_branch_exists(self, tmp_path: Path):
        """Idempotent: branch exists but no worktree — attaches new worktree."""
        project = _setup_project(tmp_path)
        subprocess.run(["git", "branch", "demo"], cwd=project, check=True, env={**os.environ, **_GIT_ENV})

        result = _run_bash(
            "worktree-utils.sh", project,
            "create-feature-worktree", "--feature", "demo",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["worktree_path"] == ".worktrees/demo"

    def test_missing_feature_arg(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("worktree-utils.sh", project, "create-feature-worktree")
        assert result.returncode != 0
        assert "--feature" in result.stderr

    def test_honors_base_branch_flag(self, tmp_path: Path):
        """--base lets caller pick the starting branch for the worktree."""
        project = _setup_project(tmp_path)
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
        """Removes worktree + feature branch when manifest exists."""
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

    def test_refuses_when_manifest_missing_without_force(self, tmp_path: Path):
        """A worktree directory exists but has no manifest — refuses unless --force."""
        project = _setup_project(tmp_path)
        wt = project / ".worktrees" / "orphan"
        subprocess.run(
            ["git", "worktree", "add", "--detach", str(wt), "main"],
            cwd=project, check=True, env={**os.environ, **_GIT_ENV},
        )

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
