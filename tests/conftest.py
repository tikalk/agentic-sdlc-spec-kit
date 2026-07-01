"""Shared test helpers for the Spec Kit test suite."""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

_ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def _has_working_bash() -> bool:
    """Check whether a functional native bash is available.

    On Windows, ``subprocess.run(["bash", ...])`` uses CreateProcess,
    which searches System32 *before* PATH — so it may find the WSL
    launcher even when Git-for-Windows bash appears first in PATH via
    ``shutil.which``.  We therefore probe with bare ``"bash"`` (the
    same way test helpers invoke it) to get an accurate result.

    On Windows, only Git-for-Windows bash (MSYS2/MINGW) is accepted.
    The WSL launcher is rejected because it runs in a separate Linux
    filesystem and cannot handle native Windows paths used by the
    test fixtures.

    Set SPECKIT_TEST_BASH=1 to force-enable bash tests regardless.
    """
    if os.environ.get("SPECKIT_TEST_BASH") == "1":
        return True
    if shutil.which("bash") is None:
        return False
    # Probe with bare "bash" — same as the test helpers — so that
    # Windows CreateProcess resolution order is respected.
    try:
        r = subprocess.run(
            ["bash", "-c", "echo ok"],
            capture_output=True, text=True, timeout=5,
        )
        if r.returncode != 0 or "ok" not in r.stdout:
            return False
    except (OSError, subprocess.TimeoutExpired):
        return False
    # On Windows, verify we have MSYS/MINGW bash (Git for Windows),
    # not the WSL launcher which can't handle native paths.
    if sys.platform == "win32":
        try:
            u = subprocess.run(
                ["bash", "-c", "uname -s"],
                capture_output=True, text=True, timeout=5,
            )
            kernel = u.stdout.strip().upper()
            if not any(k in kernel for k in ("MSYS", "MINGW", "CYGWIN")):
                return False
        except (OSError, subprocess.TimeoutExpired):
            return False
    return True


requires_bash = pytest.mark.skipif(
    not _has_working_bash(), reason="working bash not available"
)


def strip_ansi(text: str) -> str:
    """Remove ANSI escape codes from Rich-formatted CLI output."""
    return _ANSI_ESCAPE_RE.sub("", text)


# ---------------------------------------------------------------------------
# Fork-aware prefix helpers
# ---------------------------------------------------------------------------

def _cmd_prefix() -> str:
    """Return the command prefix for the current installation.

    Upstream uses 'speckit'; the tikalk fork uses 'spec'.
    """
    from specify_cli import PKG_NAMES
    return "spec" if any("agentic-sdlc" in pkg for pkg in PKG_NAMES) else "speckit"


def _skill_prefix(
    command: str | None = None, project_root: Path | None = None
) -> str:
    """Return the skill name prefix for the current installation.

    When *command* is given, resolves whether that specific command has a
    fork alias (e.g. ``speckit.plan`` → ``spec.plan``).  This matters in
    clean test environments where the ``agentic-sdlc`` preset (which
    provides the aliases) is **not** installed, so only commands that
    carry aliases in bundled presets get the ``spec-`` prefix; everything
    else keeps the upstream ``speckit-`` prefix.

    When *command* is ``None``, falls back to the global fork detection
    based on :data:`PKG_NAMES` for backward compatibility.

    *project_root* should be the directory where the preset/extension
    bundle is installed; it defaults to ``Path.cwd()`` which only works
    when the test is run from inside the project under test.
    """
    if command is not None:
        try:
            from specify_cli._core_fork import resolve_command_alias
            aliased = resolve_command_alias(
                f"speckit.{command}", project_root=project_root
            )
            return "spec" if aliased != f"speckit.{command}" else "speckit"
        except Exception:
            pass
    return _cmd_prefix()


def _content_ref(name: str, sep: str = "-") -> str:
    """Return the expected command invocation string in rendered content.

    Renders to ``/{prefix}{sep}{name}`` where ``prefix`` is the current
    fork prefix (``spec`` on the tikalk fork, ``speckit`` on upstream)
    and ``sep`` is the separator (``-`` for skills-based agents, ``.``
    for command-based agents like copilot/gemini).
    """
    return f"/{_cmd_prefix()}{sep}{name}"


def _skill_dir_name(command: str, project_root: Path | None = None) -> str:
    """Return the on-disk skill directory name for *command*.

    Mirrors :func:`specify_cli._core_fork.compute_skill_output_name`
    for skills-based agents: when the command has a fork alias whose
    resolved form starts with ``speckit.``/``spec.``/``adlc.``, the
    fork prefix replaces the namespace; otherwise the alias is used
    as-is (no prefix) — matching the upstream behavior for extension
    commands like ``git.feature`` which resolve to ``git-feature``.

    *project_root* should be the directory where the preset/extension
    bundle is installed; it defaults to ``Path.cwd()`` which only works
    when the test is run from inside the project under test.
    """
    try:
        from specify_cli._core_fork import resolve_command_alias
        canonical = f"speckit.{command}"
        aliased = resolve_command_alias(canonical, project_root=project_root)
        if aliased == canonical:
            return f"speckit-{command.replace('.', '-')}"
        # Aliased — strip namespace prefix and apply fork prefix
        for ns in ("speckit.", "spec.", "adlc."):
            if aliased.startswith(ns):
                return f"{_cmd_prefix()}-{aliased[len(ns):].replace('.', '-')}"
        # Alias doesn't start with a known namespace (extension command):
        # use alias as-is, no prefix.
        return aliased.replace(".", "-")
    except Exception:
        return f"speckit-{command.replace('.', '-')}"


def _is_fork() -> bool:
    """Return True when running against the tikalk fork (not upstream)."""
    return _cmd_prefix() == "spec"


def install_preset_to(project_root) -> None:
    """Copy the bundled agentic-sdlc preset into *project_root*/.specify/presets/.

    This makes ``build_alias_map(project_root)`` find the preset's
    ``replaces``/``aliases`` entries so that ``resolve_command_alias``
    returns fork-aliased names when called with *project_root*.

    Call this in tests that invoke ``integration.setup(tmp_path, …)``
    directly (rather than ``specify init``, which runs ``post_init`` and
    installs presets automatically).
    """
    if not _is_fork():
        return  # no-op on upstream

    import shutil
    from pathlib import Path

    # Locate bundled preset in source checkout
    bundled = Path(__file__).resolve().parent.parent / "presets" / "agentic-sdlc"
    if not (bundled / "preset.yml").exists():
        return  # no bundled preset available

    dest = Path(project_root) / ".specify" / "presets" / "agentic-sdlc"
    if dest.exists():
        return  # already installed

    dest.mkdir(parents=True, exist_ok=True)
    # Copy preset.yml (required for alias map) and commands/ (needed for skill content)
    shutil.copy2(bundled / "preset.yml", dest / "preset.yml")
    commands_src = bundled / "commands"
    if commands_src.is_dir():
        shutil.copytree(commands_src, dest / "commands", dirs_exist_ok=True)
    templates_src = bundled / "templates"
    if templates_src.is_dir():
        shutil.copytree(templates_src, dest / "templates", dirs_exist_ok=True)


# ---------------------------------------------------------------------------
# Auth config isolation — prevents tests from reading ~/.specify/auth.json
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def _isolate_auth_config(monkeypatch):
    """Ensure no test reads the real ~/.specify/auth.json."""
    from specify_cli.authentication import http as _auth_http
    monkeypatch.setattr(_auth_http, "_config_override", [])
    # Also clear the per-process cache so tests that unset _config_override
    # won't see a previously cached real-file result.
    monkeypatch.setattr(_auth_http, "_config_cache", None)


@pytest.fixture(autouse=True)
def _strip_specify_env(monkeypatch):
    """Drop any inherited SPECIFY_* vars for every test.

    The Python CLI's project resolver (`_require_specify_project`) now honors
    SPECIFY_INIT_DIR, and the shell resolvers honor SPECIFY_FEATURE* — so a
    developer or CI runner with any SPECIFY_* var exported would silently
    retarget (or hard-error) the many command/script tests that resolve a
    project. Stripping them here keeps resolution tests deterministic; a test
    that wants an override sets it explicitly via monkeypatch afterwards."""
    for key in [k for k in os.environ if k.startswith("SPECIFY_")]:
        monkeypatch.delenv(key, raising=False)


@pytest.fixture
def clean_environ(monkeypatch):
    """Strip any real GH_TOKEN / GITHUB_TOKEN from the test environment."""
    monkeypatch.delenv("GH_TOKEN", raising=False)
    monkeypatch.delenv("GITHUB_TOKEN", raising=False)


def _fake_self_upgrade_argv0(monkeypatch, tmp_path, env_name, path_parts):
    """Create a fake executable under tmp_path and point sys.argv[0] at it."""
    monkeypatch.setenv(env_name, str(tmp_path))
    fake_dir = tmp_path.joinpath(*path_parts)
    fake_dir.mkdir(parents=True)
    fake_specify = fake_dir / ("specify.exe" if os.name == "nt" else "specify")
    fake_specify.write_text("#!/usr/bin/env python\n")
    fake_specify.chmod(0o755)
    monkeypatch.setattr("sys.argv", [str(fake_specify)])
    return fake_specify


@pytest.fixture
def uv_tool_argv0(monkeypatch, tmp_path):
    """Point sys.argv[0] at a simulated `uv tool` install path under tmp HOME."""
    if os.name == "nt":
        return _fake_self_upgrade_argv0(
            monkeypatch, tmp_path, "LOCALAPPDATA", ("uv", "tools", "specify-cli", "bin")
        )
    return _fake_self_upgrade_argv0(
        monkeypatch,
        tmp_path,
        "HOME",
        (".local", "share", "uv", "tools", "specify-cli", "bin"),
    )


@pytest.fixture
def pipx_argv0(monkeypatch, tmp_path):
    """Point sys.argv[0] at a simulated pipx install path under tmp HOME."""
    if os.name == "nt":
        return _fake_self_upgrade_argv0(
            monkeypatch, tmp_path, "LOCALAPPDATA", ("pipx", "venvs", "specify-cli", "bin")
        )
    return _fake_self_upgrade_argv0(
        monkeypatch, tmp_path, "HOME", (".local", "pipx", "venvs", "specify-cli", "bin")
    )


@pytest.fixture
def uvx_ephemeral_argv0(monkeypatch, tmp_path):
    """Point sys.argv[0] at a simulated uvx ephemeral-cache path under tmp HOME."""
    if os.name == "nt":
        return _fake_self_upgrade_argv0(
            monkeypatch,
            tmp_path,
            "LOCALAPPDATA",
            ("uv", "cache", "archive-v0", "abc123", "bin"),
        )
    return _fake_self_upgrade_argv0(
        monkeypatch, tmp_path, "HOME", (".cache", "uv", "archive-v0", "abc123", "bin")
    )


@pytest.fixture
def unsupported_argv0(monkeypatch, tmp_path):
    """Point sys.argv[0] at a path that does not match any installer prefix."""
    return _fake_self_upgrade_argv0(
        monkeypatch, tmp_path, "HOME", ("random", "location", "bin")
    )
