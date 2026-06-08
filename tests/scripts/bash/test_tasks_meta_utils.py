"""
Tests for tasks-meta-utils.sh CLI subcommands.

Validates the core metadata lifecycle:
  init, add-task, start-task, complete-task, fail-task,
  review-micro, quality-gate, summary
"""

import json
import os
import subprocess
from pathlib import Path

import pytest

from tests.conftest import requires_bash

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
META_UTILS = PROJECT_ROOT / "scripts" / "bash" / "tasks-meta-utils.sh"


def _run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    env = {**os.environ, "PATH": "/usr/bin:/bin:" + os.environ.get("PATH", "")}
    return subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


@requires_bash
class TestTasksMetaUtils:
    def test_init_creates_tasks_meta(self, tmp_path: Path):
        result = _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        assert result.returncode == 0, result.stderr
        meta = tmp_path / "tasks_meta.json"
        assert meta.is_file()
        data = json.loads(meta.read_text())
        assert data["feature"] == tmp_path.name
        assert "tasks" in data

    def test_add_task(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        result = _run([
            "bash", str(META_UTILS), "add-task",
            str(meta), "T001", "Create user model", "src/models/user.py", "SYNC"
        ])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["status"] == "pending"
        assert data["tasks"]["T001"]["execution_mode"] == "SYNC"

    def test_start_task(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        result = _run(["bash", str(META_UTILS), "start-task", str(meta), "T001"])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["status"] == "in_progress"
        assert data["tasks"]["T001"]["started_at"] is not None

    def test_complete_task(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        _run(["bash", str(META_UTILS), "start-task", str(meta), "T001"])
        result = _run([
            "bash", str(META_UTILS), "complete-task",
            str(meta), "T001", "Done"
        ])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["status"] == "completed"
        assert data["tasks"]["T001"]["result_summary"] == "Done"

    def test_fail_task(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        result = _run([
            "bash", str(META_UTILS), "fail-task",
            str(meta), "T001", "Build error"
        ])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["status"] == "failed"
        assert data["tasks"]["T001"]["failure_reason"] == "Build error"

    def test_review_micro_requires_sync_completed(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        # Not completed yet -> should warn and return 1
        result = _run(["bash", str(META_UTILS), "review-micro", str(meta), "T001"])
        assert result.returncode == 1
        _run(["bash", str(META_UTILS), "start-task", str(meta), "T001"])
        _run(["bash", str(META_UTILS), "complete-task", str(meta), "T001", ""])
        result = _run(["bash", str(META_UTILS), "review-micro", str(meta), "T001"])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["micro_review_passed"] is True

    def test_quality_gate_requires_completed(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        result = _run(["bash", str(META_UTILS), "quality-gate", str(meta), "T001"])
        assert result.returncode == 1
        _run(["bash", str(META_UTILS), "start-task", str(meta), "T001"])
        _run(["bash", str(META_UTILS), "complete-task", str(meta), "T001", ""])
        _run(["bash", str(META_UTILS), "review-micro", str(meta), "T001"])
        result = _run(["bash", str(META_UTILS), "quality-gate", str(meta), "T001"])
        assert result.returncode == 0, result.stderr
        data = json.loads(meta.read_text())
        assert data["tasks"]["T001"]["quality_gate_passed"] is True

    def test_summary(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "SYNC"])
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T002", "Y", "", "ASYNC"])
        result = _run(["bash", str(META_UTILS), "summary", str(meta)])
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["total_tasks"] == 2
        assert data["sync_tasks"] == 1
        assert data["async_tasks"] == 1
        assert data["all_done"] is False

    def test_async_state_feature_scoped(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "ASYNC"])
        result = _run([
            "bash", str(META_UTILS), "dispatch-async",
            "T001", "general", "Desc", "Ctx", "Reqs", "Instr", str(tmp_path)
        ])
        assert result.returncode == 0, result.stderr
        async_dir = tmp_path / ".async_state"
        assert async_dir.is_dir()
        prompt = async_dir / "delegation_prompts" / "T001.md"
        assert prompt.is_file()

    def test_check_status_feature_scoped(self, tmp_path: Path):
        _run(["bash", str(META_UTILS), "init", str(tmp_path)])
        meta = tmp_path / "tasks_meta.json"
        _run(["bash", str(META_UTILS), "add-task", str(meta), "T001", "X", "", "ASYNC"])
        _run([
            "bash", str(META_UTILS), "dispatch-async",
            "T001", "general", "Desc", "Ctx", "Reqs", "Instr", str(tmp_path)
        ])
        result = _run(["bash", str(META_UTILS), "check-status", "T001", str(tmp_path)])
        assert result.returncode == 0, result.stderr
        assert result.stdout.strip() == "running"
