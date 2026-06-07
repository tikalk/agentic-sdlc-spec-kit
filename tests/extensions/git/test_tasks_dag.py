"""
Tests for the tasks-dag script (extensions/git/scripts/{bash,powershell}/).

Validates all 5 subcommands:
  generate, validate, show, classify, coalesce

Bash tests cover happy-path + error-path + --help.
PowerShell tests are smoke tests (--help + 1 happy-path) per Phase 1 Step 6 plan.

These tests are fork-neutral: tasks-dag.sh uses hard-coded constants
(no dependency on extensions_fork.py), so they run in both upstream and
the Tikal fork.
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


def _setup_project(tmp_path: Path, *, git: bool = True) -> Path:
    """Copy core + extension scripts; tasks-dag.sh doesn't need a git repo
    but we initialize one anyway for parity with sibling tests."""
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
        subprocess.run(["git", "init", "-q", "-b", "main"], cwd=tmp_path, check=True)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmp_path, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=tmp_path, check=True)
        subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "seed", "-q"],
            cwd=tmp_path, check=True,
        )

    return tmp_path


def _run_bash(script_name: str, cwd: Path, *args: str) -> subprocess.CompletedProcess:
    script = cwd / ".specify" / "extensions" / "git" / "scripts" / "bash" / script_name
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env={**os.environ},
    )


def _run_pwsh(script_name: str, cwd: Path, *args: str) -> subprocess.CompletedProcess:
    script = cwd / ".specify" / "extensions" / "git" / "scripts" / "powershell" / script_name
    return subprocess.run(
        ["pwsh", "-NoProfile", "-File", str(script), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env={**os.environ},
    )


# ── 12-task fixture (deterministic, used for happy-path tests) ───────────────


SAMPLE_TASKS_MD = """# Tasks: Sample Feature

## Phase 1: Setup

- [ ] T001 Create the project skeleton in src/app.py
- [ ] T002 [P] Add config loader in src/config.py
- [ ] T003 [P] Wire up logging in src/logging.py

## Phase 2: Foundational

- [ ] T004 Create user model in src/models/user.py
- [ ] T005 [P] Create session model in src/models/session.py
- [ ] T006 [P] Create token model in src/models/token.py

## Phase 3: User Story 1

- [ ] T010 [US1] Implement login endpoint in src/api/login.py
- [ ] T011 [US1] Implement logout endpoint in src/api/logout.py
- [ ] T012 [P] [US1] Add password hashing in src/utils/hash.py
- [ ] T013 [P] [US1] Add rate limiter in src/utils/ratelimit.py

## Phase 4: User Story 2

- [ ] T014 [P] [US2] Build profile page in src/ui/profile.py
- [ ] T015 [P] [US2] Build settings page in src/ui/settings.py
"""


def _write_tasks_md(project: Path, name: str = "tasks.md") -> Path:
    p = project / name
    p.write_text(SAMPLE_TASKS_MD, encoding="utf-8")
    return p


# ── Scripts present ──────────────────────────────────────────────────────────


class TestTasksDagScriptsPresent:
    def test_bash_script_exists(self):
        assert (EXT_BASH / "tasks-dag.sh").is_file()

    def test_powershell_script_exists(self):
        assert (EXT_PS / "tasks-dag.ps1").is_file()


# ── generate ─────────────────────────────────────────────────────────────────


@requires_bash
class TestGenerateBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "generate", "--help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        """Reads tasks.md and emits a DAG with the expected stats."""
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(tasks))
        assert result.returncode == 0, result.stderr
        summary = json.loads(result.stdout)
        assert summary["total_tasks"] == 12
        assert summary["parallel_tasks"] == 8
        assert summary["stories"] == 2
        assert summary["total_waves"] == 5
        assert summary["ok"] is True
        assert summary["dag_written"] is True

        # Full DAG lives in the sidecar.
        dag = json.loads(Path(summary["dag_path"]).read_text())
        assert dag["schema_version"] == "1.0"
        assert len(dag["tasks"]) == 12
        assert "execution_waves" in dag
        assert len(dag["execution_waves"]) == 5

    def test_emits_dag_file_when_out_flag_used(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        out = project / "tasks_dag.json"

        result = _run_bash(
            "tasks-dag.sh", project,
            "generate", "--tasks-md", str(tasks), "--dag", str(out),
        )
        assert result.returncode == 0, result.stderr
        assert out.is_file()
        data = json.loads(out.read_text())
        # Sidecar has total_tasks inside stats.
        assert data["stats"]["total_tasks"] == 12
        assert len(data["tasks"]) == 12

    def test_wave_assignment_matches_fixture(self, tmp_path: Path):
        """Verify the canonical 5-wave decomposition for the 12-task fixture."""
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(tasks))
        assert result.returncode == 0, result.stderr
        summary = json.loads(result.stdout)
        dag = json.loads(Path(summary["dag_path"]).read_text())

        # Build {task_id: execution_wave} map.
        wave_of = {t["id"]: t["execution_wave"] for t in dag["tasks"]}

        # Expected per design:
        #   Wave 0: T001, T002, T003  (Phase 1, T002/T003 [P], no file overlap)
        #   Wave 1: T004, T005, T006  (Phase 2, T005/T006 [P], no file overlap)
        #   Wave 2: T010              (Phase 3, sequential — T010 [US1] not [P])
        #   Wave 3: T011, T012, T013  (Phase 3, T011 [US1] not [P], T012/T013 [P][US1]
        #                              same story + no file overlap with T011)
        #   Wave 4: T014, T015        (Phase 4, [P][US2])
        assert wave_of["T001"] == 0
        assert wave_of["T002"] == 0
        assert wave_of["T003"] == 0
        assert wave_of["T004"] == 1
        assert wave_of["T005"] == 1
        assert wave_of["T006"] == 1
        assert wave_of["T010"] == 2
        assert wave_of["T011"] == 3
        assert wave_of["T012"] == 3
        assert wave_of["T013"] == 3
        assert wave_of["T014"] == 4
        assert wave_of["T015"] == 4
        # Each task's wave index is monotonically non-decreasing within the
        # execution_waves array (i.e., waves[] is sorted).
        assert dag["execution_waves"] == sorted(dag["execution_waves"])

    def test_refuses_missing_tasks_file(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "tasks-dag.sh", project,
            "generate", "--tasks-md", str(project / "missing.md"),
        )
        assert result.returncode != 0

    def test_refuses_empty_tasks_md(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        empty = project / "empty.md"
        empty.write_text("# Empty\n", encoding="utf-8")

        result = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(empty))
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestGeneratePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("tasks-dag.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_happy_path(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_pwsh("tasks-dag.ps1", project, "generate", "-TasksMd", str(tasks))
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["total_tasks"] == 12
        assert data["total_waves"] == 5


# ── validate ─────────────────────────────────────────────────────────────────


@requires_bash
class TestValidateBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "validate", "--help")
        assert result.returncode == 0, result.stderr

    def test_valid_dag(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(tasks))
        assert gen.returncode == 0
        summary = json.loads(gen.stdout)
        dag = project / "tasks_dag.json"
        # Sidecar is at summary["dag_path"]; copy to the conventional path.
        dag.write_text(Path(summary["dag_path"]).read_text(), encoding="utf-8")

        result = _run_bash("tasks-dag.sh", project, "validate", "--dag", str(dag))
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["valid"] is True
        assert data["errors"] == []

    def test_invalid_depends_on_detected(self, tmp_path: Path):
        """A task with depends_on referencing an unknown id is flagged."""
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(tasks))
        summary = json.loads(gen.stdout)
        dag_data = json.loads(Path(summary["dag_path"]).read_text())
        # Inject a bogus dependency.
        dag_data["tasks"][0]["depends_on"] = ["T999"]
        dag = project / "tasks_dag.json"
        dag.write_text(json.dumps(dag_data), encoding="utf-8")

        result = _run_bash("tasks-dag.sh", project, "validate", "--dag", str(dag))
        # Implementation may choose to return non-zero on validation failure
        # OR keep exit 0 with `valid: false` in JSON. Both are valid; we
        # assert the JSON is well-formed either way.
        data = json.loads(result.stdout)
        assert data["valid"] is False
        assert any("T999" in e or "depends_on" in e for e in data["errors"])

    def test_refuses_missing_dag(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "tasks-dag.sh", project,
            "validate", "--dag", str(project / "missing.json"),
        )
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestValidatePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("tasks-dag.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_valid_dag(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_pwsh("tasks-dag.ps1", project, "generate", "-TasksMd", str(tasks))
        summary = json.loads(gen.stdout)
        dag = project / "tasks_dag.json"
        dag.write_text(Path(summary["dag_path"]).read_text(), encoding="utf-8")

        result = _run_pwsh("tasks-dag.ps1", project, "validate", "-Dag", str(dag))
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["valid"] is True


# ── show ─────────────────────────────────────────────────────────────────────


@requires_bash
class TestShowBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "show", "--help")
        assert result.returncode == 0, result.stderr

    def test_shows_waves(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_bash("tasks-dag.sh", project, "generate", "--tasks-md", str(tasks))
        summary = json.loads(gen.stdout)
        dag = project / "tasks_dag.json"
        dag.write_text(Path(summary["dag_path"]).read_text(), encoding="utf-8")

        result = _run_bash("tasks-dag.sh", project, "show", "--dag", str(dag))
        assert result.returncode == 0, result.stderr
        out = result.stdout
        # Show emits human-readable text; just assert it mentions every task ID
        # at least once and the wave headings.
        for tid in ("T001", "T006", "T010", "T015"):
            assert tid in out
        assert "Wave" in out or "wave" in out

    def test_refuses_missing_dag(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "tasks-dag.sh", project,
            "show", "--dag", str(project / "missing.json"),
        )
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestShowPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("tasks-dag.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_shows_waves(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_pwsh("tasks-dag.ps1", project, "generate", "-TasksMd", str(tasks))
        summary = json.loads(gen.stdout)
        dag = project / "tasks_dag.json"
        dag.write_text(Path(summary["dag_path"]).read_text(), encoding="utf-8")

        result = _run_pwsh("tasks-dag.ps1", project, "show", "-Dag", str(dag))
        assert result.returncode == 0, result.stderr
        assert "T001" in result.stdout


# ── classify ─────────────────────────────────────────────────────────────────


@requires_bash
class TestClassifyBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "classify", "--help")
        assert result.returncode == 0, result.stderr

    def test_classify_task(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_bash(
            "tasks-dag.sh", project,
            "classify", "--tasks-md", str(tasks), "--task-id", "T001",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["id"] == "T001"
        assert "execution_mode" in data
        assert data["execution_mode"] in ("SYNC", "ASYNC")
        assert "execution_wave" in data
        assert isinstance(data["execution_wave"], int)

    def test_classify_unknown_task(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_bash(
            "tasks-dag.sh", project,
            "classify", "--tasks-md", str(tasks), "--task-id", "T999",
        )
        assert result.returncode != 0
        assert "T999" in result.stderr or "not found" in result.stderr.lower()

    def test_refuses_missing_task_id(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "classify", "--dag", str(project / "x.json"))
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestClassifyPowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("tasks-dag.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_classify_task(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)
        gen = _run_pwsh("tasks-dag.ps1", project, "generate", "-TasksMd", str(tasks))
        summary = json.loads(gen.stdout)
        dag = project / "tasks_dag.json"
        dag.write_text(Path(summary["dag_path"]).read_text(), encoding="utf-8")

        result = _run_pwsh(
            "tasks-dag.ps1", project,
            "classify", "-Dag", str(dag), "-TaskId", "T001",
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["id"] == "T001"


# ── coalesce ─────────────────────────────────────────────────────────────────


@requires_bash
class TestCoalesceBash:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash("tasks-dag.sh", project, "coalesce", "--help")
        assert result.returncode == 0, result.stderr

    def test_coalesce_emits_report(self, tmp_path: Path):
        """Coalesce is report-only (per Phase 1 C1): emits suggestions, doesn't rewrite tasks.md."""
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_bash(
            "tasks-dag.sh", project,
            "coalesce", "--tasks-md", str(tasks), "--dag", str(tasks.parent / "tasks_dag.json"),
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        # Schema: pairs[] of {left, right, reason}, coalescable_count, mode
        assert "pairs" in data
        assert "coalescable_count" in data
        assert data["mode"] == "report-only"
        assert isinstance(data["pairs"], list)

        # The original tasks.md must be untouched.
        assert tasks.read_text() == SAMPLE_TASKS_MD

    def test_refuses_missing_dag(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_bash(
            "tasks-dag.sh", project,
            "coalesce", "--dag", str(project / "missing.json"),
        )
        assert result.returncode != 0


@pytest.mark.skipif(not HAS_PWSH, reason="pwsh not available")
class TestCoalescePowerShell:
    def test_help(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        result = _run_pwsh("tasks-dag.ps1", project, "help")
        assert result.returncode == 0, result.stderr

    def test_coalesce_emits_report(self, tmp_path: Path):
        project = _setup_project(tmp_path)
        tasks = _write_tasks_md(project)

        result = _run_pwsh(
            "tasks-dag.ps1", project,
            "coalesce", "-TasksMd", str(tasks), "-Dag", str(tasks.parent / "tasks_dag.json"),
        )
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert "pairs" in data
        assert data["mode"] == "report-only"
