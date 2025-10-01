import subprocess

import pytest

from specify_cli import sync_team_ai_directives, TEAM_DIRECTIVES_DIRNAME


def _completed(stdout: str = "", stderr: str = ""):
    return subprocess.CompletedProcess(args=[], returncode=0, stdout=stdout, stderr=stderr)


def test_sync_clones_when_missing(tmp_path, monkeypatch):
    calls = []

    def fake_run(cmd, check, capture_output, text, env=None):
        calls.append((cmd, env))
        return _completed()

    monkeypatch.setattr(subprocess, "run", fake_run)

    status = sync_team_ai_directives("https://example.com/repo.git", tmp_path, skip_tls=True)

    assert status == "cloned"
    memory_root = tmp_path / ".specify" / "memory"
    assert memory_root.exists()
    assert calls[0][0][:2] == ["git", "clone"]
    assert calls[0][0][2] == "https://example.com/repo.git"
    assert calls[0][1]["GIT_SSL_NO_VERIFY"] == "1"


def test_sync_updates_existing_repo(tmp_path, monkeypatch):
    destination = tmp_path / ".specify" / "memory" / TEAM_DIRECTIVES_DIRNAME
    (destination / ".git").mkdir(parents=True)

    commands = []

    def fake_run(cmd, check, capture_output, text, env=None):
        commands.append(cmd)
        if "config" in cmd:
            return _completed("https://example.com/repo.git\n")
        return _completed()

    monkeypatch.setattr(subprocess, "run", fake_run)

    status = sync_team_ai_directives("https://example.com/repo.git", tmp_path)

    assert status == "updated"
    assert any(item[3] == "pull" for item in commands if len(item) > 3)
    assert commands[0][:4] == ["git", "-C", str(destination), "rev-parse"]


def test_sync_resets_remote_when_url_changes(tmp_path, monkeypatch):
    destination = tmp_path / ".specify" / "memory" / TEAM_DIRECTIVES_DIRNAME
    (destination / ".git").mkdir(parents=True)

    commands = []

    def fake_run(cmd, check, capture_output, text, env=None):
        commands.append(cmd)
        if "config" in cmd:
            return _completed("https://old.example.com/repo.git\n")
        return _completed()

    monkeypatch.setattr(subprocess, "run", fake_run)

    sync_team_ai_directives("https://new.example.com/repo.git", tmp_path)

    assert any(
        item[:5] == ["git", "-C", str(destination), "remote", "set-url"]
        for item in commands
    )


def test_sync_raises_on_git_failure(tmp_path, monkeypatch):
    def fake_run(cmd, check, capture_output, text, env=None):
        raise subprocess.CalledProcessError(returncode=1, cmd=cmd, stderr="fatal: error")

    monkeypatch.setattr(subprocess, "run", fake_run)

    with pytest.raises(RuntimeError) as exc:
        sync_team_ai_directives("https://example.com/repo.git", tmp_path)

    assert "fatal: error" in str(exc.value)
