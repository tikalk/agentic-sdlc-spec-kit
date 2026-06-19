"""
Workflow-dispatch fork customizations.

Leaf module with zero internal dependencies. Provides a tee-based
subprocess runner that both streams output live to the terminal AND
captures it for state persistence.

Dependency direction (locked):
    _workflows_fork.py  (THIS MODULE - pure constants, no internal imports)
"""

import subprocess
import sys
import threading


def get_workflow_stream_default() -> bool:
    """Return whether workflow steps should stream output to the terminal.

    When ``True`` (the default), steps stream live CLI output to the
    terminal AND capture stdout/stderr for state persistence via a
    tee implementation (see :func:`run_and_tee`).
    """
    return True


def run_and_tee(
    exec_args: list[str],
    cwd: str | None = None,
) -> dict[str, int | str]:
    """Run a subprocess, teeing stdout/stderr to both terminal and buffers.

    Uses ``subprocess.Popen`` with ``threading`` to read stdout/stderr
    concurrently, writing each line to the terminal (``sys.stdout``/
    ``sys.stderr``) while accumulating it for the return dict.

    Returns a dict with ``exit_code``, ``stdout``, and ``stderr``.
    Handles ``KeyboardInterrupt`` by terminating the child process
    and returning exit code 130.
    """
    proc = subprocess.Popen(
        exec_args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=cwd,
        bufsize=1,
    )
    stdout_lines: list[str] = []
    stderr_lines: list[str] = []

    def _tee(
        src: subprocess.PIPE,
        dest: sys.stdout,
        acc: list[str],
    ) -> None:
        for line in iter(src.readline, ""):
            dest.write(line)
            dest.flush()
            acc.append(line)
        src.close()

    t1 = threading.Thread(target=_tee, args=(proc.stdout, sys.stdout, stdout_lines))
    t2 = threading.Thread(target=_tee, args=(proc.stderr, sys.stderr, stderr_lines))
    t1.start()
    t2.start()

    try:
        proc.wait()
    except KeyboardInterrupt:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        return {"exit_code": 130, "stdout": "", "stderr": "Interrupted by user"}
    finally:
        t1.join()
        t2.join()

    return {
        "exit_code": proc.returncode,
        "stdout": "".join(stdout_lines),
        "stderr": "".join(stderr_lines),
    }
