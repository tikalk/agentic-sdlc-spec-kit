"""
Tests for explicit [SYNC]/[ASYNC] marker parsing in tasks-dag.sh.
"""

import json
import os
import subprocess
from pathlib import Path

import pytest

from tests.conftest import requires_bash

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
DAG_SCRIPT = PROJECT_ROOT / "extensions" / "git" / "scripts" / "bash" / "tasks-dag.sh"


SAMPLE_TASKS_WITH_MODES = """# Tasks: Sample Feature

## Phase 1: Setup

- [ ] T001 [ASYNC] Create project structure in src/app.py
- [ ] T002 [P] [SYNC] Add config loader in src/config.py
- [ ] T003 [P] [ASYNC] Wire up logging in src/logging.py

## Phase 2: Foundational

- [ ] T004 [SYNC] Create user model in src/models/user.py
- [ ] T005 [P] [ASYNC] Create session model in src/models/session.py
"""


def _run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    env = {**os.environ}
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=env)


@requires_bash
class TestTasksDagExplicitMode:
    def test_explicit_sync_async_parsed(self, tmp_path: Path):
        tasks_md = tmp_path / "tasks.md"
        tasks_md.write_text(SAMPLE_TASKS_WITH_MODES, encoding="utf-8")
        result = _run(["bash", str(DAG_SCRIPT), "generate", "--tasks-md", str(tasks_md)], cwd=tmp_path)
        assert result.returncode == 0, result.stderr
        summary = json.loads(result.stdout)
        dag = json.loads(Path(summary["dag_path"]).read_text())

        modes = {t["id"]: t["execution_mode"] for t in dag["tasks"]}
        assert modes["T001"] == "ASYNC"
        assert modes["T002"] == "SYNC"
        assert modes["T003"] == "ASYNC"
        assert modes["T004"] == "SYNC"
        assert modes["T005"] == "ASYNC"

    def test_explicit_mode_overrides_heuristic(self, tmp_path: Path):
        # T006 has >2 files (would heuristic to ASYNC) but explicit [SYNC]
        tasks_md = tmp_path / "tasks.md"
        tasks_md.write_text(
            "- [ ] T006 [SYNC] Research and analyze in src/a.py src/b.py src/c.py\n",
            encoding="utf-8",
        )
        result = _run(["bash", str(DAG_SCRIPT), "generate", "--tasks-md", str(tasks_md)], cwd=tmp_path)
        assert result.returncode == 0, result.stderr
        summary = json.loads(result.stdout)
        dag = json.loads(Path(summary["dag_path"]).read_text())
        assert dag["tasks"][0]["execution_mode"] == "SYNC"

    def test_classify_emits_explicit_mode(self, tmp_path: Path):
        tasks_md = tmp_path / "tasks.md"
        tasks_md.write_text(SAMPLE_TASKS_WITH_MODES, encoding="utf-8")
        result = _run(["bash", str(DAG_SCRIPT), "classify", "--task-id", "T002", "--tasks-md", str(tasks_md)], cwd=tmp_path)
        assert result.returncode == 0, result.stderr
        data = json.loads(result.stdout)
        assert data["ok"] is True
        assert data["execution_mode"] == "SYNC"
        assert data["is_parallel"] == 1
